// F14 Geofence chat sąsiedzki (Nextdoor-style).
// Wiadomości w promieniu (domyślnie 2 km) wokół aktualnej lokalizacji.
// Socket 'neighborhood:message' + polling 15s. Wysyła lat/lng do backendu.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/socket_service.dart';
import '../../theme/design_tokens.dart';

class NeighborhoodChatScreen extends StatefulWidget {
  const NeighborhoodChatScreen({super.key});

  @override
  State<NeighborhoodChatScreen> createState() => _NeighborhoodChatScreenState();
}

class _NeighborhoodChatScreenState extends State<NeighborhoodChatScreen> {
  static const _radiusM = 2000.0;
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _messages = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _sending = false;
  double? _lat, _lng;
  Timer? _poll;
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _load(silent: true));
    _bindSocket();
  }

  Future<void> _init() async {
    final pos = await LocationService().getCurrentPosition();
    if (pos != null) {
      _lat = pos.latitude;
      _lng = pos.longitude;
    }
    await _load();
  }

  void _bindSocket() {
    final sock = context.read<SocketService>();
    _socketSub = sock.onNeighborhoodMessage.listen((m) {
      if (!mounted || _lat == null) return;
      // Filtr po dystansie — pokaż tylko wiadomości w promieniu.
      final d = _distanceM(m['lat'], m['lng']);
      if (d == null || d > _radiusM) return;
      if (_messages.any((x) => x['id'] == m['id'])) return;
      setState(() => _messages.add(m));
      _scrollToBottom();
    });
  }

  double? _distanceM(dynamic lat, dynamic lng) {
    if (lat is! num || lng is! num || _lat == null || _lng == null) return null;
    // Przybliżenie (equirectangular) — wystarczające dla filtra promienia.
    const r = 6371000.0;
    final dLat = (lat - _lat!) * 3.141592653589793 / 180;
    final dLng = (lng - _lng!) * 3.141592653589793 / 180;
    final x = dLng * (1 - dLat * dLat / 2); // tani cos
    return r * (dLat.abs() + x.abs());
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final params = <String, String>{'radius_m': _radiusM.toInt().toString(), 'limit': '100'};
      if (_lat != null) {
        params['lat'] = _lat.toString();
        params['lng'] = _lng.toString();
      }
      final res = await api.get('/neighborhood/messages', params);
      if (!mounted) return;
      final list = (res['messages'] as List? ?? []).cast<Map<String, dynamic>>();
      setState(() {
        _messages..clear()..addAll(list);
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    HapticFeedback.selectionClick();
    try {
      final api = context.read<ApiService>();
      final res = await api.post('/neighborhood/messages', {
        'body': text,
        if (_lat != null) 'lat': _lat,
        if (_lng != null) 'lng': _lng,
      });
      if (!mounted) return;
      if (res['error'] != null) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res['error'].toString())));
        return;
      }
      setState(() {
        _messages.add(Map<String, dynamic>.from(res));
        _input.clear();
        _sending = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _socketSub?.cancel();
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().user?.id;
    return Scaffold(
      backgroundColor: context.iosBackground,
      appBar: AppBar(
        backgroundColor: context.iosCardSurface,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Wróć',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sąsiedzi',
                style: SerenityText.bodyMain.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.iosLabel,
                )),
            Text('W promieniu 2 km',
                style: SerenityText.labelCaps.copyWith(
                  color: context.iosSecondaryLabel,
                )),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Odśwież',
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _lat == null
                    ? _buildNoLocation()
                    : _messages.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount: _messages.length,
                            itemBuilder: (ctx, i) {
                              final m = _messages[i];
                              return _buildBubble(m, m['author_id'] == myId);
                            },
                          ),
          ),
          if (_lat != null) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildNoLocation() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off,
                  size: 64,
                  color: context.iosSecondaryLabel.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text('Brak lokalizacji',
                  style: SerenityText.headlineHeroMobile
                      .copyWith(color: context.iosSecondaryLabel)),
              const SizedBox(height: 8),
              Text('Udostępnij lokalizację, aby zobaczyć czat sąsiedzki.',
                  textAlign: TextAlign.center,
                  style: SerenityText.bodyMain
                      .copyWith(color: context.iosSecondaryLabel)),
              const SizedBox(height: 16),
              TextButton(onPressed: _init, child: const Text('Spróbuj ponownie')),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined,
                size: 64,
                color: context.iosSecondaryLabel.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Cisza w okolicy',
                style: SerenityText.headlineHeroMobile
                    .copyWith(color: context.iosSecondaryLabel)),
            const SizedBox(height: 8),
            Text('Napisz pierwszą wiadomość do sąsiadów',
                style: SerenityText.bodyMain
                    .copyWith(color: context.iosSecondaryLabel)),
          ],
        ),
      );

  Widget _buildBubble(Map<String, dynamic> m, bool mine) {
    final time = DateTime.tryParse(m['created_at'] ?? '');
    final timeLabel = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: SerenityColors.secondaryContainer,
              backgroundImage: (m['author_avatar'] != null &&
                      (m['author_avatar'] as String).isNotEmpty)
                  ? NetworkImage(m['author_avatar'])
                  : null,
              child: (m['author_avatar'] == null ||
                      (m['author_avatar'] as String).isEmpty)
                  ? Text(
                      ((m['author_username'] ?? '?') as String)
                          .characters
                          .first
                          .toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12))
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine
                    ? SerenityColors.primaryContainer
                    : context.iosCardSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!mine)
                    Text(m['author_username'] ?? '',
                        style: SerenityText.labelCaps.copyWith(
                            color: SerenityColors.onSecondaryContainer,
                            fontSize: 10)),
                  if (!mine) const SizedBox(height: 2),
                  Text(m['body'] ?? '',
                      style: TextStyle(
                          color: mine ? Colors.white : SerenityColors.primary,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(timeLabel,
                      style: TextStyle(
                          color:
                              (mine ? Colors.white : SerenityColors.onSurfaceVariant)
                                  .withValues(alpha: 0.65),
                          fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
      decoration: BoxDecoration(
        color: context.iosCardSurface,
        border: Border(top: BorderSide(color: context.iosSeparator)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 5,
                maxLength: 1000,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Napisz do sąsiadów…',
                  counterText: '',
                  filled: true,
                  fillColor: SerenityColors.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: SerenityColors.primaryContainer,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sending ? null : _send,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
