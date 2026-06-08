import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'fcm_service.dart' show appNavigatorKey;

/// Most między Flutterem a natywnymi widgetami Androida (home_widget).
///
/// - `pushSafety` wstrzykuje stan zagrożeń do widgetu „Stan zagrożeń".
/// - `registerClickHandler` routuje tapnięcia w widgety (besafe://sos,
///   besafe://status) przez globalny appNavigatorKey.
class WidgetService {
  static const _sos = 'SosWidgetProvider';
  static const _status = 'StatusWidgetProvider';
  static const _pkg = 'pl.u235.alertmap';

  /// Aktualizuje widget „Stan zagrożeń" danymi z home_screen.
  static Future<void> pushSafety({
    required int level,
    required String message,
    required String alerts,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('safety_level', level);
      await HomeWidget.saveWidgetData<String>('safety_message', message);
      await HomeWidget.saveWidgetData<String>('safety_alerts', alerts);
      await HomeWidget.updateWidget(
        androidName: _status,
        qualifiedAndroidName: '$_pkg.$_status',
      );
    } catch (e) {
      debugPrint('[Widget] pushSafety failed: $e');
    }
  }

  /// Wymusza render widgetu SOS (statyczny — ustawia click intent).
  static Future<void> refreshSos() async {
    try {
      await HomeWidget.updateWidget(
        androidName: _sos,
        qualifiedAndroidName: '$_pkg.$_sos',
      );
    } catch (e) {
      debugPrint('[Widget] refreshSos failed: $e');
    }
  }

  /// Rejestruje obsługę tapnięć w widgety. Wołać po zalogowaniu (gdy nawigator
  /// gotowy). Obsługuje też zimny start z tapnięcia w widget.
  static void registerClickHandler() {
    // Tap gdy aplikacja działa — nawigator gotowy, routujemy od razu.
    HomeWidget.widgetClicked.listen(_route);
    // Zimny start z widgetu — poczekaj aż auth-gate zamontuje home router
    // (jego setState po loginie inaczej podmieniłby świeżo pushnięty ekran).
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
      // Zimny start z widgetu: nawigator może nie być jeszcze gotowy.
      // Ponawiamy przez ~6s aż MaterialApp się zbuduje.
      if (attempt < 20) {
        Future.delayed(
          const Duration(milliseconds: 300),
          () => _route(uri, attempt: attempt + 1),
        );
      }
      return;
    }
    switch (uri.host) {
      case 'sos':
        nav.pushNamed('/sos');
        break;
      case 'status':
        nav.pushNamed('/map');
        break;
    }
  }
}
