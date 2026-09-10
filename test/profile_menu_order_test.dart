import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/screens/profile/profile_screen.dart';
import 'package:hopscotch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoRouter createTestRouter() {
    return GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/my-orders',
          builder: (context, state) => const Scaffold(body: Text('Orders Destination Screen')),
        ),
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const Scaffold(body: Text('Wallet Destination Screen')),
        ),
        GoRoute(
          path: '/loyalty-hub',
          builder: (context, state) => const Scaffold(body: Text('Loyalty Hub Screen')),
        ),
        GoRoute(
          path: '/addresses',
          builder: (context, state) => const Scaffold(body: Text('Addresses Screen')),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const Scaffold(body: Text('Notifications Screen')),
        ),
      ],
    );
  }

  Widget createTestProfileApp({
    required GoRouter router,
    Size size = const Size(375, 2500),
  }) {
    return ProviderScope(
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    );
  }

  group('Profile Screen Menu Order Tests', () {
    testWidgets('Menu items order: Reward Settings -> Order History -> My Wallet -> Saved Addresses -> Notifications', (tester) async {
      final router = createTestRouter();
      await tester.binding.setSurfaceSize(const Size(375, 2500));
      await tester.pumpWidget(createTestProfileApp(router: router));
      await tester.pumpAndSettle();

      // Find each item title
      final rewardSettingsFinder = find.text('Reward Settings');
      final orderHistoryFinder = find.text('Order History');
      final myWalletFinder = find.text('My Wallet');
      final savedAddressesFinder = find.text('Saved Addresses');
      final notificationsFinder = find.text('Notifications');

      // Verify all exist in the menu
      expect(rewardSettingsFinder, findsOneWidget);
      expect(orderHistoryFinder, findsOneWidget, reason: 'There must be exactly ONE Order History item');
      expect(myWalletFinder, findsOneWidget, reason: 'There must be exactly ONE My Wallet item in menu');
      expect(savedAddressesFinder, findsOneWidget);
      expect(notificationsFinder, findsOneWidget);

      // Verify exact vertical positions (Y-coordinates)
      final rewardSettingsY = tester.getRect(rewardSettingsFinder).top;
      final orderHistoryY = tester.getRect(orderHistoryFinder).top;
      final myWalletY = tester.getRect(myWalletFinder).top;
      final savedAddressesY = tester.getRect(savedAddressesFinder).top;
      final notificationsY = tester.getRect(notificationsFinder).top;

      // 1. Reward Settings is above Order History
      expect(
        rewardSettingsY,
        lessThan(orderHistoryY),
        reason: 'Reward Settings must appear above Order History',
      );

      // 2. Order History is immediately above My Wallet
      expect(
        orderHistoryY,
        lessThan(myWalletY),
        reason: 'Order History must appear directly above My Wallet',
      );

      // 3. My Wallet is immediately above Saved Addresses
      expect(
        myWalletY,
        lessThan(savedAddressesY),
        reason: 'My Wallet must appear directly above Saved Addresses',
      );

      // 4. Saved Addresses is above Notifications
      expect(
        savedAddressesY,
        lessThan(notificationsY),
        reason: 'Saved Addresses must appear above Notifications',
      );
    });

    testWidgets('Order History navigates to /my-orders on tap', (tester) async {
      final router = createTestRouter();
      await tester.binding.setSurfaceSize(const Size(375, 2500));
      await tester.pumpWidget(createTestProfileApp(router: router));
      await tester.pumpAndSettle();

      final orderHistoryFinder = find.text('Order History');
      expect(orderHistoryFinder, findsOneWidget);

      await tester.tap(orderHistoryFinder);
      await tester.pumpAndSettle();

      expect(find.text('Orders Destination Screen'), findsOneWidget);
    });

    testWidgets('My Wallet navigates to /wallet on tap', (tester) async {
      final router = createTestRouter();
      await tester.binding.setSurfaceSize(const Size(375, 2500));
      await tester.pumpWidget(createTestProfileApp(router: router));
      await tester.pumpAndSettle();

      final myWalletFinder = find.text('My Wallet');
      expect(myWalletFinder, findsOneWidget);

      await tester.tap(myWalletFinder);
      await tester.pumpAndSettle();

      expect(find.text('Wallet Destination Screen'), findsOneWidget);
    });

    testWidgets('Responsive layouts on 320px, 360px, 375px, 390px, 412px, 430px, 768px without errors', (tester) async {
      final widths = [320.0, 360.0, 375.0, 390.0, 412.0, 430.0, 768.0];

      for (final width in widths) {
        final router = createTestRouter();
        await tester.binding.setSurfaceSize(Size(width, 2500));
        await tester.pumpWidget(createTestProfileApp(router: router, size: Size(width, 2500)));
        await tester.pumpAndSettle();

        expect(find.text('Order History'), findsOneWidget);
        expect(find.text('My Wallet'), findsOneWidget);

        final orderHistoryY = tester.getRect(find.text('Order History')).top;
        final myWalletY = tester.getRect(find.text('My Wallet')).top;

        expect(
          orderHistoryY,
          lessThan(myWalletY),
          reason: 'Order History must be above My Wallet at width $width',
        );
      }
    });
  });
}
