import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

/// Ekran odpowiedzi na sygnał ("Wyślij sygnał") od członka rodziny.
/// Otwierany przez tap w powiadomienie FCM type=family_ping.
class PingResponseScreen extends StatefulWidget {
  final String pingId;
  final String? fromUsername;
  final String? groupName;
  final String? sentAt;

  const PingResponseScreen({
    super.key,
    required this.pingId,
    this.fromUsername,
    this.groupName,
    this.sentAt,
  });

  factory PingResponseScreen.fromPayload(Map<String, dynamic> data) {
    return PingResponseScreen(
      pingId: data['ping_id']?.toString() ?? '',
      fromUsername: data['from_username']?.toString(),
      groupName: data['group_name']?.toString(),
      sentAt: data['sent_at']?.toString(),
    );
  }

  @override
  State<PingResponseScreen> createState() => _PingResponseScreenState();
}

class _PingResponseScreenState extends State<PingResponseScreen> {
  String? _fromUsername;
  String? _groupName;
  String? _sentAt;
  String? _responseStatus;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final TextEditingController _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fromUsername = widget.fromUsername;
    _groupName = widget.groupName;
    _sentAt = widget.sentAt;
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.pingId.isEmpty) {
      setState(() {
        _error = 'Brak ID sygnału';
        _loading = false;
      });
      return;
    }
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/family/pings/${widget.pingId}');
      if (!mounted) return;
      if (res['error'] != null) {
        setState(() {
          _error = res['error'].toString();
          _loading = false;
        });
        return;
      }
      setState(() {
        _fromUsername = res['from_username']?.toString() ?? _fromUsername;
        _groupName = res['group_name']?.toString() ?? _groupName;
        _sentAt = res['sent_at']?.toString() ?? _sentAt;
        _responseStatus = res['response_status']?.toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Nie udało się wczytać sygnału';
        _loading = false;
      });
    }
  }

  Future<void> _respond(String status) async {
    if (_submitting || _responseStatus != null) return;
    final isOk = status == 'ok';
    if (!isOk) {
      // dla not_ok pokaż dialog z opcjonalną notką
      final note = await _askNote();
      if (note == null) return; // anulowano
      _note.text = note;
    }
    setState(() => _submitting = true);
    HapticFeedback.mediumImpact();
    try {
      final api = context.read<ApiService>();
      final body = <String, dynamic>{'status': status};
      if (_note.text.trim().isNotEmpty) body['message'] = _note.text.trim();
      final res = await api.post('/family/pings/${widget.pingId}/respond', body);
      if (!mounted) return;
      if (res['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: ${res['error']}')),
        );
        setState(() => _submitting = false);
        return;
      }
      setState(() {
        _responseStatus = status;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isOk
            ? 'Wysłano: wszystko OK'
            : 'Wysłano prośbę o pomoc'),
        backgroundColor: isOk ? SerenityColors.glowSafeMint : SerenityColors.glowAlertCoral,
      ));
      // Wróć po krótkiej chwili
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context).pop(status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd sieci: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  Future<String?> _askNote() async {
    final ctrl = TextEditingController(text: _note.text);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Powiadom rodzinę'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Co się dzieje? (możesz zostawić puste)',
              style: TextStyle(color: SerenityColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 200,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'np. zgubiłem się, potrzebuję pomocy...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SerenityColors.glowAlertCoral,
            ),
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('Wyślij'),
          ),
        ],
      ),
    );
  }

  String _formatAge(String? raw) {
    if (raw == null) return '';
    try {
      final t = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(t);
      if (diff.inSeconds < 60) return 'przed chwilą';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min temu';
      if (diff.inHours < 24) return '${diff.inHours} h temu';
      return '${diff.inDays} d temu';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _fromUsername ?? 'Ktoś z rodziny';
    final groupTxt = _groupName != null ? 'grupa "$_groupName"' : 'rodzina';
    final age = _formatAge(_sentAt);

    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      appBar: AppBar(
        backgroundColor: SerenityColors.surfaceBright,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Zamknij',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Sygnał od rodziny'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          style: TextStyle(color: SerenityColors.glowAlertCoral)),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        _buildHero(name, groupTxt, age),
                        const Spacer(),
                        if (_responseStatus != null)
                          _buildAlreadyResponded()
                        else ...[
                          _buildActionButton(
                            label: 'WSZYSTKO OK',
                            sublabel: 'Jestem bezpieczny',
                            icon: Icons.check_circle_outline,
                            color: SerenityColors.glowSafeMint,
                            textColor: SerenityColors.primaryContainer,
                            onTap: () => _respond('ok'),
                          ),
                          const SizedBox(height: 16),
                          _buildActionButton(
                            label: 'POTRZEBUJĘ POMOCY',
                            sublabel: 'Wyślij notatkę',
                            icon: Icons.report_problem_outlined,
                            color: SerenityColors.glowAlertCoral,
                            textColor: Colors.white,
                            onTap: () => _respond('not_ok'),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHero(String name, String groupTxt, String age) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SerenityColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: SerenityColors.primaryContainer.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SerenityColors.glowAlertCoral.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.notifications_active,
                size: 40, color: SerenityColors.glowAlertCoral),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, height: 1.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'prosi o znak życia',
            style: TextStyle(
                fontSize: 15, color: SerenityColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              _chip(groupTxt, Icons.group_outlined),
              if (age.isNotEmpty) _chip(age, Icons.schedule),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SerenityColors.primaryContainer.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: SerenityColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: SerenityColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAlreadyResponded() {
    final isOk = _responseStatus == 'ok';
    final isExpired = _responseStatus == 'expired';
    final color = isOk
        ? SerenityColors.glowSafeMint
        : (isExpired ? SerenityColors.onSurfaceVariant : SerenityColors.glowAlertCoral);
    final label = isOk
        ? 'Odpowiedziałeś: Wszystko OK'
        : (isExpired ? 'Sygnał wygasł' : 'Odpowiedziałeś: Potrzebuję pomocy');
    final icon = isOk
        ? Icons.check_circle
        : (isExpired ? Icons.schedule : Icons.report);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: SerenityColors.primaryContainer,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String sublabel,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _submitting ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(sublabel,
                        style: TextStyle(
                            color: textColor.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (_submitting)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: textColor),
                )
              else
                Icon(Icons.chevron_right, color: textColor, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
