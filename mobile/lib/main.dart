import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'providers/auth_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/mode_provider.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'services/background_service.dart';
import 'services/update_service.dart';
import 'services/analytics.dart';
import 'services/fcm_service.dart';
import 'services/crash_detection_service.dart';
import 'services/shake_detection_service.dart';
import 'services/sos_audio_service.dart';
import 'services/biometric_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/escort/escort_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/family/family_screen.dart';
import 'screens/family/family_group_screen.dart';
import 'screens/family/family_sos_screen.dart';
import 'screens/family/ping_response_screen.dart';
import 'screens/alerts/alert_detail_screen.dart';
import 'models/alert.dart';
import 'models/user.dart' show AppMode;
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';

import 'screens/alerts/my_alerts_screen.dart';
import 'screens/alerts/stats_screen.dart';
import 'screens/profile/ranking_screen.dart';
import 'screens/legal/legal_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/mode/mode_picker_screen.dart';
import 'screens/profile/referral_screen.dart';
import 'screens/permissions/permissions_screen.dart';
import 'screens/profile/badges_screen.dart';
import 'screens/community/news_screen.dart';
import 'screens/emergency/emergency_numbers_screen.dart';
import 'screens/sos/sos_screen.dart';
import 'screens/home/home_kids_screen.dart';
import 'screens/home/home_senior_screen.dart';

import 'services/i18n.dart';
import 'widgets/collapsible_dock.dart';
import 'widgets/nav_routes.dart' show NavTabs;

// Sentry DSN — be:Safe production project (sentry.io project 4511406965194832)
// Publiczny DSN — bezpieczny w bundle APK (Sentry rate-limit + project key tylko ingest).
// Aby wyłączyć w dev: zostawić puste lub `flutter run --dart-define=SENTRY_DSN=`.
const String _sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue: 'https://cc93b0a06c984051e9e77463aad8a546@o4511406962704384.ingest.de.sentry.io/4511406965194832',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await S.load();
  await initDockState();

  if (_sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = 0.2; // 20% tras dla performance monitoring
        options.debug = false;
      },
      appRunner: () => runApp(const AlertMapApp()),
    );
  } else {
    runApp(const AlertMapApp());
  }
}

class AlertMapApp extends StatelessWidget {
  const AlertMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    final socket = SocketService();
    final bg = BackgroundService(api, socket);
    Analytics.init(api);
    Analytics.track('app_open');

    return MultiProvider(
      providers: [
        Provider.value(value: api),
        Provider.value(value: socket),
        Provider.value(value: bg),
        ChangeNotifierProvider(create: (_) => AuthProvider(api)..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => AlertProvider(api, socket)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ModeProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProv, __) => DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
          // Use dynamic color only if user hasn't picked a custom theme
          final useSystem = themeProv.themeId == 'blue' && lightDynamic != null;
          final useSerenity = themeProv.isSerenity;
          return MaterialApp(
          title: 'be:Safe',
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: themeProv.mode,
          theme: useSerenity
              ? buildSerenityTheme(brightness: Brightness.light)
              : ThemeData(
                  colorScheme: useSystem ? lightDynamic!.harmonized() : ColorScheme.fromSeed(seedColor: themeProv.seedColor, brightness: Brightness.light),
                  useMaterial3: true,
                ),
          darkTheme: useSerenity
              ? buildSerenityTheme(brightness: Brightness.dark)
              : ThemeData(
                  colorScheme: useSystem && darkDynamic != null ? darkDynamic!.harmonized() : ColorScheme.fromSeed(seedColor: themeProv.seedColor, brightness: Brightness.dark),
                  useMaterial3: true,
                ),
          home: const _AuthGate(),
          builder: (context, child) => GlobalDockOverlay(child: child ?? const SizedBox.shrink()),
          onGenerateRoute: (settings) {
            final uri = Uri.parse(settings.name ?? '');
            if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'family') {
              return MaterialPageRoute(builder: (_) => FamilyGroupScreen(
                groupId: uri.pathSegments[1],
                groupName: (settings.arguments as String?) ?? 'Grupa',
              ));
            }
            // FCM-driven routes z payloadem
            if (settings.name == '/family-sos' && settings.arguments is Map) {
              final data = (settings.arguments as Map).cast<String, dynamic>();
              return MaterialPageRoute(builder: (_) => FamilySosScreen.fromPayload(data));
            }
            if (settings.name == '/ping-response' && settings.arguments is Map) {
              final data = (settings.arguments as Map).cast<String, dynamic>();
              return MaterialPageRoute(builder: (_) => PingResponseScreen.fromPayload(data));
            }
            if (settings.name == '/alert-detail' && settings.arguments is Map) {
              final args = (settings.arguments as Map).cast<String, dynamic>();
              final alertId = args['alert_id'] as String?;
              if (alertId != null) {
                return MaterialPageRoute(builder: (_) => _AlertDetailLoader(alertId: alertId));
              }
            }
            return MaterialPageRoute(builder: (_) => switch (settings.name) {
              '/map' => const MapScreen(),
              '/family' => const FamilyScreen(),
              '/profile' => const ProfileScreen(),
              '/settings' => const SettingsScreen(),
              '/my-alerts' => const MyAlertsScreen(),
              '/stats' => const StatsScreen(),
              '/ranking' => const RankingScreen(),
              '/login' => const LoginScreen(),
              '/forgot-password' => const ForgotPasswordScreen(),
              '/terms' => const LegalScreen(type: 'terms'),
              '/privacy' => const LegalScreen(type: 'privacy'),
              '/referral' => const ReferralScreen(),
              '/permissions' => const PermissionsScreen(),
              '/badges' => const BadgesScreen(),
              '/news' => const NewsScreen(),
              '/emergency' => const EmergencyNumbersScreen(),
              '/sos' => const SosScreen(),
              '/mode-picker' => const ModePickerScreen(allowSkip: true),
              '/escort' => const EscortScreen(),
              _ => const MapScreen(),
            });
          },
        );}),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _servicesStarted = false;
  bool? _onboardingDone;
  bool? _modePicked;
  bool _biometricPassed = false; // F24: czy biometria zatwierdzona w tej sesji
  bool _biometricInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => UpdateService.checkForUpdate(context));
    final auth = context.read<AuthProvider>();
    auth.addListener(() => _handleAuth(auth));
    // Sprawdź stan natychmiast - tryAutoLogin może już skończyć przed addListener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleAuth(auth);
    });
    _loadOnboarding();
  }

  Future<void> _loadOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _onboardingDone = prefs.getBool('onboarding_done') ?? false;
      _modePicked = prefs.getBool('mode_picked') ?? false;
    });
  }

  Future<void> _completeModePicker() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mode_picked', true);
    if (mounted) setState(() => _modePicked = true);
  }

  void _handleAuth(AuthProvider auth) {
    if (auth.isLoggedIn && !_servicesStarted) {
      final token = context.read<ApiService>().token;
      if (token != null) {
        _servicesStarted = true;
        final api = context.read<ApiService>();
        // F33: sync trybu aplikacji z backendu po loginie
        final user = auth.user;
        if (user != null) {
          context.read<ModeProvider>().syncFromUser(user);
        }
        Analytics.track('login_success');
        // Rejestruj payload handler dla powiadomień FCM (przed init żeby getInitialMessage
        // mógł od razu zrutować, jeśli aplikacja została uruchomiona tapnięciem)
        registerFcmPayloadHandler((data) async {
          final type = data['type'];
          final nav = appNavigatorKey.currentState;
          if (nav == null) return;
          switch (type) {
            case 'new_alert':
            case 'child_in_alert_area':
            case 'family_alert_near_child':
              final alertId = data['alert_id'];
              if (alertId is String && alertId.isNotEmpty) {
                nav.pushNamed('/alert-detail', arguments: {'alert_id': alertId});
              }
              break;
            case 'family_sos':
              nav.pushNamed('/family-sos', arguments: Map<String, dynamic>.from(data));
              break;
            case 'family_ping':
              nav.pushNamed('/ping-response', arguments: Map<String, dynamic>.from(data));
              break;
            case 'ping_response':
              // Nadawca otrzymuje odpowiedź. Jeśli not_ok - otwórz family żeby zobaczył kto i gdzie.
              // Dla ok pokazujemy tylko SnackBar (zostajemy gdzie jesteśmy).
              final status = data['status']?.toString();
              final fromUsername = data['from_username']?.toString() ?? 'rodzina';
              final messenger = ScaffoldMessenger.maybeOf(nav.context);
              if (status == 'not_ok') {
                messenger?.showSnackBar(SnackBar(
                  content: Text('⚠️ $fromUsername potrzebuje pomocy'),
                  backgroundColor: const Color(0xFFFF7A7A),
                  duration: const Duration(seconds: 5),
                ));
                nav.pushNamed('/family');
              } else if (status == 'ok') {
                messenger?.showSnackBar(SnackBar(
                  content: Text('✅ $fromUsername: wszystko OK'),
                  backgroundColor: const Color(0xFF9DF4CB),
                  duration: const Duration(seconds: 4),
                ));
              } else if (status == 'expired') {
                messenger?.showSnackBar(SnackBar(
                  content: Text('⏱ $fromUsername nie odpowiedział na sygnał'),
                  duration: const Duration(seconds: 5),
                ));
              }
              break;
            case 'geofence_exit':
            case 'geofence_enter':
            case 'route_exit':
            case 'route_return':
              nav.pushNamed('/family');
              break;
            case 'escort_invite':
            case 'escort_panic':
            case 'escort_completed':
              nav.pushNamed('/escort');
              break;
            case 'family_message':
              nav.pushNamed('/family', arguments: Map<String, dynamic>.from(data));
              break;
            case 'pet_lost':
            case 'pet_lost_nearby':
            case 'pet_found':
            case 'pet_sighting':
              nav.pushNamed('/family', arguments: Map<String, dynamic>.from(data));
              break;
          }
        });
        FcmService.init(api);
        // F04: Crash detection init (opt-in z SharedPreferences)
        CrashDetectionService.navigatorKey = appNavigatorKey;
        CrashDetectionService().init(api: api);
        // F07: Shake-to-SOS panic gesture
        ShakeDetectionService.navigatorKey = appNavigatorKey;
        ShakeDetectionService().init();
        // F02: Audio SOS recording (RODO opt-in)
        SosAudioService().init();
        // F24: Biometric auth (opt-in)
        BiometricService().init();
        context.read<BackgroundService>().init().then((_) {
          if (!mounted) return;
          context.read<BackgroundService>().startTracking(token);
          context.read<AlertProvider>().connectSocket(token);
        });
      }
      if (mounted) setState(() {});
    } else if (!auth.isLoggedIn && _servicesStarted) {
      _servicesStarted = false;
      context.read<BackgroundService>().stopTracking();
      context.read<AlertProvider>().disconnectSocket();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (_onboardingDone == null || _modePicked == null) {
      _setDockVisible(false);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_onboardingDone!) {
      _setDockVisible(false);
      return OnboardingScreen(onComplete: () => setState(() => _onboardingDone = true));
    }
    // P0 Login: jeśli token jest w SharedPrefs (autoLoginInProgress=true) — pokazuj
    // "Sprawdzam sesję..." zamiast flash LoginScreen → ModePicker. Po sukcesie
    // _user zostanie ustawiony i przejdziemy do _HomeRouter.
    if (auth.autoLoginInProgress) {
      _setDockVisible(false);
      return const _SessionCheckScreen();
    }
    // F33: po onboardingu (a przed loginem) wymuszamy wybór trybu raz.
    // Logged-in użytkownicy też pierwszy raz przechodzą przez picker — synch z
    // backendu nadpisze ich wybór, jeśli był już ustawiony wcześniej.
    if (!_modePicked! && !auth.isLoggedIn) {
      _setDockVisible(false);
      return ModePickerScreen(
        allowSkip: false,
        onDone: _completeModePicker,
      );
    }
    // F24: jeśli zalogowany, biometria włączona i jeszcze nie zatwierdzona w tej sesji
    if (auth.isLoggedIn && BiometricService().enabled && !_biometricPassed) {
      _setDockVisible(false);
      if (!_biometricInProgress) {
        _biometricInProgress = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final ok = await BiometricService().authenticate(
            reason: 'Odblokuj be:Safe',
          );
          if (!mounted) return;
          if (ok) {
            setState(() => _biometricPassed = true);
          } else {
            // Niepowodzenie — pozostaje na ekranie blokady, user może spróbować ponownie
            setState(() => _biometricInProgress = false);
          }
        });
      }
      return _BiometricLockScreen(
        onRetry: () => setState(() => _biometricInProgress = false),
        onLogout: () async {
          await auth.logout();
          if (mounted) setState(() => _biometricPassed = false);
        },
      );
    }
    final loggedIn = auth.isLoggedIn;
    if (loggedIn) {
      // Po loginie: dock widoczny, domyślnie aktywny tab = Home
      _setDockVisible(true);
      if (dockActiveIndex.value < 0) dockActiveIndex.value = NavTabs.home;
    } else {
      _setDockVisible(false);
    }
    return loggedIn ? const _HomeRouter() : const LoginScreen();
  }

  void _setDockVisible(bool visible) {
    // Defer to po build żeby uniknąć setState during build
    if (dockVisible.value != visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dockVisible.value = visible;
      });
    }
  }
}

/// F24: Ekran blokady biometrycznej. Pokazywany gdy zalogowany ale nie potwierdził biometrii.
class _BiometricLockScreen extends StatelessWidget {
  const _BiometricLockScreen({required this.onRetry, required this.onLogout});
  final VoidCallback onRetry;
  final Future<void> Function() onLogout;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2027),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.fingerprint, size: 56, color: Color(0xFF9DF4CB)),
                ),
                const SizedBox(height: 24),
                const Text('be:Safe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF03080E))),
                const SizedBox(height: 8),
                const Text('Aplikacja zablokowana', style: TextStyle(fontSize: 16, color: Color(0xFF44474B))),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Odblokuj'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2027),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onLogout,
                  child: const Text('Wyloguj się i zaloguj hasłem'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pokazywany podczas tryAutoLogin (~< 6s) zamiast flash LoginScreen.
/// Jednolity branded ekran startowy z logo + spinner.
class _SessionCheckScreen extends StatelessWidget {
  const _SessionCheckScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2027),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.shield, size: 44, color: Color(0xFF9DF4CB)),
            ),
            const SizedBox(height: 24),
            const Text(
              'be:Safe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF03080E)),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sprawdzam sesję…',
              style: TextStyle(fontSize: 14, color: Color(0xFF44474B)),
            ),
          ],
        ),
      ),
    );
  }
}

/// F33: routing Home wg trybu z ModeProvider.
/// - KIDS   → HomeKidsScreen (2×2 grid, triple-tap POMOC, 3-tab nav)
/// - SENIOR → HomeSeniorScreen (DZIEŃ DOBRY, ZAMELDUJ SIĘ, 4 akcje, 4-tab nav)
/// - NORMAL → HomeScreen (oryginalny pełny UI)
class _HomeRouter extends StatelessWidget {
  const _HomeRouter();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ModeProvider>();
    if (!mode.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    switch (mode.mode) {
      case AppMode.kids:
        return const HomeKidsScreen();
      case AppMode.senior:
        return const HomeSeniorScreen();
      case AppMode.normal:
        return const HomeScreen();
    }
  }
}

/// Wrapper który ściąga AlertModel z backendu po `alertId` i pokazuje AlertDetailScreen.
/// Używany dla FCM tap routing — payload zawiera tylko alert_id, model trzeba dociągnąć.
class _AlertDetailLoader extends StatefulWidget {
  final String alertId;
  const _AlertDetailLoader({required this.alertId});

  @override
  State<_AlertDetailLoader> createState() => _AlertDetailLoaderState();
}

class _AlertDetailLoaderState extends State<_AlertDetailLoader> {
  AlertModel? _alert;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiService>();
      final res = await api.get('/alerts/${widget.alertId}');
      if (res is Map && res['id'] != null && mounted) {
        setState(() => _alert = AlertModel.fromJson(res));
      } else if (mounted) {
        setState(() => _error = 'Nie znaleziono alertu');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Błąd: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_alert != null) return AlertDetailScreen(alert: _alert!);
    return Scaffold(
      appBar: AppBar(title: const Text('Wczytywanie...')),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.maybePop(context),
                      child: const Text('Wróć'),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
// CI test
