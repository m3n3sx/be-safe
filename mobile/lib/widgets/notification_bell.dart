// Dzwoneczek powiadomień z badge nieprzeczytanych. Otwiera centrum powiadomień.
// Reużywany w home_screen / home_kids_screen / home_senior_screen.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../screens/community/notifications_screen.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, this.color, this.size = 24});
  final Color? color;
  final double size;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final res = await context.read<ApiService>().get('/notifications/unread-count');
      if (!mounted) return;
      final c = (res['count'] as num?)?.toInt() ?? 0;
      setState(() => _unread = c);
    } catch (_) {}
  }

  Future<void> _open() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    // Po powrocie odśwież badge (NotificationsScreen oznacza jako przeczytane).
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, size: widget.size),
          color: widget.color,
          tooltip: 'Powiadomienia',
          onPressed: _open,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        if (_unread > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFCE2200),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                _unread > 99 ? '99+' : '$_unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
