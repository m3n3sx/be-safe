import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'providers/auth_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'services/background_service.dart';
import 'services/update_service.dart';
import 'services/analytics.dart';
import 'services/fcm_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/family/family_screen.dart';
import 'screens/family/family_group_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';

import 'screens/alerts/my_alerts_screen.dart';
import 'screens/alerts/stats_screen.dart';
import 'screens/profile/ranking_screen.dart';
import 'screens/legal/legal_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/profile/referral_screen.dart';
import 'screens/profile/badges_screen.dart';
import 'screens/community/news_screen.dart';
import 'screens/emergency/emergency_numbers_screen.dart';

import 'services/i18n.dart';

// Sentry DSN — wstaw swój z sentry.io (Project Settings → Client Keys)
// Jeśli pusty, Sentry jest wyłączony (development mode)
const String _sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await S.load();

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
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProv, __) => DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
          // Use dynamic color only if user hasn't picked a custom theme
          final useSystem = themeProv.themeId == 'blue' && lightDynamic != null;
          final useSerenity = themeProv.isSerenity;
          return MaterialApp(
          title: 'be:Safe',
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
          onGenerateRoute: (settings) {
            final uri = Uri.parse(settings.name ?? '');
            if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'family') {
              return MaterialPageRoute(builder: (_) => FamilyGroupScreen(
                groupId: uri.pathSegments[1],
                groupName: (settings.arguments as String?) ?? 'Grupa',
              ));
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
              '/terms' => const LegalScreen(type: 'terms'),
              '/privacy' => const LegalScreen(type: 'privacy'),
              '/referral' => const ReferralScreen(),
              '/badges' => const BadgesScreen(),
              '/news' => const NewsScreen(),
              '/emergency' => const EmergencyNumbersScreen(),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => UpdateService.checkForUpdate(context));
    final auth = context.read<AuthProvider>();
    auth.addListener(() => _handleAuth(auth));
    _loadOnboarding();
  }

  Future<void> _loadOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _onboardingDone = prefs.getBool('onboarding_done') ?? false);
  }

  void _handleAuth(AuthProvider auth) {
    if (auth.isLoggedIn && !_servicesStarted) {
      final token = context.read<ApiService>().token;
      if (token != null) {
        _servicesStarted = true;
        final api = context.read<ApiService>();
        Analytics.track('login_success');
        FcmService.init(api);
        context.read<BackgroundService>().init().then((_) {
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
    if (_onboardingDone == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_onboardingDone!) return OnboardingScreen(onComplete: () => setState(() => _onboardingDone = true));
    return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
// CI test
