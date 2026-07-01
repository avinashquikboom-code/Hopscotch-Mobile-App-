import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_text.dart';
import '../../../core/widgets/custom_button.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  // Keeps track of which FAQ card is currently expanded
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

  void _triggerConciergeAction(String action) {
    final responsive = context.responsive;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$action... 📞',
          style: TextStyle(fontSize: responsive.fontSize14),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Premium light ivory canvas
      appBar: AppBar(
        title: Text(
          'COUTURE CONCIERGE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: responsive.fontSize14,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: responsive.iconSize(24)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Personal Stylist Header Card
            Container(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: responsive.iconSize(30),
                            backgroundColor: AppTheme.primaryColor.withValues(
                              alpha: 0.08,
                            ),
                            backgroundImage: const NetworkImage(
                              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: responsive.spacing(12),
                              height: responsive.spacing(12),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: responsive.spacing(AppTheme.spaceL)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aria Sterling',
                              style: TextStyle(
                                fontSize: responsive.fontSize18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            SizedBox(height: responsive.spacing(2)),
                            Text(
                              'Elite Personal Stylist',
                              style: TextStyle(
                                fontSize: responsive.fontSize12,
                                color: AppTheme.textSecondaryColor.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                  Text(
                    'Our dedicated global styling concierges are available 24/7 to assist with bespoke sizing, order adjustments, or private key security.',
                    style: TextStyle(
                      fontSize: responsive.fontSize12,
                      height: 1.5,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: responsive.spacing(56),
                          child: CustomButton(
                            text: 'CHAT NOW',
                            onPressed: () =>
                                _triggerConciergeAction('Connecting with Aria'),
                          ),
                        ),
                      ),
                      SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                      Expanded(
                        child: SizedBox(
                          height: responsive.spacing(56),
                          child: OutlinedButton.icon(
                            onPressed: () => _triggerConciergeAction(
                              'Initiating secure concierge call',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 1.5,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: responsive.spacing(16),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                              ),
                            ),
                            icon: Icon(
                              Icons.phone_outlined,
                              size: responsive.iconSize(16),
                            ),
                            label: Text(
                              'CALL NOW',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: responsive.fontSize14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

            // 2. FAQ section header
            Text(
              'FREQUENTLY ASKED QUERIES',
              style: TextStyle(
                fontSize: responsive.fontSize11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryColor,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),

            // 3. Expandable FAQ Cards List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqs.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: responsive.spacing(AppTheme.spaceL)),
              itemBuilder: (context, index) {
                final faq = _faqs[index];
                final isExpanded = _expandedFaqIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedFaqIndex = isExpanded ? null : index;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(
                      responsive.spacing(AppTheme.spaceL),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      border: Border.all(
                        color: isExpanded
                            ? AppTheme.primaryColor
                            : AppTheme.borderColor,
                        width: isExpanded ? 1.5 : 1.0,
                      ),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                faq['question']!,
                                style: TextStyle(
                                  fontSize: responsive.fontSize14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: isExpanded ? 0.25 : 0.0,
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: responsive.iconSize(14),
                                color: AppTheme.textLightColor,
                              ),
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: ConstrainedBox(
                            constraints: isExpanded
                                ? const BoxConstraints()
                                : const BoxConstraints(maxHeight: 0),
                            child: isExpanded
                                ? Padding(
                                    padding: EdgeInsets.only(
                                      top: responsive.spacing(AppTheme.spaceM),
                                    ),
                                    child: Text(
                                      faq['answer']!,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize12,
                                        height: 1.6,
                                        color: AppTheme.textSecondaryColor
                                            .withValues(alpha: 0.95),
                                      ),
                                    ),
                                  )
                                : Container(),
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
