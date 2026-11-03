import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

const _bookingBg = Color(0xFF08090B);
const _bookingPanel = Color(0xFF15171B);
const _bookingRed = Color(0xFFFF3038);
const _bookingSilver = Color(0xFFC5CBD2);

class BookingScreen extends StatefulWidget {
  final bool english;

  const BookingScreen({
    super.key,
    required this.english,
  });

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
  bool _loading = false;

  String? _message;
  List<Map<String, dynamic>> _requests = [];
  StreamSubscription<AuthState>? _authSubscription;

  bool get _en => widget.english;

  String t(String fa, String en) => _en ? en : fa;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get _configured => _client != null;

  bool get _signedIn {
    final client = _client;
    if (client == null) return false;

    try {
      return client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    final client = _client;
    if (client != null) {
      _authSubscription = client.auth.onAuthStateChange.listen((_) {
        _loadRequests();
      });
    }
    _loadRequests();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _name.dispose();
    _phone.dispose();
    _vehicle.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    setState(() => _message = message);
  }

  Future<void> _loadRequests() async {
    final client = _client;

    if (client == null || !_signedIn) {
      if (mounted) {
        setState(() {
          _requests = [];
          _admin = false;
        });
      }
      return;
    }

    if (_loading) return;

    setState(() => _loading = true);

    try {
      final user = client.auth.currentUser;
      if (user == null) return;

      final profile = await client
          .from('profiles')
          .select('role, permissions')
          .eq('id', user.id)
          .maybeSingle();

      final role = profile?['role']?.toString();

      final permissions = Map<String, dynamic>.from(
        profile?['permissions'] as Map? ?? {},
      );

      final isAdmin = role == 'owner' ||
          (role == 'admin' && permissions['manage_bookings'] == true);

      final rows = isAdmin
          ? await client
              .from('booking_requests')
              .select()
              .order('created_at', ascending: false)
              .limit(100)
          : await client
              .from('booking_requests')
              .select()
              .eq('user_id', user.id)
              .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _admin = isAdmin;
        _requests = List<Map<String, dynamic>>.from(rows);
      });
    } catch (e) {
      _showMessage(
        '${t('خطا در دریافت درخواست‌ها: ', 'Could not load requests: ')}$e',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submit() async {
    final client = _client;

    if (client == null) {
      _showMessage(
        t(
          'اتصال پایگاه داده برنامه برقرار نیست. تنظیمات Supabase را بررسی کن.',
          'Database connection is not configured. Check Supabase settings.',
        ),
      );
      return;
    }

    final user = client.auth.currentUser;

    if (user == null) {
      _showMessage(
        t(
          'برای ثبت نوبت ابتدا از بخش گاراژ وارد حساب کاربری شو.',
          'Please sign in from the Garage tab before booking.',
        ),
      );
      return;
    }

    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _vehicle.text.trim().isEmpty) {
      _showMessage(
        t(
          'نام، شماره تماس و مدل خودرو را کامل وارد کن.',
          'Enter your name, phone number and vehicle model.',
        ),
      );
      return;
    }

    if (_phone.text.trim().length < 8) {
      _showMessage(
        t(
          'شماره تماس واردشده معتبر نیست.',
          'The phone number does not appear valid.',
        ),
      );
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final date =
          '${_date.year.toString().padLeft(4, '0')}-'
          '${_date.month.toString().padLeft(2, '0')}-'
          '${_date.day.toString().padLeft(2, '0')}';

      await client.from('booking_requests').insert({
        'user_id': user.id,
        'customer_name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'vehicle': _vehicle.text.trim(),
        'service': _service,
        'preferred_date': date,
        'preferred_time': _time,
        'notes': _notes.text.trim(),
        'status': 'pending',
      });

      _name.clear();
      _phone.clear();
      _vehicle.clear();
      _notes.clear();

      _showMessage(
        t(
          'درخواست نوبت با موفقیت ثبت شد. پس از بررسی با شما تماس گرفته می‌شود.',
          'Your booking request was submitted successfully. You will be contacted after review.',
        ),
      );

      await _loadRequests();
    } catch (e) {
      _showMessage(
        '${t('ثبت درخواست ناموفق بود: ', 'Booking request failed: ')}$e',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _changeStatus(
    Map<String, dynamic> row,
    String status,
  ) async {
    final client = _client;

    if (client == null || !_signedIn || !_admin) {
      _showMessage(
        t(
          'دسترسی مدیریت نوبت‌ها وجود ندارد.',
          'You do not have permission to manage bookings.',
        ),
      );
      return;
    }

    try {
      await client
          .from('booking_requests')
          .update({'status': status})
          .eq('id', row['id']);

      _showMessage(
        t('وضعیت درخواست به‌روزرسانی شد.', 'Request status updated.'),
      );

      await _loadRequests();
    } catch (e) {
      _showMessage(
        '${t('خطا در تغییر وضعیت: ', 'Could not update status: ')}$e',
      );
    }
  }

  Future<void> _selectDate() async {
    DateTime? selectedDate;

    if (_en) {
      selectedDate = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 180)),
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _bookingRed,
              surface: _bookingPanel,
            ),
          ),
          child: child!,
        ),
      );
    } else {
      final selectedJalali = await showPersianDatePicker(
        context: context,
        initialDate: Jalali.fromDateTime(_date),
        firstDate: Jalali.now(),
        lastDate: Jalali.fromDateTime(
          DateTime.now().add(const Duration(days: 180)),
        ),
        helpText: 'انتخاب تاریخ نوبت',
        cancelText: 'لغو',
        confirmText: 'تأیید',
        textDirection: TextDirection.rtl,
        builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _bookingRed,
              surface: _bookingPanel,
            ),
          ),
          child: child!,
        ),
      );

      selectedDate = selectedJalali?.toDateTime();
    }

    if (selectedDate != null && mounted) {
      setState(() => _date = selectedDate!);
    }
  }

  String _formattedDate() {
    if (_en) {
      return '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}';
    }

    final jalali = Jalali.fromDateTime(_date);

    return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bookingBg,
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: _bookingRed,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t('درخواست نوبت کاراکال', 'CARACAL APPOINTMENTS'),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _loadRequests,
                icon: const Icon(
                  Icons.refresh,
                  color: _bookingSilver,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t(
              'درخواست خدمات تخصصی خودرو',
              'Request a specialist vehicle service',
            ),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          if (!_configured)
            _card(
              Text(
                t(
                  'اتصال پایگاه داده برقرار نیست.',
                  'Database connection is unavailable.',
                ),
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          if (!_signedIn)
            _card(
              Column(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: _bookingSilver,
                    size: 38,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t(
                      'برای ثبت نوبت ابتدا از بخش گاراژ وارد حساب کاربری شو.',
                      'Please sign in from the Garage tab before submitting a booking.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  _name,
                  t('نام و نام خانوادگی', 'Full name'),
                  icon: Icons.person_outline,
                ),
                _field(
                  _phone,
                  t('شماره تماس', 'Phone number'),
                  type: TextInputType.phone,
                  icon: Icons.phone_outlined,
                ),
                _field(
                  _vehicle,
                  t('مدل خودرو', 'Vehicle model'),
                  icon: Icons.directions_car_outlined,
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _service,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: t('نوع خدمات', 'Service type'),
                    prefixIcon: const Icon(
                      Icons.build_outlined,
                      color: _bookingSilver,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'ریمپ و کالیبراسیون',
                      child: Text(
                        t(
                          'ریمپ و کالیبراسیون',
                          'ECU remapping & calibration',
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'عیب‌یابی تخصصی',
                      child: Text(
                        t(
                          'عیب‌یابی تخصصی',
                          'Advanced diagnostics',
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'مشاوره فنی',
                      child: Text(
                        t('مشاوره فنی', 'Technical consultation'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'بررسی و بازبینی',
                      child: Text(
                        t('بررسی و بازبینی', 'Inspection'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _service = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    '${t('تاریخ پیشنهادی: ', 'Preferred date: ')}${_formattedDate()}',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _time,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: t('ساعت پیشنهادی', 'Preferred time'),
                    prefixIcon: const Icon(
                      Icons.access_time,
                      color: _bookingSilver,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    '09:00',
                    '10:00',
                    '11:00',
                    '12:00',
                    '14:00',
                    '15:00',
                    '16:00',
                    '17:00',
                    '18:00',
                  ].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _time = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  _notes,
                  t(
                    'توضیحات تکمیلی (اختیاری)',
                    'Additional notes (optional)',
                  ),
                  lines: 3,
                  icon: Icons.notes,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _bookingRed,
                      foregroundColor: Colors.white,
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _busy
                          ? t('در حال ثبت...', 'Submitting...')
                          : t('ثبت درخواست نوبت', 'SUBMIT BOOKING'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_message != null)
            _card(
              SelectableText(
                _message!,
                style: const TextStyle(
                  color: _bookingSilver,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _admin
                      ? t('مدیریت درخواست‌های نوبت', 'BOOKING MANAGEMENT')
                      : t('درخواست‌های من', 'MY BOOKINGS'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _bookingRed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_signedIn)
            Text(
              t(
                'پس از ورود، درخواست‌های شما اینجا نمایش داده می‌شوند.',
                'Your requests will appear here after signing in.',
              ),
              style: const TextStyle(color: Colors.white54),
            )
          else if (_requests.isEmpty && !_loading)
            Text(
              t(
                'هنوز درخواستی ثبت نشده است.',
                'No booking requests yet.',
              ),
              style: const TextStyle(color: Colors.white54),
            ),
          ..._requests.map(_requestCard),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
    int lines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: lines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null
              ? null
              : Icon(icon, color: _bookingSilver),
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(.18)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: _bookingRed),
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bookingPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _requestCard(Map<String, dynamic> row) {
    final status = row['status']?.toString() ?? 'pending';

    final statusText = {
          'pending': t('در انتظار بررسی', 'Pending'),
          'confirmed': t('تأیید شده', 'Confirmed'),
          'completed': t('انجام شده', 'Completed'),
          'cancelled': t('لغو شده', 'Cancelled'),
        }[status] ??
        status;

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${row['service'] ?? ''} • ${row['vehicle'] ?? ''}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${row['preferred_date'] ?? ''}  ${row['preferred_time'] ?? ''}',
            style: const TextStyle(color: _bookingSilver),
          ),
          const SizedBox(height: 5),
          Text(
            '${t('وضعیت: ', 'Status: ')}$statusText',
            style: const TextStyle(
              color: _bookingRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (row['customer_name'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '${row['customer_name']} • ${row['phone'] ?? ''}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ),
          if (row['notes'] != null &&
              row['notes'].toString().trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                row['notes'].toString(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
          if (_admin) ...[
            const Divider(height: 22, color: Colors.white12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: () => _changeStatus(row, 'confirmed'),
                  child: Text(t('تأیید', 'Confirm')),
                ),
                TextButton(
                  onPressed: () => _changeStatus(row, 'completed'),
                  child: Text(t('انجام شد', 'Complete')),
                ),
                TextButton(
                  onPressed: () => _changeStatus(row, 'cancelled'),
                  child: Text(t('لغو', 'Cancel')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
