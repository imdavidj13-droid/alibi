import 'package:alibi/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'alibi_onboarding_seen': true,
    });
  });

  testWidgets('Alibi generator screen loads', (tester) async {
    await tester.pumpWidget(const AlibiApp());
    await tester.pumpAndSettle();

    expect(find.text('ALIBI'), findsOneWidget);
    expect(find.text('Say less.\nGet out clean.'), findsOneWidget);
    expect(find.text('CREATE ALIBI'), findsOneWidget);
    expect(find.text('Believable'), findsOneWidget);
  });

  testWidgets('User can generate an excuse', (tester) async {
    await tester.pumpWidget(const AlibiApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CREATE ALIBI'));
    await tester.tap(find.text('CREATE ALIBI'));
    await tester.pumpAndSettle();

    expect(find.text('BELIEVABILITY'), findsOneWidget);
    expect(find.text('FOLLOW-UP RISK'), findsOneWidget);
    expect(find.text('Another'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });
}
