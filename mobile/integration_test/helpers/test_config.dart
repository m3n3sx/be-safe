/// E2E test configuration constants and persona definitions.
///
/// Used by all Patrol persona suites to log in to known seed accounts
/// and call the admin /test/reset-persona endpoint between scenarios.
///
/// Secret comes from --dart-define=TEST_RESET_SECRET=...
/// Production URL by default.
library;

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://besafe.org.pl/api/v1',
);

const String testResetSecret = String.fromEnvironment(
  'TEST_RESET_SECRET',
  defaultValue: '',
);

/// RUN_ID override - przy CI/skrypcie ustawia stabilny ID dla pobrania metryk.
/// Gdy puste, suity generują własne `<prefix>_<ts>`.
const String runIdOverride = String.fromEnvironment(
  'RUN_ID',
  defaultValue: '',
);

/// Default seed password (matches seed_test_personas.sql)
const String testPassword = 'Test123!';

/// 4 persony zgodne z /home/ooxo/alert/docs/E2E_TEST_PLAN.md
enum Persona {
  parentTech,
  parentEasy,
  kidAnna,
  seniorJadwiga;

  String get username => switch (this) {
        Persona.parentTech => 'parent_tech',
        Persona.parentEasy => 'parent_easy',
        Persona.kidAnna => 'kid_anna',
        Persona.seniorJadwiga => 'senior_jadwiga',
      };

  String get email => switch (this) {
        Persona.parentTech => 'parent.tech@test.besafe.org.pl',
        Persona.parentEasy => 'parent.easy@test.besafe.org.pl',
        Persona.kidAnna => 'kid.anna@test.besafe.org.pl',
        Persona.seniorJadwiga => 'senior.jadwiga@test.besafe.org.pl',
      };

  /// Human label used in test names + report
  String get label => switch (this) {
        Persona.parentTech => 'Rodzic techniczny',
        Persona.parentEasy => 'Rodzic nietechniczny',
        Persona.kidAnna => 'Dziecko (10 lat)',
        Persona.seniorJadwiga => 'Senior (68 lat)',
      };

  /// Min touch target size in dp — stricter for seniors
  double get minTouchTargetDp => this == Persona.seniorJadwiga ? 56.0 : 48.0;
}

/// Standardowe progi UX
class UxBudget {
  /// Time to login screen interactive (warm start)
  static const Duration warmStart = Duration(seconds: 3);

  /// Time to fully loaded HomeScreen
  static const Duration homeLoaded = Duration(seconds: 5);

  /// Time to dotarcia do SOS od main screen
  static const Duration reachSos = Duration(seconds: 4);

  /// Time to create an alert (tap "Zgłoś" -> potwierdzenie)
  static const Duration createAlert = Duration(seconds: 25);

  /// Max settle time after navigation
  static const Duration settle = Duration(seconds: 8);
}
