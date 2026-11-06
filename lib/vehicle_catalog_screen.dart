import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const _catalogBg = Color(0xFF08090B);
const _catalogPanel = Color(0xFF15171B);
const _catalogRed = Color(0xFFFF3038);
const _catalogSilver = Color(0xFFC5CBD2);

class VehicleCatalogScreen extends StatefulWidget {
  final bool english;
  const VehicleCatalogScreen({super.key, required this.english});

  @override
  State<VehicleCatalogScreen> createState() => _VehicleCatalogScreenState();
}

class _VehicleCatalogScreenState extends State<VehicleCatalogScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _makes = [];
  bool _loading = true;
  bool _hasAccess = false;
  bool _isAdmin = false;
  bool _signedIn = false;
  String? _error;

  String t(String fa, String en) => widget.english ? en : fa;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    setState(() { _loading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() { _signedIn = false; _hasAccess = false; _loading = false; });
        return;
      }

      var isAdmin = false;
      try {
        final profile = await client.from('profiles')
            .select('role,permissions').eq('id', user.id).maybeSingle();
        final role = (profile?['role'] ?? '').toString().toLowerCase();
        final permissions = Map<String, dynamic>.from(profile?['permissions'] ?? {});
        isAdmin = const {'owner', 'admin', 'super_admin'}.contains(role) ||
            permissions['manage_content'] == true;
      } catch (_) {
        // A normal member does not need profile privileges to access the catalog.
      }

      var activeMembership = false;
      try {
        final rows = await client.from('memberships')
            .select('id')
            .eq('user_id', user.id)
            .eq('status', 'active')
            .or('starts_at.is.null,starts_at.lte.${DateTime.now().toUtc().toIso8601String()}')
            .or('ends_at.is.null,ends_at.gt.${DateTime.now().toUtc().toIso8601String()}')
            .limit(1);
        activeMembership = (rows as List).isNotEmpty;
      } catch (e) {
        debugPrint('CARACAL catalog membership check: $e');
      }

      if (!mounted) return;
      setState(() {
        _signedIn = true;
        _isAdmin = isAdmin;
        _hasAccess = isAdmin || activeMembership;
      });
      if (_hasAccess) await _loadCatalog();
      else if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final rows = await Supabase.instance.client
          .from('vehicle_catalog')
          .select('id,slug,make_id,make_fa,make_en,model_fa,model_en,body_type,year_start,year_end,summary_fa,summary_en,data_status,is_verified')
          .eq('is_published', true)
          .order('sort_order');

      final vehicles = (rows as List).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        return <String, dynamic>{
          'id': row['slug'],
          'uuid': row['id'],
          'makeId': row['make_id'],
          'model': {'fa': row['model_fa'], 'en': row['model_en']},
          'bodyType': row['body_type'],
          'yearStart': row['year_start'],
          'yearEnd': row['year_end'],
          'summary': {'fa': row['summary_fa'], 'en': row['summary_en']},
          'dataStatus': row['data_status'],
          'isVerified': row['is_verified'] == true,
        };
      }).toList();

      final makeMap = <String, Map<String, dynamic>>{};
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        makeMap[row['make_id'].toString()] = {
          'id': row['make_id'],
          'name': {'fa': row['make_fa'], 'en': row['make_en']},
        };
      }

      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _makes = makeMap.values.toList();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '${t('خطای دریافت اطلاعات:', 'Catalog request failed:')} $e';
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _makeName(String id) {
    for (final item in _makes) {
      if (item['id'] == id) {
        final name = item['name'];
        if (name is Map) return (name[widget.english ? 'en' : 'fa'] ?? '').toString();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _vehicles.where((v) {
      final model = v['model'] as Map? ?? {};
      final fa = (model['fa'] ?? '').toString().toLowerCase();
      final en = (model['en'] ?? '').toString().toLowerCase();
      final make = _makeName(v['makeId']?.toString() ?? '').toLowerCase();
      return query.isEmpty || fa.contains(query) || en.contains(query) || make.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: _catalogBg,
      appBar: AppBar(
        title: Text(t('بانک اطلاعات خودروها', 'VEHICLE DATABASE')),
        backgroundColor: _catalogBg,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: t('بروزرسانی', 'Refresh'),
            onPressed: _loading ? null : _checkAccessAndLoad,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _catalogRed))
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center,
                        style: const TextStyle(color: _catalogSilver)),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _checkAccessAndLoad,
                        child: Text(t('تلاش دوباره', 'Try again'))),
                  ]),
                ))
              : !_hasAccess
                  ? _lockedView()
                  : _catalogView(visible),
    );
  }

  Widget _lockedView() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _catalogPanel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _catalogSilver.withOpacity(.25)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_rounded, color: _catalogRed, size: 58),
          const SizedBox(height: 16),
          Text(t('دسترسی اشتراکی', 'SUBSCRIBER ACCESS'),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text(
            _signedIn
                ? t('تمام بخش بانک اطلاعات خودروها ویژه اعضای دارای اشتراک فعال است. برای فعال‌سازی یا تمدید اشتراک، به بخش گاراژ و حساب کاربری بروید و وضعیت عضویت خود را بررسی کنید.',
                    'The entire vehicle database is available only to members with an active subscription. To activate or renew, open Garage & Account and check your membership.')
                : t('تمام بخش بانک اطلاعات خودروها ویژه اعضای دارای اشتراک فعال است. ابتدا وارد حساب کاربری شوید و سپس اشتراک خود را فعال کنید.',
                    'The entire vehicle database requires an active subscription. Sign in to your account, then activate a membership.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _catalogSilver, height: 1.8),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _catalogRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: Text(t('بازگشت به برنامه', 'BACK TO APP')),
          )),
          const SizedBox(height: 8),
          Text(t('پس از فعال شدن اشتراک، این صفحه را دوباره باز یا بروزرسانی کنید.',
              'After your subscription is activated, reopen or refresh this page.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ),
    ),
  );

  Widget _catalogView(List<Map<String, dynamic>> visible) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Row(children: [
        Expanded(child: Text(t('مدل‌های منتشرشده: ${_vehicles.length}', 'Published models: ${_vehicles.length}'),
            style: const TextStyle(color: _catalogSilver, fontWeight: FontWeight.bold))),
        if (_isAdmin) const Icon(Icons.admin_panel_settings, color: _catalogRed, size: 18),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: t('جست‌وجوی خودرو یا سازنده...', 'Search vehicle or manufacturer...'),
          prefixIcon: const Icon(Icons.search, color: _catalogRed),
          filled: true, fillColor: _catalogPanel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      const SizedBox(height: 14),
      if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.all(28),
          child: Text(t('مدلی برای نمایش پیدا نشد.', 'No published vehicle models match this search.'),
              textAlign: TextAlign.center, style: const TextStyle(color: _catalogSilver)),
        ),
      for (final vehicle in visible)
        Card(
          color: _catalogPanel,
          margin: const EdgeInsets.only(bottom: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.white12),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF292D33),
              child: Icon(Icons.directions_car, color: _catalogSilver),
            ),
            title: Text(((vehicle['model'] as Map?)?[widget.english ? 'en' : 'fa'] ?? '').toString(),
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(_makeName(vehicle['makeId']?.toString() ?? ''),
                style: const TextStyle(color: _catalogSilver)),
            trailing: const Icon(Icons.chevron_right, color: _catalogRed),
            onTap: () => _showVehicle(vehicle),
          ),
        ),
      const SizedBox(height: 12),
      Text(t('اطلاعات فنی فقط پس از بررسی منبع و تأیید تخصصی منتشر می‌شوند.',
          'Technical details are published only after source review and expert verification.'),
          style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.6)),
    ],
  );

  Future<List<Map<String, dynamic>>> _loadVehicleResources(String vehicleId) async {
    final client = Supabase.instance.client;
    final rows = await client.from('catalog_resources')
        .select('id,title_fa,title_en,description_fa,description_en,resource_type,category,storage_path,external_url,original_filename,mime_type,file_size_bytes,is_verified')
        .eq('vehicle_id', vehicleId).eq('is_published', true).order('sort_order');
    final resources = <Map<String, dynamic>>[];
    for (final raw in rows as List) {
      final item = Map<String, dynamic>.from(raw as Map);
      String? accessUrl = (item['external_url'] ?? '').toString().trim();
      final path = (item['storage_path'] ?? '').toString().trim();
      if (path.isNotEmpty) {
        accessUrl = await client.storage.from('vehicle-technical-library').createSignedUrl(path, 900);
      }
      item['access_url'] = accessUrl;
      resources.add(item);
    }
    return resources;
  }

  Future<void> _openResource(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showVehicle(Map<String, dynamic> vehicle) {
    final model = vehicle['model'] as Map? ?? {};
    final name = (model[widget.english ? 'en' : 'fa'] ?? '').toString();
    final summary = vehicle['summary'] as Map? ?? {};
    final summaryText = (summary[widget.english ? 'en' : 'fa'] ?? '').toString();
    final resourcesFuture = _loadVehicleResources(vehicle['uuid'].toString());
    showModalBottomSheet<void>(
      context: context, backgroundColor: _catalogPanel, isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false, initialChildSize: .72, minChildSize: .45, maxChildSize: .94,
          builder: (context, scrollController) => ListView(
            controller: scrollController, padding: const EdgeInsets.all(22),
            children: [
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(_makeName(vehicle['makeId']?.toString() ?? ''), style: const TextStyle(color: _catalogSilver)),
              const SizedBox(height: 18),
              Text(summaryText.isNotEmpty ? summaryText : t(
                'این رکورد فعلاً فقط شامل نام و خانواده خودرو است. منابع آموزشی مجاز پس از بررسی اضافه می‌شوند.',
                'This record currently contains only the vehicle name and model family. Approved learning resources will be added after review.'),
                style: const TextStyle(height: 1.7, color: _catalogSilver)),
              const SizedBox(height: 18),
              Text(t('منابع و فایل‌های آموزشی', 'EDUCATIONAL RESOURCES'), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .6)),
              const SizedBox(height: 10),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: resourcesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator(color: _catalogRed)));
                  if (snapshot.hasError) return Text(t('دریافت منابع با خطا روبه‌رو شد: ', 'Could not load resources: ') + snapshot.error.toString(), style: const TextStyle(color: _catalogSilver, fontSize: 12));
                  final resources = snapshot.data ?? [];
                  if (resources.isEmpty) return Text(t('هنوز فایل یا مطلب آموزشی برای این خودرو ثبت نشده است.', 'No educational resources have been added for this vehicle yet.'), style: const TextStyle(color: Colors.white54, height: 1.6));
                  return Column(children: resources.map((item) {
                    final title = (item[widget.english ? 'title_en' : 'title_fa'] ?? '').toString();
                    final description = (item[widget.english ? 'description_en' : 'description_fa'] ?? '').toString();
                    final url = (item['access_url'] ?? '').toString();
                    final rawBytes = item['file_size_bytes'];
                    final size = rawBytes is num ? ' · ' + (rawBytes / 1048576).toStringAsFixed(1) + ' MB' : '';
                    return Card(color: const Color(0xFF202329), child: ListTile(
                      leading: const Icon(Icons.description_outlined, color: _catalogSilver),
                      title: Text(title.isEmpty ? t('منبع آموزشی', 'Learning resource') : title),
                      subtitle: Text((description.isNotEmpty ? description : (item['resource_type'] ?? '').toString()) + size, style: const TextStyle(color: _catalogSilver, fontSize: 11)),
                      trailing: Icon(url.isNotEmpty ? Icons.open_in_new : Icons.lock_outline, color: _catalogRed),
                      onTap: url.isEmpty ? null : () => _openResource(url),
                    ));
                  }).toList());
                },
              ),
              const SizedBox(height: 12),
              Text(t('وضعیت: فهرست اولیه مدل — اطلاعات فنی هنوز تأیید نشده است.', 'Status: initial model index — technical details are not yet verified.'), style: const TextStyle(fontSize: 11, color: Colors.white54, height: 1.6)),
              Align(alignment: AlignmentDirectional.centerEnd, child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('بستن', 'Close')))),
            ],
          ),
        ),
      ),
    );
  }
}
