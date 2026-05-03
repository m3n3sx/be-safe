import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          ? const Center(child: Text('Brak grup rodzinnych'))
          : ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (_, i) {
                final g = _groups[i];
                return ListTile(
                  leading: const Icon(Icons.family_restroom),
                  title: Text(g['name']),
                  subtitle: Text('Kod: ${g['invite_code']}'),
                  trailing: IconButton(
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
