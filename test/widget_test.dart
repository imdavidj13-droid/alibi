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

  testWidgets('User can open the generated result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AlibiApp());

    await tester.tap(find.text('GENERATE'));
    await tester.pumpAndSettle();

    expect(find.text('COPY EXCUSE'), findsOneWidget);
    expect(find.text('BELIEVABILITY'), findsOneWidget);
  });
}