import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/widgets/main_shell.dart';
import 'package:hopscotch/routes/app_routes.dart';

// Splash & Onboarding
import 'package:hopscotch/screens/splash_onboarding/splash_screen.dart';
import 'package:hopscotch/screens/splash_onboarding/language_selection_screen.dart';
import 'package:hopscotch/screens/splash_onboarding/currency_selection_screen.dart';
import 'package:hopscotch/screens/splash_onboarding/onboarding_screen.dart';

// Auth
import 'package:hopscotch/screens/auth/login_screen.dart';
import 'package:hopscotch/screens/auth/signup_screen.dart';
import 'package:hopscotch/screens/auth/forgot_password_screen.dart';

// Shell Tabs
import 'package:hopscotch/screens/home/home_screen.dart';
import 'package:hopscotch/screens/categories/categories_screen.dart';
import 'package:hopscotch/screens/wishlist/wishlist_screen.dart';
import 'package:hopscotch/screens/cart/cart_screen.dart';
import 'package:hopscotch/screens/profile/profile_screen.dart';

// Secondary standalone pages
import 'package:hopscotch/screens/product/product_listing_screen.dart';
import 'package:hopscotch/screens/product/product_detail_screen.dart';
import 'package:hopscotch/screens/product/search_screen.dart';
import 'package:hopscotch/screens/checkout/checkout_screen.dart';
import 'package:hopscotch/screens/checkout/order_success_screen.dart';
import 'package:hopscotch/screens/profile/my_orders_screen.dart';
import 'package:hopscotch/screens/profile/notifications_screen.dart';
import 'package:hopscotch/screens/profile/settings_screen.dart';
import 'package:hopscotch/screens/profile/edit_profile_screen.dart';
import 'package:hopscotch/screens/profile/help_center_screen.dart';
import 'package:hopscotch/screens/profile/legal_policies_screen.dart';

// New screens
import 'package:hopscotch/screens/offers/offers_screen.dart';
import 'package:hopscotch/screens/coupons/coupons_screen.dart';
import 'package:hopscotch/screens/orders/track_order_screen.dart';
import 'package:hopscotch/screens/address/addresses_screen.dart';
import 'package:hopscotch/screens/about/about_screen.dart';
import 'package:hopscotch/screens/about/privacy_policy_screen.dart';
import 'package:hopscotch/screens/about/terms_screen.dart';
import 'package:hopscotch/screens/about/contact_us_screen.dart';
import 'dart:io';
import 'package:hopscotch/screens/visual_search/visual_search_preview_screen.dart';
import 'package:hopscotch/screens/visual_search/visual_search_results_screen.dart';
import 'package:hopscotch/visual_search/domain/entities/visual_search_result.dart';
import 'package:hopscotch/core/session_manager.dart';

class AppPages {
  static final List<RouteBase> _routes = [
      // Root redirect to Home
      GoRoute(
        path: '/',
        redirect: (context, state) => AppRoutes.home,
      ),
      // 1. Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),

      // 2. Language Selection Screen
      GoRoute(
        path: AppRoutes.languageSelection,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LanguageSelectionScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),

      // 3. Currency Selection Screen
      GoRoute(
        path: AppRoutes.currencySelection,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CurrencySelectionScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),

      // 4. Onboarding Screen
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),

      // 3. Authentication
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignupScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),

      // 4. Shell Navigation Scaffolding (Home, Categories, Wishlist, Cart, Profile)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionDuration: const Duration(milliseconds: 350),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: AppRoutes.categories,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const CategoriesScreen(),
              transitionDuration: const Duration(milliseconds: 350),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: AppRoutes.wishlist,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const WishlistScreen(),
              transitionDuration: const Duration(milliseconds: 350),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: AppRoutes.cart,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const CartScreen(),
              transitionDuration: const Duration(milliseconds: 350),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionDuration: const Duration(milliseconds: 350),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
        ],
      ),

      // 5. Standalone / Detailed screens
      GoRoute(
        path: AppRoutes.products,
        pageBuilder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          final subcategory = state.uri.queryParameters['subcategory'];
          final filter = state.uri.queryParameters['filter'];
          final categoryName = state.uri.queryParameters['categoryName'] ?? 'Elite Clothing';
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: ProductListingScreen(
              categoryId: categoryId,
              subcategory: subcategory,
              filter: filter,
              categoryName: categoryName,
            ),
            transitionDuration: const Duration(milliseconds: 450),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final heroTagPrefix = state.uri.queryParameters['heroTagPrefix'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: ProductDetailScreen(productId: id, heroTagPrefix: heroTagPrefix),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.visualSearchPreview,
        pageBuilder: (context, state) {
          final file = state.extra as File;
          return CustomTransitionPage(
            key: state.pageKey,
            child: VisualSearchPreviewScreen(image: file),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.visualSearchResults,
        pageBuilder: (context, state) {
          final result = state.extra as VisualSearchResult;
          return CustomTransitionPage(
            key: state.pageKey,
            child: VisualSearchResultsScreen(result: result),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.checkout,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CheckoutScreen(),
          transitionDuration: const Duration(milliseconds: 450),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        pageBuilder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? 'ORD-000000';
          return CustomTransitionPage(
            key: state.pageKey,
            child: OrderSuccessScreen(orderId: orderId),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myOrders,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MyOrdersScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.helpCenter,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HelpCenterScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.legalPolicies,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LegalPoliciesScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      // New screens
      GoRoute(
        path: AppRoutes.offers,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OffersScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.coupons,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CouponsScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.trackOrder,
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? 'ORD-000000';
          return CustomTransitionPage(
            key: state.pageKey,
            child: TrackOrderScreen(orderId: orderId),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.addresses,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AddressesScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.about,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AboutScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.terms,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TermsScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.contactUs,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ContactUsScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
  ];

  static late final GoRouter router;

  static void init(StartupState startupState) {
    String initialLoc;
    switch (startupState) {
      case StartupState.onboarding:
        initialLoc = AppRoutes.onboarding;
        break;
      case StartupState.login:
        initialLoc = AppRoutes.login;
        break;
      case StartupState.home:
        initialLoc = AppRoutes.home;
        break;
    }

    router = GoRouter(
      initialLocation: initialLoc,
      routes: _routes,
      redirect: (context, state) {
        final loc = state.uri.toString();
        final isLoggedIn = SessionManager.sessionActiveSync;
        final isOnboarded = SessionManager.onboardingDoneSync;

        final onAuthPages =
            loc == AppRoutes.login || 
            loc == AppRoutes.signup || 
            loc == AppRoutes.forgotPassword || 
            loc == AppRoutes.onboarding ||
            loc == AppRoutes.splash;

        if (!isOnboarded && loc != AppRoutes.onboarding) return AppRoutes.onboarding;
        if (isOnboarded && !isLoggedIn && !onAuthPages) return AppRoutes.login;
        if (isLoggedIn && (loc == AppRoutes.login || loc == AppRoutes.signup || loc == AppRoutes.onboarding)) return AppRoutes.home;
        return null;
      },
    );
  }
}
