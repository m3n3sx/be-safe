/// be:Safe v2 — Referral Screen (Serenity Guard)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/glow_orb.dart';
import '../../widgets/serenity_card.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String? _code;
  int _referrals = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().get('/users/me');
      if (mounted) {
        setState(() {
          _code = res['referral_code'];
          _referrals = res['referrals_count'] ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _code ?? '...';
    final shareUrl = 'https://besafe.org.pl?ref=$code';
    final shareText =
        'Dołącz do be:Safe — aplikacji bezpieczeństwa społeczności! Użyj mojego kodu polecającego: $code\n\n$shareUrl';

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
                    'Zaproś znajomych',
                    style: SerenityText.headlineHeroMobile,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(SerenitySpacing.xl),
                      child: Column(
                        children: [
                          GlowOrb(
                            size: 160,
                            color: SerenityColors.glowSafeMint,
                            coreOpacity: 0.5,
                            pulse: false,
                            child: Icon(
                              Icons.card_giftcard,
                              size: 56,
                              color: SerenityColors.primary,
                            ),
                          ),
                          const SizedBox(height: SerenitySpacing.xl),
                          Text(
                            'Twój kod polecający',
                            style: SerenityText.labelCaps,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Clipboard.setData(
                                ClipboardData(text: code),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor:
                                      SerenityColors.secondary,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      SerenityShapes.radiusXl,
                                    ),
                                  ),
                                  content: const Text('Kod skopiowany'),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: SerenityColors.primaryContainer,
                                borderRadius: SerenityShapes.pill(),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    code,
                                    style:
                                        SerenityText.displayMd.copyWith(
                                      fontSize: 28,
                                      height: 1.0,
                                      letterSpacing: 4,
                                      color: SerenityColors.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.copy,
                                    color: SerenityColors.onPrimary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: SerenitySpacing.xl),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: SerenityColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(
                                SerenityShapes.radiusXl,
                              ),
                              boxShadow: SerenityElevation.card(),
                            ),
                            child: QrImageView(
                              data: shareUrl,
                              size: 200,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: SerenitySpacing.xl),
                          Row(
                            children: [
                              Expanded(
                                child: SerenityCard(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$_referrals',
                                        style: SerenityText.displayMd
                                            .copyWith(
                                          fontSize: 36,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Poleconych',
                                        style: SerenityText.labelCaps,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SerenityCard(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_referrals * 10}',
                                        style: SerenityText.displayMd
                                            .copyWith(
                                          fontSize: 36,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Punktów',
                                        style: SerenityText.labelCaps,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: SerenitySpacing.xl),
                          Material(
                            color: SerenityColors.primaryContainer,
                            borderRadius: SerenityShapes.pill(),
                            child: InkWell(
                              borderRadius: SerenityShapes.pill(),
                              onTap: () => Share.share(shareText),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.share,
                                      color: SerenityColors.onPrimary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Udostępnij',
                                      style: SerenityText.labelButton
                                          .copyWith(
                                        fontSize: 16,
                                        color: SerenityColors.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: SerenitySpacing.md),
                          Text(
                            'Polecaj be:Safe znajomym i rodzinie — razem tworzymy bezpieczniejsze miasto',
                            textAlign: TextAlign.center,
                            style: SerenityText.bodyMain.copyWith(
                              fontSize: 13,
                            ),
                          ),
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
