import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../widgets/shimmer_loader.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});
  @override State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  List<Map<String, dynamic>> _earned = [];
  List<Map<String, dynamic>> _available = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().get('/me/badges');
      if (mounted) setState(() {
        _earned = List<Map<String, dynamic>>.from(res['earned'] ?? []);
        _available = List<Map<String, dynamic>>.from(res['available'] ?? []);
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Odznaki')),
      body: _loading
        ? const ShimmerGrid(count: 9)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              if (_earned.isNotEmpty) ...[
                const Text('Zdobyte odznaki', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12, mainAxisSpacing: 12,
                  children: _earned.map((b) => _badgeCard(b, earned: true)).toList(),
                ),
                const SizedBox(height: 24),
              ],

              Text('Do zdobycia (${_available.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12,
                children: _available.map((b) => _badgeCard(b, earned: false)).toList(),
              ),

              if (_earned.isEmpty && _available.isEmpty) Center(child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Brak dostępnych odznak', style: TextStyle(fontSize: 16)),
                ]),
              )),
            ]),
          ),
    );
  }

  Widget _badgeCard(Map<String, dynamic> b, {required bool earned}) {
    final color = _parseColor(b['color']);
    return GestureDetector(
      onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text('${b['icon']} ${b['name']}'),
        content: Text(b['description'] ?? ''),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      )),
      child: Container(
        decoration: BoxDecoration(
          color: earned ? color.withValues(alpha: 0.15) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: earned ? color : Colors.grey.shade300, width: 2),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(b['icon'] ?? '🏅',
            style: TextStyle(fontSize: 40, color: earned ? null : Colors.grey.shade400)),
          const SizedBox(height: 4),
          Text(b['name'] ?? '', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
              color: earned ? color : Colors.grey.shade500)),
        ]),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.grey;
    final v = int.tryParse(hex.replaceAll('#', ''), radix: 16) ?? 0;
    return Color(0xFF000000 | v);
  }
}
