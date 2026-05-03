import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/i18n.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _radius = 500;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _radius = (context.read<AuthProvider>().user?.alertRadiusM ?? 500).toDouble();
  }

  Future<void> _saveRadius() async {
    setState(() => _saving = true);
    await context.read<ApiService>().patch('/users/me', {'alert_radius_m': _radius.round()});
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.get('saved'))));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: Text(S.get('profile'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        CircleAvatar(radius: 40, backgroundColor: Colors.red.shade100,
          child: Text(user?.username[0].toUpperCase() ?? '?', style: TextStyle(fontSize: 32, color: Colors.red.shade700))),
        const SizedBox(height: 12),
        Text(user?.username ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(user?.email ?? '', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text('${S.get('reputation')}: ${user?.reputationScore ?? 0}'),
        ]),
        const SizedBox(height: 32),
        Text(S.get('alert_radius'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text('Otrzymujesz powiadomienia o zagrożeniach w promieniu ${_radius.round()}m', style: TextStyle(color: Colors.grey.shade600)),
        Slider(
          value: _radius, min: 100, max: 5000, divisions: 49,
          label: '${_radius.round()}m',
          onChanged: (v) => setState(() => _radius = v),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('100m', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          Text('5km', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saving ? null : _saveRadius,
          child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(S.get('save_radius')),
        ),
        const SizedBox(height: 32),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.leaderboard),
          title: const Text('Ranking użytkowników'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/ranking'),
        ),
        ListTile(
          leading: const Icon(Icons.bar_chart),
          title: Text(S.get('stats')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/stats'),
        ),
        ListTile(
          leading: const Icon(Icons.share_location),
          title: Text(S.get('share_location')),
          subtitle: const Text('Wygeneruj tymczasowy link'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final res = await context.read<ApiService>().post('/users/me/share-location', {'hours': 1});
            if (res['url'] != null && mounted) {
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: Text(S.get('share_link')),
                content: SelectableText(res['url']),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
              ));
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: Text(S.get('my_alerts')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/my-alerts'),
        ),
        ListTile(
          leading: const Icon(Icons.family_restroom),
          title: Text(S.get('family_groups')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/family'),
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: Text(S.get('settings')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
        const Divider(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            await context.read<AuthProvider>().logout();
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          },
          icon: const Icon(Icons.logout, color: Colors.red),
          label: Text(S.get('logout'), style: const TextStyle(color: Colors.red)),
        ),
      ]),
    );
  }
}
