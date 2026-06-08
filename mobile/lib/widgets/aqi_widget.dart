import 'package:flutter/material.dart';
import '../theme/ios_surfaces.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/widget_service.dart';
import '../theme/design_tokens.dart';

/// F17: AQI banner — najbliższa stacja GIOŚ + kolor wg indeksu.
class AqiWidget extends StatefulWidget {
  const AqiWidget({super.key, this.maxWidth, this.compact = false});
  final double? maxWidth;
  final bool compact;
  @override
  State<AqiWidget> createState() => _AqiWidgetState();
}

class _AqiWidgetState extends State<AqiWidget> {
  Map<String, dynamic>? _station;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() { _loading = true; });
    try {
      final pos = await LocationService().getCurrentPosition().timeout(const Duration(seconds: 8));
      if (pos == null) {
        if (mounted) setState(() { _loading = false; });
        return;
      }
      final api = context.read<ApiService>();
      final res = await api.get(
        '/aqi/nearby?lat=${pos.latitude}&lng=${pos.longitude}&radius_m=30000&limit=1',
      ) as Map<String, dynamic>?;
      final list = (res?['stations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() {
        _station = list.isNotEmpty ? list.first : null;
        _loading = false;
      });
      // Zasil widget AQI.
      if (list.isNotEmpty) {
        final s = list.first;
        WidgetService.pushAqi(
          index: (s['aqi_index'] as int?) ?? -1,
          label: s['aqi_label']?.toString() ?? 'Brak danych',
          city: s['city']?.toString() ?? '',
        );
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Color _colorFor(int? idx) {
    switch (idx) {
      case 0: return const Color(0xFF4CAF50); // Bardzo dobry
      case 1: return const Color(0xFF8BC34A); // Dobry
      case 2: return const Color(0xFFFFEB3B); // Umiarkowany
      case 3: return const Color(0xFFFF9800); // Dostateczny
      case 4: return const Color(0xFFFF5722); // Zły
      case 5: return const Color(0xFFB71C1C); // Bardzo zły
      default: return const Color(0xFF9E9E9E);
    }
  }

  IconData _iconFor(int? idx) {
    if (idx == null || idx < 0) return Icons.help_outline;
    if (idx <= 1) return Icons.sentiment_very_satisfied;
    if (idx == 2) return Icons.sentiment_neutral;
    if (idx == 3) return Icons.sentiment_dissatisfied;
    return Icons.warning_amber;
  }

  @override
  Widget build(BuildContext context) {
    final station = _station;
    if (_loading) {
      return const SizedBox(height: 56, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))));
    }
    if (station == null) {
      return const SizedBox.shrink();
    }
    final idx = station['aqi_index'] as int?;
    final label = station['aqi_label']?.toString() ?? 'Brak danych';
    final city = station['city']?.toString() ?? '';
    final color = _colorFor(idx);
    final distance = (station['distance_m'] as num?)?.toDouble() ?? 0;
    final distStr = distance < 1000 ? '${distance.round()} m' : '${(distance / 1000).toStringAsFixed(1)} km';

    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth ?? double.infinity),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(_iconFor(idx), color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.air, size: 13, color: Color(0xFF44474B)),
                    const SizedBox(width: 4),
                    Text('JAKOŚĆ POWIETRZA',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: color.withValues(alpha: 0.9))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.iosLabel)),
                if (!widget.compact)
                  Text('$city · $distStr',
                      style: TextStyle(fontSize: 11, color: context.iosSecondaryLabel)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Odśwież',
            onPressed: _load,
            visualDensity: VisualDensity.compact,
            color: const Color(0xFF44474B),
          ),
        ],
      ),
    );
  }
}
