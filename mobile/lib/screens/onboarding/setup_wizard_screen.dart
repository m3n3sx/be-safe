import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:shared_preferences/shared_preferences.dart';
import '../family/add_geofence_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mode_provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../services/api_service.dart';
import '../../models/user.dart' show AppMode, AppModeX;
import '../../theme/design_tokens.dart';
import '../../theme/ios_surfaces.dart';

/// Konfigurator be:Safe — kreator krok po kroku z opcją pominięcia.
///
/// Uruchamiany raz po pierwszym zalogowaniu (flaga `setup_done`) oraz ręcznie
/// z Ustawień. Każdy krok można pominąć, cały konfigurator też.
class SetupWizardScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SetupWizardScreen({super.key, required this.onDone});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _step = 0;
  static const _total = 9; // 0..8

  // stan kroków
  int _radius = 1500;
  final _groupCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _familyBusy = false;
  String? _familyMsg;

  // uprawnienia systemowe
  static const _permList = <(Permission, String, String)>[
    (Permission.locationWhenInUse, 'Lokalizacja', 'Alerty i mapa wokół Ciebie'),
    (Permission.notification, 'Powiadomienia', 'Ostrzeżenia o zagrożeniach'),
    (Permission.microphone, 'Mikrofon', 'Nagranie audio przy alarmie SOS'),
    (Permission.camera, 'Aparat', 'Zdjęcia do zgłoszeń zagrożeń'),
    (Permission.contacts, 'Kontakty', 'Fałszywy telefon i zaufane kontakty'),
  ];
  final Map<Permission, bool> _perms = {};

  // preferencje powiadomień (jak w Ustawieniach)
  bool _notifAlerts = true;
  bool _notifFamily = true;
  bool _notifSound = true;
  bool _notifVibration = true;

  // rodzina / strefy
  List<dynamic> _groups = [];

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    if (u != null) _radius = u.alertRadiusM.clamp(300, 10000);
    _refreshPerms();
    _loadNotifPrefs();
    _loadGroups();
  }

  Future<void> _loadNotifPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifAlerts = p.getBool('notif_alerts') ?? true;
      _notifFamily = p.getBool('notif_family') ?? true;
      _notifSound = p.getBool('notif_sound') ?? true;
      _notifVibration = p.getBool('notif_vibration') ?? true;
    });
  }

  Future<void> _saveNotif(String key, bool v) async =>
      (await SharedPreferences.getInstance()).setBool(key, v);

  Future<void> _loadGroups() async {
    try {
      final res = await context.read<ApiService>().get('/family/groups');
      final g = (res is Map ? res['groups'] : null) as List? ?? [];
      if (mounted) setState(() => _groups = g);
    } catch (_) {}
  }

  @override
  void dispose() {
    _groupCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshPerms() async {
    for (final p in _permList) {
      _perms[p.$1] = (await p.$1.status).isGranted;
    }
    if (mounted) setState(() {});
  }

  Future<void> _finish() async {
    // zapis promienia (jeśli zalogowany)
    try {
      await context.read<ApiService>().put('/users/me', {'alert_radius_m': _radius});
    } catch (_) {}
    widget.onDone();
  }

  void _next() {
    if (_step >= _total - 1) {
      _finish();
    } else {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.iosBackground,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _stepContent(),
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Górny pasek: postęp + „Pomiń konfigurator" ──────────────────────────
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              Text('Krok ${_step + 1} z $_total',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.iosSecondaryLabel)),
              const Spacer(),
              if (_step < _total - 1)
                TextButton(
                  onPressed: _finish,
                  child: Text('Pomiń konfigurator',
                      style: TextStyle(color: context.iosSecondaryLabel)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / _total,
              minHeight: 6,
              backgroundColor: context.iosCardSurfaceHigh,
              valueColor:
                  const AlwaysStoppedAnimation(SerenityColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dolny pasek: Wstecz / Pomiń krok / Dalej ────────────────────────────
  Widget _bottomBar() {
    final last = _step == _total - 1;
    final canSkipStep = _step != 0 && !last;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: context.iosBackground,
        border: Border(top: BorderSide(color: context.iosSeparator.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          if (_step > 0)
            TextButton(onPressed: _back, child: const Text('Wstecz')),
          const Spacer(),
          if (canSkipStep)
            TextButton(
              onPressed: _next,
              child: Text('Pomiń', style: TextStyle(color: context.iosSecondaryLabel)),
            ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _next,
            style: FilledButton.styleFrom(
              backgroundColor: SerenityColors.primaryContainer,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(last ? 'Zakończ' : (_step == 0 ? 'Zaczynamy' : 'Dalej'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _stepContent() {
    return switch (_step) {
      0 => _welcome(),
      1 => _modeStep(),
      2 => _permsStep(),
      3 => _notifPrefsStep(),
      4 => _radiusStep(),
      5 => _familyStep(),
      6 => _safeZonesStep(),
      7 => _a11yStep(),
      _ => _doneStep(),
    };
  }

  Widget _heading(String title, String subtitle, {IconData? icon}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 40, color: SerenityColors.secondary),
            const SizedBox(height: 12),
          ],
          Text(title,
              style: SerenityText.headlineHeroMobile.copyWith(fontSize: 26)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(fontSize: 15, height: 1.4, color: context.iosSecondaryLabel)),
          const SizedBox(height: 24),
        ],
      );

  // 0 — Powitanie
  Widget _welcome() => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tune, size: 56, color: SerenityColors.secondary),
            const SizedBox(height: 16),
            Text('Skonfigurujmy be:Safe',
                style: SerenityText.headlineHeroMobile.copyWith(fontSize: 30)),
            const SizedBox(height: 10),
            Text(
              'Kilka kroków, aby dopasować aplikację do siebie: tryb, '
              'uprawnienia, zasięg alertów, rodzina i ułatwienia dostępu. '
              'Każdy krok możesz pominąć i zmienić później w Ustawieniach.',
              style: TextStyle(fontSize: 16, height: 1.5, color: context.iosSecondaryLabel),
            ),
          ],
        ),
      );

  // 1 — Tryb aplikacji
  Widget _modeStep() {
    final mode = context.watch<ModeProvider>().mode;
    Widget tile(AppMode m, IconData ic, String desc) {
      final sel = mode == m;
      return GestureDetector(
        onTap: () => context.read<ModeProvider>().setMode(m, context.read<AuthProvider>()),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sel ? SerenityColors.secondaryContainer : context.iosCardSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: sel ? SerenityColors.secondary : context.iosSeparator,
                width: sel ? 2 : 1),
          ),
          child: Row(children: [
            Icon(ic, size: 30, color: sel ? SerenityColors.onSecondaryContainer : context.iosLabel),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.label,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: sel ? SerenityColors.onSecondaryContainer : context.iosLabel)),
                Text(desc,
                    style: TextStyle(
                        fontSize: 13,
                        color: sel ? SerenityColors.onSecondaryContainer : context.iosSecondaryLabel)),
              ]),
            ),
            if (sel) const Icon(Icons.check_circle, color: SerenityColors.secondary),
          ]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Tryb aplikacji', 'Wybierz układ dopasowany do użytkownika.',
            icon: Icons.dashboard_customize),
        tile(AppMode.normal, Icons.person, 'Pełen zestaw funkcji (13–59 lat)'),
        tile(AppMode.kids, Icons.child_care, 'Prosty, duże przyciski (7–12 lat)'),
        tile(AppMode.senior, Icons.elderly, 'Powiększony, czytelny (60+)'),
      ],
    );
  }

  // 2 — Uprawnienia (rozszerzone)
  Widget _permsStep() {
    Widget row(Permission perm, String title, String desc) {
      final granted = _perms[perm] ?? false;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.iosCardSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.iosLabel)),
              const SizedBox(height: 2),
              Text(desc, style: TextStyle(fontSize: 13, color: context.iosSecondaryLabel)),
            ]),
          ),
          const SizedBox(width: 12),
          granted
              ? const Icon(Icons.check_circle, color: SerenityColors.secondary, size: 28)
              : FilledButton(
                  onPressed: () async {
                    await perm.request();
                    _refreshPerms();
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: SerenityColors.secondaryContainer,
                      foregroundColor: SerenityColors.onSecondaryContainer),
                  child: const Text('Zezwól'),
                ),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Uprawnienia', 'Potrzebne do pełnej ochrony. Każde możesz pominąć '
            'i przyznać później w Ustawieniach systemu.', icon: Icons.verified_user_outlined),
        ..._permList.map((p) => row(p.$1, p.$2, p.$3)),
      ],
    );
  }

  // 3 — Preferencje powiadomień
  Widget _notifPrefsStep() {
    Widget sw(String title, String desc, bool v, ValueChanged<bool> on) => SwitchListTile(
          title: Text(title, style: TextStyle(color: context.iosLabel, fontWeight: FontWeight.w600)),
          subtitle: Text(desc, style: TextStyle(color: context.iosSecondaryLabel, fontSize: 13)),
          value: v,
          onChanged: on,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Powiadomienia', 'Zdecyduj, o czym chcesz być informowany.',
            icon: Icons.notifications_active_outlined),
        Container(
          decoration: BoxDecoration(color: context.iosCardSurface, borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            sw('Alerty zagrożeń', 'Powiadomienia o zagrożeniach w okolicy', _notifAlerts,
                (v) { setState(() => _notifAlerts = v); _saveNotif('notif_alerts', v); }),
            _div(),
            sw('Alerty rodzinne', 'Geofence i lokalizacja bliskich', _notifFamily,
                (v) { setState(() => _notifFamily = v); _saveNotif('notif_family', v); }),
            _div(),
            sw('Dźwięk', 'Sygnał dźwiękowy powiadomień', _notifSound,
                (v) { setState(() => _notifSound = v); _saveNotif('notif_sound', v); }),
            _div(),
            sw('Wibracja', 'Wibracja przy powiadomieniach', _notifVibration,
                (v) { setState(() => _notifVibration = v); _saveNotif('notif_vibration', v); }),
          ]),
        ),
      ],
    );
  }

  Widget _div() => Divider(height: 1, color: context.iosSeparator.withValues(alpha: 0.4));

  // 3 — Promień powiadomień
  Widget _radiusStep() {
    final km = (_radius / 1000).toStringAsFixed(_radius >= 1000 ? 1 : 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Zasięg alertów', 'Jak daleko od Ciebie chcesz dostawać ostrzeżenia?',
            icon: Icons.radar),
        Center(
          child: Text(_radius >= 1000 ? '$km km' : '$_radius m',
              style: SerenityText.displayLg.copyWith(fontSize: 56, color: context.iosLabel)),
        ),
        Slider(
          value: _radius.toDouble(),
          min: 300,
          max: 10000,
          divisions: 97,
          label: _radius >= 1000 ? '$km km' : '$_radius m',
          onChanged: (v) => setState(() => _radius = (v / 100).round() * 100),
        ),
        Text('Mniejszy zasięg = mniej powiadomień, tylko najbliższe zagrożenia.',
            style: TextStyle(fontSize: 13, color: context.iosSecondaryLabel)),
      ],
    );
  }

  // 4 — Rodzina
  Widget _familyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Rodzina', 'Utwórz grupę dla bliskich lub dołącz kodem zaproszenia. '
            'Opcjonalne — możesz pominąć.', icon: Icons.family_restroom),
        TextField(
          controller: _groupCtrl,
          decoration: InputDecoration(
            labelText: 'Nazwa nowej grupy',
            hintText: 'np. Moja rodzina',
            filled: true,
            fillColor: context.iosCardSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _familyBusy ? null : _createGroup,
            icon: const Icon(Icons.add),
            label: const Text('Utwórz grupę'),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Divider(color: context.iosSeparator)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('albo', style: TextStyle(color: context.iosSecondaryLabel)),
          ),
          Expanded(child: Divider(color: context.iosSeparator)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Kod zaproszenia',
            hintText: 'np. E2ETEST',
            filled: true,
            fillColor: context.iosCardSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _familyBusy ? null : _joinGroup,
            icon: const Icon(Icons.group_add),
            label: const Text('Dołącz kodem'),
          ),
        ),
        if (_familyMsg != null) ...[
          const SizedBox(height: 12),
          Text(_familyMsg!, style: TextStyle(color: SerenityColors.secondary, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }

  Future<void> _createGroup() async {
    final name = _groupCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _familyBusy = true);
    try {
      final res = await context.read<ApiService>().post('/family/groups', {'name': name});
      if (mounted) setState(() => _familyMsg = 'Utworzono grupę! Kod: ${res['invite_code'] ?? ''}');
      _loadGroups();
    } catch (_) {
      if (mounted) setState(() => _familyMsg = 'Nie udało się utworzyć grupy.');
    } finally {
      if (mounted) setState(() => _familyBusy = false);
    }
  }

  Future<void> _joinGroup() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _familyBusy = true);
    try {
      await context.read<ApiService>().post('/family/groups/join', {'invite_code': code});
      if (mounted) setState(() => _familyMsg = 'Dołączono do grupy!');
      _loadGroups();
    } catch (_) {
      if (mounted) setState(() => _familyMsg = 'Nieprawidłowy kod lub błąd.');
    } finally {
      if (mounted) setState(() => _familyBusy = false);
    }
  }

  // 6 — Bezpieczne strefy
  Widget _safeZonesStep() {
    final hasGroup = _groups.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Bezpieczne strefy', 'Wyznacz miejsca jak dom czy szkoła — '
            'dostaniesz alert, gdy bliski wejdzie lub wyjdzie. Opcjonalne.',
            icon: Icons.add_location_alt_outlined),
        if (!hasGroup)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: context.iosCardSurface, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Icon(Icons.info_outline, color: context.iosSecondaryLabel),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Najpierw utwórz lub dołącz do grupy rodzinnej (poprzedni krok), '
                  'aby móc dodać strefę.',
                  style: TextStyle(color: context.iosSecondaryLabel, fontSize: 14),
                ),
              ),
            ]),
          )
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openAddGeofence,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Dodaj bezpieczną strefę'),
              style: FilledButton.styleFrom(
                backgroundColor: SerenityColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openAddGeofence() async {
    LatLng center = const LatLng(52.2297, 21.0122);
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
      center = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
    if (!mounted) return;
    final gid = _groups.first['id'] as String?;
    if (gid == null) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddGeofenceScreen(groupId: gid, initialCenter: center),
    ));
  }

  // 7 — Ułatwienia dostępu
  Widget _a11yStep() {
    final a11y = context.watch<AccessibilityProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Ułatwienia dostępu', 'Włącz, jeśli potrzebujesz. Więcej opcji '
            'znajdziesz w Ustawieniach.', icon: Icons.accessibility_new),
        Container(
          decoration: BoxDecoration(color: context.iosCardSurface, borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            SwitchListTile(
              title: Text('Większy tekst', style: TextStyle(color: context.iosLabel, fontWeight: FontWeight.w600)),
              subtitle: Text('Powiększa czcionkę w całej aplikacji', style: TextStyle(color: context.iosSecondaryLabel)),
              value: a11y.textScale >= 1.3,
              onChanged: (v) => a11y.textScale = v ? 1.3 : 1.0,
            ),
            Divider(height: 1, color: context.iosSeparator.withValues(alpha: 0.4)),
            SwitchListTile(
              title: Text('Wysoki kontrast', style: TextStyle(color: context.iosLabel, fontWeight: FontWeight.w600)),
              subtitle: Text('Czytelniejsze, mocniejsze kolory', style: TextStyle(color: context.iosSecondaryLabel)),
              value: a11y.highContrast,
              onChanged: (v) => a11y.highContrast = v,
            ),
          ]),
        ),
      ],
    );
  }

  // 6 — Gotowe
  Widget _doneStep() => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 88, color: SerenityColors.secondary),
            const SizedBox(height: 20),
            Text('Wszystko gotowe!',
                style: SerenityText.headlineHeroMobile.copyWith(fontSize: 28),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Możesz teraz korzystać z be:Safe. Wszystkie ustawienia zmienisz '
              'w każdej chwili w zakładce Profil → Ustawienia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5, color: context.iosSecondaryLabel),
            ),
          ],
        ),
      );
}
