import 'package:doordesk/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('DoorDesk startet (Login oder Supabase-Hinweis)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DoorDeskApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final hasDoorDesk = find.textContaining('DoorDesk').evaluate().isNotEmpty;
    final hasLogin = find.text('Anmelden').evaluate().isNotEmpty;
    final needsConfig = find.textContaining('Supabase nicht konfiguriert').evaluate().isNotEmpty;
    expect(hasDoorDesk || hasLogin || needsConfig, isTrue);
  });
}
