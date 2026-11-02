import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bookingBg = Color(0xFF08090B);
const _bookingPanel = Color(0xFF15171B);
const _bookingRed = Color(0xFFFF3038);

class BookingScreen extends StatefulWidget {
  final bool english;
  const BookingScreen({super.key, required this.english});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _vehicle = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _time = '10:00';
  String _service = 'ریمپ و کالیبراسیون';
  bool _busy = false;
  bool _admin = false;
  String? _message;
  List<Map<String, dynamic>> _requests = [];

  bool get _en => widget.english;
  String t(String fa, String en) => _en ? en : fa;
  SupabaseClient get _client => Supabase.instance.client;
  bool get _configured {
    try { return Supabase.instance.client.auth.currentUser != null || true; }
    catch (_) { return false; }
  }
  bool get _signedIn {
    try { return _client.auth.currentUser != null; } catch (_) { return false; }
  }

  @override
  void initState() { super.initState(); _loadRequests(); }
  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _vehicle.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (!_signedIn) return;
    try {
      final profile = await _client.from('profiles').select('role,permissions').eq('id', _client.auth.currentUser!.id).maybeSingle();
      final role = profile?['role']?.toString();
      final perms = Map<String, dynamic>.from(profile?['permissions'] as Map? ?? {});
      final isAdmin = role == 'owner' || role == 'admin' || perms['manage_bookings'] == true;
      _admin = isAdmin;
      final rows = isAdmin
          ? await _client.from('booking_requests').select().order('created_at', ascending: false).limit(100)
          : await _client.from('booking_requests').select().eq('user_id', _client.auth.currentUser!.id).order('created_at', ascending: false);
      if (mounted) setState(() => _requests = List<Map<String, dynamic>>.from(rows));
    } catch (e) { if (mounted) setState(() => _message = e.toString()); }
  }

  Future<void> _submit() async {
    if (!_signedIn) { setState(() => _message = t('برای ثبت نوبت ابتدا از بخش گاراژ وارد حساب شو.', 'Sign in from the Garage tab before booking.')); return; }
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty || _vehicle.text.trim().isEmpty) {
      setState(() => _message = t('نام، شماره تماس و خودرو را کامل کن.', 'Enter your name, phone number and vehicle.')); return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      await _client.from('booking_requests').insert({
        'user_id': _client.auth.currentUser!.id,
        'customer_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'vehicle': _vehicle.text.trim(),
        'service': _service,
        'preferred_date': '${_date.year.toString().padLeft(4,'0')}-${_date.month.toString().padLeft(2,'0')}-${_date.day.toString().padLeft(2,'0')}',
        'preferred_time': _time,
        'notes': _notes.text.trim(),
        'status': 'pending',
      });
      _name.clear(); _phone.clear(); _vehicle.clear(); _notes.clear();
      setState(() => _message = t('درخواست نوبت ثبت شد؛ پس از بررسی با تو تماس گرفته می‌شود.', 'Booking request submitted. You will be contacted after review.'));
      await _loadRequests();
    } catch (e) { setState(() => _message = '${t('ثبت نوبت ناموفق بود: ', 'Booking failed: ')}$e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _changeStatus(Map<String, dynamic> row, String status) async {
    try {
      await _client.from('booking_requests').update({'status': status}).eq('id', row['id']);
      await _loadRequests();
    } catch (e) { if (mounted) setState(() => _message = e.toString()); }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Text(t('درخواست نوبت کاراکال', 'CARACAL APPOINTMENTS'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
    const SizedBox(height: 6),
    Text(t('درخواست خدمات تخصصی خودرو', 'Request a specialist vehicle service'), style: const TextStyle(color: Colors.white60)),
    const SizedBox(height: 18),
    if (!_signedIn) _card(Column(children: [const Icon(Icons.lock_outline, color: Colors.white70, size: 36), const SizedBox(height: 8), Text(t('برای ثبت نوبت باید وارد حساب کاربری شوی.', 'Please sign in to submit a booking.'), textAlign: TextAlign.center)])),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _field(_name, t('نام و نام خانوادگی', 'Full name')),
      _field(_phone, t('شماره تماس', 'Phone number'), type: TextInputType.phone),
      _field(_vehicle, t('مدل خودرو', 'Vehicle model')),
      DropdownButtonFormField<String>(value: _service, decoration: InputDecoration(labelText: t('نوع خدمات', 'Service'), border: const OutlineInputBorder()), items: [
        DropdownMenuItem(value: 'ریمپ و کالیبراسیون', child: Text(t('ریمپ و کالیبراسیون', 'ECU remapping & calibration'))),
        DropdownMenuItem(value: 'عیب‌یابی تخصصی', child: Text(t('عیب‌یابی تخصصی', 'Advanced diagnostics'))),
        DropdownMenuItem(value: 'مشاوره فنی', child: Text(t('مشاوره فنی', 'Technical consultation'))),
        DropdownMenuItem(value: 'بررسی و بازبینی', child: Text(t('بررسی و بازبینی', 'Inspection'))),
      ], onChanged: (v) => setState(() => _service = v ?? _service)),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 180))); if (d != null) setState(() => _date = d); }, icon: const Icon(Icons.calendar_today), label: Text('${t('تاریخ پیشنهادی: ', 'Preferred date: ')}${_date.year}/${_date.month}/${_date.day}')),
      DropdownButtonFormField<String>(value: _time, decoration: InputDecoration(labelText: t('ساعت پیشنهادی', 'Preferred time'), border: const OutlineInputBorder()), items: ['09:00','10:00','11:00','12:00','14:00','15:00','16:00','17:00','18:00'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _time = v ?? _time)),
      const SizedBox(height: 12),
      _field(_notes, t('توضیحات تکمیلی (اختیاری)', 'Additional notes (optional)'), lines: 3),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: _busy ? null : _submit, icon: _busy ? const SizedBox(width: 16,height: 16,child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send), label: Text(t('ثبت درخواست نوبت', 'SUBMIT BOOKING'))),
    ])),
    if (_message != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: SelectableText(_message!, style: const TextStyle(color: Colors.white70))),
    const SizedBox(height: 14),
    Row(children: [Expanded(child: Text(t('درخواست‌های من / مدیریت نوبت‌ها', 'MY REQUESTS / BOOKING MANAGEMENT'), style: const TextStyle(fontWeight: FontWeight.w900))), IconButton(onPressed: _loadRequests, icon: const Icon(Icons.refresh, color: _bookingRed))]),
    if (_requests.isEmpty) Text(t('هنوز درخواستی ثبت نشده است.', 'No booking requests yet.'), style: const TextStyle(color: Colors.white54)),
    ..._requests.map(_requestCard),
  ]);

  Widget _field(TextEditingController c, String label, {TextInputType type = TextInputType.text, int lines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: c, keyboardType: type, maxLines: lines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
  Widget _card(Widget child) => Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _bookingPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: child);
  Widget _requestCard(Map<String, dynamic> row) {
    final status = row['status']?.toString() ?? 'pending';
    final statusText = {'pending': t('در انتظار بررسی','Pending'), 'confirmed': t('تأیید شده','Confirmed'), 'completed': t('انجام شده','Completed'), 'cancelled': t('لغو شده','Cancelled')}[status] ?? status;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${row['service'] ?? ''} • ${row['vehicle'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text('${row['preferred_date'] ?? ''}  ${row['preferred_time'] ?? ''}'),
      Text('${t('وضعیت: ','Status: ')}$statusText', style: const TextStyle(color: _bookingRed, fontWeight: FontWeight.bold)),
      if (row['customer_name'] != null) Text('${row['customer_name']} • ${row['phone'] ?? ''}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
      if (row['notes'] != null && row['notes'].toString().isNotEmpty) Text(row['notes'].toString(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
      if (_admin) Wrap(spacing: 8, children: [TextButton(onPressed: () => _changeStatus(row,'confirmed'), child: Text(t('تأیید','Confirm'))), TextButton(onPressed: () => _changeStatus(row,'completed'), child: Text(t('انجام شد','Complete'))), TextButton(onPressed: () => _changeStatus(row,'cancelled'), child: Text(t('لغو','Cancel')))]),
    ]));
  }

}
