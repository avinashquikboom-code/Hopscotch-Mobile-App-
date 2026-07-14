import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';

class LegalPoliciesScreen extends StatefulWidget {
  const LegalPoliciesScreen({super.key});

  @override
  State<LegalPoliciesScreen> createState() => _LegalPoliciesScreenState();
}

class _LegalPoliciesScreenState extends State<LegalPoliciesScreen> {
  // Keeps track of the active policy tab
  int _activeTab = 0;

  final List<Map<String, dynamic>> _policies = [
    {
      'title': 'Terms of Use',
      'lastUpdated': 'Last updated: June 15, 2026',
      'sections': [
        {
          'heading': '1. Bespoke Custom Tailoring',
          'body':
              'By purchasing custom tailored or bespoke-fitting garments from Aura Couture, you acknowledge and agree that minor visual adjustments and drape alignments may occur during the physical tailoring phase. Because each item is constructed based on individual clients\' specified measurements, variations are custom-tailored to provide the ultimate styling fit.',
        },
        {
          'heading': '2. Proprietary Couture Designs',
          'body':
              'All designs, custom knitwear weaves, silk patterns, embroidery drapes, and application structures featured inside the Aura Couture catalog represent exclusive, patented intellectual property owned by Aura Couture and its collaborative European design houses. Unauthorized reproduction or reverse-engineering is strictly prohibited.',
        },
        {
          'heading': '3. Order Cancellation Window',
          'body':
              'Due to our rapid white-glove logistics pipeline and immediate stock reservation system, orders may only be cancelled or modified within exactly one (1) hour of secure transaction authorization. Once custom physical preparation or tailoring begins at our ateliers, cancellations are no longer accepted.',
        },
      ],
    },
    {
      'title': 'Privacy Policy',
      'lastUpdated': 'Last updated: May 02, 2026',
      'sections': [
        {
          'heading': '1. Biometric Enclave Protection',
          'body':
              'If you choose to authorize billing or purchase secure keys using biometric data, your fingerprint or facial signature never leaves your physical mobile device. Biometric data is strictly encapsulated inside your native device hardware\'s Secure Enclave/Keymaster. Aura Couture never accesses, transmits, or caches biometric identifiers.',
        },
        {
          'heading': '2. Encrypted Data Streams',
          'body':
              'All customer profiles, styling metrics, order logistics, and transaction credentials are securely compiled and encrypted end-to-end using industry-standard TLS 1.3 encryption streams. We do not distribute or monetize customer data to third-party advertising cooperatives.',
        },
        {
          'heading': '3. Personal styling measurements',
          'body':
              'Your bespoke styling profiles, height metrics, and measurement logs reside within heavily secured, isolated database matrices. This data is exclusively parsed by your designated personal concierges and atelier tailors to ensure correct custom fitting.',
        },
      ],
    },
    {
      'title': 'Shipping & Alterations',
      'lastUpdated': 'Last updated: April 10, 2026',
      'sections': [
        {
          'heading': '1. White-Glove Logistics Delivery',
          'body':
              'All luxury shipments are fully insured and dispatched via elite, high-speed priority couriers (DHL Express and FedEx Priority). Hand-wrapped, customized boxes require physical signature authorization upon delivery to guarantee secure, damage-free transfer.',
        },
        {
          'heading': '2. Complaints and Alteration Ateliers',
          'body':
              'Aura Couture operates under an elite styling guarantee. If a custom garment does not fit to your total satisfaction, we provide complimentary alteration credits. alter your garment at any of our collaborative luxury tailoring ateliers globally. Simply contact your Concierge to receive an authorized atelier voucher.',
        },
        {
          'heading': '3. Customs & Import Tariffs',
          'body':
              'For global couture dispatches shipped internationally across European borders, import tariffs and local luxury taxes are fully pre-calculated and authorized at checkout, ensuring complete white-glove logistics processing straight to your destination.',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final activePolicy = _policies[_activeTab];
    final List<Map<String, String>> sections = List<Map<String, String>>.from(
      activePolicy['sections'],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Premium light ivory canvas
      appBar: AppBar(
        title: Text(
          'LEGAL POLICIES',
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
      body: Column(
        children: [
          // 1. Premium Horizontal Custom Segmented Tabs
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(AppTheme.spaceXL),
              vertical: responsive.spacing(AppTheme.spaceM),
            ),
            child: Container(
              height: responsive.spacing(48),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              padding: EdgeInsets.all(responsive.spacing(4)),
              child: Row(
                children: List.generate(_policies.length, (index) {
                  final isSelected = _activeTab == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeTab = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _policies[index]['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsive.fontSize11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // 2. Main Scrollable Editorial Document Reader
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(AppTheme.spaceXL),
                vertical: responsive.spacing(AppTheme.spaceM),
              ),
              child: Container(
                padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activePolicy['title']!.toUpperCase(),
                      style: TextStyle(
                        fontSize: responsive.fontSize16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(4)),
                    Text(
                      activePolicy['lastUpdated']!,
                      style: TextStyle(
                        fontSize: responsive.fontSize10,
                        color: AppTheme.textLightColor,
                      ),
                    ),
                    Divider(
                      height: responsive.spacing(AppTheme.spaceXXL),
                      color: AppTheme.borderColor,
                    ),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sections.length,
                      separatorBuilder: (context, index) => SizedBox(
                        height: responsive.spacing(AppTheme.spaceXXL),
                      ),
                      itemBuilder: (context, index) {
                        final sec = sections[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sec['heading']!,
                              style: TextStyle(
                                fontSize: responsive.fontSize12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            SizedBox(
                              height: responsive.spacing(AppTheme.spaceS),
                            ),
                            Text(
                              sec['body']!,
                              style: TextStyle(
                                fontSize: responsive.fontSize10,
                                height: 1.5,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
        ],
      ),
    );
  }
}
