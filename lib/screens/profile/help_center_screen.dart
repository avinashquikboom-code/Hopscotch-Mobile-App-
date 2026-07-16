import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/widgets/fade_in_animation.dart';
import 'package:hopscotch/widgets/toast_notification.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? _expandedFaqIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How does Bespoke Sizing work?',
      'answer':
          'Our bespoke tailoring program utilizes advanced sizing recommendation algorithms linked directly to historical European custom measurement charts. When placing an order, simply select your nearest size. Our personal concierge team will contact you for custom shoulder, sleeve, and drape adjustments.',
    },
    {
      'question': 'What are your secure billing parameters?',
      'answer':
          'Aura Couture operates strictly under certified PCI-DSS secure billing standards. If enabled, biometric authentication data resides solely inside your device\'s native hardware secure enclave. No credit card numbers or security credentials are ever cached on our external servers.',
    },
    {
      'question': 'What is your insured courier logistics timeline?',
      'answer':
          'All garments are meticulously hand-wrapped and dispatched with elite, fully-insured couriers (such as DHL Express or FedEx Priority). Shipping generally takes 1-3 business days. All dispatches include full end-to-end tracking references and signature delivery requirements.',
    },
    {
      'question': 'Are custom garments returnable?',
      'answer':
          'Because our garments are adjusted to individual client measurements, we do not accept standard returns on bespoke tailored items. However, we offer an elite styling guarantee: if a garment does not fit to your absolute satisfaction, we provide complimentary custom adjustment alterations at any of our partner ateliers.',
    },
  ];

  final List<Map<String, dynamic>> _contactOptions = [
    {
      'icon': Icons.chat_bubble_outline,
      'title': 'Live Chat',
      'subtitle': 'Chat with our support team',
      'color': AppTheme.primaryColor,
    },
    {
      'icon': Icons.phone_outlined,
      'title': 'Call Us',
      'subtitle': '+1 (800) 123-4567',
      'color': Colors.green,
    },
    {
      'icon': Icons.email_outlined,
      'title': 'Email',
      'subtitle': 'support@auracouture.com',
      'color': Colors.blue,
    },
    {
      'icon': Icons.location_on_outlined,
      'title': 'Visit Store',
      'subtitle': 'Find nearest location',
      'color': Colors.orange,
    },
  ];

  void _handleContactOption(String title) {
    ToastNotification.show(
      context,
      message: 'Opening $title...',
      isError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'HELP CENTER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: responsive.fontSize18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: responsive.iconSize(24)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            FadeInAnimation(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'How can we help you?',
                style: TextStyle(
                  fontSize: responsive.fontSize24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceS)),
            FadeInAnimation(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'Choose a topic or search for help',
                style: TextStyle(
                  fontSize: responsive.fontSize14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

            // Contact Options Grid
            FadeInAnimation(
              delay: const Duration(milliseconds: 300),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: responsive.spacing(AppTheme.spaceM),
                  mainAxisSpacing: responsive.spacing(AppTheme.spaceM),
                ),
                itemCount: _contactOptions.length,
                itemBuilder: (context, index) {
                  final option = _contactOptions[index];
                  return GestureDetector(
                    onTap: () => _handleContactOption(option['title']),
                    child: Container(
                      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceM)),
                            decoration: BoxDecoration(
                              color: option['color'].withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              option['icon'],
                              color: option['color'],
                              size: responsive.iconSize(24),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                          Text(
                            option['title'],
                            style: TextStyle(
                              fontSize: responsive.fontSize14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(4)),
                          Expanded(
                            child: Text(
                              option['subtitle'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: responsive.fontSize11,
                                color: AppTheme.textSecondaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

            // FAQ Section
            FadeInAnimation(
              delay: const Duration(milliseconds: 400),
              child: Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: TextStyle(
                  fontSize: responsive.fontSize16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),

            // FAQ List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqs.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: responsive.spacing(AppTheme.spaceM)),
              itemBuilder: (context, index) {
                final faq = _faqs[index];
                final isExpanded = _expandedFaqIndex == index;

                return FadeInAnimation(
                  delay: Duration(milliseconds: 500 + (index * 100)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(AppTheme.spaceL),
                        vertical: responsive.spacing(AppTheme.spaceS),
                      ),
                      childrenPadding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(AppTheme.spaceL),
                        vertical: responsive.spacing(AppTheme.spaceM),
                      ),
                      title: Text(
                        faq['question']!,
                        style: TextStyle(
                          fontSize: responsive.fontSize14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      trailing: AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: isExpanded ? 0.5 : 0.0,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expandedFaqIndex = expanded ? index : null;
                        });
                      },
                      children: [
                        Text(
                          faq['answer']!,
                          style: TextStyle(
                            fontSize: responsive.fontSize13,
                            height: 1.5,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
          ],
        ),
      ),
    );
  }
}
