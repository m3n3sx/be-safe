// Centrum powiadomień — inbox użytkownika.
// Lista wszystkich powiadomień z backendu (/notifications), swipe-to-delete,
// "Wyczyść wszystko", pull-refresh, ikona per typ, tap → routing wg data.type.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/fcm_service.dart' show appNavigatorKey;
import '../../theme/design_tokens.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/notifications', {'limit': '100'});
      if (!mounted) return;
      setState(() {
        _items = (res['notifications'] as List? ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
      // Oznacz wszystkie jako przeczytane (best-effort) — zeruje badge.
      api.post('/notifications/read', {}).catchError((_) => <String, dynamic>{});
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteOne(String id) async {
    setState(() => _items.removeWhere((n) => n['id'] == id));
    await context.read<ApiService>().delete('/notifications/$id');
  }

  Future<void> _clearAll() async {
    final api = context.read<ApiService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wyczyścić wszystkie?'),
        content: const Text('Usuniesz wszystkie powiadomienia. Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Wyczyść', style: TextStyle(color: SerenityColors.glowAlertCoral)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _items = []);
    await api.delete('/notifications');
  }

  // Ikona + kolor wg typu powiadomienia.
  (IconData, Color) _visual(String type) {
    switch (type) {
      case 'new_alert':
      case 'child_in_alert_area':
      case 'family_alert_near_child':
        return (Icons.warning_amber_rounded, const Color(0xFFCE2200));
      case 'family_sos':
        return (Icons.sos, const Color(0xFFCE2200));
      case 'family_ping':
      case 'ping_response':
        return (Icons.notifications_active, const Color(0xFF2979FF));
      case 'family_message':
        return (Icons.chat_bubble_outline, SerenityColors.primary);
      case 'geofence_exit':
      case 'geofence_enter':
      case 'route_exit':
      case 'route_return':
        return (Icons.location_on_outlined, const Color(0xFFEB6A00));
      case 'escort_invite':
      case 'escort_panic':
      case 'escort_completed':
        return (Icons.directions_walk, const Color(0xFF7DD3AC));
      case 'family_event_reminder':
        return (Icons.event_outlined, const Color(0xFF2979FF));
      case 'pet_lost':
      case 'pet_lost_nearby':
      case 'pet_found':
      case 'pet_sighting':
        return (Icons.pets, const Color(0xFFEB6A00));
      case 'child_low_battery':
        return (Icons.battery_alert, const Color(0xFFEB6A00));
      case 'kpp_responder_call':
        return (Icons.medical_services_outlined, const Color(0xFFCE2200));
      case 'checkin_reminder':
      case 'checkin_missing':
        return (Icons.check_circle_outline, const Color(0xFF7DD3AC));
      default:
        return (Icons.notifications_outlined, SerenityColors.onSurfaceVariant);
    }
  }

  // Routing po tapnięciu — zgodnie z mapą tras FCM.
  void _open(Map<String, dynamic> n) {
    final data = (n['data'] as Map?)?.cast<String, dynamic>() ?? {};
    final type = (n['type'] ?? '').toString();
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    String route;
    switch (type) {
      case 'new_alert':
      case 'child_in_alert_area':
      case 'family_alert_near_child':
      case 'kpp_responder_call':
        route = '/alert-detail';
        break;
      case 'family_sos':
        route = '/family-sos';
        break;
      case 'family_ping':
        route = '/ping-response';
        break;
      case 'escort_invite':
      case 'escort_panic':
      case 'escort_completed':
        route = '/escort';
        break;
      case 'checkin_reminder':
        route = '/home';
        break;
      default:
        route = '/family';
    }
    nav.pushNamed(route, arguments: data);
  }

  String _relativeTime(String? iso) {
    if (iso == null) return '';
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'teraz';
    if (d.inHours < 1) return '${d.inMinutes} min temu';
    if (d.inDays < 1) return '${d.inHours} godz temu';
    if (d.inDays < 7) return '${d.inDays} dni temu';
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.surface,
      appBar: AppBar(
        backgroundColor: SerenityColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Wróć',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Powiadomienia',
            style: SerenityText.bodyMain.copyWith(
              fontWeight: FontWeight.w600, color: SerenityColors.primary)),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Wyczyść', style: TextStyle(color: SerenityColors.glowAlertCoral)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: SerenityColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: SerenityColors.outlineVariant.withValues(alpha: 0.5)),
                    itemBuilder: (_, i) => _buildTile(_items[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => ListView(
        // ListView (nie Center) żeby pull-refresh działał na pustym stanie.
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.28),
          Icon(Icons.notifications_none,
              size: 64, color: SerenityColors.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Center(
            child: Text('Brak powiadomień',
                style: SerenityText.headlineHeroMobile.copyWith(
                    color: SerenityColors.onSurfaceVariant)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Tu pojawią się alerty, sygnały rodziny i przypomnienia.',
                textAlign: TextAlign.center,
                style: SerenityText.bodyMain.copyWith(color: SerenityColors.onSurfaceVariant)),
          ),
        ],
      );

  Widget _buildTile(Map<String, dynamic> n) {
    final id = n['id'].toString();
    final (icon, color) = _visual((n['type'] ?? '').toString());
    final isRead = n['is_read'] == true;
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteOne(id),
      background: Container(
        alignment: Alignment.centerRight,
        color: SerenityColors.glowAlertCoral.withValues(alpha: 0.15),
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: SerenityColors.glowAlertCoral),
      ),
      child: ListTile(
        onTap: () => _open(n),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          (n['title'] ?? '').toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
            color: SerenityColors.primary,
          ),
        ),
        subtitle: n['body'] != null && (n['body'] as String).isNotEmpty
            ? Text((n['body']).toString(), maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: Text(
          _relativeTime(n['created_at']?.toString()),
          style: SerenityText.labelCaps.copyWith(
              color: SerenityColors.onSurfaceVariant, fontSize: 11),
        ),
      ),
    );
  }
}
