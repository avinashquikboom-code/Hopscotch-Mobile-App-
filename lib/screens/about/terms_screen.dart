import 'package:flutter/material.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Terms of Service', style: TextStyle(fontSize: responsive.fontSize18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
            _buildTermsSection(context,
              'Acceptance of Terms',
              'By accessing and using AURA Couture, you accept and agree to be bound by the terms and provisions of this agreement. If you do not agree to abide by these terms, please do not use our service.',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildTermsSection(context,
              'Account Registration',
              'To access certain features of our service, you must register for an account. You agree to:\n\n• Provide accurate and complete information\n• Maintain the security of your account\n• Notify us of unauthorized access\n• Be responsible for all activities under your account',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildTermsSection(context,
              'Products and Services',
              'We strive to display accurate product information. However:\n\n• Colors may vary slightly due to monitor settings\n• Product measurements are approximate\n• We reserve the right to modify prices\n• Availability is subject to change',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildTermsSection(context,
              'Orders and Payment',
              'By placing an order, you agree to:\n\n• Provide valid payment information\n• Pay all charges for your purchases\n• Accept our cancellation and return policies\n• Confirm order details before submission',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildTermsSection(context,
              'Shipping and Delivery',
              'Shipping times are estimates and not guaranteed. We are not liable for:\n\n• Delays caused by shipping carriers\n• Lost or stolen packages after delivery\n• Customs delays for international orders',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildTermsSection(context,
              'Returns and Refunds',
              'Our return policy allows:\n\n• Returns within 30 days of delivery\n• Items must be unworn with original tags\n• Refunds processed within 7-10 business days\n• Shipping costs non-refundable',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildTermsSection(context,
              'User Conduct',
              'You agree not to:\n\n• Use the service for illegal purposes\n• Interfere with the operation of the service\n• Attempt to gain unauthorized access\n• Post harmful or inappropriate content',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildTermsSection(context,
              'Intellectual Property',
              'All content on our platform is protected by intellectual property laws. You may not:\n\n• Copy, modify, or distribute our content\n• Use our trademarks without permission\n• Reverse engineer our technology',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildTermsSection(context,
              'Limitation of Liability',
              'To the fullest extent permitted by law, we shall not be liable for:\n\n• Indirect, incidental, or consequential damages\n• Loss of profits or data\n• Service interruptions\n• Third-party actions or products',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildTermsSection(context,
              'Governing Law',
              'These terms shall be governed by and construed in accordance with the laws of India. Any disputes shall be resolved in the courts of Mumbai, Maharashtra.',
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            _buildTermsSection(context,
              'Contact Us',
              'For questions about these Terms of Service, please contact:\n\nEmail: legal@auracouture.com\nPhone: +91 1800-123-4567',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(BuildContext context, String title, String content) {
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
