import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});
  @override State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().get('/posts');
      if (mounted) setState(() {
        _posts = List<Map<String, dynamic>>.from(res['posts'] ?? []);
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktualności')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _posts.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.article_outlined, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Brak aktualności'),
            ]))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (_, i) {
                  final p = _posts[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showPost(p),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (p['category'] != null) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(p['category'], style: const TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(height: 8),
                          Text(p['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(p['content'] ?? '',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showPost(Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8, maxChildSize: 0.95, expand: false,
        builder: (_, controller) => ListView(
          controller: controller, padding: const EdgeInsets.all(24),
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(horizontal: 160),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(p['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(p['content'] ?? '', style: const TextStyle(fontSize: 15, height: 1.6)),
          ],
        ),
      ),
    );
  }
}
