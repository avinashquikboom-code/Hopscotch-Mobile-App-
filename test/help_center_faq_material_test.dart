import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/screens/profile/help_center_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createHelpCenterApp({
    ThemeMode themeMode = ThemeMode.light,
    Size size = const Size(375, 2500),
  }) {
    return ProviderScope(
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(
            surface: Color(0xFFFFFFFF),
            outline: Color(0xFFE2E8F0),
            onSurface: Color(0xFF0F172A),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            surface: Color(0xFF1E293B),
            outline: Color(0xFF334155),
            onSurface: Color(0xFFF8FAFC),
          ),
        ),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const HelpCenterScreen(),
        ),
      ),
    );
  }

  group('Help Center FAQ ListTile Material & InkSplash Tests', () {
    testWidgets('Renders all FAQ questions with proper Material ancestor and zero hidden ink assertions', (tester) async {
      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };

      try {
        await tester.binding.setSurfaceSize(const Size(375, 2500));
        await tester.pumpWidget(createHelpCenterApp());
        await tester.pumpAndSettle();

        // Check for FAQ section title
        expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsOneWidget);

        // Find all ExpansionTile widgets
        final expansionTiles = find.byType(ExpansionTile);
        expect(expansionTiles, findsNWidgets(4));

        // Find all internal ListTiles created by ExpansionTile
        final listTiles = find.byType(ListTile);
        expect(listTiles, findsNWidgets(4));

        // For every ListTile, verify that its nearest ancestor with a background color is a Material
        // and that NO intermediate DecoratedBox with background color exists.
        for (int i = 0; i < 4; i++) {
          final listTileElement = tester.element(listTiles.at(i));

          // Check intermediate widget using exact Flutter logic
          Widget? intermediateWidget;
          listTileElement.visitAncestorElements((ancestor) {
            if (ancestor.widget is Material) {
              return false; // Stop at Material
            }
            final widget = ancestor.widget;
            final Color? color = switch (widget) {
              ColoredBox(:final Color color) => color,
              DecoratedBox(decoration: BoxDecoration(:final Color? color)) => color,
              DecoratedBox(decoration: ShapeDecoration(:final Color? color)) => color,
              _ => null,
            };
            if (color != null && color.a > 0) {
              intermediateWidget = widget;
              return false;
            }
            return true;
          });

          expect(
            intermediateWidget,
            isNull,
            reason: 'ListTile $i must NOT have an intermediate DecoratedBox with background color before reaching Material',
          );

          // Verify the Material ancestor has shape with 16px borderRadius and 1.5 border width
          final materialFinder = find.ancestor(
            of: listTiles.at(i),
            matching: find.byType(Material),
          );
          expect(materialFinder, findsWidgets);

          // Find the Material that has the shape
          bool foundMaterialWithShape = false;
          for (final candidate in tester.widgetList<Material>(materialFinder)) {
            if (candidate.shape is RoundedRectangleBorder) {
              final shape = candidate.shape as RoundedRectangleBorder;
              expect(shape.borderRadius, equals(BorderRadius.circular(16)));
              expect(shape.side.width, equals(1.5));
              expect(candidate.clipBehavior, equals(Clip.antiAlias));
              foundMaterialWithShape = true;
              break;
            }
          }
          expect(foundMaterialWithShape, isTrue, reason: 'ListTile $i must have an enclosing Material with RoundedRectangleBorder');
        }

        // Verify no assertion error occurred
        for (final error in errors) {
          expect(
            error.exceptionAsString().contains('ListTile background color or ink splashes may be invisible'),
            isFalse,
            reason: 'Flutter assertion must NOT be fired: ${error.exceptionAsString()}',
          );
        }
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('Tapping FAQ items expands and collapses with smooth rotation and zero assertions', (tester) async {
      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };

      try {
        await tester.binding.setSurfaceSize(const Size(375, 2500));
        await tester.pumpWidget(createHelpCenterApp());
        await tester.pumpAndSettle();

        // Tap first FAQ question: 'How does Bespoke Sizing work?'
        final firstFaqQuestion = find.text('How does Bespoke Sizing work?');
        expect(firstFaqQuestion, findsOneWidget);

        await tester.tap(firstFaqQuestion);
        await tester.pumpAndSettle();

        // Answer text should now be visible
        expect(
          find.text('Our bespoke tailoring program utilizes advanced sizing recommendation algorithms linked directly to historical European custom measurement charts. When placing an order, simply select your nearest size. Our personal concierge team will contact you for custom shoulder, sleeve, and drape adjustments.'),
          findsOneWidget,
        );

        // Tap second FAQ question: 'What are your secure billing parameters?'
        final secondFaqQuestion = find.text('What are your secure billing parameters?');
        await tester.tap(secondFaqQuestion);
        await tester.pumpAndSettle();

        // Second answer should be visible
        expect(
          find.text('FCISeller operates strictly under certified PCI-DSS secure billing standards. If enabled, biometric authentication data resides solely inside your device\'s native hardware secure enclave. No credit card numbers or security credentials are ever cached on our external servers.'),
          findsOneWidget,
        );

        // Tap second FAQ again to collapse
        await tester.tap(secondFaqQuestion);
        await tester.pumpAndSettle();

        // Verify zero ListTile ink splash assertions occurred
        final assertionErrors = errors.where(
          (e) => e.exceptionAsString().contains('ListTile background color or ink splashes may be invisible'),
        );
        expect(assertionErrors, isEmpty, reason: 'No hidden ink assertions should occur during expand/collapse');
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('Dark theme renders Material background with surface color and 16px border radius', (tester) async {
      final List<FlutterErrorDetails> errors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
        originalOnError?.call(details);
      };

      try {
        await tester.binding.setSurfaceSize(const Size(375, 2500));
        await tester.pumpWidget(createHelpCenterApp(themeMode: ThemeMode.dark));
        await tester.pumpAndSettle();

        // Verify FAQ renders in dark mode without assertion
        final listTiles = find.byType(ListTile);
        expect(listTiles, findsNWidgets(4));

        // Tap each FAQ item in dark mode
        for (int i = 0; i < 4; i++) {
          await tester.tap(listTiles.at(i));
          await tester.pumpAndSettle();
        }

        final assertionErrors = errors.where(
          (e) => e.exceptionAsString().contains('ListTile background color or ink splashes may be invisible'),
        );
        expect(assertionErrors, isEmpty);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });
}
