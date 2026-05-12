/// be:Safe v2 — Family Screen (Twoja Rodzina)
///
/// Shows family group members status in a Serenity-style grid.
/// Empty state when no group. Switch between groups via top chip row.
///
/// Design source: design/stitch_v2/screens/rodzina_be_safe/
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/glow_orb.dart';
import '../../widgets/serenity_card.dart';
import 'family_group_screen.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<dynamic> _groups = [];
  int _activeGroup = 0;
  List<dynamic> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGroups());
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/family/groups');
      final groups = (res['groups'] as List?) ?? [];
      _groups = groups;
      if (groups.isNotEmpty) {
        if (_activeGroup >= groups.length) _activeGroup = 0;
        await _loadMembers(groups[_activeGroup]['id']);
      } else {
        _members = [];
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMembers(String groupId) async {
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/family/groups/$groupId/members');
      final members = (res['members'] as List?) ?? [];
      _members = members;
    } catch (_) {
      _members = [];
    }
  }

  int get _onlineCount {
    final now = DateTime.now();
    return _members.where((m) {
      final last = m['last_seen_at'] ?? m['updated_at'];
      if (last == null) return false;
      try {
        return now.difference(DateTime.parse(last.toString())).inMinutes < 15;
      } catch (_) {
        return false;
      }
    }).length;
  }

  bool _isOnline(Map m) {
    final last = m['last_seen_at'] ?? m['updated_at'];
    if (last == null) return false;
    try {
      return DateTime.now()
              .difference(DateTime.parse(last.toString()))
              .inMinutes <
          15;
    } catch (_) {
      return false;
    }
  }

  String _statusLabel(Map m) {
    if (_isOnline(m)) {
      final loc = m['location_label'] ?? m['last_location_label'];
      return loc != null ? 'Bezpieczny · $loc' : 'Bezpieczny';
    }
    return 'Niedostępny';
  }

  String _lastSeenText(Map m) {
    final last = m['last_seen_at'] ?? m['updated_at'];
    if (last == null) return '—';
    try {
      final diff = DateTime.now().difference(DateTime.parse(last.toString()));
      if (diff.inMinutes < 1) return 'teraz';
      if (diff.inHours < 1) return '${diff.inMinutes} min temu';
      if (diff.inDays < 1) return '${diff.inHours} godz temu';
      return '${diff.inDays} dni temu';
    } catch (_) {
      return '—';
    }
  }

  Color _orbColor() {
    if (_members.isEmpty) return SerenityColors.glowCalmAqua;
    final online = _onlineCount;
    if (online == _members.length) return SerenityColors.glowSafeMint;
    if (online > 0) return SerenityColors.glowCalmAqua;
    return SerenityColors.glowAlertCoral;
  }

  String _statusMessage() {
    if (_members.isEmpty) return 'Brak członków';
    final online = _onlineCount;
    if (online == _members.length) return 'Wszyscy bezpieczni';
    if (online == 0) return 'Brak kontaktu';
    return '$online z ${_members.length} online';
  }

  Future<String?> _showInputDialog(String label) => showDialog<String>(
        context: context,
        builder: (ctx) {
          final c = TextEditingController();
          return AlertDialog(
            title: Text(label),
            content: TextField(controller: c, autofocus: true),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Anuluj'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, c.text),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

  Future<void> _createGroup() async {
    final name = await _showInputDialog('Nazwa grupy rodzinnej');
    if (name == null || name.isEmpty) return;
    if (!mounted) return;
    final api = context.read<ApiService>();
    final res = await api.post('/family/groups', {'name': name});
    if (res['invite_code'] != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kod zaproszenia: ${res['invite_code']}')),
      );
    }
    _loadGroups();
  }

  Future<void> _joinGroup() async {
    final code = await _showInputDialog('Kod zaproszenia');
    if (code == null || code.isEmpty) return;
    if (!mounted) return;
    await context
        .read<ApiService>()
        .post('/family/groups/join', {'invite_code': code});
    _loadGroups();
  }

  void _showQr(String name, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SerenityColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        ),
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Zeskanuj QR albo wpisz kod',
              style: SerenityText.bodyMain.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: 'besafe://family/join/$code',
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              code,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSignal() async {
    if (_groups.isEmpty) return;
    HapticFeedback.mediumImpact();
    try {
      final api = context.read<ApiService>();
      await api.post('/family/groups/${_groups[_activeGroup]['id']}/ping', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: SerenityColors.secondary,
          content: const Text('Sygnał wysłany do członków rodziny'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się wysłać sygnału')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _groups.isEmpty
                ? _buildEmpty()
                : _buildGroupView(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SerenitySpacing.xl),
      child: Column(
        children: [
          _buildTopBar(actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              color: SerenityColors.primary,
              onPressed: _createGroup,
              tooltip: 'Utwórz grupę',
            ),
          ]),
          const Spacer(),
          SizedBox(
            width: 220,
            height: 220,
            child: GlowOrb(
              size: 220,
              color: SerenityColors.glowCalmAqua,
              coreOpacity: 0.5,
              child: const Icon(
                Icons.family_restroom,
                size: 64,
                color: SerenityColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Brak rodziny',
            style: SerenityText.displayMd.copyWith(
              fontSize: 36,
              height: 44 / 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Utwórz grupę i zaproś bliskich. Zobaczysz ich lokalizację i dostaniesz alerty gdy opuszczą bezpieczną strefę.',
            style: SerenityText.bodyMain,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _PrimaryPillButton(
            label: 'Utwórz grupę',
            icon: Icons.add,
            onTap: _createGroup,
          ),
          const SizedBox(height: 12),
          _OutlinePillButton(label: 'Dołącz kodem', onTap: _joinGroup),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildGroupView() {
    final active = _groups[_activeGroup];
    return RefreshIndicator(
      onRefresh: _loadGroups,
      color: SerenityColors.primary,
      backgroundColor: SerenityColors.surfaceContainerLowest,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildTopBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_2, size: 26),
                  color: SerenityColors.primary,
                  onPressed: () =>
                      _showQr(active['name'], active['invite_code']),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 28),
                  color: SerenityColors.primary,
                  onPressed: () => _openGroupMenu(active),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _buildHero()),
          if (_groups.length > 1)
            SliverToBoxAdapter(child: _buildGroupChips()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: SerenitySpacing.xl,
              vertical: SerenitySpacing.lg,
            ),
            sliver: _members.isEmpty
                ? SliverToBoxAdapter(child: _buildNoMembers(active))
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: SerenitySpacing.md,
                      crossAxisSpacing: SerenitySpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _MemberCard(
                        member: _members[i],
                        online: _isOnline(_members[i] as Map),
                        statusLabel: _statusLabel(_members[i] as Map),
                        lastSeen: _lastSeenText(_members[i] as Map),
                      ),
                      childCount: _members.length,
                    ),
                  ),
          ),
          SliverToBoxAdapter(child: _buildActions()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ── UI parts ────────────────────────────────────────────────────────────

  Widget _buildTopBar({required List<Widget> actions}) {
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.shield, color: SerenityColors.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'be:Safe',
                style: SerenityText.headlineHeroMobile,
              ),
            ],
          ),
          Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final online = _onlineCount;
    final total = _members.length;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        children: [
          Text(
            'Twoja Rodzina',
            style: SerenityText.displayMd.copyWith(
              fontSize: 40,
              height: 48 / 40,
            ),
          ),
          const SizedBox(height: 32),
          GlowOrb(
            size: 240,
            color: _orbColor(),
            coreOpacity: 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  total == 0 ? '—' : '$online/$total',
                  style: SerenityText.displayLg.copyWith(
                    fontSize: 72,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(_statusMessage(), style: SerenityText.bodyMain),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: SerenitySpacing.xl),
          itemCount: _groups.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == _activeGroup;
            return _GroupChip(
              label: _groups[i]['name'],
              active: active,
              onTap: () async {
                setState(() => _activeGroup = i);
                await _loadMembers(_groups[i]['id']);
                if (mounted) setState(() {});
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoMembers(Map group) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Text(
          'Nie masz jeszcze członków w tej grupie.',
          style: SerenityText.bodyMain,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _OutlinePillButton(
          label: 'Pokaż kod zaproszenia',
          icon: Icons.qr_code_2,
          onTap: () => _showQr(group['name'], group['invite_code']),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SerenitySpacing.xl,
        vertical: SerenitySpacing.md,
      ),
      child: Column(
        children: [
          _PrimaryPillButton(
            label: 'Wyślij sygnał',
            icon: Icons.notifications_active_outlined,
            onTap: _members.isEmpty ? null : _sendSignal,
          ),
          const SizedBox(height: 12),
          _OutlinePillButton(
            label: 'Sprawdź trasę',
            icon: Icons.timeline,
            onTap: () {
              final g = _groups[_activeGroup];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FamilyGroupScreen(
                    groupId: g['id'],
                    groupName: g['name'],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openGroupMenu(Map group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SerenityColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: SerenityColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: SerenityColors.primary,
              ),
              title: Text(
                'Utwórz nową grupę',
                style: SerenityText.labelButton.copyWith(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _createGroup();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.link,
                color: SerenityColors.primary,
              ),
              title: Text(
                'Dołącz do innej grupy',
                style: SerenityText.labelButton.copyWith(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _joinGroup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                'Usuń grupę',
                style: SerenityText.labelButton.copyWith(
                  fontSize: 16,
                  color: SerenityColors.error,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Usuń grupę?'),
                    content: Text('Grupa "${group['name']}" zostanie usunięta.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d),
                        child: const Text('Anuluj'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(d, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Usuń'),
                      ),
                    ],
                  ),
                );
                if (ok == true && mounted) {
                  await context
                      .read<ApiService>()
                      .delete('/family/groups/${group['id']}');
                  _loadGroups();
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ──────────────────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final Map member;
  final bool online;
  final String statusLabel;
  final String lastSeen;

  const _MemberCard({
    required this.member,
    required this.online,
    required this.statusLabel,
    required this.lastSeen,
  });

  @override
  Widget build(BuildContext context) {
    final name = member['username'] ?? member['display_name'] ?? '?';
    final avatarUrl = member['avatar_url'];
    final ringColor = online
        ? SerenityColors.glowSafeMint
        : SerenityColors.outlineVariant;

    return SerenityCard(
      padding: const EdgeInsets.all(SerenitySpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 3),
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl.toString().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl.toString(),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _AvatarFallback(name: name),
                      errorWidget: (_, __, ___) => _AvatarFallback(name: name),
                    )
                  : _AvatarFallback(name: name),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: SerenityText.labelButton.copyWith(
              fontSize: 15,
              color: SerenityColors.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online
                      ? SerenityColors.secondary
                      : SerenityColors.outline,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  online ? statusLabel : lastSeen,
                  style: SerenityText.bodyMain.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: SerenityColors.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: SerenityText.headlineHero.copyWith(
          color: SerenityColors.onSecondaryContainer,
          fontSize: 28,
        ),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _GroupChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? SerenityColors.secondaryContainer
          : SerenityColors.surfaceContainerLowest,
      borderRadius: SerenityShapes.pill(),
      child: InkWell(
        borderRadius: SerenityShapes.pill(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: SerenityShapes.pill(),
            border: active
                ? null
                : Border.all(
                    color: SerenityColors.outlineVariant.withValues(alpha: 0.5),
                  ),
          ),
          child: Text(
            label,
            style: SerenityText.labelButton.copyWith(
              color: active
                  ? SerenityColors.onSecondaryContainer
                  : SerenityColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _PrimaryPillButton({
    required this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: enabled
            ? SerenityColors.primaryContainer
            : SerenityColors.surfaceContainerHigh,
        borderRadius: SerenityShapes.pill(),
        child: InkWell(
          borderRadius: SerenityShapes.pill(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: enabled
                        ? SerenityColors.onPrimary
                        : SerenityColors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: SerenityText.labelButton.copyWith(
                    fontSize: 16,
                    color: enabled
                        ? SerenityColors.onPrimary
                        : SerenityColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinePillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _OutlinePillButton({
    required this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: SerenityShapes.pill(),
        child: InkWell(
          borderRadius: SerenityShapes.pill(),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: SerenityShapes.pill(),
              border: Border.all(
                color: SerenityColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: SerenityColors.primary, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: SerenityText.labelButton.copyWith(
                    fontSize: 16,
                    color: SerenityColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
