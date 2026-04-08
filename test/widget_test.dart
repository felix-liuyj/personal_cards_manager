import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/main.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PersonalCardsApp()));

    await tester.pump();

    expect(find.text('卡片管理'), findsOneWidget);
  });
}
