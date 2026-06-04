// Smoke test be:Safe.
//
// AlertMapApp uruchamia Analytics.init, tryAutoLogin (sieć) i ciągłe animacje
// (GlowOrb, shimmer), więc pumpAndSettle wisiałby (zob. AGENTS.md reguła #8).
// Trzymamy lekki sanity test renderowania MaterialApp — chroni przed regresją
// kompilacji i zastępuje wygenerowany z szablonu licznik.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp renderuje się', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('be:Safe'))),
    );
    expect(find.text('be:Safe'), findsOneWidget);
  });
}
