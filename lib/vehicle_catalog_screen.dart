import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? _error;

  String t(String fa, String en) => widget.english ? en : fa;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      // The live Supabase catalog is the source of truth. Only published rows
      // are visible to app users; drafts stay in the admin workspace.
      final rows = await Supabase.instance.client
          .from('vehicle_catalog')
          .select('slug,make_id,make_fa,make_en,model_fa,model_en,body_type,year_start,year_end,summary_fa,summary_en,data_status,is_verified')
          .eq('is_published', true)
          .order('sort_order');

      final vehicles = (rows as List).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        return <String, dynamic>{
          'id': row['slug'],
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
        _error = t('اتصال به بانک مرکزی خودروها برقرار نشد. اتصال اینترنت و دسترسی دیتابیس را بررسی کن.',
            'Could not connect to the live vehicle catalog. Check the connection and database access.');
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _makeName(String id) {
    Map<String, dynamic>? make;
    for (final item in _makes) {
      if (item['id'] == id) {
        make = item;
        break;
      }
    }
    final name = make?['name'];
    if (name is Map) return (name[widget.english ? 'en' : 'fa'] ?? '').toString();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _vehicles.where((v) {
      final model = v['model'] as Map? ?? {};
      final fa = (model['fa'] ?? '').toString().toLowerCase();
      final en = (model['en'] ?? '').toString().toLowerCase();
      return query.isEmpty || fa.contains(query) || en.contains(query);
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
            onPressed: _loading ? null : () {
              setState(() => _loading = true);
              _loadCatalog();
            },
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
                    OutlinedButton(onPressed: () {
                      setState(() { _loading = true; _error = null; });
                      _loadCatalog();
                    }, child: Text(t('تلاش دوباره', 'Try again'))),
                  ]),
                ))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(t('مدل‌های منتشرشده: ${_vehicles.length}', 'Published models: ${_vehicles.length}'),
                        style: const TextStyle(color: _catalogSilver, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: t('جست‌وجوی نام خودرو...', 'Search vehicle models...'),
                        prefixIcon: const Icon(Icons.search, color: _catalogRed),
                        filled: true, fillColor: _catalogPanel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(t('مدلی برای نمایش پیدا نشد.',
                            'No published vehicle models match this search.'),
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
                ),
    );
  }

  void _showVehicle(Map<String, dynamic> vehicle) {
    final model = vehicle['model'] as Map? ?? {};
    final name = (model[widget.english ? 'en' : 'fa'] ?? '').toString();
    final summary = vehicle['summary'] as Map? ?? {};
    final summaryText = (summary[widget.english ? 'en' : 'fa'] ?? '').toString();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _catalogPanel,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(_makeName(vehicle['makeId']?.toString() ?? ''),
                  style: const TextStyle(color: _catalogSilver)),
              const SizedBox(height: 18),
              Text(summaryText.isNotEmpty ? summaryText : t(
                  'این رکورد فعلاً فقط شامل نام و خانواده خودرو است. مشخصات فنی پس از بررسی منابع معتبر تکمیل می‌شود.',
                  'This record currently contains only the vehicle name and model family. Technical details will be added after reliable source review.'),
                  style: const TextStyle(height: 1.7, color: _catalogSilver)),
              const SizedBox(height: 12),
              Text(t('وضعیت: فهرست اولیه مدل — اطلاعات فنی هنوز تأیید نشده است.',
                  'Status: initial model index — technical details are not yet verified.'),
                  style: const TextStyle(fontSize: 11, color: Colors.white54, height: 1.6)),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(onPressed: () => Navigator.pop(ctx),
                    child: Text(t('بستن', 'Close'))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
