import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hopscotch/constants/seller_constants.dart';
import 'package:hopscotch/repositories/config_repository.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/widgets/toast_notification.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
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

  Future<void> _handleContactOption(
    String title, {
    required String phoneNum,
    required String emailAddr,
    required String addressText,
  }) async {
    if (title == 'Call Us') {
      final phone = phoneNum.replaceAll(' ', '').replaceAll('-', '');
      final uri = Uri.parse('tel:$phone');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        } else {
          await launchUrl(uri);
          return;
        }
      } catch (_) {}
    } else if (title == 'Email') {
      final uri = Uri.parse('mailto:$emailAddr');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        } else {
          await launchUrl(uri);
          return;
        }
      } catch (_) {}
    } else if (title == 'Visit Store') {
      final query = Uri.encodeComponent(addressText);
      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        } else {
          await launchUrl(uri);
          return;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    ToastNotification.show(
      context,
      message: 'Support: $emailAddr | Tel: $phoneNum',
      isError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sellerInfoAsync = ref.watch(apiSellerInfoProvider);
    final sellerData = sellerInfoAsync.valueOrNull;

    final sellerPhone = (sellerData?['sellerContactNumber']?.trim().isNotEmpty == true)
        ? sellerData!['sellerContactNumber']!.trim()
        : SellerConfig.contactNumber;

    final sellerEmail = (sellerData?['sellerEmail']?.trim().isNotEmpty == true)
        ? sellerData!['sellerEmail']!.trim()
        : SellerConfig.supportEmail;

    final sellerAddress = (sellerData?['sellerAddress']?.trim().isNotEmpty == true)
        ? sellerData!['sellerAddress']!.trim()
        : SellerConfig.address;

    final sellerCity = (sellerData?['sellerCity']?.trim().isNotEmpty == true)
        ? sellerData!['sellerCity']!.trim()
        : SellerConfig.city;

    final sellerState = (sellerData?['sellerState']?.trim().isNotEmpty == true)
        ? sellerData!['sellerState']!.trim()
        : SellerConfig.state;

    final List<Map<String, dynamic>> contactOptions = [
      {
        'icon': Icons.chat_bubble_outline,
        'title': 'Live Chat',
        'subtitle': 'Chat with our support team',
        'color': AppTheme.primaryColor,
      },
      {
        'icon': Icons.phone_outlined,
        'title': 'Call Us',
        'subtitle': sellerPhone,
        'color': Colors.green,
      },
      {
        'icon': Icons.email_outlined,
        'title': 'Email',
        'subtitle': sellerEmail,
        'color': Colors.blue,
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Visit Store',
        'subtitle': '$sellerCity, $sellerState',
        'color': Colors.orange,
      },
    ];

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
              itemCount: contactOptions.length,
              itemBuilder: (context, index) {
                final option = contactOptions[index];
                final optionTitle = option['title'] as String;
                final optionSubtitle = option['subtitle'] as String;
                final optionColor = option['color'] as Color;
                final optionIcon = option['icon'] as IconData;

                return SupportCard(
                  icon: optionIcon,
                  title: optionTitle,
                  description: optionSubtitle,
                  color: optionColor,
                  onTap: () => _handleContactOption(
                    optionTitle,
                    phoneNum: sellerPhone,
                    emailAddr: sellerEmail,
                    addressText: sellerAddress,
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
                    borderRadius: BorderRadius.circular(16),
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
                  child: Material(
                    color: isDark
                        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isExpanded
                            ? AppTheme.primaryColor.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        key: PageStorageKey<String>('faq_$index'),
                        shape: const Border(),
                        collapsedShape: const Border(),
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
                            color: isExpanded
                                ? AppTheme.primaryColor
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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

/// A consistent, properly aligned support card for the Help Center.
///
/// Ensures identical icon container dimensions, horizontal and vertical centering,
/// and consistent spacing across all 4 support cards (Live Chat, Call Us, Email, Visit Store).
class SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const SupportCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(10),
            vertical: responsive.spacing(14),
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.8)
                : color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── ICON CONTAINER ──
              Container(
                width: responsive.spacing(48),
                height: responsive.spacing(48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(responsive.spacing(14)),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: responsive.iconSize(26),
                ),
              ),
              SizedBox(height: responsive.spacing(10)),
              // ── TITLE ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.spacing(4)),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: responsive.fontSize12,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              // ── DESCRIPTION ──
              SizedBox(
                height: responsive.spacing(28),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: responsive.spacing(4)),
                    child: Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: responsive.fontSize10,
                        height: 1.25,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
