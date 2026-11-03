import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const url = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://fabbzaviesndfobxhrxf.supabase.co');
const anon = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZhYmJ6YXZpZXNuZGZvYnhocnhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM1MzEyNjcsImV4cCI6MjEwOTEwNzI2N30.mwJfaLmV0dKso2dsXxX3gr2naFYqFEFtGi6Nw731RNk');
const ownerEmail = 'hamed.soltani714@gmail.com';
const bg = Color(0xFF08090B), panel = Color(0xFF15171B), silver = Color(0xFFC5CBD2), red = Color(0xFFFF3038);
SupabaseClient get db => Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: url, anonKey: anon);
  runApp(const CaracalAdmin());
}
class CaracalAdmin extends StatelessWidget {
  const CaracalAdmin({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner:false, title:'CARACAL ADMIN',
    theme:ThemeData(brightness:Brightness.dark,scaffoldBackgroundColor:bg,colorScheme:const ColorScheme.dark(primary:red,surface:panel),useMaterial3:true),
    home:const Gate(),
  );
}
class Gate extends StatelessWidget {
  const Gate({super.key});
  @override Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream:db.auth.onAuthStateChange,
    builder:(context,_)=>db.auth.currentSession==null?const LoginPage():const AccessCheck(),
  );
}
class AccessCheck extends StatefulWidget {
  const AccessCheck({super.key});
  @override State<AccessCheck> createState()=>_AccessCheckState();
}
class _AccessCheckState extends State<AccessCheck> {
  late Future<Map<String,dynamic>> future;
  @override void initState(){super.initState();future=load();}
  Future<Map<String,dynamic>> load() async {
    final u=db.auth.currentUser!;
    final p=await db.from('profiles').select('id,email,role,permissions').eq('id',u.id).maybeSingle();
    if(p==null || !['owner','admin'].contains(p['role'])) {await db.auth.signOut();throw Exception('این حساب دسترسی مدیریت ندارد.');}
    if(p['role']=='owner' && (p['email']??u.email).toString().toLowerCase()!=ownerEmail){await db.auth.signOut();throw Exception('حساب مالک معتبر نیست.');}
    return Map<String,dynamic>.from(p);
  }
  @override Widget build(BuildContext context)=>FutureBuilder<Map<String,dynamic>>(future:future,builder:(context,s){
    if(s.connectionState!=ConnectionState.done)return const Scaffold(body:Center(child:CircularProgressIndicator(color:red)));
    if(s.hasError)return Scaffold(body:Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.lock_outline,color:red,size:48),Text(s.error.toString(),textAlign:TextAlign.center),FilledButton(onPressed:()=>db.auth.signOut(),child:const Text('بازگشت'))]))));
    return AdminHome(profile:s.data!);
  });
}
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState()=>_LoginPageState();
}
class _LoginPageState extends State<LoginPage>{
  final email=TextEditingController(),pass=TextEditingController(),code=TextEditingController();
  bool otp=false,busy=false,hide=true;String? error;
  @override void dispose(){email.dispose();pass.dispose();code.dispose();super.dispose();}
  Future<void> run(Future<void> Function() action) async {
    setState((){busy=true;error=null;});
    try{await action();}catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('Exception: ',''));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> signIn()=>run(()async{final e=email.text.trim().toLowerCase();if(!e.contains('@')||pass.text.length<6)throw Exception('ایمیل معتبر و گذرواژه را وارد کن.');await db.auth.signInWithPassword(email:e,password:pass.text);});
  Future<void> sendCode()=>run(()async{final e=email.text.trim().toLowerCase();if(!e.contains('@'))throw Exception('ایمیل معتبر وارد کن.');await db.auth.signInWithOtp(email:e,shouldCreateUser:false);setState(()=>otp=true);});
  Future<void> verify()=>run(()async{await db.auth.verifyOTP(email:email.text.trim().toLowerCase(),token:code.text.trim(),type:OtpType.email);});
  @override Widget build(BuildContext context)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(22),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),child:Card(color:panel,child:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Icon(Icons.pets,size:58,color:silver),const Text('CARACAL',textAlign:TextAlign.center,style:TextStyle(fontSize:28,fontWeight:FontWeight.w900,letterSpacing:5)),
    const Text('ADMIN CONTROL CENTER',textAlign:TextAlign.center,style:TextStyle(color:red,fontSize:11,letterSpacing:2)),
    const Text('DRIVE • LEARN • UPGRADE',textAlign:TextAlign.center,style:TextStyle(color:silver,fontSize:10)),
    const SizedBox(height:25),const Text('ورود امن مالک و مدیران',textAlign:TextAlign.center,style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    const SizedBox(height:15),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ایمیل')),
    if(!otp)TextField(controller:pass,obscureText:hide,decoration:InputDecoration(labelText:'گذرواژه',suffixIcon:IconButton(onPressed:()=>setState(()=>hide=!hide),icon:Icon(hide?Icons.visibility:Icons.visibility_off)))),
    if(otp)TextField(controller:code,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'کد یک‌بارمصرف ایمیل')),
    if(error!=null)Padding(padding:const EdgeInsets.all(8),child:Text(error!,style:const TextStyle(color:Colors.orangeAccent))),
    const SizedBox(height:12),FilledButton(onPressed:busy?null:(otp?verify:signIn),child:Text(busy?'در حال اتصال…':otp?'تأیید کد و ورود':'ورود با گذرواژه')),
    TextButton(onPressed:busy?null:(otp?()=>setState(()=>otp=false):sendCode),child:Text(otp?'بازگشت':'ورود با کد ایمیل')),
    const Text('ساخت حساب جدید غیرفعال است؛ فقط حساب‌های دارای نقش owner یا admin مجازند.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white54,fontSize:11)),
  ])))))));
}
class AdminHome extends StatefulWidget {
  final Map<String,dynamic> profile;const AdminHome({super.key,required this.profile});
  @override State<AdminHome> createState()=>_AdminHomeState();
}
class _AdminHomeState extends State<AdminHome>{
  int tab=0;bool busy=false;String? error;
  List<Map<String,dynamic>> bookings=[],lessons=[],users=[],memberships=[],notifications=[];
  bool get owner=>widget.profile['role']=='owner';
  Map<String,dynamic> get perms=>Map<String,dynamic>.from(widget.profile['permissions']??{});
  bool get canBookings=>owner||perms['manage_bookings']==true;
  bool get canContent=>owner||perms['manage_content']==true;
  bool get canUsers=>owner||perms['manage_users']==true;
  bool get canPublish=>owner||perms['publish_content']==true;
  bool get canMemberships=>owner||perms['manage_memberships']==true;
  bool get canNotifications=>owner||perms['manage_notifications']==true;
  @override void initState(){super.initState();refresh();}
  Future<void> refresh()async{
    if(mounted)setState((){busy=true;error=null;});
    try{
      if(canBookings){final r=await db.from('booking_requests').select('*').order('created_at',ascending:false).limit(200);bookings=List<Map<String,dynamic>>.from(r);}
      if(canContent){final r=await db.from('lessons').select('*').order('created_at',ascending:false).limit(200);lessons=List<Map<String,dynamic>>.from(r);}
      if(owner||canUsers||canMemberships){final r=await db.from('profiles').select('id,email,role,permissions').order('created_at',ascending:false).limit(300);users=List<Map<String,dynamic>>.from(r);}
      if(canMemberships){final r=await db.from('memberships').select('*').order('created_at',ascending:false).limit(300);memberships=List<Map<String,dynamic>>.from(r);}
      if(canNotifications){final r=await db.from('app_notifications').select('*').order('created_at',ascending:false).limit(300);notifications=List<Map<String,dynamic>>.from(r);}
    }catch(e){error=e.toString();}
    if(mounted)setState(()=>busy=false);
  }
  Future<void> act(Future<void> Function() action)async{
    setState((){busy=true;error=null;});
    try{await action();await refresh();}catch(e){if(mounted)setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> changeBooking(Map<String,dynamic>b,String status)=>act(()async{await db.from('booking_requests').update({'status':status}).eq('id',b['id']);});
  Future<void> saveLesson(Map<String,dynamic> l)=>act(()async{
    final data=<String,dynamic>{for(final k in ['title','title_fa','title_en','summary','summary_fa','summary_en','body','body_fa','body_en','category','is_published','media_url','media_type'])if(l.containsKey(k))k:l[k]};
    if(l['id']==null){data['created_by']=db.auth.currentUser!.id; if(!canPublish)data['is_published']=false; await db.from('lessons').insert(data);}else{if(!canPublish)data['is_published']=false; await db.from('lessons').update(data).eq('id',l['id']);}
  });
  Future<void> invite(String mail,Map<String,bool> p)=>act(()async{
    if(!owner)throw Exception('فقط مالک اجازه دعوت مدیر دارد.');
    final r=await db.functions.invoke('create-admin',body:{'email':mail,'permissions':p});
    if(r.status>=400)throw Exception(r.data.toString());
  });
  Future<void> savePermissions(String id,Map<String,dynamic> p)=>act(()async{
    if(!owner)throw Exception('فقط مالک اجازه تغییر دسترسی دارد.');
    await db.from('profiles').update({'permissions':p}).eq('id',id).eq('role','admin');
  });
  @override Widget build(BuildContext context){
    final pages=<({String name,IconData icon,Widget page})>[
      (name:'خانه',icon:Icons.dashboard_outlined,page:overview()),
      if(canBookings)(name:'نوبت‌ها',icon:Icons.calendar_month_outlined,page:bookingPage()),
      if(canContent)(name:'آموزش',icon:Icons.school_outlined,page:contentPage()),
      if(canMemberships)(name:'اشتراک‌ها',icon:Icons.workspace_premium_outlined,page:membershipsPage()),
      if(canNotifications)(name:'اعلان‌ها',icon:Icons.notifications_active_outlined,page:notificationsPage()),
      if(owner||canUsers)(name:'کاربران',icon:Icons.people_outline,page:usersPage()),
      if(owner)(name:'مدیران',icon:Icons.admin_panel_settings_outlined,page:adminsPage()),
    ];
    if(tab>=pages.length)tab=0;
    return Scaffold(appBar:AppBar(backgroundColor:bg,title:const Text('CARACAL ADMIN',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1.3)),actions:[
      IconButton(onPressed:busy?null:refresh,icon:const Icon(Icons.refresh)),IconButton(onPressed:()=>db.auth.signOut(),icon:const Icon(Icons.logout))
    ]),
    body:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,0,16,12),child:Row(children:[const CircleAvatar(backgroundColor:panel,child:Icon(Icons.verified_user,color:silver)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(owner?'مالک اصلی':(widget.profile['email']?.toString()??'')),Text(owner?'OWNER • مالک اصلی':'ADMIN • مدیر',style:const TextStyle(color:red,fontSize:10,fontWeight:FontWeight.bold))]))])),
      if(error!=null)Padding(padding:const EdgeInsets.all(10),child:Text(error!,style:const TextStyle(color:Colors.orangeAccent))),
      if(busy)const LinearProgressIndicator(color:red,minHeight:2),
      Expanded(child:RefreshIndicator(color:red,onRefresh:refresh,child:IndexedStack(index:tab,children:pages.map((p)=>p.page).toList()))),
    ]),
    bottomNavigationBar:NavigationBar(backgroundColor:panel,indicatorColor:red.withOpacity(.2),selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:pages.map((p)=>NavigationDestination(icon:Icon(p.icon),label:p.name)).toList()));
  }
  Widget card(Widget child)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(17),border:Border.all(color:Colors.white10)),child:child);
  Widget empty(String text)=>Padding(padding:const EdgeInsets.all(25),child:Center(child:Text(text,style:const TextStyle(color:silver))));
  Widget overview(){
    final items=<({String title,String value,IconData icon})>[
      (title:'درخواست نوبت',value:canBookings?bookings.length.toString():'—',icon:Icons.calendar_month),
      (title:'در انتظار بررسی',value:canBookings?bookings.where((b)=>b['status']=='pending').length.toString():'—',icon:Icons.pending_actions),
      (title:'مطالب آموزشی',value:canContent?lessons.length.toString():'—',icon:Icons.menu_book),
      (title:'کاربران',value:owner||canUsers?users.length.toString():'—',icon:Icons.people),
    ];
    return ListView(padding:const EdgeInsets.all(16),children:[
      const Text('مرکز فرماندهی',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900)),const Text('مدیریت متمرکز CARACAL TUNING',style:TextStyle(color:silver)),const SizedBox(height:18),
      GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.35,crossAxisSpacing:10,mainAxisSpacing:10,children:items.map((x)=>card(Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(x.icon,color:red),Text(x.value,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),Text(x.title,style:const TextStyle(color:silver,fontSize:11))]))).toList()),
      card(Text(owner?'مالک اصلی: دسترسی کامل به تمام بخش‌ها.':'دسترسی‌ها: '+[if(canBookings)'نوبت‌ها',if(canContent)'محتوا',if(canUsers)'کاربران'].join(' • '),style:const TextStyle(color:silver))),
      card(const Text('داده‌ها مستقیماً از Supabase خوانده می‌شوند. امنیت نهایی باید با سیاست‌های RLS دیتابیس اعمال شود.',style:TextStyle(color:Colors.white54,fontSize:12))),
    ]);
  }
  Widget bookingPage()=>ListView(padding:const EdgeInsets.all(14),children:[
    const Text('درخواست‌های نوبت',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:12),
    if(bookings.isEmpty)empty('درخواستی ثبت نشده است.'),
    ...bookings.map((b)=>card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(b['customer_name']?.toString()??'مشتری',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
      Text((b['vehicle']??'—').toString()+' • '+(b['service']??'—').toString(),style:const TextStyle(color:silver)),
      Text((b['preferred_date']??'').toString()+' | '+(b['preferred_time']??'').toString()),
      Text('تماس: '+(b['phone']??'—').toString(),style:const TextStyle(color:silver,fontSize:12)),
      Wrap(spacing:5,children:[for(final e in {'pending':'در انتظار','confirmed':'تأیید','completed':'انجام شد','cancelled':'لغو'}.entries)OutlinedButton(onPressed:busy?null:()=>changeBooking(b,e.key),child:Text(e.value,style:const TextStyle(fontSize:10)))]),
    ]))),
  ]);
  Widget contentPage()=>ListView(padding:const EdgeInsets.all(14),children:[
    Row(children:[const Expanded(child:Text('محتوای آموزشی',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:()=>editLesson(),icon:const Icon(Icons.add),label:const Text('افزودن'))]),
    if(lessons.isEmpty)empty('هنوز مطلبی ثبت نشده است.'),
    ...lessons.map((l)=>card(ListTile(contentPadding:EdgeInsets.zero,title:Text((l['title_fa']??l['title']??'بدون عنوان').toString()),subtitle:Text((l['title_en']??'').toString()+' • '+((l['is_published']==true)?'منتشرشده':'پیش‌نویس')),trailing:IconButton(onPressed:()=>editLesson(existing:l),icon:const Icon(Icons.edit,color:silver))))),
  ]);
  Future<void> editLesson({Map<String,dynamic>? existing})async{
    final l=<String,dynamic>{'id':existing?['id'], 'title_fa':existing?['title_fa']??existing?['title']??'','title_en':existing?['title_en']??'','summary_fa':existing?['summary_fa']??existing?['summary']??'','summary_en':existing?['summary_en']??'','body_fa':existing?['body_fa']??existing?['body']??'','body_en':existing?['body_en']??'','category':existing?['category']??'general','is_published':existing?['is_published']==true};
    final c=<String,TextEditingController>{for(final k in ['title_fa','title_en','summary_fa','summary_en','body_fa','body_en','category'])k:TextEditingController(text:l[k].toString())};
    bool published=canPublish && l['is_published']==true;
    String mediaUrl=(existing?['media_url']??'').toString();
    String mediaType=(existing?['media_type']??'none').toString();
    bool uploading=false;
    Future<void> pickMedia(StateSetter setDialog) async {
      try {
        final result=await FilePicker.platform.pickFiles(type:FileType.any,withData:true);
        if(result==null || result.files.isEmpty)return;
        final file=result.files.single;
        final bytes=file.bytes;
        if(bytes==null || bytes.isEmpty)throw Exception('خواندن فایل انتخاب‌شده ممکن نشد.');
        if(bytes.length>50*1024*1024)throw Exception('حداکثر حجم فایل ۵۰ مگابایت است.');
        final ext=(file.extension??'').toLowerCase();
        final type=['jpg','jpeg','png','webp','gif'].contains(ext)?'image':
          ['mp4','mov','webm','m4v'].contains(ext)?'video':'document';
        final safeName=file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
        final path='lessons/${DateTime.now().millisecondsSinceEpoch}_$safeName';
        setDialog(()=>uploading=true);
        final contentType=type=='image'?(ext=='jpg'?'image/jpeg':'image/$ext'):
          type=='video'?'video/$ext':'application/octet-stream';
        await db.storage.from('caracal-media').uploadBinary(path,bytes,
          fileOptions:FileOptions(contentType:contentType,upsert:false));
        mediaUrl=db.storage.from('caracal-media').getPublicUrl(path);
        mediaType=type;
        setDialog((){});
      }catch(e){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('بارگذاری ناموفق: $e')));
      }finally{setDialog(()=>uploading=false);}
    }
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(backgroundColor:panel,title:Text(existing==null?'آموزش جدید':'ویرایش آموزش'),content:SizedBox(width:480,child:SingleChildScrollView(child:Column(children:[
      for(final e in {'title_fa':'عنوان فارسی','title_en':'عنوان انگلیسی','summary_fa':'خلاصه فارسی','summary_en':'خلاصه انگلیسی','body_fa':'متن فارسی','body_en':'متن انگلیسی','category':'دسته‌بندی'}.entries)Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:c[e.key],maxLines:e.key.startsWith('body')?4:1,decoration:InputDecoration(labelText:e.value))),
      SwitchListTile(value:published,onChanged:canPublish?(v)=>setDialog(()=>published=v):null,title:const Text('انتشار مطلب'),subtitle:canPublish?null:const Text('انتشار فقط با مجوز مالک امکان‌پذیر است.')), 
      const SizedBox(height:10),
      Align(alignment:Alignment.centerRight,child:Text('رسانه آموزشی',style:TextStyle(color:silver,fontWeight:FontWeight.bold))),
      if(mediaUrl.isNotEmpty)SelectableText(mediaUrl,style:const TextStyle(fontSize:10,color:silver)),
      Row(children:[
        Expanded(child:OutlinedButton.icon(onPressed:uploading?null:()=>pickMedia(setDialog),icon:uploading?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.upload_file),label:Text(uploading?'در حال بارگذاری…':'انتخاب و بارگذاری فایل'))),
        if(mediaUrl.isNotEmpty)IconButton(tooltip:'حذف پیوند رسانه',onPressed:()=>setDialog((){mediaUrl='';mediaType='none';}),icon:const Icon(Icons.delete_outline,color:red)),
      ]),
    ]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('انصراف')),FilledButton(onPressed:busy?null:()async{for(final k in c.keys){l[k]=c[k]!.text.trim();}l['is_published']=published;l['media_url']=mediaUrl;l['media_type']=mediaType;Navigator.pop(ctx);await saveLesson(l);},child:const Text('ذخیره'))])));
    for(final x in c.values){x.dispose();}
  }
  Widget usersPage()=>ListView(padding:const EdgeInsets.all(14),children:[
    const Text('کاربران',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),
    if(users.isEmpty)empty('کاربری برای نمایش وجود ندارد.'),
    ...users.map((u)=>card(ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.person_outline,color:silver),title:Text(u['role']=='owner'?'مالک اصلی':(u['email']?.toString()??'بدون ایمیل')),subtitle:Text('نقش: '+(u['role']??'user').toString())))),
  ]);
  Widget membershipsPage()=>ListView(padding:const EdgeInsets.all(14),children:[
    Row(children:[const Expanded(child:Text('مدیریت اشتراک‌ها',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:()=>editMembership(),icon:const Icon(Icons.add),label:const Text('ثبت اشتراک'))]),
    const SizedBox(height:10),
    if(memberships.isEmpty)empty('اشتراکی ثبت نشده است.'),
    ...memberships.map((m)=>card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text((()=>users.firstWhere((u)=>u['id']==m['user_id'],orElse:()=>{'email':m['user_id']})['role']=='owner'?'مالک اصلی':(users.firstWhere((u)=>u['id']==m['user_id'],orElse:()=>{'email':m['user_id']})['email']?.toString()??'کاربر'))(),style:const TextStyle(fontWeight:FontWeight.bold)),
      Text('طرح: ${m['plan']} • وضعیت: ${m['status']}',style:const TextStyle(color:silver)),
      if((m['notes']??'').toString().isNotEmpty)Text(m['notes'].toString(),style:const TextStyle(color:silver)),
      Row(children:[OutlinedButton(onPressed:()=>editMembership(existing:m),child:const Text('ویرایش')),const SizedBox(width:8),OutlinedButton(onPressed:()=>act(()async{await db.from('memberships').delete().eq('id',m['id']);}),child:const Text('حذف'))])
    ]))),
  ]);
  Future<void> editMembership({Map<String,dynamic>? existing})async{
    String? userId=existing?['user_id']?.toString()??(users.isNotEmpty?users.first['id']?.toString():null);
    final plan=TextEditingController(text:existing?['plan']?.toString()??'standard');
    final notes=TextEditingController(text:existing?['notes']?.toString()??'');
    String status=existing?['status']?.toString()??'pending';
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(
      backgroundColor:panel,title:Text(existing==null?'اشتراک جدید':'ویرایش اشتراک'),
      content:SizedBox(width:420,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<String>(value:userId,decoration:const InputDecoration(labelText:'کاربر'),items:users.map((u)=>DropdownMenuItem(value:u['id'].toString(),child:Text(u['email']?.toString()??u['id'].toString()))).toList(),onChanged:(v)=>setDialog(()=>userId=v)),
        TextField(controller:plan,decoration:const InputDecoration(labelText:'نام طرح')),
        DropdownButtonFormField<String>(value:status,decoration:const InputDecoration(labelText:'وضعیت'),items:['pending','active','expired','cancelled'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setDialog(()=>status=v??status)),
        TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'یادداشت')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('لغو')),FilledButton(onPressed:userId==null?null:()async{
        final data=<String,dynamic>{'user_id':userId,'plan':plan.text.trim(),'status':status,'notes':notes.text.trim(),if(existing==null)'created_by':db.auth.currentUser!.id};
        Navigator.pop(ctx);await act(()async{if(existing==null){await db.from('memberships').insert(data);}else{await db.from('memberships').update(data).eq('id',existing['id']);}});
      },child:const Text('ذخیره'))],
    )));
    plan.dispose();notes.dispose();
  }
  Widget notificationsPage()=>ListView(padding:const EdgeInsets.all(14),children:[
    Row(children:[const Expanded(child:Text('مرکز اعلان‌ها',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900))),FilledButton.icon(onPressed:()=>editNotification(),icon:const Icon(Icons.add),label:const Text('اعلان جدید'))]),
    const SizedBox(height:10),
    if(notifications.isEmpty)empty('اعلانی ثبت نشده است.'),
    ...notifications.map((n)=>card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(n['title_fa']?.toString()??'',style:const TextStyle(fontWeight:FontWeight.bold)),
      Text(n['body_fa']?.toString()??'',maxLines:3,overflow:TextOverflow.ellipsis,style:const TextStyle(color:silver)),
      Row(children:[Text(n['is_published']==true?'منتشرشده':'پیش‌نویس',style:const TextStyle(color:red)),const Spacer(),OutlinedButton(onPressed:()=>editNotification(existing:n),child:const Text('ویرایش')),IconButton(onPressed:()=>act(()async{await db.from('app_notifications').delete().eq('id',n['id']);}),icon:const Icon(Icons.delete_outline,color:red))])
    ]))),
  ]);
  Future<void> editNotification({Map<String,dynamic>? existing})async{
    final titleFa=TextEditingController(text:existing?['title_fa']?.toString()??'');
    final titleEn=TextEditingController(text:existing?['title_en']?.toString()??'');
    final bodyFa=TextEditingController(text:existing?['body_fa']?.toString()??'');
    final bodyEn=TextEditingController(text:existing?['body_en']?.toString()??'');
    bool published=existing?['is_published']==true;
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setDialog)=>AlertDialog(
      backgroundColor:panel,title:Text(existing==null?'اعلان جدید':'ویرایش اعلان'),
      content:SizedBox(width:460,child:SingleChildScrollView(child:Column(children:[
        TextField(controller:titleFa,decoration:const InputDecoration(labelText:'عنوان فارسی')),
        TextField(controller:titleEn,decoration:const InputDecoration(labelText:'عنوان انگلیسی')),
        TextField(controller:bodyFa,maxLines:4,decoration:const InputDecoration(labelText:'متن فارسی')),
        TextField(controller:bodyEn,maxLines:4,decoration:const InputDecoration(labelText:'متن انگلیسی')),
        SwitchListTile(value:published,onChanged:(v)=>setDialog(()=>published=v),title:const Text('انتشار اعلان')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('لغو')),FilledButton(onPressed:()async{
        final data=<String,dynamic>{'title_fa':titleFa.text.trim(),'title_en':titleEn.text.trim(),'body_fa':bodyFa.text.trim(),'body_en':bodyEn.text.trim(),'is_published':published,if(existing==null)'created_by':db.auth.currentUser!.id};
        Navigator.pop(ctx);await act(()async{if(existing==null){await db.from('app_notifications').insert(data);}else{await db.from('app_notifications').update(data).eq('id',existing['id']);}});
      },child:const Text('ذخیره'))],
    )));
    titleFa.dispose();titleEn.dispose();bodyFa.dispose();bodyEn.dispose();
  }
  Widget adminsPage()=>ListView(padding:const EdgeInsets.all(14),children:[
    const Text('مدیریت مدیران',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900)),
    card(InviteAdmin(onInvite:invite)),
    ...users.where((u)=>u['role']=='admin').map((u)=>AdminPermissions(user:u,onSave:savePermissions)),
  ]);
}
class InviteAdmin extends StatefulWidget{
  final Future<void> Function(String,Map<String,bool>) onInvite;const InviteAdmin({super.key,required this.onInvite});
  @override State<InviteAdmin> createState()=>_InviteAdminState();
}
class _InviteAdminState extends State<InviteAdmin>{
  final email=TextEditingController();final p=<String,bool>{'manage_content':true,'publish_content':false,'manage_users':false,'manage_bookings':false,'manage_memberships':false,'manage_notifications':false};bool busy=false;
  @override void dispose(){email.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('دعوت مدیر جدید',style:TextStyle(fontSize:16,fontWeight:FontWeight.bold)),TextField(controller:email,onChanged:(_)=>setState((){}),keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'ایمیل مدیر')), 
    for(final e in {'manage_content':'مدیریت محتوا','publish_content':'انتشار محتوا','manage_users':'مدیریت کاربران','manage_bookings':'مدیریت نوبت‌ها','manage_memberships':'مدیریت اشتراک‌ها','manage_notifications':'مدیریت اعلان‌ها'}.entries)CheckboxListTile(contentPadding:EdgeInsets.zero,dense:true,value:p[e.key],onChanged:(v)=>setState(()=>p[e.key]=v??false),title:Text(e.value)),
    SizedBox(width:double.infinity,child:FilledButton(onPressed:busy||!email.text.contains('@')?null:()async{setState(()=>busy=true);try{await widget.onInvite(email.text.trim(),p);email.clear();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('درخواست دعوت ارسال شد.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}finally{if(mounted)setState(()=>busy=false);}},child:Text(busy?'در حال ارسال…':'دعوت مدیر'))),
  ]);
}
class AdminPermissions extends StatefulWidget{
  final Map<String,dynamic> user;final Future<void> Function(String,Map<String,dynamic>) onSave;
  const AdminPermissions({super.key,required this.user,required this.onSave});
  @override State<AdminPermissions> createState()=>_AdminPermissionsState();
}
class _AdminPermissionsState extends State<AdminPermissions>{
  late Map<String,dynamic> p;
  @override void initState(){super.initState();p=Map<String,dynamic>.from(widget.user['permissions']??{});}
  @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(widget.user['role']=='owner'?'مالک اصلی':(widget.user['email']?.toString()??''),style:const TextStyle(fontWeight:FontWeight.bold)),
    for(final e in {'manage_content':'مدیریت محتوا','publish_content':'انتشار محتوا','manage_users':'مدیریت کاربران','manage_bookings':'مدیریت نوبت‌ها','manage_memberships':'مدیریت اشتراک‌ها','manage_notifications':'مدیریت اعلان‌ها'}.entries)CheckboxListTile(contentPadding:EdgeInsets.zero,dense:true,value:p[e.key]==true,onChanged:(v)=>setState(()=>p[e.key]=v??false),title:Text(e.value)),
    Align(alignment:Alignment.centerLeft,child:OutlinedButton(onPressed:()=>widget.onSave(widget.user['id'].toString(),p),child:const Text('ذخیره دسترسی‌ها'))),
  ]));
}
