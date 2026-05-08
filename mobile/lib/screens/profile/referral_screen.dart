import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});
  @override State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String? _code;
  int _referrals = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await context.read<ApiService>().get('/users/me');
      if (mounted) setState(() {
        _code = res['referral_code'];
        _referrals = res['referrals_count'] ?? 0;
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final code = _code ?? '...';
    final shareUrl = 'https://alert.u235.pl?ref=$code';
    final shareText = 'Dołącz do be:Safe — aplikacji bezpieczeństwa społeczności! Użyj mojego kodu polecającego: $code\n\n$shareUrl';

    return Scaffold(
      appBar: AppBar(title: const Text('Zaproś znajomych')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Icon(Icons.card_giftcard, size: 80, color: cs.primary),
              const SizedBox(height: 16),
              const Text('Twój kod polecający', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kod skopiowany!')));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary, width: 2),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(code, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: cs.onPrimaryContainer)),
                    const SizedBox(width: 12),
                    Icon(Icons.copy, color: cs.onPrimaryContainer),
                  ]),
                ),
              ),
              const SizedBox(height: 24),

              // QR code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: shareUrl, size: 200, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 24),

              // Stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    Column(children: [
                      Text('$_referrals', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const Text('Poleconych', style: TextStyle(color: Colors.grey)),
                    ]),
                    Column(children: [
                      Text('${_referrals * 10}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const Text('Punktów', style: TextStyle(color: Colors.grey)),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: () => Share.share(shareText),
                icon: const Icon(Icons.share),
                label: const Text('Udostępnij'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              )),

              const SizedBox(height: 16),
              Text('Polecaj be:Safe znajomym i rodzinie — razem tworzymy bezpieczniejsze miasto',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ]),
          ),
    );
  }
}
