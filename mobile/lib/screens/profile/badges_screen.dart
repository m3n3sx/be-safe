/// be:Safe v2 — Badges Screen (Serenity Guard)
library;

import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  List<Map<String, dynamic>> _earned = [];
  List<Map<String, dynamic>> _available = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().get('/me/badges');
      if (mounted) {
        setState(() {
          _earned = List<Map<String, dynamic>>.from(res['earned'] ?? []);
          _available =
              List<Map<String, dynamic>>.from(res['available'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null) return SerenityColors.primary;
    final v = int.tryParse(hex.replaceAll('#', ''), radix: 16) ?? 0;
    return Color(0xFF000000 | v);
  }

  void _showDetails(Map<String, dynamic> b, bool earned) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.iosCardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        ),
        title: Row(
          children: [
            Text(
              b['icon'] ?? '🏅',
              style: TextStyle(
                fontSize: 32,
                color: earned ? null : SerenityColors.outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                b['name'] ?? '',
                style: SerenityText.headlineHeroMobile.copyWith(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          b['description'] ?? '',
          style: SerenityText.bodyMain,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _badgeTile(Map<String, dynamic> b, bool earned) {
    final color = _parseColor(b['color']);
    return GestureDetector(
      onTap: () => _showDetails(b, earned),
      child: Container(
        decoration: BoxDecoration(
          color: earned
              ? color.withValues(alpha: 0.08)
              : SerenityColors.surfaceContainer,
          borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
          border: Border.all(
            color: earned
                ? color.withValues(alpha: 0.4)
                : context.iosSeparator.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              b['icon'] ?? '🏅',
              style: TextStyle(
                fontSize: 40,
                color: earned ? null : SerenityColors.outline,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              b['name'] ?? '',
              textAlign: TextAlign.center,
              style: SerenityText.labelButton.copyWith(
                fontSize: 11,
                color: earned
                    ? SerenityColors.primary
                    : SerenityColors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.iosBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SerenitySpacing.md,
                vertical: SerenitySpacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    color: context.iosLabel,
                    tooltip: 'Wróć',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text('Odznaki', style: SerenityText.headlineHeroMobile),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_earned.isEmpty && _available.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium_outlined,
                                size: 64,
                                color: context.iosSeparator,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Brak dostępnych odznak',
                                style: SerenityText.bodyMain,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: context.iosLabel,
                          backgroundColor:
                              context.iosCardSurface,
                          child: ListView(
                            padding: const EdgeInsets.all(SerenitySpacing.xl),
                            children: [
                              if (_earned.isNotEmpty) ...[
                                Text(
                                  'ZDOBYTE (${_earned.length})',
                                  style: SerenityText.labelCaps,
                                ),
                                const SizedBox(height: SerenitySpacing.md),
                                GridView.count(
                                  crossAxisCount: 3,
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: SerenitySpacing.sm,
                                  mainAxisSpacing: SerenitySpacing.sm,
                                  children: _earned
                                      .map((b) => _badgeTile(b, true))
                                      .toList(),
                                ),
                                const SizedBox(height: SerenitySpacing.xxl),
                              ],
                              if (_available.isNotEmpty) ...[
                                Text(
                                  'DO ZDOBYCIA (${_available.length})',
                                  style: SerenityText.labelCaps,
                                ),
                                const SizedBox(height: SerenitySpacing.md),
                                GridView.count(
                                  crossAxisCount: 3,
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: SerenitySpacing.sm,
                                  mainAxisSpacing: SerenitySpacing.sm,
                                  children: _available
                                      .map((b) => _badgeTile(b, false))
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: SerenitySpacing.xxxl),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
