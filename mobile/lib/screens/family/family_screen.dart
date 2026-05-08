import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';
import '../../services/i18n.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});
  @override State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<dynamic> _groups = [];

  @override
  void initState() { super.initState(); _loadGroups(); }

  Future<void> _loadGroups() async {
    final res = await context.read<ApiService>().get('/family/groups');
    if (res['groups'] != null) setState(() => _groups = res['groups']);
  }

  Future<void> _createGroup() async {
    final name = await _showInputDialog('Nazwa grupy rodzinnej');
    if (name == null || name.isEmpty) return;
    final res = await context.read<ApiService>().post('/family/groups', {'name': name});
    if (res['invite_code'] != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kod zaproszenia: ${res['invite_code']}')));
    }
    _loadGroups();
  }

  Future<void> _joinGroup() async {
    final code = await _showInputDialog('Kod zaproszenia');
    if (code == null || code.isEmpty) return;
    await context.read<ApiService>().post('/family/groups/join', {'invite_code': code});
    _loadGroups();
  }

  void _showQr(String name, String code) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(name),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Zeskanuj QR albo wpisz kod', style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: QrImageView(data: 'besafe://family/join/$code', size: 200, backgroundColor: Colors.white),
        ),
        const SizedBox(height: 12),
        SelectableText(code, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Zamknij'))],
    ));
  }

  Future<String?> _showInputDialog(String label) => showDialog<String>(
    context: context,
    builder: (ctx) {
      final c = TextEditingController();
      return AlertDialog(
        title: Text(label),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('OK')),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.get('family'))),
      body: _groups.isEmpty
          ? Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.family_restroom, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('Brak grup rodzinnych', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Utwórz grupę i zaproś bliskich — zobaczysz ich lokalizację i dostaniesz alerty gdy opuszczą bezpieczną strefę',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  OutlinedButton.icon(onPressed: _joinGroup, icon: const Icon(Icons.link), label: const Text('Dołącz kodem')),
                  const SizedBox(width: 12),
                  FilledButton.icon(onPressed: _createGroup, icon: const Icon(Icons.add), label: const Text('Utwórz grupę')),
                ]),
              ]),
            ))
          : ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (_, i) {
                final g = _groups[i];
                return ListTile(
                  leading: const Icon(Icons.family_restroom),
                  title: Text(g['name']),
                  subtitle: Text('Kod: ${g['invite_code']}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code),
                      tooltip: 'Pokaż QR',
                      onPressed: () => _showQr(g['name'], g['invite_code']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                        title: const Text('Usuń grupę?'),
                        content: Text('Grupa "${g['name']}" zostanie usunięta.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Usuń')),
                        ],
                      ));
                      if (ok == true) { await context.read<ApiService>().delete('/family/groups/${g['id']}'); _loadGroups(); }
                    },
                  ),
                  ]),
                  onTap: () => Navigator.pushNamed(context, '/family/${g['id']}'),
                );
              },
            ),
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton.small(heroTag: 'join', onPressed: _joinGroup, child: const Icon(Icons.link)),
        const SizedBox(height: 8),
        FloatingActionButton(heroTag: 'create', onPressed: _createGroup, child: const Icon(Icons.add)),
      ]),
    );
  }
}
