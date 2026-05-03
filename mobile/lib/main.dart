import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'providers/auth_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';
import 'services/background_service.dart';
import 'services/update_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/family/family_screen.dart';
import 'screens/family/family_group_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';

import 'screens/alerts/my_alerts_screen.dart';
import 'screens/alerts/stats_screen.dart';
import 'screens/profile/ranking_screen.dart';

import 'services/i18n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await S.load();
  runApp(const AlertMapApp());
}

class AlertMapApp extends StatelessWidget {
  const AlertMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    final socket = SocketService();
    final bg = BackgroundService(api, socket);

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
          builder: (lightDynamic, darkDynamic) => MaterialApp(
          title: 'be:Safe',
          debugShowCheckedModeBanner: false,
          themeMode: themeProv.mode,
          theme: ThemeData(
            colorScheme: lightDynamic?.harmonized() ?? ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic?.harmonized() ?? ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
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
              _ => const MapScreen(),
            });
          },
        )),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => UpdateService.checkForUpdate(context));
    final auth = context.read<AuthProvider>();
    auth.addListener(() => _handleAuth(auth));
  }

  void _handleAuth(AuthProvider auth) {
    if (auth.isLoggedIn && !_servicesStarted) {
      final token = context.read<ApiService>().token;
      if (token != null) {
        _servicesStarted = true;
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
    return auth.isLoggedIn ? const MapScreen() : const LoginScreen();
  }
}
