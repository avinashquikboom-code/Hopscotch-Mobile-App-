import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_text.dart';
import '../../../core/providers/currency_provider.dart';
import '../models/product_model.dart';

enum ShareEarnStep { shareCatalog, setMargin }

class ShareEarnBottomSheet extends ConsumerStatefulWidget {
  final ProductModel product;

  const ShareEarnBottomSheet({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ShareEarnBottomSheet> createState() => _ShareEarnBottomSheetState();
}

class _ShareEarnBottomSheetState extends ConsumerState<ShareEarnBottomSheet> {
  ShareEarnStep _currentStep = ShareEarnStep.setMargin;
  double _margin = 0.0; // Default margin is ₹0 as per image
  String _selectedShareType = 'all'; // 'all' or 'this'

  // Generate Reseller Share message
  String _generateShareText(AppCurrency currency) {
    final sellingPriceStr = currency.formatPrice(widget.product.price + _margin);
    return '''
✨ *Hopscotch Special Offer!* ✨
*${widget.product.title}*

${widget.product.description.length > 150 ? '${widget.product.description.substring(0, 150)}...' : widget.product.description}

💰 *Price:* $sellingPriceStr
🚚 *Free Delivery & Cash on Delivery Available*

👇 *Order Now / View Details:*
https://hopscotch.com/p/${widget.product.id}
''';
  }

  // Handle Share Targets
  Future<void> _handleShareAction(String platform, AppCurrency currency) async {
    HapticFeedback.mediumImpact();

    if (platform == 'Copy Link') {
      await Clipboard.setData(ClipboardData(text: 'https://hopscotch.com/p/${widget.product.id}'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Product link copied to clipboard!'),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      return;
    }

    // Show loading dialog while downloading images
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing media to share...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final shareText = _generateShareText(currency);
      final List<String> imageUrlsToShare = [];

      // Determine which image(s) to share based on user selection
      if (_selectedShareType == 'all') {
        imageUrlsToShare.add(widget.product.imageUrl);
        imageUrlsToShare.addAll(widget.product.additionalImages);
      } else {
        imageUrlsToShare.add(widget.product.imageUrl);
      }

      final List<XFile> xFilesToShare = [];
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();

      for (int i = 0; i < imageUrlsToShare.length; i++) {
        final url = imageUrlsToShare[i];
        final response = await dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.data != null) {
          String ext = 'jpg';
          if (url.contains('.png')) {
            ext = 'png';
          } else if (url.contains('.webp')) {
            ext = 'webp';
          }

          final filePath = '${tempDir.path}/share_img_${widget.product.id}_$i.$ext';
          final file = File(filePath);
          await file.writeAsBytes(response.data!);
          xFilesToShare.add(XFile(filePath));
        }
      }

      // Pop loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (xFilesToShare.isNotEmpty) {
        await Share.shareXFiles(
          xFilesToShare,
          text: shareText,
          subject: widget.product.title,
        );
      } else {
        await Share.share(
          shareText,
          subject: widget.product.title,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share with images: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Mock download images
  Future<void> _downloadImages() async {
    HapticFeedback.mediumImpact();
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'Downloading images...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.download_done_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('All images saved to your gallery successfully!'),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // Copy Description
  Future<void> _copyDescription() async {
    HapticFeedback.mediumImpact();
    await Clipboard.setData(ClipboardData(text: widget.product.description));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.content_copy_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Product description copied!'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final currency = ref.watch(currencyProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(responsive.spacing(AppTheme.radiusXL)),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _currentStep == ShareEarnStep.shareCatalog
                    ? _buildShareCatalogStep(responsive, currency)
                    : _buildSetMarginStep(responsive, currency),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Screen 1: Share Catalog Widget
  Widget _buildShareCatalogStep(ResponsiveText responsive, AppCurrency currency) {
    final hasAdditional = widget.product.additionalImages.isNotEmpty;
    final additionalCount = widget.product.additionalImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.spacing(AppTheme.spaceXL)),
          child: Row(
            children: [
              Icon(
                Remix.share_forward_line,
                size: responsive.iconSize(24),
                color: AppTheme.textPrimaryColor,
              ),
              SizedBox(width: responsive.spacing(12)),
              Text(
                'Share Catalog',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: responsive.fontSize18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Margin configuration bar
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _currentStep = ShareEarnStep.setMargin;
            });
          },
          child: Container(
            width: double.infinity,
            color: Colors.blue.withValues(alpha: 0.04),
            padding: EdgeInsets.symmetric(
              vertical: responsive.spacing(12),
              horizontal: responsive.spacing(AppTheme.spaceXL),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: responsive.iconSize(16),
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: responsive.spacing(8)),
                Expanded(
                  child: Text(
                    _margin > 0
                        ? 'Margin of ${currency.formatPrice(_margin)} applied'
                        : 'Margin can be set while sharing',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: responsive.fontSize12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                Text(
                  _margin > 0 ? 'EDIT' : 'SET',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: responsive.fontSize12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

        // Share Items Cards
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.spacing(AppTheme.spaceXL)),
          child: Row(
            children: [
              // Card 1: Share All Items
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedShareType = 'all';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(responsive.spacing(8)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: _selectedShareType == 'all'
                            ? AppTheme.primaryColor
                            : AppTheme.borderColor,
                        width: _selectedShareType == 'all' ? 2 : 1,
                      ),
                      boxShadow: _selectedShareType == 'all' ? AppTheme.softShadow : null,
                    ),
                    child: Row(
                      children: [
                        // Thumbnail Image stack
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          child: Stack(
                            children: [
                              Image.network(
                                widget.product.imageUrl,
                                width: responsive.spacing(48),
                                height: responsive.spacing(48),
                                fit: BoxFit.cover,
                              ),
                              if (hasAdditional)
                                Container(
                                  width: responsive.spacing(48),
                                  height: responsive.spacing(48),
                                  color: Colors.black.withValues(alpha: 0.4),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '+$additionalCount',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: responsive.fontSize12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: responsive.spacing(12)),
                        Expanded(
                          child: Text(
                            'Share All\nItems',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: responsive.fontSize13,
                              fontWeight: FontWeight.bold,
                              color: _selectedShareType == 'all'
                                  ? AppTheme.primaryColor
                                  : AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: responsive.spacing(AppTheme.spaceL)),

              // Card 2: Share This Item
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedShareType = 'this';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(responsive.spacing(8)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: _selectedShareType == 'this'
                            ? AppTheme.primaryColor
                            : AppTheme.borderColor,
                        width: _selectedShareType == 'this' ? 2 : 1,
                      ),
                      boxShadow: _selectedShareType == 'this' ? AppTheme.softShadow : null,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          child: Image.network(
                            widget.product.imageUrl,
                            width: responsive.spacing(48),
                            height: responsive.spacing(48),
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: responsive.spacing(12)),
                        Expanded(
                          child: Text(
                            'Share This\nItem',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: responsive.fontSize13,
                              fontWeight: FontWeight.bold,
                              color: _selectedShareType == 'this'
                                  ? AppTheme.primaryColor
                                  : AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

        // Social Icons Row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.spacing(AppTheme.spaceXL)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSocialButton('WhatsApp', Remix.whatsapp_fill, const Color(0xFF25D366), currency),
              _buildSocialButton('Facebook', Remix.facebook_box_fill, const Color(0xFF1877F2), currency),
              _buildSocialButton('Instagram', Remix.instagram_line, const Color(0xFFE1306C), currency),
              _buildSocialButton('Telegram', Remix.telegram_fill, const Color(0xFF0088CC), currency),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.spacing(AppTheme.spaceXL)),
          child: Row(
            children: [
              _buildSocialButton('Messenger', Remix.messenger_fill, const Color(0xFF006AFF), currency),
              SizedBox(width: responsive.spacing(32)),
              _buildSocialButton('Others', Icons.more_horiz_rounded, const Color(0xFF6C757D), currency, isOthers: true),
            ],
          ),
        ),

        SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
        const Divider(height: 1, color: AppTheme.borderColor),

        // Bottom Actions: Download and Copy
        _buildBottomOptionRow(
          icon: Remix.download_line,
          title: 'Download All Images',
          onTap: _downloadImages,
          responsive: responsive,
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        _buildBottomOptionRow(
          icon: Remix.file_copy_line,
          title: 'Copy Description',
          onTap: _copyDescription,
          responsive: responsive,
        ),
        SizedBox(height: responsive.spacing(AppTheme.spaceL)),
      ],
    );
  }

  // Screen 2: Set Margin Widget
  Widget _buildSetMarginStep(ResponsiveText responsive, AppCurrency currency) {
    final double maxMargin = (widget.product.price * 0.45).roundToDouble(); // Around 45% of price

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.only(
            left: responsive.spacing(AppTheme.spaceXL),
            right: responsive.spacing(AppTheme.spaceS),
            top: responsive.spacing(AppTheme.spaceS),
            bottom: responsive.spacing(AppTheme.spaceS),
          ),
          child: Row(
            children: [
              Container(
                width: responsive.spacing(24),
                height: responsive.spacing(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.textPrimaryColor,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  size: responsive.iconSize(14),
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(width: responsive.spacing(12)),
              Text(
                'Set Margin',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: responsive.fontSize18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.borderColor),
        
        // Body Content
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(AppTheme.spaceXL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: responsive.spacing(AppTheme.spaceL)),
              Text(
                'Customers will see the final price, which includes your added margin.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: responsive.fontSize14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

              // Highlighted Selected Margin Display - Reseller Blue color
              Center(
                child: Text(
                  'Margin ${currency.formatPrice(_margin)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: responsive.fontSize20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E88E5),
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceL)),

              // Slider component
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  thumbColor: AppTheme.primaryColor,
                  overlayColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: _margin,
                  min: 0.0,
                  max: maxMargin,
                  onChanged: (val) {
                    setState(() {
                      _margin = val.roundToDouble();
                    });
                  },
                ),
              ),

              // Slider labels (Min/Max)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.spacing(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Min. ${currency.formatPrice(0.0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: responsive.fontSize12,
                        color: AppTheme.textLightColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Max. ${currency.formatPrice(maxMargin)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: responsive.fontSize12,
                        color: AppTheme.textLightColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
            ],
          ),
        ),

        const Divider(color: AppTheme.borderColor),
        
        // Info Banner
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: responsive.spacing(14),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: responsive.iconSize(16),
                  color: AppTheme.textLightColor,
                ),
                SizedBox(width: responsive.spacing(8)),
                Text(
                  'Maximum margin is set by the brand',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: responsive.fontSize12,
                    color: AppTheme.textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const Divider(color: AppTheme.borderColor),

        // SET MARGIN Button
        Padding(
          padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _currentStep = ShareEarnStep.shareCatalog;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(
                  vertical: responsive.spacing(16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
              child: Text(
                'SET MARGIN',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: responsive.fontSize14,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Circular Social Button builder
  Widget _buildSocialButton(
    String name,
    IconData icon,
    Color col,
    AppCurrency currency, {
    bool isOthers = false,
  }) {
    final responsive = context.responsive;
    return GestureDetector(
      onTap: () => _handleShareAction(isOthers ? 'Others' : name, currency),
      child: SizedBox(
        width: responsive.spacing(68),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: responsive.spacing(52),
              height: responsive.spacing(52),
              decoration: BoxDecoration(
                color: col.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: col.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: col,
                size: responsive.iconSize(isOthers ? 20 : 24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: responsive.fontSize11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Row builder for copy/download options at the bottom
  Widget _buildBottomOptionRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ResponsiveText responsive,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: responsive.spacing(14),
          horizontal: responsive.spacing(AppTheme.spaceXL),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: responsive.iconSize(20),
              color: AppTheme.textPrimaryColor,
            ),
            SizedBox(width: responsive.spacing(16)),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: responsive.fontSize14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textLightColor,
              size: responsive.iconSize(20),
            ),
          ],
        ),
      ),
    );
  }
}
