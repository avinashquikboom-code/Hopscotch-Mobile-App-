import 'package:flutter/material.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Privacy Policy', style: TextStyle(fontSize: responsive.fontSize18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: responsive.fontSize24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceS)),
            Text(
              'Last updated: January 2024',
              style: responsive.bodySmall.copyWith(
                color: AppTheme.textLightColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            _buildPolicySection(context,
              'Information We Collect',
              'We collect information you provide directly to us, such as when you create an account, make a purchase, or communicate with us. This includes:\n\n• Personal information (name, email, phone, address)\n• Payment information (processed securely)\n• Shopping preferences and order history\n• Device and usage information',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildPolicySection(context,
              'How We Use Your Information',
              'We use the information we collect to:\n\n• Process and fulfill your orders\n• Send you order confirmations and updates\n• Provide customer support\n• Personalize your shopping experience\n• Send promotional communications (with your consent)\n• Improve our services and develop new features',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildPolicySection(context,
              'Information Sharing',
              'We do not sell your personal information. We may share your information with:\n\n• Service providers who assist in operating our business\n• Shipping partners to deliver your orders\n• Payment processors to process transactions\n• When required by law or to protect our rights',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildPolicySection(context,
              'Data Security',
              'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. This includes:\n\n• SSL encryption for data transmission\n• Secure payment processing\n• Regular security audits\n• Access controls and authentication',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildPolicySection(context,
              'Your Rights',
              'You have the right to:\n\n• Access your personal information\n• Correct inaccurate information\n• Request deletion of your information\n• Opt-out of marketing communications\n• Object to processing of your information',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildPolicySection(context,
              'Cookies and Tracking',
              'We use cookies and similar technologies to:\n\n• Remember your preferences\n• Analyze website traffic\n• Personalize content and ads\n• You can control cookies through your browser settings',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildPolicySection(context,
              'Changes to This Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last updated" date.',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            _buildPolicySection(context,
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n\nEmail: privacy@auracouture.com\nPhone: +91 1800-123-4567',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(BuildContext context, String title, String content) {
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.softShadow,
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
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
