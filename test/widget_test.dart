import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ui_clone/app.dart';

void main() {
  testWidgets('Home shows brand and start CTA', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: UiCloneApp()),
    );
    await tester.pump();

    expect(find.text('UI Clone'), findsOneWidget);
    expect(find.text('Начать обзор интерфейса'), findsOneWidget);
  });
}
