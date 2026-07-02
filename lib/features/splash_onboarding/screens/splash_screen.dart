import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final languageCode = prefs.getString('language_code');
        final currencyCode = prefs.getString('currency_code');
        final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
        
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
          // All completed, go to home
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
                          'AURA COUTURE',
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
