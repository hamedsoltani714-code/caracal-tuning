import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      final raw = await rootBundle.loadString('assets/catalog/vehicles.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final vehicles = (data['vehicles'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['publicationStatus'] == 'published')
          .toList();
      final makes = (data['makes'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _makes = makes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _catalogRed))
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(t('بارگذاری بانک اطلاعاتی انجام نشد.', 'Could not load the vehicle catalog.'),
                      textAlign: TextAlign.center, style: const TextStyle(color: _catalogSilver))))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(t('مدل‌های ثبت‌شده: ${_vehicles.length}', 'Indexed models: ${_vehicles.length}'),
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
                        child: Text(t('مدلی پیدا نشد یا هنوز اطلاعاتی برای نمایش منتشر نشده است.',
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
                    Text(t('اطلاعات فقط پس از بررسی منبع و تأیید فنی منتشر می‌شوند.',
                        'Technical details are shown only after source verification and review.'),
                        style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.6)),
                  ],
                ),
    );
  }

  void _showVehicle(Map<String, dynamic> vehicle) {
    final model = vehicle['model'] as Map? ?? {};
    final name = (model[widget.english ? 'en' : 'fa'] ?? '').toString();
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
              Text(t('جزئیات سال ساخت، موتور و ECU هنوز در مرحله گردآوری و راستی‌آزمایی است.',
                  'Year, engine and ECU details are still being collected and verified.'),
                  style: const TextStyle(height: 1.7, color: _catalogSilver)),
              const SizedBox(height: 12),
              Text(t('برای جلوگیری از نمایش اطلاعات اشتباه، جزئیات تأییدنشده نمایش داده نمی‌شود.',
                  'Unverified technical details are intentionally hidden to avoid misleading information.'),
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
