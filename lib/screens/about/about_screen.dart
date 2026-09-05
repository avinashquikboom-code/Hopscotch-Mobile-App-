import 'package:flutter/material.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
        : AppTheme.surfaceColor;
    final cardBorder = isDark
        ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
        : AppTheme.borderColor;
    final primaryTextColor = isDark
        ? Theme.of(context).colorScheme.onSurface
        : AppTheme.textPrimaryColor;
    final secondaryTextColor = isDark
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
        : AppTheme.textSecondaryColor;
    final lightTextColor = isDark
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
        : AppTheme.textLightColor;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'About Us',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: responsive.spacing(100),
                    height: responsive.spacing(100),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      boxShadow: isDark
                          ? AppTheme.darkIntenseShadow
                          : AppTheme.intenseShadow,
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: responsive.spacing(72),
                          height: responsive.spacing(72),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                  Text(
                    'FCI SELLER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: responsive.fontSize18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: primaryTextColor,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                  Text(
                    'Premium Fashion Destination',
                    style: responsive.bodyMedium.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            // Version
            Container(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                border: Border.all(color: cardBorder, width: 1.5),
                boxShadow: isDark ? null : AppTheme.softShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'App Version',
                    style: responsive.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: primaryTextColor,
                    ),
                  ),
                  Text(
                    '1.0.0',
                    style: responsive.bodyMedium.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            // About Content
            _buildSectionCard(
              context,
              'Our Story',
              'FCI Seller was born from a passion for fashion and a commitment to quality. We believe that everyone deserves access to premium fashion that makes them feel confident and beautiful. Our curated collection features the finest designs from around the world, carefully selected to meet the highest standards of style and quality.',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildSectionCard(
              context,
              'Our Mission',
              'To provide an exceptional shopping experience by offering premium fashion at accessible prices, while maintaining the highest standards of quality and customer service. We strive to make fashion inclusive and empowering for everyone.',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildSectionCard(
              context,
              'Our Values',
              'Quality: We never compromise on quality.\nCustomer First: Your satisfaction is our priority.\nSustainability: We care about our planet.\nInnovation: We constantly evolve to serve you better.',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            // Contact Info
            Text(
              'Get in Touch',
              style: TextStyle(
                fontSize: responsive.fontSize16,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            _buildContactItem(
              context,
              Icons.email_outlined,
              'fashioncityinidia18@gmail.com',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            _buildContactItem(
              context,
              Icons.phone_outlined,
              '+91 1800-123-4567',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            _buildContactItem(
              context,
              Icons.language_outlined,
              'www.fciseller.com',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            // Social Links
            Text(
              'Follow Us',
              style: TextStyle(
                fontSize: responsive.fontSize16,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            Row(
              children: [
                _buildSocialButton(context, Icons.facebook_outlined),
                SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                _buildSocialButton(context, Icons.camera_alt_outlined),
                SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                _buildSocialButton(context, Icons.alternate_email),
                SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                _buildSocialButton(context, Icons.play_circle_outline),
              ],
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            // Copyright
            Center(
              child: Text(
                '© 2026 FCI Seller. All rights reserved.',
                style: responsive.bodySmall.copyWith(
                  color: lightTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, String content) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
        : AppTheme.surfaceColor;
    final cardBorder = isDark
        ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
        : AppTheme.borderColor;
    final secondaryTextColor = isDark
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75)
        : AppTheme.textSecondaryColor;

    return Container(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: isDark ? null : AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: responsive.fontSize12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          Text(
            content,
            style: responsive.bodyMedium.copyWith(
              color: secondaryTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String text) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
        : AppTheme.surfaceColor;
    final cardBorder = isDark
        ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
        : AppTheme.borderColor;
    final primaryTextColor = isDark
        ? Theme.of(context).colorScheme.onSurface
        : AppTheme.textPrimaryColor;

    return Container(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceM)),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: responsive.iconSize(20),
          ),
          SizedBox(width: responsive.spacing(AppTheme.spaceM)),
          Text(
            text,
            style: responsive.bodyMedium.copyWith(
              color: primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, IconData icon) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
        : AppTheme.surfaceColor;
    final cardBorder = isDark
        ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
        : AppTheme.borderColor;

    return Container(
      width: responsive.spacing(50),
      height: responsive.spacing(50),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Icon(
        icon,
        color: AppTheme.primaryColor,
        size: responsive.iconSize(24),
      ),
    );
  }
}
