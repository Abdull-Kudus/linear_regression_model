import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:revenue_estimator/main.dart';
import 'package:revenue_estimator/predict_page.dart';

void main() {
  testWidgets('shows one text field per input and a Predict button', (tester) async {
    await tester.pumpWidget(const RevenueEstimatorApp());

    expect(find.byType(TextFormField, skipOffstage: false), findsNWidgets(12));
    expect(find.widgetWithText(FilledButton, 'Predict', skipOffstage: false), findsOneWidget);
  });

  testWidgets('pressing Predict with empty fields shows an error instead of calling the API', (tester) async {
    await tester.pumpWidget(const RevenueEstimatorApp());

    await tester.ensureVisible(find.text('Predict'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Predict'));
    await tester.pumpAndSettle();

    expect(find.text('Some fields need fixing. Check the messages in red above.'), findsOneWidget);
  });

  test('money adds thousands separators and two decimals', () {
    expect(money(1376.14), r'$1,376.14');
    expect(money(2752.284), r'$2,752.28');
    expect(money(95), r'$95.00');
  });
}
