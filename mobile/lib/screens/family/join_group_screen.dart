import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../family/invite_link.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});
  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _code = TextEditingController();
  String? _groupName;
  String? _error;
  bool _busy = false;
  bool _scanning = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    final parsed = parseInvite(_code.text);
    setState(() {
      _error = null;
      _groupName = null;
    });
    if (parsed == null) {
      setState(() => _error = 'Kod jest nieprawidłowy lub wygasł');
      return;
    }
    setState(() => _busy = true);
    final res = await context.read<ApiService>().post('/family/groups/join/preview', {'invite_code': parsed});
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['error'] != null || res['group_name'] == null) {
      setState(() => _error = res['error']?.toString() ?? 'Kod jest nieprawidłowy lub wygasł');
      return;
    }
    setState(() => _groupName = res['group_name'].toString());
  }

  Future<void> _join() async {
    final parsed = parseInvite(_code.text);
    if (parsed == null || _groupName == null) return;
    final role = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in const {
              'family_member': 'Członek rodziny',
              'child': 'Dziecko',
              'senior': 'Senior',
              'partner': 'Partner',
              'friend': 'Znajomy',
              'other': 'Inna osoba',
            }.entries)
              ListTile(title: Text(entry.value), onTap: () => Navigator.pop(ctx, entry.key)),
          ],
        ),
      ),
    );
    if (role == null || !mounted || !canSelfJoinAs(role)) return;
    setState(() => _busy = true);
    final res = await context.read<ApiService>().post('/family/groups/join', {
      'invite_code': parsed,
      'role': role,
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (res['error'] != null) {
      setState(() => _error = res['error'].toString());
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dołącz do grupy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Zeskanuj kod QR albo wpisz kod. Dołączenie wymaga potwierdzenia. Roli rodzica nie wybierzesz samodzielnie.'),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Kod lub link'),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _preview, child: const Text('Sprawdź kod')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => setState(() => _scanning = !_scanning), child: Text(_scanning ? 'Zamknij skaner' : 'Skanuj aparatem')),
          if (_scanning)
            SizedBox(
              height: 280,
              child: MobileScanner(
                onDetect: (capture) {
                  final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
                  final parsed = parseInvite(raw);
                  if (parsed == null) return;
                  _code.text = parsed;
                  setState(() => _scanning = false);
                  _preview();
                },
                errorBuilder: (context, error) {
                  final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        denied
                            ? 'Brak zgody na aparat. Wpisz kod albo link poniżej.'
                            : 'Nie udało się otworzyć aparatu. Wpisz kod albo link poniżej.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: SerenityColors.error))),
          if (_groupName != null) ...[
            const SizedBox(height: 16),
            Text(_groupName!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const Text('Dołączysz dopiero po potwierdzeniu.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: _busy ? null : _join, child: Text('Dołącz do $_groupName')),
          ],
        ],
      ),
    );
  }
}
