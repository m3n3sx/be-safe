import 'package:home_widget/home_widget.dart';
import 'fcm_service.dart' show appNavigatorKey;

/// Most między Flutterem a natywnymi widgetami Androida (home_widget).
///
/// Widgety: SOS, Stan zagrożeń, Rodzina, Najbliższy alert, Szybkie akcje,
/// Check-in, AQI, Eskorta, Ostrzeżenia IMGW. Dane wstrzykiwane przez push*,
/// tapnięcia routowane przez registerClickHandler (besafe://<host>).
class WidgetService {
  static const _pkg = 'pl.u235.alertmap';

  static Future<void> _update(String provider) async {
    try {
      await HomeWidget.updateWidget(
        androidName: provider,
        qualifiedAndroidName: '$_pkg.$provider',
      );
    } catch (_) {}
  }

  /// Stan zagrożeń (N/10 + komunikat + alerty).
  static Future<void> pushSafety({
    required int level,
    required String message,
    required String alerts,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('safety_level', level);
      await HomeWidget.saveWidgetData<String>('safety_message', message);
      await HomeWidget.saveWidgetData<String>('safety_alerts', alerts);
      await _update('StatusWidgetProvider');
    } catch (_) {}
  }

  /// Rodzina — ile osób online / łącznie.
  static Future<void> pushFamily({
    required int online,
    required int total,
    required String sub,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('family_online', online);
      await HomeWidget.saveWidgetData<int>('family_total', total);
      await HomeWidget.saveWidgetData<String>('family_sub', sub);
      await _update('FamilyWidgetProvider');
    } catch (_) {}
  }

  /// Najbliższy alert — kategoria + meta (odległość • czas). has=false → brak.
  static Future<void> pushNearest({
    required bool has,
    String category = '',
    String meta = '',
  }) async {
    try {
      await HomeWidget.saveWidgetData<bool>('near_has', has);
      await HomeWidget.saveWidgetData<String>('near_cat', category);
      await HomeWidget.saveWidgetData<String>('near_meta', meta);
      await _update('NearestWidgetProvider');
    } catch (_) {}
  }

  /// AQI — indeks (0-5) + etykieta + miasto.
  static Future<void> pushAqi({
    required int index,
    required String label,
    required String city,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('aqi_index', index);
      await HomeWidget.saveWidgetData<String>('aqi_label', label);
      await HomeWidget.saveWidgetData<String>('aqi_city', city);
      await _update('AqiWidgetProvider');
    } catch (_) {}
  }

  /// Aktualizuje podtytuł check-in (np. „Zameldowano dziś o 20:14").
  static Future<void> pushCheckin(String sub) async {
    try {
      await HomeWidget.saveWidgetData<String>('checkin_sub', sub);
      await _update('CheckinWidgetProvider');
    } catch (_) {}
  }

  /// Render statycznych/launcherowych widgetów (ustawia click intents).
  static Future<void> refreshStatic() async {
    for (final p in [
      'SosWidgetProvider',
      'QuickWidgetProvider',
      'CheckinWidgetProvider',
      'EscortWidgetProvider',
      'ImgwWidgetProvider',
    ]) {
      await _update(p);
    }
  }

  /// Rejestruje obsługę tapnięć (wołać w main — niezależnie od logowania).
  static void registerClickHandler() {
    HomeWidget.widgetClicked.listen(_route);
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        Future.delayed(const Duration(milliseconds: 1200), () => _route(uri));
      }
    });
  }

  static void _route(Uri? uri, {int attempt = 0}) {
    if (uri == null) return;
    final nav = appNavigatorKey.currentState;
    if (nav == null) {
      if (attempt < 20) {
        Future.delayed(
          const Duration(milliseconds: 300),
          () => _route(uri, attempt: attempt + 1),
        );
      }
      return;
    }
    final route = switch (uri.host) {
      'sos' => '/sos',
      'family' => '/family',
      'nearest' => '/map',
      'status' => '/map',
      'aqi' => '/map',
      'imgw' => '/map',
      'escort' => '/escort',
      'fakecall' => '/fakecall',
      'report' => '/report',
      'checkin' => '/checkin',
      _ => null,
    };
    if (route != null) nav.pushNamed(route);
  }
}
