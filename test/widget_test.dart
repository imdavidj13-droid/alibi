import 'package:alibi/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Alibi home screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AlibiApp());

    expect(find.text('ALIBI'), findsOneWidget);
    expect(find.text('Need a\nway out?'), findsOneWidget);
    expect(find.text('GENERATE'), findsOneWidget);
    expect(find.text('Believable'), findsOneWidget);
  });

  testWidgets('User can generate and refresh an excuse', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlibiApp());

    await tester.tap(find.text('GENERATE'));
    await tester.pumpAndSettle();

    expect(find.text('BELIEVABILITY'), findsOneWidget);
    expect(find.text('FOLLOW-UP RISK'), findsOneWidget);
    expect(find.text('ANOTHER'), findsOneWidget);
    expect(find.text('COPY'), findsOneWidget);

    await tester.tap(find.text('ANOTHER'));
    await tester.pumpAndSettle();

    expect(find.text('ANOTHER'), findsOneWidget);
  });
}
