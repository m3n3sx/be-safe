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
      final res = await api.get('/users/me/alerts');
      int count = 0;
      if (res is List) {
        count = res.length;
      } else if (res is Map) {
        final list = res['alerts'];
        if (list is List) count = list.length;
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
      backgroundColor: SerenityColors.surfaceBright,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(child: _buildHero(user)),
            SliverToBoxAdapter(child: _buildStatsRow(user)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: SerenitySpacing.xl,
                vertical: SerenitySpacing.md,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildCheckIn(),
                  const SizedBox(height: SerenitySpacing.lg),
                  _SectionLabel('Konto'),
                  _RowTile(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Dane konta',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  _RowTile(
                    icon: Icons.tune,
                    label: 'Promień powiadomień',
                    subtitle:
                        '${user?.alertRadiusM ?? 500}m od twojej lokalizacji',
                    onTap: () => _showRadiusSheet(user?.alertRadiusM ?? 500),
                  ),
                  _RowTile(
                    icon: Icons.share_location_outlined,
                    label: 'Udostępnij lokalizację',
                    subtitle: 'Tymczasowy link na 1 godzinę',
                    onTap: _shareLocation,
                  ),
                  const SizedBox(height: SerenitySpacing.lg),
                  _SectionLabel('Społeczność'),
                  _RowTile(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Odznaki',
                    subtitle: 'Twoje osiągnięcia',
                    onTap: () => Navigator.pushNamed(context, '/badges'),
                  ),
                  _RowTile(
                    icon: Icons.leaderboard_outlined,
                    label: 'Ranking',
                    onTap: () => Navigator.pushNamed(context, '/ranking'),
                  ),
                  _RowTile(
                    icon: Icons.history,
                    label: 'Moje zgłoszenia',
                    onTap: () => Navigator.pushNamed(context, '/my-alerts'),
                  ),
                  _RowTile(
                    icon: Icons.card_giftcard_outlined,
                    label: 'Polecaj znajomym',
                    subtitle: 'Twój kod polecający',
                    onTap: () => Navigator.pushNamed(context, '/referral'),
                  ),
                  _RowTile(
                    icon: Icons.article_outlined,
                    label: 'Aktualności',
                    onTap: () => Navigator.pushNamed(context, '/news'),
                  ),
                  const SizedBox(height: SerenitySpacing.lg),
                  _SectionLabel('Ustawienia'),
                  _RowTile(
                    icon: Icons.notifications_outlined,
                    label: 'Powiadomienia',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  _RowTile(
                    icon: Icons.lock_outline,
                    label: 'Prywatność',
                    onTap: () => Navigator.pushNamed(context, '/privacy'),
                  ),
                  _RowTile(
                    icon: Icons.description_outlined,
                    label: 'Regulamin',
                    onTap: () => Navigator.pushNamed(context, '/terms'),
                  ),
                  _RowTile(
                    icon: Icons.help_outline,
                    label: 'Pomoc i wsparcie',
                    onTap: () => Navigator.pushNamed(context, '/emergency'),
                  ),
                  const SizedBox(height: SerenitySpacing.xl),
                  _buildLogout(),
                  const SizedBox(height: SerenitySpacing.xxxl),
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
            onPressed: () => Navigator.pop(context),
          ),
          Text('Twój Profil', style: SerenityText.headlineHeroMobile),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 26),
            color: SerenityColors.primary,
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
    return Padding(
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

  Widget _buildLogout() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: SerenityShapes.pill(),
        child: InkWell(
          borderRadius: SerenityShapes.pill(),
          onTap: () async {
            await context.read<AuthProvider>().logout();
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: SerenityShapes.pill(),
              border: Border.all(
                color: SerenityColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: SerenityColors.error, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Wyloguj się',
                  style: SerenityText.labelButton.copyWith(
                    fontSize: 16,
                    color: SerenityColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: SerenitySpacing.sm,
      ),
      child: Text(
        text.toUpperCase(),
        style: SerenityText.labelCaps.copyWith(
          color: SerenityColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _RowTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SerenitySpacing.xs),
      child: SerenityCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: SerenitySpacing.lg,
          vertical: SerenitySpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: SerenityColors.primary, size: 24),
            const SizedBox(width: SerenitySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: SerenityText.labelButton.copyWith(fontSize: 16),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: SerenityText.bodyMain.copyWith(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: SerenityColors.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
