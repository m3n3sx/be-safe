import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});
  @override State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<dynamic> _ranking = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await context.read<ApiService>().get('/users/ranking');
    if (res['ranking'] != null && mounted) setState(() { _ranking = res['ranking']; _loading = false; });
    else setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking użytkowników')),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _ranking.isEmpty ? const Center(child: Text('Brak danych'))
        : ListView.builder(
          itemCount: _ranking.length,
          itemBuilder: (_, i) {
            final u = _ranking[i];
            final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}.';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: i < 3 ? Colors.amber.shade100 : Colors.grey.shade200,
                child: Text(medal, style: TextStyle(fontSize: i < 3 ? 20 : 14)),
              ),
              title: Text(u['username'] ?? 'Anonim', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${u['alert_count']} zgłoszeń • ${u['total_confirms']} potwierdzeń'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 2),
                Text('${u['reputation_score']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            );
          },
        ),
    );
  }
}
