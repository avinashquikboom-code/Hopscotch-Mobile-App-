import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/providers/policy_provider.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

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

    final policyAsync = ref.watch(policyDetailProvider('privacy-policy'));

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
              : 'Official Privacy Policy';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(policyDetailProvider('privacy-policy'));
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
            'Privacy Policy',
            style: TextStyle(
              fontSize: responsive.fontSize24,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceS)),
          Text(
            'Official Store Policy',
            style: responsive.bodySmall.copyWith(
              color: lightTextColor,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
          _buildPolicySection(
            context,
            'Information We Collect',
            'Fashion City India Ltd collects personal details provided during order checkout, account registration, and customer service requests, including your name, delivery address, contact details, and transaction references.',
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceL)),
          _buildPolicySection(
            context,
            'How We Use Your Information',
            'Your data is utilized strictly to fulfill orders, coordinate couriers, provide shipment tracking notifications, prevent fraud, and assist with returns or exchanges.',
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceL)),
          _buildPolicySection(
            context,
            'Data Protection & Security',
            'We implement standard encryption (TLS/SSL) and restricted databases to safeguard your personal credentials. We do not sell or monetize personal customer details.',
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceL)),
          _buildPolicySection(
            context,
            'Contact & Grievance Redressal',
            'Fashion City India Ltd\nF/7 Jethabhai Park, Narayan Nagar Road, Paldi, Ahmedabad, Gujarat - 380007, India\nGSTIN: 24GUKPS9446A1ZA\nEmail: fashioncityinidia18@gmail.com\nPhone: +91 96015 11596',
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
        ],
      ),
    );
  }

  Widget _buildPolicySection(BuildContext context, String title, String content) {
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
