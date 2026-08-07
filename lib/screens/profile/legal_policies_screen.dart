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
              'By purchasing custom tailored or bespoke-fitting garments from FCISeller, you acknowledge and agree that minor visual adjustments and drape alignments may occur during the physical tailoring phase. Because each item is constructed based on individual clients\' specified measurements, variations are custom-tailored to provide the ultimate styling fit.',
        },
        {
          'heading': '2. Proprietary Couture Designs',
          'body':
              'All designs, custom knitwear weaves, silk patterns, embroidery drapes, and application structures featured inside the FCISeller catalog represent exclusive, patented intellectual property owned by FCISeller and its collaborative European design houses. Unauthorized reproduction or reverse-engineering is strictly prohibited.',
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
              'If you choose to authorize billing or purchase secure keys using biometric data, your fingerprint or facial signature never leaves your physical mobile device. Biometric data is strictly encapsulated inside your native device hardware\'s Secure Enclave/Keymaster. FCISeller never accesses, transmits, or caches biometric identifiers.',
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
              'FCISeller operates under an elite styling guarantee. If a custom garment does not fit to your total satisfaction, we provide complimentary alteration credits. alter your garment at any of our collaborative luxury tailoring ateliers globally. Simply contact your Concierge to receive an authorized atelier voucher.',
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Legal & Policies',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: responsive.fontSize18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, size: responsive.iconSize(24)),
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
          // Improved Tab Selector
          Padding(
            padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_policies.length, (index) {
                  final isSelected = _activeTab == index;
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Padding(
                    padding: EdgeInsets.only(right: responsive.spacing(8)),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _activeTab = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(16),
                            vertical: responsive.spacing(10),
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : (isDark
                                    ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : (isDark
                                      ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
                                      : AppTheme.borderColor),
                              width: 1.5,
                            ),
                            boxShadow: isSelected && !isDark
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            _policies[index]['title']!,
                            style: TextStyle(
                              fontSize: responsive.fontSize12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : AppTheme.textPrimaryColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Policy Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                responsive.spacing(AppTheme.spaceXL),
                0,
                responsive.spacing(AppTheme.spaceXL),
                responsive.spacing(AppTheme.spaceXL),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activePolicy['title']!,
                    style: TextStyle(
                      fontSize: responsive.fontSize20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(6)),
                  Text(
                    activePolicy['lastUpdated']!,
                    style: TextStyle(
                      fontSize: responsive.fontSize11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sections.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                    itemBuilder: (context, index) {
                      final sec = sections[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(responsive.spacing(12)),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              sec['heading']!,
                              style: TextStyle(
                                fontSize: responsive.fontSize13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                          Text(
                            sec['body']!,
                            style: TextStyle(
                              fontSize: responsive.fontSize12,
                              height: 1.8,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
