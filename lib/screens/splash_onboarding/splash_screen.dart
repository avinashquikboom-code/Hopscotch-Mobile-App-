import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/repositories/profile_repository.dart';
import 'package:hopscotch/core/session_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hopscotch/utils/dev_logger.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Check if language and currency are already selected and navigate accordingly
    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (!mounted) return;

      // Ask for location, camera, storage, and photo permissions when app installs/first launch
      try {
        await [
          Permission.location,
          Permission.camera,
          Permission.storage,
          Permission.photos,
        ].request();
      } catch (e) {
        DevLogger.logError('Error requesting runtime permissions: $e', context: 'Splash');
      }

      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      
      final languageCode = prefs.getString('language_code');
      final currencyCode = prefs.getString('currency_code');
      final onboardingCompleted = await SessionManager.isOnboardingDone();
      
      if (languageCode == null) {
        // Language not selected, go to language selection
        context.go('/language-selection');
      } else if (currencyCode == null) {
        // Language selected but currency not selected, go to currency selection
        context.go('/currency-selection');
      } else if (!onboardingCompleted) {
        // Both language and currency selected but onboarding not completed
        context.go('/onboarding');
      } else {
        // All onboarding completed, restore session silently if a token was saved previously
        final apiService = ref.read(apiServiceProvider);
        final loggedIn = await apiService.isLoggedIn();
        if (!mounted) return;
        
        if (loggedIn) {
          final restored = await apiService.restoreSession();
          if (!mounted) return;
          
          if (restored) {
            // Preload profile data so all home screen components are ready
            await ref.read(profileNotifierProvider.notifier).loadProfile();
            if (!mounted) return;
            context.go('/home');
          } else {
            // Token exists but is invalid/expired and refresh failed. Redirect to login.
            context.go('/login');
          }
        } else {
          // Not logged in (guest flow)
          context.go('/home');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Premium light ivory background matching Onboarding
      body: Stack(
        children: [
          // Elegant Centerpiece: Luxury Serif Monogram & High-Fashion Slogan
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ultra-Fine Gold Line Circular Monogram
                        Container(
                          width: responsive.spacing(100),
                          height: responsive.spacing(100),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFC59F3E).withValues(
                                alpha: 0.35,
                              ), // Delicate champagne gold
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: const Color(
                                0xFFC59F3E,
                              ), // Pure luxury gold
                              fontSize: responsive.fontSize48,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                        // Crisp Minimal Typography
                        Text(
                          'FCI SELLER',
                          style: TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: responsive.fontSize32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6.0,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                        Text(
                          'THE EPITOME OF PREMIUM FASHION',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: responsive.fontSize10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Subtle Fine-Line Linear Loading Indicator (luxury and slow)
          Positioned(
            bottom: responsive.spacing(60),
            left: responsive.spacing(80),
            right: responsive.spacing(80),
            child: Opacity(
              opacity: 0.35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: const SizedBox(
                  height: 1.0,
                  child: LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFC59F3E),
                    ),
                    backgroundColor: Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
