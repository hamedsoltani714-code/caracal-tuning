import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _bookingBg = Color(0xFF08090B);
const Color _bookingPanel = Color(0xFF17191D);
const Color _bookingRed = Color(0xFFFF3038);
const Color _bookingSilver = Color(0xFFC5CBD2);

class BookingScreen extends StatefulWidget {
  final bool english;
  const BookingScreen({super.key, required this.english});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _appointments = [];
  Map<String, dynamic>? _branch;
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  String? _service;
  String? _slot;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _services = const ['ریمپ و تیونینگ', 'عیب‌یابی و دیاگ', 'بررسی و مشاوره'];

  String tr(String fa, String en) => widget.english ? en : fa;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _name.dispose(); _phone.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _db.from('branches').select().eq('active', true).order('name');
      _branches = List<Map<String, dynamic>>.from(rows);
      if (_branch == null && _branches.isNotEmpty) _branch = _branches.first;
      await _loadAppointments();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadAppointments() async {
    if (_branch == null) return;
    final start = DateTime(_day.year, _day.month, _day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _db.from('appointments').select('starts_at,ends_at,status')
      .eq('branch_id', _branch!['id'])
      .gte('starts_at', start.toIso8601String())
      .lt('starts_at', end.toIso8601String())
      .neq('status', 'cancelled');
    _appointments = List<Map<String, dynamic>>.from(rows);
    _slot = null;
  }

  Future<List<String>> _availableSlots() async {
    if (_branch == null) return [];
    final weekday = _day.weekday % 7;
    final hours = await _db.from('branch_hours').select()
      .eq('branch_id', _branch!['id']).eq('weekday', weekday).maybeSingle();
    if (hours == null || hours['is_closed'] == true) return [];
    final closures = await _db.from('branch_closures').select('id')
      .eq('branch_id', _branch!['id']).eq('closed_on', _day.toIso8601String().substring(0,10));
    if ((closures as List).isNotEmpty) return [];
    final open = (hours['opens_at'] as String).substring(0,5).split(':').map(int.parse).toList();
    final close = (hours['closes_at'] as String).substring(0,5).split(':').map(int.parse).toList();
    final step = (hours['slot_minutes'] as num?)?.toInt() ?? 30;
    final from = DateTime(_day.year,_day.month,_day.day,open[0],open[1]);
    final until = DateTime(_day.year,_day.month,_day.day,close[0],close[1]);
    final now = DateTime.now();
    final capacity = (_branch!['capacity'] as num?)?.toInt() ?? 1;
    final result = <String>[];
    for (var t = from; t.add(Duration(minutes: step)).isAfter(until) == false; t = t.add(Duration(minutes: step))) {
      if (t.isBefore(now.add(const Duration(minutes: 15)))) continue;
      final end = t.add(Duration(minutes: step));
      final occupied = _appointments.where((a) {
        final s = DateTime.parse(a['starts_at']).toLocal();
        final e = DateTime.parse(a['ends_at']).toLocal();
        return t.isBefore(e) && end.isAfter(s);
      }).length;
      if (occupied < capacity) result.add('${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}');
    }
    return result;
  }

  Future<void> _book() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      _message(tr('برای ثبت نوبت ابتدا وارد حساب شوید.','Sign in before booking.'));
      return;
    }
    if (_branch == null || _service == null || _slot == null || _name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      _message(tr('همه موارد را کامل کنید.','Complete all fields.'));
      return;
    }
    setState(() => _saving = true);
    try {
      final p = _slot!.split(':').map(int.parse).toList();
      final start = DateTime(_day.year,_day.month,_day.day,p[0],p[1]);
      final duration = const Duration(minutes: 30);
      final result = await _db.from('appointments').insert({
        'user_id': user.id,
        'branch_id': _branch!['id'],
        'customer_name': _name.text.trim(),
        'customer_phone': _phone.text.trim(),
        'service': _service,
        'starts_at': start.toUtc().toIso8601String(),
        'ends_at': start.add(duration).toUtc().toIso8601String(),
        'status': 'pending'
      }).select('tracking_code').single();
      _message('${tr('نوبت ثبت شد. کد پیگیری:','Booking created. Tracking code:')} ${result['tracking_code']}');
      await _loadAppointments();
    } on PostgrestException catch (e) {
      _message(e.message);
    } catch (e) { _message(e.toString()); }
    if (mounted) setState(() => _saving = false);
  }

  void _message(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bookingBg,
      appBar: AppBar(title: Text(tr('رزرو نوبت','Book an appointment')), backgroundColor: _bookingBg,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child:CircularProgressIndicator(color:_bookingRed))
      : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${tr('خطا در دریافت اطلاعات:','Could not load booking data:')}\n$_error',textAlign:TextAlign.center)))
      : _branches.isEmpty ? Center(child:Text(tr('هنوز شعبه‌ای ثبت نشده است.','No active branches yet.')))
      : FutureBuilder<List<String>>(
        future: _availableSlots(),
        builder: (context,snapshot) {
          final slots = snapshot.data ?? [];
          return ListView(padding:const EdgeInsets.all(18), children:[
            _section(tr('۱. انتخاب شعبه','1. Select branch')),
            DropdownButtonFormField<String>(
              value: _branch?['id']?.toString(),
              decoration:_input(tr('شعبه','Branch')),
              items:_branches.map((b)=>DropdownMenuItem(value:b['id'].toString(),child:Text(b['name']??''))).toList(),
              onChanged:(v) async { setState(()=>_branch=_branches.firstWhere((b)=>b['id'].toString()==v)); await _loadAppointments(); setState((){}); },
            ),
            const SizedBox(height:20),
            _section(tr('۲. نوع خدمات','2. Service')),
            DropdownButtonFormField<String>(
              value:_service, decoration:_input(tr('خدمت موردنظر','Choose service')),
              items:_services.map((s)=>DropdownMenuItem(value:s,child:Text(s))).toList(),
              onChanged:(v)=>setState(()=>_service=v),
            ),
            const SizedBox(height:20),
            _section(tr('۳. تاریخ مراجعه','3. Appointment date')),
            OutlinedButton.icon(
              onPressed:() async {
                final d=await showDatePicker(context:context,initialDate:_day,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:90)));
                if(d!=null){setState(()=>_day=DateUtils.dateOnly(d));await _loadAppointments();setState((){});}
              },
              icon:const Icon(Icons.calendar_month),label:Text('${_day.year}/${_day.month.toString().padLeft(2,'0')}/${_day.day.toString().padLeft(2,'0')}'),
            ),
            const SizedBox(height:12),
            _section(tr('۴. ساعت‌های آزاد','4. Available times')),
            if(snapshot.connectionState==ConnectionState.waiting) const Center(child:CircularProgressIndicator())
            else if(slots.isEmpty) Text(tr('برای این تاریخ ساعت آزادی وجود ندارد.','No available times for this date.'))
            else Wrap(spacing:8,runSpacing:8,children:slots.map((s)=>ChoiceChip(label:Text(s),selected:_slot==s,onSelected:(_)=>setState(()=>_slot=s),selectedColor:_bookingRed.withOpacity(.35))).toList()),
            const SizedBox(height:20),
            _section(tr('۵. مشخصات شما','5. Your details')),
            TextField(controller:_name,decoration:_input(tr('نام و نام خانوادگی','Full name'))),
            const SizedBox(height:10),
            TextField(controller:_phone,keyboardType:TextInputType.phone,decoration:_input(tr('شماره تماس','Phone number'))),
            const SizedBox(height:24),
            FilledButton(
              style:FilledButton.styleFrom(backgroundColor:_bookingRed,foregroundColor:Colors.white,padding:const EdgeInsets.all(16)),
              onPressed:_saving?null:_book,
              child:_saving?const CircularProgressIndicator():Text(tr('ثبت نوبت','Confirm booking')),
            ),
            const SizedBox(height:12),
            Text(tr('ثبت نهایی نوبت با کنترل ظرفیت سمت سرور انجام می‌شود.','Final booking capacity is validated securely on the server.'),style:const TextStyle(color:_bookingSilver,fontSize:12)),
          ]);
        },
      ),
    );
  }

  Widget _section(String s)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Text(s,style:const TextStyle(color:_bookingSilver,fontSize:16,fontWeight:FontWeight.bold)));
  InputDecoration _input(String label)=>InputDecoration(labelText:label,filled:true,fillColor:_bookingPanel,border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)));
}

class OwnerAdminScreen extends StatefulWidget {
  final bool english;
  const OwnerAdminScreen({super.key,required this.english});
  @override
  State<OwnerAdminScreen> createState()=>_OwnerAdminScreenState();
}

class _OwnerAdminScreenState extends State<OwnerAdminScreen> {
  final _db=Supabase.instance.client;
  final _branchName=TextEditingController();
  final _address=TextEditingController();
  List<Map<String,dynamic>> _branches=[];
  List<Map<String,dynamic>> _appointments=[];
  bool _loading=true;
  bool _owner=false;
  String? _error;
  String tr(String fa,String en)=>widget.english?en:fa;

  @override
  void initState(){super.initState();_load();}
  @override
  void dispose(){_branchName.dispose();_address.dispose();super.dispose();}

  Future<void> _load() async {
    setState(()=>_loading=true);
    try {
      final user=_db.auth.currentUser;
      if(user==null){_owner=false;_error=tr('ابتدا وارد حساب شوید.','Please sign in first.');}
      else {
        _owner=(user.email?.toLowerCase()=='hamedsoltani714@gmail.com');
        try { _owner=_owner || (await _db.rpc('is_caracal_owner')==true); } catch(_){}
        if(!_owner){
          final role=await _db.from('staff_roles').select('role').eq('user_id',user.id).maybeSingle();
          _owner=role?['role']=='admin';
        }
        if(_owner){
          _branches=List<Map<String,dynamic>>.from(await _db.from('branches').select().order('name'));
          _appointments=List<Map<String,dynamic>>.from(await _db.from('appointments').select('id,customer_name,customer_phone,service,starts_at,status,tracking_code,branches(name)').order('starts_at',ascending:false).limit(100));
        }
      }
    }catch(e){_error=e.toString();}
    if(mounted)setState(()=>_loading=false);
  }

  Future<void> _addBranch() async {
    if(_branchName.text.trim().isEmpty)return;
    try {
      await _db.from('branches').insert({'name':_branchName.text.trim(),'address':_address.text.trim(),'active':true,'capacity':1});
      _branchName.clear();_address.clear();await _load();
    }catch(e){_snack(e.toString());}
  }
  Future<void> _status(String id,String status) async {
    try{await _db.from('appointments').update({'status':status}).eq('id',id);await _load();}
    catch(e){_snack(e.toString());}
  }
  void _snack(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));

  @override
  Widget build(BuildContext context){
    return Scaffold(backgroundColor:_bookingBg,appBar:AppBar(title:Text(tr('مدیریت کاراکال','CARACAL management')),backgroundColor:_bookingBg,actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),
      body:_loading?const Center(child:CircularProgressIndicator()):_error!=null?Center(child:Text(_error!)):!_owner?Center(child:Text(tr('دسترسی مدیریت برای این حساب فعال نیست.','This account has no management access.'))):ListView(padding:const EdgeInsets.all(16),children:[
        Text(tr('مدیریت شعب','Branch management'),style:const TextStyle(color:_bookingSilver,fontSize:19,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        TextField(controller:_branchName,decoration:const InputDecoration(labelText:'نام شعبه')),
        TextField(controller:_address,decoration:const InputDecoration(labelText:'آدرس')),
        const SizedBox(height:8),FilledButton(onPressed:_addBranch,child:Text(tr('افزودن شعبه','Add branch'))),
        ..._branches.map((b)=>Card(color:_bookingPanel,child:ListTile(title:Text(b['name']??''),subtitle:Text(b['address']??''),trailing:Text((b['active']==true)?tr('فعال','Active'):tr('غیرفعال','Inactive'))))),
        const Divider(height:32),
        Text(tr('نوبت‌ها','Appointments'),style:const TextStyle(color:_bookingSilver,fontSize:19,fontWeight:FontWeight.bold)),
        ..._appointments.map((a){
          final id=a['id'].toString();final status=a['status']?.toString()??'pending';
          return Card(color:_bookingPanel,child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('${a['customer_name']??''} • ${a['service']??''}',style:const TextStyle(fontWeight:FontWeight.bold)),
            Text('${a['customer_phone']??''} | ${a['tracking_code']??''}'),
            Text('${a['starts_at']??''} • $status',style:const TextStyle(color:_bookingSilver,fontSize:12)),
            Wrap(spacing:8,children:[
              TextButton(onPressed:()=>_status(id,'confirmed'),child:Text(tr('تأیید','Confirm'))),
              TextButton(onPressed:()=>_status(id,'completed'),child:Text(tr('انجام شد','Complete'))),
              TextButton(onPressed:()=>_status(id,'cancelled'),child:Text(tr('لغو','Cancel'))),
            ])
          ])));
        })
      ]));
  }
}
