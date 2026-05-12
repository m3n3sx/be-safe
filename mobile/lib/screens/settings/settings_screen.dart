import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
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
      backgroundColor: SerenityColors.surfaceBright,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SerenitySpacing.md,
                vertical: SerenitySpacing.md,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    color: SerenityColors.primary,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ustawienia',
                    style: SerenityText.headlineHeroMobile,
                  ),
                ],
              ),
            ),
            Expanded(
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
          subtitle: const Text('4'),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(S.get('delete_account'), style: const TextStyle(color: Colors.red)),
          onTap: () => _showDeleteAccount(),
        ),
      ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(SerenitySpacing.xl, 24, SerenitySpacing.xl, 8),
    child: Text(
      text.toUpperCase(),
      style: SerenityText.labelCaps.copyWith(
        color: SerenityColors.onSurfaceVariant,
      ),
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
    final res = await context.read<ApiService>().post('/users/me/email', {'email': email.text, 'password': password.text});
    if (mounted) _snack(res['ok'] == true ? 'Email zmieniony' : (res['error'] ?? 'Błąd'));
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
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Zmień')),
      ],
    ));
    if (result == null || result.isEmpty || !mounted) return;
    await context.read<ApiService>().patch('/users/me', {'username': result});
    if (mounted) _snack('Nazwa zmieniona');
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
