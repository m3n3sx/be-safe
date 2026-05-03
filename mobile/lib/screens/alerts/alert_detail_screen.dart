import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../services/api_service.dart';
import '../../services/i18n.dart';

class AlertDetailScreen extends StatefulWidget {
  final AlertModel alert;
  const AlertDetailScreen({super.key, required this.alert});
  @override State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  List<Map<String, dynamic>> _comments = [];
  final _commentCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() { super.initState(); _loadComments(); }

  Future<void> _loadComments() async {
    try {
      final res = await context.read<ApiService>().get('/alerts/${widget.alert.id}/comments');
      if (res['comments'] != null && mounted) setState(() => _comments = List<Map<String, dynamic>>.from(res['comments']));
    } catch (_) {}
  }

  Future<void> _addComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final res = await context.read<ApiService>().post('/alerts/${widget.alert.id}/comments', {'content': _commentCtrl.text.trim()});
      if (res['id'] != null) { _commentCtrl.clear(); _loadComments(); }
    } catch (_) {
    } finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    final cs = Theme.of(context).colorScheme;
    final timeAgo = DateTime.now().difference(a.createdAt);
    final expiresIn = a.expiresAt.difference(DateTime.now());
    final total = a.confirms + a.denies;
    final confirmPct = total > 0 ? a.confirms / total : 0.5;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(a.category.label)),
      body: Column(children: [
        Expanded(child: ListView(children: [
          // Map
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: SizedBox(height: 200, child: GoogleMap(
              initialCameraPosition: CameraPosition(target: a.location, zoom: 16),
              markers: {Marker(markerId: MarkerId(a.id), position: a.location)},
              circles: {Circle(circleId: CircleId(a.id), center: a.location, radius: a.radiusM.toDouble(),
                fillColor: Colors.red.withValues(alpha: 0.15), strokeColor: Colors.red, strokeWidth: 2)},
              myLocationEnabled: false, zoomControlsEnabled: false, mapToolbarEnabled: false,
              scrollGesturesEnabled: false, zoomGesturesEnabled: false, rotateGesturesEnabled: false, tiltGesturesEnabled: false,
              liteModeEnabled: true,
              style: isDark ? _darkStyle : null,
            )),
          ),

          if (a.photoUrl != null) Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ClipRRect(borderRadius: BorderRadius.circular(16),
              child: Image.network(a.photoUrl!, height: 200, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink())),
          ),

          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title
            Text(a.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Info chips — MD3 style
            Wrap(spacing: 8, runSpacing: 8, children: [
              _infoChip(context, Icons.access_time, '${_fmt(timeAgo)} ${S.get('ago')}'),
              _infoChip(context, Icons.timer_outlined, '${S.get('expires_in')} ${_fmt(expiresIn)}'),
              if (a.distanceM != null) _infoChip(context, Icons.near_me, '${a.distanceM!.round()}m'),
              _infoChip(context, Icons.person_outline, a.authorUsername),
            ]),
            const SizedBox(height: 16),

            if (a.description != null) ...[
              Text(a.description!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
              const SizedBox(height: 16),
            ],

            // Credibility card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(S.get('credibility'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: confirmPct, minHeight: 10, backgroundColor: cs.errorContainer, color: Colors.green)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('✅ ${a.confirms} ${S.get('confirmations')}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('❌ ${a.denies} ${S.get('denials')}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              ])),
            ),
            const SizedBox(height: 12),

            // Vote buttons — MD3 FilledButton
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: () => _vote('confirm'),
                icon: const Icon(Icons.thumb_up),
                label: Text(S.get('confirm')),
                style: FilledButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              )),
              const SizedBox(width: 12),
              Expanded(child: FilledButton.icon(
                onPressed: () => _vote('deny'),
                icon: const Icon(Icons.thumb_down),
                label: Text(S.get('outdated')),
                style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError,
                  padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              )),
            ]),
            const SizedBox(height: 24),

            // Comments header
            Row(children: [
              const Icon(Icons.chat_bubble_outline, size: 18), const SizedBox(width: 6),
              Text('${S.get('comments')} (${_comments.length})', style: Theme.of(context).textTheme.titleSmall),
            ]),
            const SizedBox(height: 8),

            // Comments list — MD3 cards
            ..._comments.map((c) => _commentTile(context, c)),
            if (_comments.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(S.get('no_comments'), style: TextStyle(color: cs.onSurfaceVariant))),
          ])),
        ])),

        // Comment input — MD3 style
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 8, MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outlineVariant))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _commentCtrl,
              decoration: InputDecoration(
                hintText: S.get('add_comment'),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addComment(),
            )),
            const SizedBox(width: 8),
            _sending
              ? const SizedBox(width: 40, height: 40, child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton.filled(onPressed: _addComment, icon: const Icon(Icons.send, size: 20)),
          ]),
        ),
      ]),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant), const SizedBox(width: 4),
        Text(text, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      ]),
    );
  }

  Widget _commentTile(BuildContext context, Map<String, dynamic> c) {
    final cs = Theme.of(context).colorScheme;
    final author = c['author'] is Map ? c['author']['username'] ?? 'Anonim' : 'Anonim';
    final time = DateTime.tryParse(c['created_at'] ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 16, backgroundColor: cs.primaryContainer,
          child: Text(author[0].toUpperCase(), style: TextStyle(fontSize: 13, color: cs.onPrimaryContainer, fontWeight: FontWeight.bold))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            if (time != null) ...[const SizedBox(width: 8), Text(_fmt(DateTime.now().difference(time)), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))],
          ]),
          const SizedBox(height: 4),
          Text(c['content'] ?? '', style: const TextStyle(fontSize: 14)),
        ])),
      ])),
    );
  }

  String _fmt(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    return '${d.inMinutes}min';
  }

  void _vote(String type) async {
    try {
      await context.read<AlertProvider>().vote(widget.alert.id, type);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(type == 'confirm' ? 'Potwierdzono zagrożenie' : 'Oznaczono jako nieaktualne'))); Navigator.pop(context); }
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Już głosowałeś na ten alert'))); }
  }

  static const String _darkStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]}
  ]''';
}
