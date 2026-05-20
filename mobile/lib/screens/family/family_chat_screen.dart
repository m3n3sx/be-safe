// F14 Family chat — proste wiadomości w obrębie grupy rodzinnej.
//
// Polling co 10s + Socket.io 'family:message' nasłuch dla real-time.
// FCM push z type='family_message' (już obsłużone w fcm_service.dart).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../theme/design_tokens.dart';

class FamilyChatScreen extends StatefulWidget {
  const FamilyChatScreen({super.key, required this.groupId, required this.groupName});

  final String groupId;
  final String groupName;

  @override
  State<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _messages = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
    _bindSocket();
  }

  void _bindSocket() {
    final sock = context.read<SocketService>();
    _socketSub = sock.onFamilyMessage.listen((m) {
      if (m['group_id'] != widget.groupId) return;
      if (!mounted) return;
      setState(() {
        if (_messages.any((x) => x['id'] == m['id'])) return;
        _messages.add(m);
      });
      _scrollToBottom();
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/family/groups/${widget.groupId}/messages?limit=100');
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
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    HapticFeedback.selectionClick();
    try {
      final api = context.read<ApiService>();
      final res = await api.post('/family/groups/${widget.groupId}/messages', {'body': text});
      if (!mounted) return;
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
      backgroundColor: SerenityColors.surface,
      appBar: AppBar(
        backgroundColor: SerenityColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Wróć',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName,
                style: SerenityText.bodyMain.copyWith(
                  fontWeight: FontWeight.w600,
                  color: SerenityColors.primary,
                )),
            Text('Czat rodzinny',
                style: SerenityText.labelCaps.copyWith(
                  color: SerenityColors.onSurfaceVariant,
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
                : _messages.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final m = _messages[i];
                          final mine = m['author_id'] == myId;
                          return _buildBubble(m, mine);
                        },
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: SerenityColors.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Brak wiadomości',
                style: SerenityText.headlineHeroMobile.copyWith(
                  color: SerenityColors.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            Text('Napisz pierwszą wiadomość do rodziny',
                style: SerenityText.bodyMain.copyWith(
                  color: SerenityColors.onSurfaceVariant,
                )),
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
              backgroundImage: (m['author_avatar'] != null && (m['author_avatar'] as String).isNotEmpty)
                  ? NetworkImage(m['author_avatar'])
                  : null,
              child: (m['author_avatar'] == null || (m['author_avatar'] as String).isEmpty)
                  ? Text(((m['author_username'] ?? '?') as String).characters.first.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine
                    ? SerenityColors.primaryContainer
                    : SerenityColors.surfaceContainerLowest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: SerenityColors.primaryContainer.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!mine)
                    Text(m['author_username'] ?? '',
                        style: SerenityText.labelCaps.copyWith(
                          color: SerenityColors.onSecondaryContainer,
                          fontSize: 10,
                        )),
                  if (!mine) const SizedBox(height: 2),
                  Text(m['body'] ?? '',
                      style: TextStyle(
                        color: mine ? Colors.white : SerenityColors.primary,
                        fontSize: 15,
                      )),
                  const SizedBox(height: 4),
                  Text(timeLabel,
                      style: TextStyle(
                        color: (mine ? Colors.white : SerenityColors.onSurfaceVariant)
                            .withValues(alpha: 0.65),
                        fontSize: 10,
                      )),
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
        color: SerenityColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: SerenityColors.outlineVariant)),
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
                maxLength: 2000,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Napisz wiadomość…',
                  counterText: '',
                  filled: true,
                  fillColor: SerenityColors.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
