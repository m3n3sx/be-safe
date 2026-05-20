/// be:Safe v2 — My Alerts Screen (Serenity Guard)
///
/// Lists alerts reported by the current user. Each row uses SerenityCard with
/// category icon + title + status, plus overflow menu for extend/edit/delete.
///
/// Design source: design/stitch_v2/screens/alerty_bezpiecze_stwa/
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alert.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/serenity_card.dart';
import 'alert_detail_screen.dart';

class MyAlertsScreen extends StatefulWidget {
  const MyAlertsScreen({super.key});

  @override
  State<MyAlertsScreen> createState() => _MyAlertsScreenState();
}

class _MyAlertsScreenState extends State<MyAlertsScreen> {
  List<AlertModel> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await context.read<ApiService>().get('/alerts/mine');
      final list = ((res as dynamic)['alerts'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _alerts = list.map((a) => AlertModel.fromJson(a)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _extend(String id) async {
    await context
        .read<ApiService>()
        .patch('/alerts/$id', {'extend_hours': 3});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SerenityColors.secondary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        ),
        content: const Text('Przedłużono o 3 godziny'),
      ),
    );
    _load();
  }

  Future<void> _editDesc(String id, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SerenityColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        ),
        title: const Text('Edytuj opis'),
        content: TextField(controller: ctrl, maxLines: 3, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    await context
        .read<ApiService>()
        .patch('/alerts/$id', {'description': result});
    _load();
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SerenityColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        ),
        title: const Text('Usunąć alert?'),
        content: const Text('Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: SerenityColors.error),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await context.read<ApiService>().delete('/alerts/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _alerts.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
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
          Text(
            'Moje zgłoszenia',
            style: SerenityText.headlineHeroMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(SerenitySpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 72,
            color: SerenityColors.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Brak zgłoszeń',
            style: SerenityText.headlineHeroMobile.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Twoje zgłoszenia pojawią się tutaj',
            textAlign: TextAlign.center,
            style: SerenityText.bodyMain,
          ),
          const SizedBox(height: 24),
          Material(
            color: SerenityColors.primaryContainer,
            borderRadius: SerenityShapes.pill(),
            child: InkWell(
              borderRadius: SerenityShapes.pill(),
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: SerenityColors.glowAlertCoral,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Zgłoś zagrożenie',
                      style: SerenityText.labelButton.copyWith(
                        fontSize: 15,
                        color: SerenityColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _load,
      color: SerenityColors.primary,
      backgroundColor: SerenityColors.surfaceContainerLowest,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          SerenitySpacing.xl,
          SerenitySpacing.sm,
          SerenitySpacing.xl,
          SerenitySpacing.xxxl,
        ),
        itemCount: _alerts.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: SerenitySpacing.xs),
        itemBuilder: (_, i) {
          final a = _alerts[i];
          final isActive = a.expiresAt.isAfter(DateTime.now());
          return SerenityCard(
            padding: const EdgeInsets.symmetric(
              horizontal: SerenitySpacing.lg,
              vertical: SerenitySpacing.md,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlertDetailScreen(alert: a),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? SerenityColors.tertiaryFixed
                        : SerenityColors.surfaceContainer,
                  ),
                  child: Icon(
                    a.category.iconData,
                    color: isActive
                        ? SerenityColors.onTertiaryContainer
                        : SerenityColors.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: SerenitySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: SerenityText.labelButton.copyWith(
                          fontSize: 15,
                          color: isActive
                              ? SerenityColors.primary
                              : SerenityColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${a.category.label} · ${isActive ? 'aktywny' : 'wygasł'}',
                        style: SerenityText.bodyMain.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: SerenityColors.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: SerenityColors.surfaceContainerLowest,
                  onSelected: (v) {
                    if (v == 'view') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlertDetailScreen(alert: a),
                        ),
                      );
                    }
                    if (v == 'extend') _extend(a.id);
                    if (v == 'edit') _editDesc(a.id, a.description ?? '');
                    if (v == 'delete') _delete(a.id);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'view', child: Text('Szczegóły')),
                    if (isActive)
                      const PopupMenuItem(
                        value: 'extend',
                        child: Text('Przedłuż o 3h'),
                      ),
                    if (isActive)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edytuj opis'),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Usuń',
                        style: TextStyle(color: SerenityColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
