import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart' show AppModeX;
import '../../providers/mode_provider.dart';
import '../../providers/theme_provider.dart';
import '../mode/mode_picker_screen.dart';
import '../cyber_safety/cyber_safety_screen.dart';
import '../parental_controls/parental_controls_screen.dart';
import '../../services/api_service.dart';
import '../../services/update_service.dart' show appVersion;
import '../../services/crash_detection_service.dart';
import '../../services/shake_detection_service.dart';
import '../../services/biometric_service.dart';
import '../../services/sos_audio_service.dart';
import '../../services/i18n.dart';
import '../../theme/design_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _alertsEnabled = true;
  bool _familyAlertsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _alertsEnabled = p.getBool('notif_alerts') ?? true;
      _familyAlertsEnabled = p.getBool('notif_family') ?? true;
      _soundEnabled = p.getBool('notif_sound') ?? true;
      _vibrationEnabled = p.getBool('notif_vibration') ?? true;
    });
  }

  Future<void> _saveBool(String key, bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: SerenityColors.groupedBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                    color: SerenityColors.primary,
                    tooltip: 'Wróć',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ustawienia',
                    style: SerenityText.largeTitle.copyWith(fontSize: 28),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListTileTheme(
                data: ListTileThemeData(
                  tileColor: SerenityColors.groupedSurface,
                  selectedTileColor: SerenityColors.groupedSurface,
                  iconColor: SerenityColors.primaryContainer,
                  textColor: SerenityColors.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  minVerticalPadding: 12,
                ),
                child: ListView(children: [
        // === WYGLĄD ===
        _header(S.get('appearance')),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Język / Language'),
          subtitle: Text(S.langName(S.lang)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLanguagePicker(),
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: Text(S.get('theme')),
          subtitle: Text(switch (theme.mode) { ThemeMode.dark => S.get('dark'), ThemeMode.light => S.get('light'), _ => S.get('system') }),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemePicker(theme),
        ),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: const Text('Kolor motywu'),
          subtitle: Text(appThemes.firstWhere((t) => t.id == theme.themeId, orElse: () => appThemes[0]).name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showColorPicker(theme),
        ),
        // F33: tryb aplikacji (KIDS / SENIOR / NORMAL)
        Consumer<ModeProvider>(
          builder: (context, mode, _) => ListTile(
            leading: const Icon(Icons.dashboard_customize),
            title: const Text('Tryb aplikacji'),
            subtitle: Text(mode.mode.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ModePickerScreen(allowSkip: true),
              ),
            ),
          ),
        ),
        // F28: Cyber-bezpieczeństwo i ochrona danych osobowych
        ListTile(
          leading: const Icon(Icons.security_outlined),
          title: const Text('Bezpieczeństwo danych'),
          subtitle: const Text('mObywatel, ochrona PESEL, phishing'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CyberSafetyScreen()),
          ),
        ),
        // F32: Parental controls — linki do narzędzi (Family Link, Bark, Qustodio…)
        ListTile(
          leading: const Icon(Icons.family_restroom_outlined),
          title: const Text('Kontrola rodzicielska'),
          subtitle: const Text('Family Link, Apple Screen Time, Bark, Qustodio'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ParentalControlsScreen()),
          ),
        ),

        // === POWIADOMIENIA ===
        _header(S.get('notifications')),
        SwitchListTile(
          secondary: const Icon(Icons.warning_amber),
          title: Text(S.get('threat_alerts')),
          subtitle: const Text('Powiadomienia o zagrożeniach w okolicy'),
          value: _alertsEnabled,
          onChanged: (v) { setState(() => _alertsEnabled = v); _saveBool('notif_alerts', v); },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.family_restroom),
          title: Text(S.get('family_alerts')),
          subtitle: const Text('Geofence, lokalizacja dziecka'),
          value: _familyAlertsEnabled,
          onChanged: (v) { setState(() => _familyAlertsEnabled = v); _saveBool('notif_family', v); },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.volume_up),
          title: Text(S.get('sound')),
          value: _soundEnabled,
          onChanged: (v) { setState(() => _soundEnabled = v); _saveBool('notif_sound', v); },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.vibration),
          title: Text(S.get('vibration')),
          value: _vibrationEnabled,
          onChanged: (v) { setState(() => _vibrationEnabled = v); _saveBool('notif_vibration', v); },
        ),

        // === KONTO ===
        _header(S.get('account')),
        ListTile(
          leading: const Icon(Icons.email),
          title: Text(S.get('change_email')),
          subtitle: Text(user?.email ?? ''),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showChangeEmail(),
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: Text(S.get('change_password')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showChangePassword(),
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: Text(S.get('change_username')),
          subtitle: Text(user?.username ?? ''),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showChangeUsername(),
        ),
        ListTile(
          leading: const Icon(Icons.phone),
          title: const Text('Numer telefonu'),
          subtitle: Text(user?.phone ?? 'Brak — dodaj aby rodzina mogła zadzwonić'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showChangePhone(),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.medical_services_outlined),
          title: const Text('Ratownik KPP'),
          subtitle: Text(
            user?.isKpp == true
                ? 'Otrzymujesz wezwania SOS w promieniu 2km'
                : 'Włącz jeśli masz uprawnienia Kwalifikowanej Pierwszej Pomocy',
          ),
          value: user?.isKpp ?? false,
          onChanged: (v) => _toggleKpp(v),
        ),
        // F04: Crash detection
        StatefulBuilder(
          builder: (ctx, setSt) {
            final enabled = CrashDetectionService().isEnabled;
            return SwitchListTile(
              secondary: const Icon(Icons.car_crash_outlined),
              title: const Text('Wykrywanie wypadków'),
              subtitle: Text(
                enabled
                    ? 'Aktywne — auto-SOS po wykryciu wstrząsu (30s grace)'
                    : 'Akcelerometr wykryje nagły wstrząs i zaalarmuje rodzinę',
              ),
              value: enabled,
              onChanged: (v) async {
                if (v) {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (dc) => AlertDialog(
                      title: const Text('Włączyć wykrywanie wypadków?'),
                      content: const Text(
                        'Aplikacja będzie monitorować akcelerometr w tle. '
                        'Po wykryciu nagłego wstrząsu (np. upadek, wypadek) '
                        'pokaże 30-sekundowy odlicznik. Jeśli nie anulujesz, '
                        'wyślemy automatyczne SOS do rodziny i sąsiadów.\n\n'
                        'Może zwiększyć zużycie baterii o ~3-5%.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dc, false),
                          child: const Text('Anuluj'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dc, true),
                          child: const Text('Włącz'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                }
                if (!ctx.mounted) return;
                final api = ctx.read<ApiService>();
                await CrashDetectionService().setEnabled(v, api: api);
                setSt(() {});
              },
            );
          },
        ),

        // F24: Biometryczna blokada aplikacji
        StatefulBuilder(
          builder: (ctx, setSt) {
            final enabled = BiometricService().enabled;
            return SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Blokada biometryczna'),
              subtitle: Text(
                enabled
                    ? 'Aktywna — odcisk palca lub Face Unlock przy starcie aplikacji'
                    : 'Chroni aplikację odciskiem palca / Face Unlock',
              ),
              value: enabled,
              onChanged: (v) async {
                final supported = await BiometricService().isDeviceSupported();
                if (!supported) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Urządzenie nie obsługuje biometrii lub brak skonfigurowanego odcisku/PIN-u'),
                  ));
                  return;
                }
                final ok = await BiometricService().setEnabled(v);
                if (!ctx.mounted) return;
                if (v && !ok) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Nie udało się włączyć — autoryzacja nieudana'),
                  ));
                }
                setSt(() {});
              },
            );
          },
        ),

        // F07: Shake-to-SOS panic gesture
        StatefulBuilder(
          builder: (ctx, setSt) {
            final enabled = ShakeDetectionService().isEnabled;
            return SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text('Shake-to-SOS (panic gesture)'),
              subtitle: Text(
                enabled
                    ? 'Aktywne — 3× wstrząśnij telefonem aby otworzyć SOS'
                    : 'Szybki dostęp do SOS przez gest panicki',
              ),
              value: enabled,
              onChanged: (v) async {
                if (v) {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (dc) => AlertDialog(
                      title: const Text('Włączyć Shake-to-SOS?'),
                      content: const Text(
                        'Po wykryciu 3 wyraźnych potrząśnięć telefonem '
                        '(np. machanie ręką) aplikacja otworzy ekran SOS. '
                        'Możesz wtedy zdecydować czy wysłać alarm.\n\n'
                        'Nie wysyła SOS automatycznie — wymaga potwierdzenia.\n'
                        'Może zwiększyć zużycie baterii o ~2-3%.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dc, false),
                          child: const Text('Anuluj'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dc, true),
                          child: const Text('Włącz'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                }
                await ShakeDetectionService().setEnabled(v);
                setSt(() {});
              },
            );
          },
        ),

        // F02: Audio SOS Recording (RODO opt-in)
        StatefulBuilder(
          builder: (ctx, setSt) {
            final svc = SosAudioService();
            final enabled = svc.enabled;
            final hasConsent = svc.hasConsent;
            return SwitchListTile(
              secondary: const Icon(Icons.mic_none),
              title: const Text('Nagrywanie audio przy SOS'),
              subtitle: Text(
                enabled
                    ? 'Aktywne — 30s nagrania podczas alarmu SOS'
                    : hasConsent
                        ? 'Zgoda jest, ale funkcja wyłączona'
                        : 'Wymaga zgody RODO — kliknij aby skonfigurować',
              ),
              value: enabled,
              onChanged: (v) async {
                if (v && !hasConsent) {
                  // RODO consent flow
                  final ok = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (dc) => AlertDialog(
                      title: const Text('Zgoda RODO — Nagrywanie audio'),
                      content: const SingleChildScrollView(
                        child: Text(
                          'Aplikacja może nagrywać do 30 sekund dźwięku '
                          'gdy WYŚLESZ alarm SOS. Nagranie pomoże ratownikom '
                          'zrozumieć sytuację (np. szum drogi, krzyki, instrukcje).\n\n'
                          '🔒 Jak chronimy Twoje dane:\n'
                          '• Nagranie jest zapisane lokalnie w prywatnym katalogu aplikacji\n'
                          '• NIE jest wysyłane na zewnętrzne serwery bez Twojej zgody\n'
                          '• Możesz je usunąć w dowolnej chwili (ta sekcja, "Usuń nagrania")\n'
                          '• Cofnięcie zgody usuwa wszystkie nagrania\n\n'
                          '⚠️ Funkcja aktywuje się TYLKO podczas alarmu SOS — '
                          'nigdy w tle, nigdy bez Twojej świadomości.\n\n'
                          'Klikając "Zgadzam się" akceptujesz przetwarzanie '
                          'nagrań audio na podstawie art. 6 ust. 1 lit. a RODO '
                          '(dobrowolna zgoda).',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dc, false),
                          child: const Text('Nie zgadzam się'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dc, true),
                          child: const Text('Zgadzam się'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  await svc.grantConsent();
                }
                final success = await svc.setEnabled(v);
                if (!success && v && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Brak uprawnień do mikrofonu'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                setSt(() {});
              },
            );
          },
        ),

        // Sub-actions for audio SOS (only when consent granted)
        if (SosAudioService().hasConsent) ...[
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text('Usuń nagrania SOS'),
            subtitle: const Text('Usuwa wszystkie zapisane nagrania audio'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (dc) => AlertDialog(
                  title: const Text('Usunąć wszystkie nagrania?'),
                  content: const Text(
                    'Wszystkie zapisane nagrania SOS zostaną nieodwracalnie usunięte.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dc, false),
                      child: const Text('Anuluj'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(dc, true),
                      child: const Text('Usuń wszystkie'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await SosAudioService().clearAllRecordings();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nagrania usunięte'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel_outlined, color: Colors.red),
            title: const Text('Cofnij zgodę RODO',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('Wyłącza funkcję i usuwa wszystkie nagrania'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (dc) => AlertDialog(
                  title: const Text('Cofnąć zgodę RODO?'),
                  content: const Text(
                    'Funkcja nagrywania zostanie wyłączona. '
                    'Wszystkie istniejące nagrania zostaną usunięte. '
                    'Możesz ponownie udzielić zgody w dowolnej chwili.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dc, false),
                      child: const Text('Anuluj'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(dc, true),
                      child: const Text('Cofnij zgodę'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await SosAudioService().revokeConsent();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Zgoda cofnięta — funkcja wyłączona'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],

        // === INNE ===
        _header(S.get('other')),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Regulamin'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/terms'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Polityka prywatności'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/privacy'),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(S.get('app_version')),
          subtitle: Text('v$appVersion'),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(S.get('delete_account'), style: const TextStyle(color: Colors.red)),
          onTap: () => _showDeleteAccount(),
        ),
        SizedBox(height: 96 + MediaQuery.of(context).padding.bottom),
      ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
    child: Text(
      text.toUpperCase(),
      style: SerenityText.iosSectionHeader,
    ),
  );

  void _showLanguagePicker() {
    showDialog(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Język / Language'),
      children: S.availableLanguages.map((code) => SimpleDialogOption(
        onPressed: () async { await S.setLang(code); Navigator.pop(ctx); setState(() {}); },
        child: Row(children: [
          Icon(Icons.check, color: S.lang == code ? Theme.of(context).colorScheme.primary : Colors.transparent),
          const SizedBox(width: 12),
          Text(S.langName(code), style: TextStyle(fontWeight: S.lang == code ? FontWeight.bold : FontWeight.normal)),
        ]),
      )).toList(),
    ));
  }

  void _showThemePicker(ThemeProvider theme) {
    showDialog(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Wybierz motyw'),
      children: [
        for (final (mode, label, icon) in [
          (ThemeMode.dark, 'Ciemny', Icons.dark_mode),
          (ThemeMode.light, 'Jasny', Icons.light_mode),
          (ThemeMode.system, 'Systemowy', Icons.settings_brightness),
        ])
          SimpleDialogOption(
            onPressed: () { theme.setMode(mode); Navigator.pop(ctx); },
            child: Row(children: [
              Icon(icon, color: theme.mode == mode ? Theme.of(context).colorScheme.primary : null),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontWeight: theme.mode == mode ? FontWeight.bold : FontWeight.normal)),
            ]),
          ),
      ],
    ));
  }

  void _showColorPicker(ThemeProvider theme) {
    showDialog(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Kolor motywu'),
      children: appThemes.map((t) => SimpleDialogOption(
        onPressed: () { theme.setThemeColor(t.id); Navigator.pop(ctx); },
        child: Row(children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: t.seedColor, shape: BoxShape.circle,
            border: theme.themeId == t.id ? Border.all(color: Colors.black, width: 2) : null)),
          const SizedBox(width: 12),
          Text('${t.emoji} ${t.name}', style: TextStyle(fontWeight: theme.themeId == t.id ? FontWeight.bold : FontWeight.normal)),
        ]),
      )).toList(),
    ));
  }

  Future<void> _showChangeEmail() async {
    final email = TextEditingController();
    final password = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Zmień email'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Nowy email'), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 8),
        TextField(controller: password, decoration: const InputDecoration(labelText: 'Aktualne hasło'), obscureText: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Zmień')),
      ],
    ));
    if (result != true || !mounted) return;
    final res = await context.read<ApiService>().post('/users/me/email', {'email': email.text.trim(), 'password': password.text});
    if (!mounted) return;
    if (res['ok'] == true) {
      await context.read<AuthProvider>().refreshMe();
      if (mounted) _snack('Email zmieniony');
    } else {
      _snack(res['error']?.toString() ?? 'Błąd');
    }
  }

  Future<void> _showChangePassword() async {
    final current = TextEditingController();
    final newPass = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Zmień hasło'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: current, decoration: const InputDecoration(labelText: 'Aktualne hasło'), obscureText: true),
        const SizedBox(height: 8),
        TextField(controller: newPass, decoration: const InputDecoration(labelText: 'Nowe hasło (min 6 znaków)'), obscureText: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Zmień')),
      ],
    ));
    if (result != true || !mounted) return;
    final res = await context.read<ApiService>().post('/users/me/password', {'current_password': current.text, 'new_password': newPass.text});
    if (mounted) _snack(res['ok'] == true ? 'Hasło zmienione' : (res['error'] ?? 'Błąd'));
  }

  Future<void> _showChangeUsername() async {
    final ctrl = TextEditingController(text: context.read<AuthProvider>().user?.username);
    final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Zmień nazwę'),
      content: TextField(controller: ctrl, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Zmień')),
      ],
    ));
    if (result == null || result.isEmpty || !mounted) return;
    final res = await context.read<ApiService>().patch('/users/me', {'username': result});
    if (!mounted) return;
    if (res['error'] != null) {
      _snack(res['error'].toString());
      return;
    }
    await context.read<AuthProvider>().refreshMe();
    if (mounted) _snack('Nazwa zmieniona');
  }

  Future<void> _showChangePhone() async {
    final user = context.read<AuthProvider>().user;
    final ctrl = TextEditingController(text: user?.phone ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Numer telefonu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Numer pomocny przy SOS — rodzina może bezpośrednio zadzwonić. Format: +48123456789 lub 123456789.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                hintText: '+48 123 456 789',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          if ((user?.phone ?? '').isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Usuń'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Zapisz')),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final res = await context.read<ApiService>().patch('/users/me', {'phone': result.isEmpty ? null : result});
    if (!mounted) return;
    if (res['error'] != null) {
      _snack(res['error'].toString());
      return;
    }
    await context.read<AuthProvider>().refreshMe();
    if (mounted) _snack(result.isEmpty ? 'Telefon usunięty' : 'Telefon zapisany');
  }

  Future<void> _toggleKpp(bool v) async {
    if (v) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ratownik KPP'),
          content: const Text(
              'Włączając ten tryb deklarujesz posiadanie uprawnień Kwalifikowanej Pierwszej Pomocy (KPP). '
              'Będziesz otrzymywać powiadomienia o SOS w promieniu 2 km, niezależnie od członkostwa w rodzinie.\n\n'
              'Reagowanie jest zawsze dobrowolne. Fałszywa deklaracja może skutkować zablokowaniem konta.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Włącz'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    final api = context.read<ApiService>();
    final auth = context.read<AuthProvider>();
    final res = await api.patch('/users/me', {'is_kpp': v});
    if (res['error'] == null) {
      await auth.refreshMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: v
            ? SerenityColors.secondaryContainer
            : SerenityColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(SerenityShapes.radiusXl)),
        content: Text(v
            ? '✓ Tryb ratownika KPP włączony'
            : 'Tryb ratownika wyłączony'),
      ));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Nie udało się zapisać. Spróbuj ponownie.'),
      ));
    }
  }

  Future<void> _showDeleteAccount() async {
    final password = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Usuń konto'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Ta operacja jest nieodwracalna. Wszystkie Twoje dane zostaną usunięte.', style: TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        TextField(controller: password, decoration: const InputDecoration(labelText: 'Potwierdź hasłem'), obscureText: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Usuń konto')),
      ],
    ));
    if (result != true || !mounted) return;
    await context.read<ApiService>().post('/users/me/delete', {'password': password.text});
    if (mounted) {
      await context.read<AuthProvider>().logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
