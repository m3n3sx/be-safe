/// be:Safe v2 — Alert Detail Screen (Serenity Guard)
///
/// Alert detail: map preview, photo, title, info chips, credibility,
/// vote buttons, realtime comments.
///
/// Design source: design/stitch_v2/screens/szczeg_y_alertu_be_safe/
library;

import 'package:flutter/material.dart';
import '../../theme/map_style.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/serenity_card.dart';

class AlertDetailScreen extends StatefulWidget {
  final AlertModel alert;
  const AlertDetailScreen({super.key, required this.alert});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  List<Map<String, dynamic>> _comments = [];
  final _commentCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;
  void Function()? _unsubscribe;

  @override
  void initState() {
    super.initState();
    _loadComments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final socket = context.read<SocketService>();
      _unsubscribe = socket.subscribeToAlert(
        widget.alert.id,
        onNewComment: (c) {
          if (!mounted) return;
          if (_comments.any((x) => x['id'] == c['id'])) return;
          setState(() => _comments.add(c));
          _scrollToBottom();
        },
        onCommentDeleted: (c) {
          if (!mounted) return;
          setState(
            () => _comments.removeWhere((x) => x['id'] == c['comment_id']),
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _commentCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadComments() async {
    try {
      final res = await context
          .read<ApiService>()
          .get('/alerts/${widget.alert.id}/comments');
      final list = (res['comments'] as List?) ?? [];
      if (mounted) {
        setState(() => _comments = List<Map<String, dynamic>>.from(list));
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _addComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final res = await context.read<ApiService>().post(
        '/alerts/${widget.alert.id}/comments',
        {'content': _commentCtrl.text.trim()},
      );
      if (res['id'] != null) {
        _commentCtrl.clear();
        if (!_comments.any((x) => x['id'] == res['id'])) {
          setState(() => _comments.add(res));
          _scrollToBottom();
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _vote(String type) async {
    HapticFeedback.lightImpact();
    final isConfirm = type == 'confirm';
    // Confirmation dialog — zapobiega pomyłkowemu tapnięciu (głos jest
    // jednorazowy, nie ma cofania na backendzie).
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isConfirm ? 'Potwierdzić zagrożenie?' : 'Oznaczyć jako nieaktualne?',
        ),
        content: Text(
          isConfirm
              ? 'Potwierdzasz, że zagrożenie nadal istnieje. Tego głosu nie można cofnąć.'
              : 'Oznaczasz alert jako nieaktualny. Po kilku takich głosach alert zostanie ukryty. Tego głosu nie można cofnąć.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: isConfirm
                  ? SerenityColors.secondary
                  : SerenityColors.error,
            ),
            child: Text(isConfirm ? 'Potwierdzam' : 'Nieaktualne'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    try {
      await context.read<AlertProvider>().vote(widget.alert.id, type);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isConfirm
              ? SerenityColors.secondary
              : SerenityColors.onSurfaceVariant,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
          ),
          content: Text(
            isConfirm
                ? 'Potwierdzono zagrożenie'
                : 'Oznaczono jako nieaktualne',
          ),
        ),
      );
      // NIE pop-ujemy — niech user zostaje na widoku alertu i widzi efekt głosu
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Już głosowałeś na ten alert')),
      );
    }
  }

  Future<void> _reportAlert() async {
    HapticFeedback.lightImpact();
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.iosCardSurface,
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
                color: context.iosSeparator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SerenitySpacing.xl,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Zgłoś nadużycie',
                  style: SerenityText.headlineHeroMobile.copyWith(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final r in [
              ('spam', 'Spam / reklama'),
              ('fake', 'Fałszywe zgłoszenie'),
              ('offensive', 'Treść obraźliwa'),
              ('illegal', 'Treść niezgodna z prawem'),
              ('other', 'Inne'),
            ])
              ListTile(
                title: Text(r.$2, style: SerenityText.labelButton.copyWith(fontSize: 15)),
                onTap: () => Navigator.pop(ctx, r.$1),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await context
          .read<ApiService>()
          .post('/alerts/${widget.alert.id}/report', {'reason': reason});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SerenityColors.secondary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
            ),
            content: const Text('Zgłoszenie wysłane. Dziękujemy!'),
          ),
        );
      }
    } catch (_) {}
  }

  String _fmt(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    final timeAgo = DateTime.now().difference(a.createdAt);
    final expiresIn = a.expiresAt.difference(DateTime.now());
    final total = a.confirms + a.denies;
    final confirmPct = total > 0 ? a.confirms / total : 0.5;

    return Scaffold(
      backgroundColor: context.iosBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(a),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: EdgeInsets.zero,
                children: [
                  _buildMap(a),
                  if (a.photoUrl != null) _buildPhoto(a),
                  Padding(
                    padding: const EdgeInsets.all(SerenitySpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: SerenityText.displayMd.copyWith(
                            fontSize: 28,
                            height: 36 / 28,
                          ),
                        ),
                        const SizedBox(height: SerenitySpacing.md),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _infoChip(
                              Icons.access_time,
                              '${_fmt(timeAgo)} temu',
                            ),
                            _infoChip(
                              Icons.timer_outlined,
                              'wygasa za ${_fmt(expiresIn)}',
                            ),
                            if (a.distanceM != null)
                              _infoChip(
                                Icons.near_me,
                                '${a.distanceM!.round()}m',
                              ),
                            _authorChip(a),
                          ],
                        ),
                        if (a.description != null) ...[
                          const SizedBox(height: SerenitySpacing.lg),
                          Text(
                            a.description!,
                            style: SerenityText.bodyMain.copyWith(
                              fontSize: 15,
                              color: context.iosLabel,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: SerenitySpacing.lg),
                        _buildCredibility(a, confirmPct),
                        const SizedBox(height: SerenitySpacing.md),
                        _buildVoteRow(),
                        const SizedBox(height: SerenitySpacing.xxl),
                        _buildCommentsHeader(),
                        const SizedBox(height: SerenitySpacing.sm),
                        ..._comments.map(_buildCommentTile),
                        if (_comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Brak komentarzy. Bądź pierwszy!',
                              style: SerenityText.bodyMain,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AlertModel a) {
    return Padding(
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
          Expanded(
            child: Text(
              a.category.label,
              style: SerenityText.headlineHeroMobile.copyWith(fontSize: 22),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            color: context.iosLabel,
            tooltip: 'Udostępnij alert',
            onPressed: () => Share.share(
              '⚠️ ${a.title}\n\n${a.description ?? ""}\n\n'
              'Lokalizacja: https://www.google.com/maps?q=${a.location.latitude},${a.location.longitude}\n\n'
              'be:Safe — https://besafe.org.pl',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            color: context.iosLabel,
            tooltip: 'Zgłoś nadużycie',
            onPressed: _reportAlert,
          ),
        ],
      ),
    );
  }

  Widget _buildMap(AlertModel a) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SerenitySpacing.xl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        child: SizedBox(
          height: 200,
          child: GoogleMap(
              style: Theme.of(context).brightness == Brightness.dark ? kDarkMapStyle : null,
            initialCameraPosition: CameraPosition(target: a.location, zoom: 16),
            markers: {Marker(markerId: MarkerId(a.id), position: a.location)},
            circles: {
              Circle(
                circleId: CircleId(a.id),
                center: a.location,
                radius: a.radiusM.toDouble(),
                fillColor:
                    SerenityColors.glowAlertCoral.withValues(alpha: 0.18),
                strokeColor: SerenityColors.glowAlertCoral,
                strokeWidth: 2,
              ),
            },
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            liteModeEnabled: true,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(AlertModel a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SerenitySpacing.xl,
        SerenitySpacing.md,
        SerenitySpacing.xl,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        child: Image.network(
          a.photoUrl!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SerenityColors.surfaceContainer,
        borderRadius: BorderRadius.circular(SerenityShapes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.iosSecondaryLabel),
          const SizedBox(width: 6),
          Text(text, style: SerenityText.labelCaps.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _authorChip(AlertModel a) {
    final repColor = a.authorReputation >= 200
        ? SerenityColors.secondary
        : (a.authorReputation >= 100
            ? SerenityColors.onTertiaryContainer
            : SerenityColors.error);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: a.authorVerified
            ? SerenityColors.primary.withValues(alpha: 0.08)
            : SerenityColors.surfaceContainer,
        borderRadius: BorderRadius.circular(SerenityShapes.radiusFull),
        border: a.authorVerified
            ? Border.all(color: context.iosLabel, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            a.authorVerified ? Icons.verified : Icons.person_outline,
            size: 14,
            color: a.authorVerified
                ? SerenityColors.primary
                : SerenityColors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            a.authorUsername,
            style: SerenityText.labelCaps.copyWith(
              fontSize: 11,
              color: a.authorVerified
                  ? SerenityColors.primary
                  : SerenityColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.star, size: 11, color: repColor),
          const SizedBox(width: 2),
          Text(
            '${a.authorReputation}',
            style: SerenityText.labelCaps.copyWith(
              fontSize: 10,
              color: repColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredibility(AlertModel a, double confirmPct) {
    return SerenityCard(
      padding: const EdgeInsets.all(SerenitySpacing.md + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WIARYGODNOŚĆ',
            style: SerenityText.labelCaps,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: confirmPct,
              minHeight: 10,
              backgroundColor: SerenityColors.tertiaryFixed,
              color: SerenityColors.secondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '✓ ${a.confirms} potwierdzeń',
                style: SerenityText.labelButton.copyWith(
                  fontSize: 13,
                  color: SerenityColors.secondary,
                ),
              ),
              Text(
                '✗ ${a.denies} zaprzeczeń',
                style: SerenityText.labelButton.copyWith(
                  fontSize: 13,
                  color: SerenityColors.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteRow() {
    return Row(
      children: [
        Expanded(
          child: _voteButton(
            label: 'Potwierdzam',
            icon: Icons.thumb_up_outlined,
            color: SerenityColors.secondary,
            onTap: () => _vote('confirm'),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _voteButton(
            label: 'Nieaktualne',
            icon: Icons.thumb_down_outlined,
            color: SerenityColors.onTertiaryContainer,
            onTap: () => _vote('deny'),
            outline: true,
          ),
        ),
      ],
    );
  }

  Widget _voteButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool outline = false,
  }) {
    return Material(
      color: outline ? Colors.transparent : color,
      borderRadius: SerenityShapes.pill(),
      child: InkWell(
        borderRadius: SerenityShapes.pill(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: SerenityShapes.pill(),
            border: outline
                ? Border.all(color: color.withValues(alpha: 0.5))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: outline ? color : SerenityColors.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: SerenityText.labelButton.copyWith(
                  color: outline ? color : SerenityColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsHeader() {
    return Row(
      children: [
        Icon(
          Icons.chat_bubble_outline,
          size: 18,
          color: context.iosSecondaryLabel,
        ),
        const SizedBox(width: 8),
        Text(
          'KOMENTARZE (${_comments.length})',
          style: SerenityText.labelCaps,
        ),
      ],
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> c) {
    final author =
        c['author'] is Map ? c['author']['username'] ?? 'Anonim' : 'Anonim';
    final time = DateTime.tryParse(c['created_at'] ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: SerenitySpacing.sm),
      child: SerenityCard(
        padding: const EdgeInsets.all(SerenitySpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: SerenityColors.secondaryContainer,
              child: Text(
                author.isNotEmpty ? author[0].toUpperCase() : '?',
                style: SerenityText.labelButton.copyWith(
                  fontSize: 13,
                  color: SerenityColors.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        author,
                        style: SerenityText.labelButton.copyWith(fontSize: 13),
                      ),
                      if (time != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${_fmt(DateTime.now().difference(time))} temu',
                          style:
                              SerenityText.labelCaps.copyWith(fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c['content'] ?? '',
                    style: SerenityText.bodyMain.copyWith(
                      fontSize: 14,
                      color: context.iosLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        8,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: context.iosBackground,
        border: Border(
          top: BorderSide(
            color: context.iosSeparator.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              style: SerenityText.bodyMain.copyWith(
                color: context.iosLabel,
              ),
              decoration: InputDecoration(
                hintText: 'Dodaj komentarz...',
                hintStyle: SerenityText.bodyMain.copyWith(
                  color: context.iosSecondaryLabel,
                ),
                filled: true,
                fillColor: SerenityColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: SerenityShapes.pill(),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: SerenityShapes.pill(),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: SerenityShapes.pill(),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addComment(),
            ),
          ),
          const SizedBox(width: 8),
          _sending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Material(
                  color: SerenityColors.primaryContainer,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _addComment,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.send,
                        size: 20,
                        color: SerenityColors.onPrimary,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
