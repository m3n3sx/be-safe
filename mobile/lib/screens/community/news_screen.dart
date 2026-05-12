/// be:Safe v2 — News Screen (Serenity Guard)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/serenity_card.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().get('/posts');
      if (mounted) {
        setState(() {
          _posts = List<Map<String, dynamic>>.from(res['posts'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPost(Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SerenityColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(SerenitySpacing.xl),
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: SerenityColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: SerenitySpacing.xl),
            if (p['category'] != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SerenityColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(SerenityShapes.radiusFull),
                ),
                child: Text(
                  p['category'],
                  style: SerenityText.labelCaps.copyWith(
                    color: SerenityColors.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: SerenitySpacing.md),
            ],
            Text(
              p['title'] ?? '',
              style: SerenityText.displayMd.copyWith(
                fontSize: 28,
                height: 36 / 28,
              ),
            ),
            const SizedBox(height: SerenitySpacing.md),
            Text(
              p['content'] ?? '',
              style: SerenityText.bodyMain.copyWith(
                fontSize: 15,
                color: SerenityColors.primary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
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
                  Text(
                    'Aktualności',
                    style: SerenityText.headlineHeroMobile,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _posts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 64,
                                color: SerenityColors.outlineVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Brak aktualności',
                                style: SerenityText.bodyMain,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: SerenityColors.primary,
                          backgroundColor:
                              SerenityColors.surfaceContainerLowest,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              SerenitySpacing.xl,
                              SerenitySpacing.sm,
                              SerenitySpacing.xl,
                              SerenitySpacing.xxxl,
                            ),
                            itemCount: _posts.length,
                            separatorBuilder: (_, __) => const SizedBox(
                              height: SerenitySpacing.xs,
                            ),
                            itemBuilder: (_, i) {
                              final p = _posts[i];
                              return SerenityCard(
                                onTap: () => _showPost(p),
                                padding: const EdgeInsets.all(
                                  SerenitySpacing.lg,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (p['category'] != null)
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: SerenityColors
                                              .secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            SerenityShapes.radiusFull,
                                          ),
                                        ),
                                        child: Text(
                                          p['category'],
                                          style: SerenityText.labelCaps
                                              .copyWith(
                                            fontSize: 10,
                                            color: SerenityColors
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      p['title'] ?? '',
                                      style: SerenityText.labelButton
                                          .copyWith(
                                        fontSize: 17,
                                        color: SerenityColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p['content'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: SerenityText.bodyMain.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
