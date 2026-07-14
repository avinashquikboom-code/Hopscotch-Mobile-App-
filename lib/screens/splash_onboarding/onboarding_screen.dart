import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/widgets/custom_button.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  double _pageOffset = 0.0;
  int _currentIndex = 0;

  final List<String> _imageUrls = [
    'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=1000&q=80',
    'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?auto=format&fit=crop&w=1000&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _pageOffset = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Elegant soft slate ivory light background
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Sliding Image Card Frame (Centered in upper area)
            Positioned(
              top: screenHeight * 0.02,
              left: 0,
              right: 0,
              height: screenHeight * 0.48,
              child: Stack(
                children: List.generate(3, (index) {
                  final double offsetDiff = index - _pageOffset;
                  final double opacity = (1.0 - offsetDiff.abs()).clamp(
                    0.0,
                    1.0,
                  );
                  // Dynamic subtle horizontal translation of the image inside the frame (internal parallax!)
                  final double translationX = offsetDiff * -140.0;

                  return Opacity(
                    opacity: opacity,
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width:
                            MediaQuery.of(context).size.width -
                            (responsive.spacing(AppTheme.spaceXL) * 2),
                        height: screenHeight * 0.45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xff0f172a,
                              ).withValues(alpha: 0.08),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Transform.translate(
                                offset: Offset(translationX, 0),
                                child: Transform.scale(
                                  scale:
                                      1.12, // Keeps image beautifully proportioned
                                  child: Image.network(
                                    _imageUrls[index],
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            color: const Color(0xFFE2E8F0),
                                          );
                                        },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xFFE2E8F0),
                                                    Color(0xFFCBD5E1),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.checkroom_rounded,
                                                color: const Color(0xFF94A3B8),
                                                size: responsive.iconSize(48),
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                              // Elegant subtle light gradient overlay to soften image contrast
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.15),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 2. High-Fashion Typography Panel
            Positioned(
              bottom: responsive.spacing(
                120,
              ), // Clean separation from indicators and buttons
              left: 0,
              right: 0,
              height: responsive.spacing(180),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: 3,
                itemBuilder: (context, index) {
                  final double offsetDiff = index - _pageOffset;
                  final double textOpacity = (1.0 - offsetDiff.abs() * 1.5)
                      .clamp(0.0, 1.0);
                  final double textTranslationY = offsetDiff * 32.0;

                  String subtitle, title, description;
                  switch (index) {
                    case 0:
                      subtitle = l10n.onboardingSubtitle1;
                      title = l10n.onboardingTitle1;
                      description = l10n.onboardingDesc1;
                      break;
                    case 1:
                      subtitle = l10n.onboardingSubtitle2;
                      title = l10n.onboardingTitle2;
                      description = l10n.onboardingDesc2;
                      break;
                    case 2:
                      subtitle = l10n.onboardingSubtitle3;
                      title = l10n.onboardingTitle3;
                      description = l10n.onboardingDesc3;
                      break;
                    default:
                      subtitle = '';
                      title = '';
                      description = '';
                  }

                  return Opacity(
                    opacity: textOpacity,
                    child: Transform.translate(
                      offset: Offset(0, textTranslationY),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(AppTheme.spaceXL),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: responsive.fontSize11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                            SizedBox(
                              height: responsive.spacing(AppTheme.spaceS),
                            ),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: responsive.fontSize24,
                                height: 1.1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: responsive.spacing(AppTheme.spaceM),
                            ),
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                height: 1.5,
                                fontSize: responsive.fontSize11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. Header Skip Button (Clean and dark)
            Positioned(
              top: responsive.spacing(AppTheme.spaceS),
              right: responsive.spacing(AppTheme.spaceXL),
              child: TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_completed', true);
                  if (mounted) {
                    context.go('/login');
                  }
                },
                child: Text(
                  l10n.skip,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    fontSize: responsive.fontSize11,
                  ),
                ),
              ),
            ),

            // 4. Elite Custom Footer Controls (Dots & Button)
            Positioned(
              bottom: responsive.spacing(24),
              left: responsive.spacing(AppTheme.spaceXL),
              right: responsive.spacing(AppTheme.spaceXL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Elastic Indicator Dots (Styled with Indigo colors)
                  Row(
                    children: List.generate(3, (index) {
                      final double activeDiff = (index - _pageOffset).abs();
                      final double widthFactor = (1.0 - activeDiff).clamp(
                        0.0,
                        1.0,
                      );
                      final double dotWidth = 8.0 + (16.0 * widthFactor);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(right: responsive.spacing(6)),
                        width: dotWidth,
                        height: responsive.spacing(8),
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? AppTheme.primaryColor
                              : AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(
                            responsive.spacing(4),
                          ),
                        ),
                      );
                    }),
                  ),
                  // Premium Indigo Styled Navigation Button
                  SizedBox(
                    width: responsive.spacing(135),
                    child: CustomButton(
                      text: _currentIndex == 2
                          ? l10n.begin
                          : l10n.next,
                      onPressed: () {
                        if (_currentIndex < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.fastOutSlowIn,
                          );
                        } else {
                          context.go('/login');
                        }
                      },
                      isFullWidth: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
