import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alert.dart';
import '../../services/api_service.dart';
import '../../services/i18n.dart';
import '../../services/location_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _totals;
  List<dynamic> _byCategory = [];
  List<dynamic> _trend = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final pos = await LocationService().getCurrentPosition();
    if (pos == null || !mounted) return;
    final res = await context.read<ApiService>().get('/alerts/stats', {
      'lat': pos.latitude.toString(), 'lng': pos.longitude.toString(), 'radius_m': '3000',
    });
    if (mounted) setState(() { _totals = res['totals']; _byCategory = res['by_category'] ?? []; _trend = res['trend'] ?? []; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.get('stats'))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        // Summary cards
        Row(children: [
          _card(S.get('today'), '${_totals?['today'] ?? 0}', Colors.red),
          const SizedBox(width: 8),
          _card(S.get('week'), '${_totals?['week'] ?? 0}', Colors.orange),
          const SizedBox(width: 8),
          _card(S.get('total'), '${_totals?['total'] ?? 0}', Colors.blue),
        ]),
        const SizedBox(height: 24),
        Text(S.get('top_threats_30d'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ..._byCategory.map((c) {
          final cat = AlertCategory.values.where((ac) => ac.apiValue == c['category']).firstOrNull;
          final maxCount = _byCategory.isNotEmpty ? (_byCategory[0]['count'] as int) : 1;
          return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
            SizedBox(width: 130, child: Text('${cat?.emoji ?? '⚠️'} ${cat?.label ?? c['category']}', style: const TextStyle(fontSize: 13))),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: (c['count'] as int) / maxCount, minHeight: 16,
                backgroundColor: Colors.grey.shade200, color: cat?.color ?? Colors.grey))),
            const SizedBox(width: 8),
            Text('${c['count']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ]));
        }),
        const SizedBox(height: 24),
        Text(S.get('trend_14d'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(height: 120, child: _trend.isEmpty ? const Center(child: Text('Brak danych')) : Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _trend.map((t) {
            final maxT = _trend.map((x) => x['count'] as int).reduce((a, b) => a > b ? a : b);
            final h = maxT > 0 ? (t['count'] as int) / maxT * 100 : 0.0;
            return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text('${t['count']}', style: const TextStyle(fontSize: 9)),
              Container(height: h, decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 2),
              Text((t['day'] ?? '').toString().substring(5, 10), style: const TextStyle(fontSize: 8)),
            ])));
          }).toList(),
        )),
      ]),
    );
  }

  Widget _card(String label, String value, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(color: color, fontSize: 12)),
    ]),
  ));
}
