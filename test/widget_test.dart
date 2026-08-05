import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/core/session_manager.dart';
import 'package:hopscotch/routes/app_pages.dart';
import 'package:hopscotch/main.dart';

void main() {
  setUpAll(() {
    AppPages.init(StartupState.home);
  });

  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    expect(find.byType(MyApp), findsOneWidget);
  });
}
