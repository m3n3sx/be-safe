/// be:Safe v2 — Stats Screen (Serenity Guard)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alert.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/serenity_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _totals;
  List<dynamic> _byCategory = [];
  List<dynamic> _trend = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pos = await LocationService().getCurrentPosition();
    if (pos == null || !mounted) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await context.read<ApiService>().get('/alerts/stats', {
        'lat': pos.latitude.toString(),
        'lng': pos.longitude.toString(),
        'radius_m': '3000',
      });
      if (mounted) {
        setState(() {
          _totals = res['totals'];
          _byCategory = res['by_category'] ?? [];
          _trend = res['trend'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: SerenityColors.primary,
                      backgroundColor: SerenityColors.surfaceContainerLowest,
                      child: ListView(
                        padding: const EdgeInsets.all(SerenitySpacing.xl),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  'Dziś',
                                  '${_totals?['today'] ?? 0}',
                                  SerenityColors.glowAlertCoral,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _statCard(
                                  'Tydzień',
                                  '${_totals?['week'] ?? 0}',
                                  SerenityColors.glowCalmAqua,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _statCard(
                                  'Razem',
                                  '${_totals?['total'] ?? 0}',
                                  SerenityColors.glowSafeMint,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: SerenitySpacing.xxl),
                          _label('TOP ZAGROŻENIA (30 DNI)'),
                          const SizedBox(height: SerenitySpacing.md),
                          ..._byCategory.map(_categoryBar),
                          const SizedBox(height: SerenitySpacing.xxl),
                          _label('TREND (14 DNI)'),
                          const SizedBox(height: SerenitySpacing.md),
                          _buildTrend(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SerenitySpacing.md,
        vertical: SerenitySpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            color: SerenityColors.primary,
            tooltip: 'Wróć',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text('Statystyki', style: SerenityText.headlineHeroMobile),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: SerenityText.labelCaps);
  }

  Widget _statCard(String label, String value, Color accent) {
    return SerenityCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: 0.6),
                  accent.withValues(alpha: 0),
                ],
                stops: const [0, 1],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: SerenityText.displayMd.copyWith(
              fontSize: 36,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: SerenityText.labelCaps.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _categoryBar(dynamic c) {
    final cat = AlertCategory.values
        .where((ac) => ac.apiValue == c['category'])
        .firstOrNull;
    final maxCount = _byCategory.isNotEmpty
        ? (_byCategory[0]['count'] as int)
        : 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '${cat?.emoji ?? '⚠️'} ${cat?.label ?? c['category']}',
              style: SerenityText.bodyMain.copyWith(
                fontSize: 13,
                color: SerenityColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (c['count'] as int) / maxCount,
                minHeight: 12,
                backgroundColor: SerenityColors.surfaceContainer,
                color: SerenityColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${c['count']}',
            style: SerenityText.labelButton.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTrend() {
    if (_trend.isEmpty) {
      return SerenityCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text('Brak danych', style: SerenityText.bodyMain),
        ),
      );
    }
    final maxT = _trend
        .map((x) => x['count'] as int)
        .reduce((a, b) => a > b ? a : b);
    return SerenityCard(
      padding: const EdgeInsets.all(SerenitySpacing.md),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _trend.map((t) {
            final h = maxT > 0 ? (t['count'] as int) / maxT * 90 : 0.0;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${t['count']}',
                      style: SerenityText.labelCaps.copyWith(fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: SerenityColors.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (t['day'] ?? '').toString().length >= 10
                          ? (t['day']).toString().substring(5, 10)
                          : '',
                      style: SerenityText.labelCaps.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
