// F19 Family planner: lista wydarzeń + dodawanie.
// Backend: GET/POST/PATCH/DELETE /family/groups/:id/events
// Cron przypomnień wyzwala FCM type='family_event_reminder' (X min przed startem).

import 'package:flutter/material.dart';
import '../../theme/ios_surfaces.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class FamilyPlannerScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const FamilyPlannerScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<FamilyPlannerScreen> createState() => _FamilyPlannerScreenState();
}

class _FamilyPlannerScreenState extends State<FamilyPlannerScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/family/groups/${widget.groupId}/events?upcoming=1');
      if (!mounted) return;
      final list = (res['events'] as List?) ?? const [];
      setState(() {
        _events = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Nie udało się załadować wydarzeń';
        _loading = false;
      });
    }
  }

  Future<void> _addEvent() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEventSheet(groupId: widget.groupId),
    );
    if (result == true) _load();
  }

  Future<void> _deleteEvent(Map<String, dynamic> e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usunąć wydarzenie?'),
        content: Text(e['title'] ?? ''),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: SerenityColors.error),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = context.read<ApiService>();
      await api.delete('/family/groups/${widget.groupId}/events/${e['id']}');
      if (mounted) _load();
    } catch (_) {}
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$dd.$mm  $hh:$mi';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.iosBackground,
      appBar: AppBar(
        backgroundColor: context.iosBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Wróć',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName,
                style: const TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
            const Text('Planner rodzinny',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Odśwież', onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SerenityColors.primaryContainer,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nowe wydarzenie'),
        onPressed: _addEvent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: SerenityColors.error)),
                      TextButton(onPressed: _load, child: const Text('Spróbuj ponownie')),
                    ],
                  ),
                )
              : _events.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_outlined, size: 64, color: context.iosSeparator),
                            const SizedBox(height: 12),
                            const Text(
                              'Brak nadchodzących wydarzeń',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Dodaj wspólny obiad, urodziny lub wizytę u lekarza —\nwszyscy w rodzinie dostaną przypomnienie.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.iosSecondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: _events.length,
                        itemBuilder: (_, i) => _eventTile(_events[i]),
                      ),
                    ),
    );
  }

  Widget _eventTile(Map<String, dynamic> e) {
    final author = e['author_username'] as String? ?? '?';
    final location = e['location'] as String?;
    final reminder = (e['reminder_minutes_before'] as num?)?.toInt() ?? 30;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.iosCardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SerenityColors.primaryContainer.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SerenityColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_note,
                    color: SerenityColors.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['title'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.iosLabel,
                      ),
                    ),
                    Text(
                      _formatDate(e['starts_at'] ?? ''),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.iosSecondaryLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Usuń',
                onPressed: () => _deleteEvent(e),
              ),
            ],
          ),
          if (e['description'] is String && (e['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              e['description'] as String,
              style: TextStyle(
                fontSize: 13,
                color: context.iosSecondaryLabel,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (location != null && location.isNotEmpty)
                _chip(Icons.location_on_outlined, location),
              _chip(Icons.alarm, 'Przypomnienie ${reminder} min'),
              _chip(Icons.person_outline, author),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SerenityColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.iosSecondaryLabel),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.iosSecondaryLabel)),
        ],
      ),
    );
  }
}

class _AddEventSheet extends StatefulWidget {
  final String groupId;
  const _AddEventSheet({required this.groupId});

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  DateTime _when = DateTime.now().add(const Duration(hours: 1));
  int _reminder = 30;
  bool _saving = false;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(hours: 6)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (time == null) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wpisz tytuł wydarzenia')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final api = context.read<ApiService>();
      await api.post('/family/groups/${widget.groupId}/events', {
        'title': title,
        'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        'starts_at': _when.toUtc().toIso8601String(),
        'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
        'reminder_minutes_before': _reminder,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać: $e')),
      );
    }
  }

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}  $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.iosBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: SerenityColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Nowe wydarzenie rodzinne',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Tytuł',
                hintText: 'np. Urodziny taty, wizyta u lekarza',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(
                labelText: 'Opis (opcjonalnie)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              maxLength: 500,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Miejsce (opcjonalnie)',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text('Termin: ${_fmt(_when)}'),
              onPressed: _pickDateTime,
            ),
            const SizedBox(height: 12),
            Text('Przypomnienie: $_reminder min wcześniej',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Slider(
              min: 0, max: 240, divisions: 12, value: _reminder.toDouble(),
              label: '$_reminder min',
              onChanged: (v) => setState(() => _reminder = v.round()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: SerenityColors.primaryContainer,
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Zapisz', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
