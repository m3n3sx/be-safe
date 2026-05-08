import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyNumbersScreen extends StatelessWidget {
  const EmergencyNumbersScreen({super.key});

  static const _numbers = [
    _Emergency('112', 'Europejski numer alarmowy', Icons.emergency, Colors.red, 'Uniwersalny — policja, straż, pogotowie'),
    _Emergency('997', 'Policja', Icons.local_police, Color(0xFF1565C0), 'Kradzieże, wypadki, zagrożenia'),
    _Emergency('998', 'Straż Pożarna', Icons.local_fire_department, Color(0xFFE65100), 'Pożary, wypadki, ratownictwo'),
    _Emergency('999', 'Pogotowie ratunkowe', Icons.medical_services, Color(0xFFD32F2F), 'Sytuacje zagrażające życiu'),
    _Emergency('986', 'Straż Miejska', Icons.security, Color(0xFF388E3C), 'Porządek publiczny'),
    _Emergency('987', 'Centrum Zarządzania Kryzysowego', Icons.crisis_alert, Color(0xFF7B1FA2), 'Kryzysy, katastrofy'),
    _Emergency('601100100', 'GOPR/TOPR — Góry', Icons.terrain, Color(0xFF00796B), 'Ratownictwo górskie'),
    _Emergency('601100300', 'WOPR — Woda', Icons.water, Color(0xFF0277BD), 'Ratownictwo wodne'),
    _Emergency('116111', 'Telefon zaufania dla dzieci', Icons.child_care, Color(0xFFE91E63), 'Pomoc psychologiczna (bezpłatny)'),
    _Emergency('116123', 'Kryzysowy telefon zaufania', Icons.support_agent, Color(0xFF5E35B1), 'Pomoc w kryzysie emocjonalnym'),
  ];

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Numery alarmowe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.red.shade700),
              const SizedBox(width: 12),
              const Expanded(child: Text(
                'W sytuacji bezpośredniego zagrożenia życia ZAWSZE dzwoń pod 112. Aplikacja nie zastępuje służb ratunkowych.',
                style: TextStyle(fontSize: 13),
              )),
            ]),
          ),
          ..._numbers.map((n) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: n.color.withValues(alpha: 0.15),
                child: Icon(n.icon, color: n.color)),
              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(n.desc),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: n.color, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.phone, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(n.number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
              ),
              onTap: () => _call(n.number),
            ),
          )),
        ],
      ),
    );
  }
}

class _Emergency {
  final String number, title, desc;
  final IconData icon;
  final Color color;
  const _Emergency(this.number, this.title, this.icon, this.color, this.desc);
}
