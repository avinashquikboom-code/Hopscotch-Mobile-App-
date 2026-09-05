import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hopscotch/constants/seller_constants.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
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
          'FCISeller operates strictly under certified PCI-DSS secure billing standards. If enabled, biometric authentication data resides solely inside your device\'s native hardware secure enclave. No credit card numbers or security credentials are ever cached on our external servers.',
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
      'subtitle': SellerConfig.contactNumber,
      'color': Colors.green,
    },
    {
      'icon': Icons.email_outlined,
      'title': 'Email',
      'subtitle': SellerConfig.supportEmail,
      'color': Colors.blue,
    },
    {
      'icon': Icons.location_on_outlined,
      'title': 'Visit Store',
      'subtitle': '${SellerConfig.city}, ${SellerConfig.state}',
      'color': Colors.orange,
    },
  ];

  Future<void> _handleContactOption(String title) async {
    if (title == 'Call Us') {
      final phone = SellerConfig.contactNumber.replaceAll(' ', '').replaceAll('-', '');
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } else if (title == 'Email') {
      final uri = Uri.parse('mailto:${SellerConfig.supportEmail}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } else if (title == 'Visit Store') {
      final query = Uri.encodeComponent(SellerConfig.address);
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!mounted) return;
    ToastNotification.show(
      context,
      message: 'Support: ${SellerConfig.supportEmail}',
      isError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Help Center',
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
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          responsive.spacing(AppTheme.spaceXL),
          responsive.spacing(AppTheme.spaceL),
          responsive.spacing(AppTheme.spaceXL),
          responsive.spacing(AppTheme.spaceXL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'How can we help?',
              style: TextStyle(
                fontSize: responsive.fontSize24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: responsive.spacing(6)),
            Text(
              'Browse topics or explore our support options below',
              style: TextStyle(
                fontSize: responsive.fontSize14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

            // Contact Options Grid - Improved Cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: responsive.spacing(12),
                mainAxisSpacing: responsive.spacing(12),
              ),
              itemCount: _contactOptions.length,
              itemBuilder: (context, index) {
                final option = _contactOptions[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleContactOption(option['title']),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                            : option['color'].withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: option['color'].withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: option['color'].withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(responsive.spacing(12)),
                            decoration: BoxDecoration(
                              color: option['color'].withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              option['icon'],
                              color: option['color'],
                              size: responsive.iconSize(28),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(12)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8)),
                            child: Text(
                              option['title'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: responsive.fontSize12,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(4)),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(6)),
                              child: Text(
                                option['subtitle'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: responsive.fontSize10,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

            // FAQ Section Header
            Text(
              'Frequently Asked Questions'.toUpperCase(),
              style: TextStyle(
                fontSize: responsive.fontSize10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),

            // FAQ List - Improved Expansion Tiles
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqs.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: responsive.spacing(10)),
              itemBuilder: (context, index) {
                final faq = _faqs[index];
                final isExpanded = _expandedFaqIndex == index;

                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpanded
                          ? AppTheme.primaryColor.withValues(alpha: 0.3)
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: isExpanded && !isDark
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(16),
                        vertical: responsive.spacing(12),
                      ),
                      childrenPadding: EdgeInsets.fromLTRB(
                        responsive.spacing(16),
                        0,
                        responsive.spacing(16),
                        responsive.spacing(16),
                      ),
                      collapsedBackgroundColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      title: Text(
                        faq['question']!,
                        style: TextStyle(
                          fontSize: responsive.fontSize13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: isExpanded ? 0.5 : 0.0,
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: isExpanded ? AppTheme.primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          size: responsive.iconSize(24),
                        ),
                      ),
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expandedFaqIndex = expanded ? index : null;
                        });
                      },
                      children: [
                        Divider(
                          height: responsive.spacing(12),
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                        ),
                        Text(
                          faq['answer']!,
                          style: TextStyle(
                            fontSize: responsive.fontSize12,
                            height: 1.6,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
