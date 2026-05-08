import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alert.dart';
import '../../services/api_service.dart';
import '../../services/i18n.dart';
import '../../widgets/shimmer_loader.dart';
import 'alert_detail_screen.dart';

class MyAlertsScreen extends StatefulWidget {
  const MyAlertsScreen({super.key});
  @override State<MyAlertsScreen> createState() => _MyAlertsScreenState();
}

class _MyAlertsScreenState extends State<MyAlertsScreen> {
  List<AlertModel> _alerts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await context.read<ApiService>().get('/alerts/mine');
    if (res['alerts'] != null && mounted) {
      setState(() { _alerts = (res['alerts'] as List).map((a) => AlertModel.fromJson(a)).toList(); _loading = false; });
    } else { setState(() => _loading = false); }
  }

  Future<void> _extend(String id) async {
    await context.read<ApiService>().patch('/alerts/$id', {'extend_hours': 3});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Przedłużono o 3 godziny')));
    _load();
  }

  Future<void> _editDesc(String id, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edytuj opis'),
      content: TextField(controller: ctrl, maxLines: 3, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Zapisz')),
      ],
    ));
    if (result == null || !mounted) return;
    await context.read<ApiService>().patch('/alerts/$id', {'description': result});
    _load();
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(S.get('delete_alert')), content: Text(S.get('irreversible')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.get('cancel'))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: Text(S.get('delete')))],
    ));
    if (ok != true) return;
    await context.read<ApiService>().delete('/alerts/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.get('my_alerts'))),
      body: _loading ? ListView(children: const [
          SizedBox(height: 8),
          ShimmerListTile(),
          ShimmerListTile(),
          ShimmerListTile(),
          ShimmerListTile(),
          ShimmerListTile(),
        ])
        : _alerts.isEmpty ? Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(S.get('no_alerts'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Twoje zgłoszenia pojawią się tutaj',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/map'),
                icon: const Icon(Icons.warning_amber),
                label: const Text('Zgłoś zagrożenie'),
              ),
            ]),
          ))
        : RefreshIndicator(onRefresh: _load, child: ListView.builder(
          itemCount: _alerts.length,
          itemBuilder: (_, i) {
            final a = _alerts[i];
            final isActive = a.expiresAt.isAfter(DateTime.now());
            return ListTile(
              leading: Icon(a.category.iconData, color: isActive ? a.category.color : Colors.grey),
              title: Text(a.title, style: TextStyle(color: isActive ? null : Colors.grey)),
              subtitle: Text('${a.category.label} • ${isActive ? S.get('active') : S.get('expired')}'),
              trailing: PopupMenuButton(itemBuilder: (_) => [
                PopupMenuItem(value: 'view', child: Text(S.get('details'))),
                if (isActive) const PopupMenuItem(value: 'extend', child: Text('Przedłuż o 3h')),
                if (isActive) const PopupMenuItem(value: 'edit', child: Text('Edytuj opis')),
                PopupMenuItem(value: 'delete', child: Text(S.get('delete'), style: const TextStyle(color: Colors.red))),
              ], onSelected: (v) {
                if (v == 'view') Navigator.push(context, MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: a)));
                if (v == 'delete') _delete(a.id);
                if (v == 'extend') _extend(a.id);
                if (v == 'edit') _editDesc(a.id, a.description ?? '');
              }),
            );
          },
        )),
    );
  }
}
