import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/providers/policy_provider.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';

class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? Theme.of(context).colorScheme.onSurface
        : AppTheme.textPrimaryColor;
    final lightTextColor = isDark
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
        : AppTheme.textLightColor;

    final policyAsync = ref.watch(policyDetailProvider('terms-and-conditions'));

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Terms of Service',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: policyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (err, _) => _buildFallbackContent(context, responsive, primaryTextColor, lightTextColor),
        data: (policy) {
          if (policy == null || policy.content.isEmpty) {
            return _buildFallbackContent(context, responsive, primaryTextColor, lightTextColor);
          }

          final updatedStr = policy.updatedAt != null
              ? 'Last updated: ${policy.updatedAt!.day}/${policy.updatedAt!.month}/${policy.updatedAt!.year}'
              : 'Official Terms of Service';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(policyDetailProvider('terms-and-conditions'));
            },
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policy.title,
                    style: TextStyle(
                      fontSize: responsive.fontSize24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                  Text(
                    updatedStr,
                    style: responsive.bodySmall.copyWith(
                      color: lightTextColor,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                          : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(
                        color: isDark
                            ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
                            : AppTheme.borderColor,
                        width: 1.5,
                      ),
                      boxShadow: isDark ? null : AppTheme.softShadow,
                    ),
                    child: Text(
                      policy.plainTextContent,
                      style: responsive.bodyMedium.copyWith(
                        color: isDark
                            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)
                            : AppTheme.textSecondaryColor,
                        height: 1.65,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallbackContent(
    BuildContext context,
    dynamic responsive,
    Color primaryTextColor,
    Color lightTextColor,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms of Service',
            style: TextStyle(
              fontSize: responsive.fontSize24,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceS)),
          Text(
            'Official Terms and Conditions',
            style: responsive.bodySmall.copyWith(
              color: lightTextColor,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
          _buildTermsSection(
            context,
            'Acceptance of Terms',
            'By accessing and using the Fashion City India Ltd platform, you accept and agree to be bound by these Terms and Conditions. If you do not agree to abide by these terms, please do not use our service.',
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceL)),
          _buildTermsSection(
            context,
            'Account Registration',
            'To access certain features of our service, you must register for an account. You agree to provide accurate and complete information, maintain account credentials securely, and notify us of unauthorized access.',
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceL)),
          _buildTermsSection(
            context,
            'Products, Pricing & Availability',
            'All prices listed are in Indian Rupees (INR) and inclusive of applicable Goods and Services Tax (GSTIN: 24GUKPS9446A1ZA). We reserve the right to correct typographical pricing errors.',
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceL)),
          _buildTermsSection(
            context,
            'Governing Law & Jurisdiction',
            'These terms shall be governed by and construed in accordance with the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts in Ahmedabad, Gujarat, India.',
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
          _buildTermsSection(
            context,
            'Contact Information',
            'Fashion City India Ltd\nF/7 Jethabhai Park, Narayan Nagar Road, Paldi, Ahmedabad, Gujarat - 380007, India\nEmail: fashioncityinidia18@gmail.com\nPhone: +91 96015 11596',
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
        ],
      ),
    );
  }

  Widget _buildTermsSection(BuildContext context, String title, String content) {
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
      width: double.infinity,
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
              fontSize: responsive.fontSize14,
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
}
