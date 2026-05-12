/// be:Safe v2 — Ranking Screen (Serenity Guard)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/serenity_card.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<dynamic> _ranking = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().get('/users/ranking');
      if (mounted) {
        setState(() {
          _ranking = res['ranking'] ?? [];
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SerenitySpacing.md,
                vertical: SerenitySpacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    color: SerenityColors.primary,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text('Ranking', style: SerenityText.headlineHeroMobile),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _ranking.isEmpty
                      ? Center(
                          child: Text('Brak danych',
                              style: SerenityText.bodyMain),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            SerenitySpacing.xl,
                            SerenitySpacing.sm,
                            SerenitySpacing.xl,
                            SerenitySpacing.xxxl,
                          ),
                          itemCount: _ranking.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: SerenitySpacing.xs),
                          itemBuilder: (_, i) {
                            final u = _ranking[i];
                            final medal = i == 0
                                ? '🥇'
                                : i == 1
                                    ? '🥈'
                                    : i == 2
                                        ? '🥉'
                                        : '${i + 1}';
                            final isTop = i < 3;
                            return SerenityCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SerenitySpacing.md,
                                vertical: SerenitySpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isTop
                                          ? SerenityColors.secondaryContainer
                                          : SerenityColors.surfaceContainer,
                                    ),
                                    child: Center(
                                      child: Text(
                                        medal,
                                        style: TextStyle(
                                          fontSize: isTop ? 22 : 16,
                                          fontWeight: FontWeight.w500,
                                          color: SerenityColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: SerenitySpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u['username'] ?? 'Anonim',
                                          style: SerenityText.labelButton
                                              .copyWith(fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${u['alert_count']} zgłoszeń · ${u['total_confirms']} potwierdzeń',
                                          style: SerenityText.bodyMain
                                              .copyWith(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color:
                                            SerenityColors.onTertiaryContainer,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${u['reputation_score']}',
                                        style: SerenityText.labelButton
                                            .copyWith(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
