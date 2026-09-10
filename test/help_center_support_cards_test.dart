import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/screens/profile/help_center_screen.dart';
import 'package:hopscotch/constants/seller_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createHelpCenterApp({
    ThemeMode themeMode = ThemeMode.light,
    Size size = const Size(375, 812),
  }) {
    return ProviderScope(
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(surface: Color(0xFFFFFFFF)),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(surface: Color(0xFF1E293B)),
        ),
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const HelpCenterScreen(),
        ),
      ),
    );
  }

  group('Help Center Support Cards Alignment & Centering Tests', () {
    testWidgets('Renders all 4 support cards with correct titles, descriptions, and icons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(createHelpCenterApp());
      await tester.pumpAndSettle();

      // Verify all 4 card titles
      expect(find.text('Live Chat'), findsOneWidget);
      expect(find.text('Call Us'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Visit Store'), findsOneWidget);

      // Verify descriptions / support info
      expect(find.text('Chat with our support team'), findsOneWidget);
      expect(find.text(SellerConfig.contactNumber), findsOneWidget);
      expect(find.text(SellerConfig.supportEmail), findsOneWidget);
      expect(find.text('${SellerConfig.city}, ${SellerConfig.state}'), findsOneWidget);

      // Verify 4 SupportCard widgets exist
      expect(find.byType(SupportCard), findsNWidgets(4));
    });

    testWidgets('Icon containers have identical vertical position in same row and proper top spacing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(createHelpCenterApp());
      await tester.pumpAndSettle();

      final icons = [
        Icons.chat_bubble_outline,
        Icons.phone_outlined,
        Icons.email_outlined,
        Icons.location_on_outlined,
      ];

      final cardRects = <Rect>[];
      final iconRects = <Rect>[];

      for (int i = 0; i < icons.length; i++) {
        final cardFinder = find.byType(SupportCard).at(i);
        final iconFinder = find.byIcon(icons[i]);

        final cardRect = tester.getRect(cardFinder);
        final iconRect = tester.getRect(iconFinder);

        cardRects.add(cardRect);
        iconRects.add(iconRect);

        // 1. Icon must be horizontally centered within the card
        final cardCenterX = cardRect.center.dx;
        final iconCenterX = iconRect.center.dx;
        expect((cardCenterX - iconCenterX).abs(), lessThan(2.0),
            reason: 'Card $i icon should be horizontally centered within card');

        // 2. Icon must NOT touch top edge: top spacing must be > 10px
        final topSpacing = iconRect.top - cardRect.top;
        expect(topSpacing, greaterThan(12.0),
            reason: 'Card $i icon must have visible breathing room from top edge (actual: $topSpacing)');

        // 3. Icon must be completely inside the card bounds
        expect(iconRect.top, greaterThan(cardRect.top));
        expect(iconRect.bottom, lessThan(cardRect.bottom));
      }

      // 4. Row 1 (Live Chat & Call Us) must have identical icon Y-coordinate
      expect((iconRects[0].top - iconRects[1].top).abs(), lessThan(1.0),
          reason: 'Row 1 icons (Live Chat & Call Us) must have identical vertical Y-coordinate');

      // 5. Row 2 (Email & Visit Store) must have identical icon Y-coordinate
      expect((iconRects[2].top - iconRects[3].top).abs(), lessThan(1.0),
          reason: 'Row 2 icons (Email & Visit Store) must have identical vertical Y-coordinate');

      // 6. Relative top spacing inside card must be identical between Row 1 and Row 2
      final topOffsetRow1 = iconRects[0].top - cardRects[0].top;
      final topOffsetRow2 = iconRects[2].top - cardRects[2].top;
      expect((topOffsetRow1 - topOffsetRow2).abs(), lessThan(1.0),
          reason: 'Internal top spacing must be identical across both rows ($topOffsetRow1 vs $topOffsetRow2)');
    });

    // Test all 9 screen widths requested in the specification
    const screenWidths = [320.0, 360.0, 375.0, 390.0, 412.0, 430.0, 480.0, 600.0, 768.0];

    for (final width in screenWidths) {
      testWidgets('Responsive test at ${width.toInt()}px width: perfectly centered, no overflow', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 850));
        await tester.pumpWidget(createHelpCenterApp(size: Size(width, 850)));
        await tester.pumpAndSettle();

        // Must find all 4 cards without overflow
        expect(find.byType(SupportCard), findsNWidgets(4));
        expect(tester.takeException(), isNull);

        // Verify icons remain centered and properly spaced from top edge
        final card1Finder = find.byType(SupportCard).at(0);
        final card1Rect = tester.getRect(card1Finder);
        final icon1Finder = find.byIcon(Icons.chat_bubble_outline);
        final icon1Rect = tester.getRect(icon1Finder);

        expect((card1Rect.center.dx - icon1Rect.center.dx).abs(), lessThan(2.0));
        expect(icon1Rect.top - card1Rect.top, greaterThan(10.0));
      });
    }

    testWidgets('Dark mode test: renders cleanly without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createHelpCenterApp(themeMode: ThemeMode.dark, size: const Size(390, 844)));
      await tester.pumpAndSettle();

      expect(find.byType(SupportCard), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping support cards triggers click callback without errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(createHelpCenterApp());
      await tester.pumpAndSettle();

      // Tap Live Chat
      await tester.tap(find.text('Live Chat'));
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);

      // Tap Call Us
      await tester.tap(find.text('Call Us'));
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });
  });
}
