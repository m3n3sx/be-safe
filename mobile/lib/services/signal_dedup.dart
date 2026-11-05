class SignalDedup {
  final Set<String> seen = {};

  bool present(Map event) {
    final keys = <String>[];
    void add(dynamic value) {
      if (value == null) return;
      final text = value.toString();
      if (text.isNotEmpty) keys.add(text);
    }

    final data = event['data'] is Map ? Map<String, dynamic>.from(event['data'] as Map) : event;
    add(event['id']);
    add(event['ping_id']);
    add(data['ping_id']);
    add(data['notification_id']);
    final type = event['type']?.toString();
    final alertId = event['alert_id'] ?? data['alert_id'];
    if (type == 'family_sos' && alertId != null) add('sos:$alertId');
    if (keys.any(seen.contains)) {
      seen.addAll(keys);
      return false;
    }
    seen.addAll(keys);
    return keys.isNotEmpty;
  }
}

bool shouldShowSosLatch({
  required bool acknowledged,
  required String alertStatus,
  required DateTime? expiresAt,
  required DateTime now,
  required bool shownThisProcess,
}) {
  if (acknowledged) return false;
  if (alertStatus != 'active') return false;
  if (expiresAt != null && !expiresAt.isAfter(now)) return false;
  if (shownThisProcess) return false;
  return true;
}
