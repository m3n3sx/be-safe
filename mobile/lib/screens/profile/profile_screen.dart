/// be:Safe v2 — Profile Screen (Twój Profil)
///
/// Hero: avatar + 2 stat cards (Zgłoszeń / Punktów zaufania).
/// Flat list of settings sections in SerenityCard rows.
///
/// Design source: design/stitch_v2/screens/profil_u_ytkownika/
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/serenity_card.dart';
import '../../widgets/inset_grouped_section.dart';
import '../../widgets/apple_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _alertCount = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  Future<void> _loadStats() async {
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/alerts/mine');
      int count = 0;
      final list = res['alerts'];
      if (list is List) {
        count = list.length;
      }
      if (mounted) {
        setState(() {
          _alertCount = count;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _checkIn() async {
    HapticFeedback.mediumImpact();
    try {
      await context.read<ApiService>().post(
        '/users/me/checkin',
        {'status': 'safe'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: SerenityColors.secondary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
          ),
          content: const Text(
            '✓ Powiadomiono rodzinę że jesteś bezpieczny/a',
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _shareLocation() async {
    try {
      final res = await context.read<ApiService>().post(
        '/users/me/share-location',
        {'hours': 1},
      );
      if (res['url'] != null && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: SerenityColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
            ),
            title: const Text('Link do lokalizacji'),
            content: SelectableText(res['url']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: SerenityColors.groupedBackground,
      extendBody: true,
      // bottomNavigationBar usunięty — globalny dock przez MaterialApp.builder
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(child: _buildHero(user)),
            SliverToBoxAdapter(child: _buildStatsRow(user)),
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SerenitySpacing.md,
                      vertical: SerenitySpacing.sm,
                    ),
                    child: _buildCheckIn(),
                  ),
                  InsetGroupedSection(
                    header: 'Konto',
                    children: [
                      InsetGroupedRow(
                        icon: Icons.manage_accounts_outlined,
                        iconColor: SerenityColors.primaryContainer,
                        title: 'Dane konta',
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                      ),
                      InsetGroupedRow(
                        icon: Icons.tune,
                        iconColor: SerenityColors.secondary,
                        title: 'Promień powiadomień',
                        value: '${user?.alertRadiusM ?? 500}m',
                        onTap: () => _showRadiusSheet(user?.alertRadiusM ?? 500),
                      ),
                      InsetGroupedRow(
                        icon: Icons.share_location_outlined,
                        iconColor: SerenityColors.secondary,
                        title: 'Udostępnij lokalizację',
                        subtitle: 'Tymczasowy link na 1 godzinę',
                        onTap: _shareLocation,
                      ),
                    ],
                  ),
                  InsetGroupedSection(
                    header: 'Społeczność',
                    children: [
                      InsetGroupedRow(
                        icon: Icons.workspace_premium_outlined,
                        iconColor: SerenityColors.secondary,
                        title: 'Odznaki',
                        subtitle: 'Twoje osiągnięcia',
                        onTap: () => Navigator.pushNamed(context, '/badges'),
                      ),
                      InsetGroupedRow(
                        icon: Icons.leaderboard_outlined,
                        iconColor: SerenityColors.secondary,
                        title: 'Ranking',
                        onTap: () => Navigator.pushNamed(context, '/ranking'),
                      ),
                      InsetGroupedRow(
                        icon: Icons.history,
                        iconColor: SerenityColors.primaryContainer,
                        title: 'Moje zgłoszenia',
                        onTap: () => Navigator.pushNamed(context, '/my-alerts'),
                      ),
                      InsetGroupedRow(
                        icon: Icons.card_giftcard_outlined,
                        iconColor: SerenityColors.glowAlertCoral,
                        title: 'Polecaj znajomym',
                        subtitle: 'Twój kod polecający',
                        onTap: () => Navigator.pushNamed(context, '/referral'),
                      ),
                      InsetGroupedRow(
                        icon: Icons.article_outlined,
                        iconColor: SerenityColors.primaryContainer,
                        title: 'Aktualności',
                        onTap: () => Navigator.pushNamed(context, '/news'),
                      ),
                    ],
                  ),
                  InsetGroupedSection(
                    header: 'Ustawienia',
                    children: [
                      InsetGroupedRow(
                        icon: Icons.notifications_outlined,
                        iconColor: SerenityColors.primaryContainer,
                        title: 'Powiadomienia',
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                      ),
                      InsetGroupedRow(
                        icon: Icons.verified_user_outlined,
                        iconColor: SerenityColors.secondary,
                        title: 'Uprawnienia',
                        subtitle: 'Lokalizacja, kamera, mikrofon',
                        onTap: () =>
                            Navigator.pushNamed(context, '/permissions'),
                      ),
                      InsetGroupedRow(
                        icon: Icons.lock_outline,
                        iconColor: SerenityColors.primaryContainer,
                        title: 'Prywatność',
                        onTap: () => Navigator.pushNamed(context, '/privacy'),
                      ),
                      InsetGroupedRow(
                        icon: Icons.description_outlined,
                        iconColor: SerenityColors.primaryContainer,
                        title: 'Regulamin',
                        onTap: () => Navigator.pushNamed(context, '/terms'),
                      ),
                      InsetGroupedRow(
                        icon: Icons.help_outline,
                        iconColor: SerenityColors.primaryContainer,
                        title: 'Pomoc i wsparcie',
                        onTap: () => Navigator.pushNamed(context, '/emergency'),
                      ),
                    ],
                  ),
                  InsetGroupedSection(
                    footer: 'Zostaniesz wylogowany ze wszystkich urządzeń.',
                    children: [
                      InsetGroupedRow(
                        icon: Icons.logout,
                        title: 'Wyloguj się',
                        destructive: true,
                        onTap: _doLogout,
                      ),
                    ],
                  ),
                  // Padding na docka z nawigacją (~96px + safe area)
                  SizedBox(
                    height: 96 + MediaQuery.of(context).padding.bottom,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SerenitySpacing.xl,
        vertical: SerenitySpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            color: SerenityColors.primary,
            tooltip: 'Wróć',
            onPressed: () => Navigator.pop(context),
          ),
          Text('Twój Profil', style: SerenityText.headlineHeroMobile),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 26),
            color: SerenityColors.primary,
            tooltip: 'Ustawienia',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(user) {
    final name = user?.username ?? '';
    final email = user?.email ?? '';
    final avatarUrl = user?.avatarUrl;
    return AppleCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: SerenitySpacing.xl),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SerenityColors.surfaceContainerLowest,
                  boxShadow: SerenityElevation.card(),
                ),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl.toString(),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _avatarFallback(name),
                        )
                      : _avatarFallback(name),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: SerenityColors.primaryContainer,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.edit,
                        color: SerenityColors.onPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: SerenityText.headlineHeroMobile.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: SerenityText.bodyMain.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: SerenityColors.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: SerenityText.displayMd.copyWith(
          fontSize: 56,
          color: SerenityColors.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildStatsRow(user) {
    final reputation = user?.reputationScore ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SerenitySpacing.xl,
        vertical: SerenitySpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              value: _loadingStats ? '—' : '$_alertCount',
              label: _alertCount == 1 ? 'Zgłoszenie' : 'Zgłoszeń',
            ),
          ),
          const SizedBox(width: SerenitySpacing.md),
          Expanded(
            child: _StatCard(
              value: '$reputation',
              label: 'Punktów zaufania',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckIn() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: SerenityColors.secondaryContainer,
        borderRadius: SerenityShapes.pill(),
        child: InkWell(
          borderRadius: SerenityShapes.pill(),
          onTap: _checkIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: SerenityColors.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Jestem bezpieczny/a',
                  style: SerenityText.labelButton.copyWith(
                    fontSize: 16,
                    color: SerenityColors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _doLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wylogować się?'),
        content: const Text(
          'Stracisz dostęp do alertów i lokalizacji rodziny do następnego zalogowania.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: SerenityColors.error),
            child: const Text('Wyloguj'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showRadiusSheet(int current) {
    double radius = current.toDouble();
    bool saving = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SerenityColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: SerenitySpacing.xl,
            right: SerenitySpacing.xl,
            top: SerenitySpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Text(
                'Promień powiadomień',
                style: SerenityText.headlineHeroMobile.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Otrzymujesz powiadomienia o zagrożeniach w promieniu ${radius.round()}m',
                style: SerenityText.bodyMain,
              ),
              const SizedBox(height: SerenitySpacing.md),
              SliderTheme(
                data: SliderTheme.of(ctx).copyWith(
                  activeTrackColor: SerenityColors.primary,
                  thumbColor: SerenityColors.primary,
                  inactiveTrackColor: SerenityColors.surfaceContainerHigh,
                  overlayColor:
                      SerenityColors.primary.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: radius,
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  label: '${radius.round()}m',
                  onChanged: (v) => setS(() => radius = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('100m', style: SerenityText.labelCaps),
                  Text('5km', style: SerenityText.labelCaps),
                ],
              ),
              const SizedBox(height: SerenitySpacing.xl),
              Material(
                color: SerenityColors.primaryContainer,
                borderRadius: SerenityShapes.pill(),
                child: InkWell(
                  borderRadius: SerenityShapes.pill(),
                  onTap: saving
                      ? null
                      : () async {
                          setS(() => saving = true);
                          await context
                              .read<ApiService>()
                              .patch('/users/me', {
                            'alert_radius_m': radius.round(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  SerenityColors.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'Zapisz',
                              style: SerenityText.labelButton.copyWith(
                                fontSize: 16,
                                color: SerenityColors.onPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ──────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return SerenityCard(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            value,
            style: SerenityText.displayMd.copyWith(
              fontSize: 44,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: SerenityText.bodyMain.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}


