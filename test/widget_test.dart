import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipv4_subnet_calculator/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('affiche les trois onglets et calcule un sous-reseau', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SubnetCalculatorApp());
    await tester.pumpAndSettle();

    expect(find.text('Calculateur'), findsOneWidget);
    expect(find.text('VLSM'), findsOneWidget);
    expect(find.text('Regroupement'), findsOneWidget);

    // Valeurs par defaut deja renseignees : 192.168.1.10 / 24.
    await tester.tap(find.widgetWithText(FilledButton, 'Calculer'));
    await tester.pumpAndSettle();

    expect(find.text('192.168.1.0'), findsOneWidget); // adresse reseau
    expect(find.text('192.168.1.255'), findsOneWidget); // broadcast
  });
}
