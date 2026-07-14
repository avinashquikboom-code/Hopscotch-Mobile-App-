import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/product_repository.dart';
import 'package:hopscotch/repositories/category_repository.dart';
import 'package:hopscotch/repositories/auth_repository.dart';
import 'package:hopscotch/repositories/notification_repository.dart';
import 'package:hopscotch/repositories/banner_repository.dart';
import 'package:hopscotch/models/banner_model.dart';
import 'package:hopscotch/widgets/product_card.dart';
import 'package:hopscotch/widgets/skeleton_loaders.dart';
import 'package:hopscotch/l10n/app_localizations.dart';

import 'dart:io';
import 'package:hopscotch/widgets/visual_search_bottom_sheet.dart';

// ─── Blinkit-style palette (tune to your brand) ───────────────────────────────
const _kHeaderTop = Color(0xFF0A1F44); // deep navy
const _kHeaderBottom = Color(0xFF123A6B); // lighter navy
const _kOnHeader = Colors.white;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late PageController _bannerController;
  late AnimationController _fadeController;
  int _activeBanner = 0;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(initialPage: 0);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showImageSourceBottomSheet() async {
    final image = await VisualSearchBottomSheet.show(context);
    if (image != null && mounted) {
      context.push('/visual-search/preview', extra: File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final newArrivalsAsync = ref.watch(newArrivalsProvider);
    final notifications = ref.watch(notificationProvider);
    final bannersAsync = ref.watch(bannersProvider);
    final unreadNotifications = notifications.where((n) => !n.isRead).length;
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;
    final screenH = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allCategoriesProvider);
            ref.invalidate(trendingProductsProvider);
            ref.invalidate(newArrivalsProvider);
            ref.invalidate(bannersProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              bottom: 120,
            ), // Leave space for floating nav bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════════════════════
                // BLINKIT-STYLE DARK HEADER
                // brand block + bell/avatar, search bar, category tabs
                // ═══════════════════════════════════════════════════════
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_kHeaderTop, _kHeaderBottom],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Row 1: brand block + actions ──
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            responsive.spacing(AppTheme.spaceXL),
                            responsive.spacing(AppTheme.spaceM),
                            responsive.spacing(AppTheme.spaceXL),
                            0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AURA COUTURE',
                                      style: TextStyle(
                                        color: _kOnHeader,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2.0,
                                        fontSize: responsive.fontSize12,
                                      ),
                                    ),
                                    SizedBox(height: responsive.spacing(2.0)),
                                    // Big Blinkit-style headline
                                    Text(
                                      user != null
                                          ? 'Hello, ${user.name.split(" ").first}'
                                          : l10n.discoverLuxury,
                                      style: TextStyle(
                                        color: _kOnHeader,
                                        fontWeight: FontWeight.w900,
                                        fontSize: responsive.fontSize(26.0),
                                        height: 1.1,
                                      ),
                                    ),
                                    SizedBox(height: responsive.spacing(2.0)),
                                    Text(
                                      l10n.discoverLuxury,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _kOnHeader.withValues(
                                          alpha: 0.75,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        fontSize: responsive.fontSize14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Notification bell with badge
                              Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _kOnHeader.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.notifications_none_rounded,
                                        color: _kOnHeader,
                                        size: responsive.iconSize(24.0),
                                      ),
                                      onPressed: () =>
                                          context.push('/notifications'),
                                    ),
                                  ),
                                  if (unreadNotifications > 0)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          responsive.spacing(4.0),
                                        ),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.accentColor,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: responsive.iconSize(16.0),
                                          minHeight: responsive.iconSize(16.0),
                                        ),
                                        child: Text(
                                          unreadNotifications.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: responsive.fontSize10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                            ],
                          ),
                        ),

                        // ── Row 2: dark search bar ──
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(AppTheme.spaceXL),
                            vertical: responsive.spacing(AppTheme.spaceM),
                          ),
                          child: GestureDetector(
                            onTap: () => context.push('/search'),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: responsive.spacing(14.0),
                                horizontal: responsive.spacing(18.0),
                              ),
                              decoration: BoxDecoration(
                                color: _kOnHeader.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusM,
                                ),
                                border: Border.all(
                                  color: _kOnHeader.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    color: _kOnHeader,
                                    size: responsive.iconSize(22.0),
                                  ),
                                  SizedBox(
                                    width: responsive.spacing(AppTheme.spaceM),
                                  ),
                                  Expanded(
                                    child: Text(
                                      l10n.searchPlaceholder,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: responsive.bodyMedium.copyWith(
                                        color: _kOnHeader.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: responsive.iconSize(22.0),
                                    color: _kOnHeader.withValues(alpha: 0.25),
                                  ),
                                  SizedBox(
                                    width: responsive.spacing(AppTheme.spaceM),
                                  ),
                                  GestureDetector(
                                    onTap: _showImageSourceBottomSheet,
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      color: _kOnHeader,
                                      size: responsive.iconSize(22.0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Row 3: Blinkit-style category tabs ──
                        // (All + real categories, fashion icons, underline)
                        SizedBox(
                          height: responsive.spacing(84.0),
                          child: categoriesAsync.when(
                            data: (categories) => ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: responsive.spacing(AppTheme.spaceL),
                              ),
                              itemCount: categories.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _CategoryTab(
                                    label: 'All',
                                    icon: Icons.grid_view_rounded,
                                    isActive: true,
                                    responsive: responsive,
                                    onTap: () {},
                                  );
                                }
                                final category = categories[index - 1];
                                return _CategoryTab(
                                  label: category.name,
                                  icon: _fashionIconFor(category.name),
                                  isActive: false,
                                  responsive: responsive,
                                  onTap: () => context.push(
                                    '/products?categoryId=${category.id}&categoryName=${category.name}',
                                  ),
                                );
                              },
                            ),
                            loading: () => ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: responsive.spacing(AppTheme.spaceL),
                              ),
                              itemCount: 5,
                              itemBuilder: (context, index) => Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.spacing(
                                    AppTheme.spaceM,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SkeletonLoader(
                                      width: responsive.spacing(32.0),
                                      height: responsive.spacing(32.0),
                                      borderRadius: responsive.spacing(16.0),
                                    ),
                                    SizedBox(height: responsive.spacing(6.0)),
                                    SkeletonLoader(
                                      width: responsive.spacing(48.0),
                                      height: responsive.spacing(10.0),
                                      borderRadius: responsive.spacing(5.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ═══════════════════════════════════════════════════════
                // HERO BANNER (image only, curved bottom corners)
                // ═══════════════════════════════════════════════════════
                SizedBox(
                  height: screenH * 0.32,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                    child: bannersAsync.when(
                      data: (banners) {
                        if (banners.isEmpty) {
                          return _HeroBannerPlaceholder(responsive: responsive);
                        }
                        return _HeroBannerCarousel(
                          banners: banners,
                          controller: _bannerController,
                          activePage: _activeBanner,
                          onPageChanged: (i) =>
                              setState(() => _activeBanner = i),
                          responsive: responsive,
                          onExplore: (banner) {
                            final link = banner.link;
                            if (link != null) context.push(link);
                          },
                        );
                      },
                      loading: () => Container(
                        color: const Color(0xFF1A1A2E),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      error: (_, __) =>
                          _HeroBannerPlaceholder(responsive: responsive),
                    ),
                  ),
                ),

                // ── Dot indicators ──
                const SizedBox(height: 12),
                bannersAsync.maybeWhen(
                  data: (banners) => banners.isEmpty
                      ? const SizedBox.shrink()
                      : Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(banners.length, (i) {
                              final isActive = i == _activeBanner;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: isActive ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // 5. Trending Products
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(30 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(AppTheme.spaceXL),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.trendingHighlights,
                                style: responsive.headline5,
                              ),
                              TextButton(
                                onPressed: () => context.push(
                                  '/products?filter=trending&categoryName=Trending',
                                ),
                                child: Text(
                                  l10n.seeAll,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize14,
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
                SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                SizedBox(
                  height: responsive.spacing(290),
                  child: trendingAsync.when(
                    data: (products) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(AppTheme.spaceXL),
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return TweenAnimationBuilder<double>(
                          key: ValueKey('trend_$index'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 500 + (index * 100)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(30 * (1 - value), 0),
                              child: Opacity(
                                opacity: value,
                                child: Container(
                                  width: responsive.spacing(175),
                                  margin: EdgeInsets.only(
                                    right: responsive.spacing(AppTheme.spaceL),
                                  ),
                                  child: ProductCard(
                                    product: product,
                                    heroTagPrefix: 'home_trending',
                                    onTap: () => context.push(
                                      '/product/${product.id}?heroTagPrefix=home_trending',
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    loading: () => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(AppTheme.spaceXL),
                      ),
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        width: responsive.spacing(175),
                        margin: EdgeInsets.only(
                          right: responsive.spacing(AppTheme.spaceL),
                        ),
                        child: const ProductCardSkeleton(),
                      ),
                    ),
                    error: (err, stack) =>
                        Center(child: Text('${l10n.error}: $err')),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // 6. New Arrivals
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(30 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(AppTheme.spaceXL),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.theNewGuard,
                                style: responsive.headline5,
                              ),
                              TextButton(
                                onPressed: () => context.push(
                                  '/products?filter=new&categoryName=New Arrivals',
                                ),
                                child: Text(
                                  l10n.seeAll,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize14,
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
                SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                SizedBox(
                  height: responsive.spacing(290),
                  child: newArrivalsAsync.when(
                    data: (products) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(AppTheme.spaceXL),
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return TweenAnimationBuilder<double>(
                          key: ValueKey('new_$index'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 600 + (index * 100)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(30 * (1 - value), 0),
                              child: Opacity(
                                opacity: value,
                                child: Container(
                                  width: responsive.spacing(175),
                                  margin: EdgeInsets.only(
                                    right: responsive.spacing(AppTheme.spaceL),
                                  ),
                                  child: ProductCard(
                                    product: product,
                                    heroTagPrefix: 'home_new',
                                    onTap: () => context.push(
                                      '/product/${product.id}?heroTagPrefix=home_new',
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    loading: () => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(AppTheme.spaceXL),
                      ),
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        width: responsive.spacing(175),
                        margin: EdgeInsets.only(
                          right: responsive.spacing(AppTheme.spaceL),
                        ),
                        child: const ProductCardSkeleton(),
                      ),
                    ),
                    error: (err, stack) =>
                        Center(child: Text('${l10n.error}: $err')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Fashion icon mapping for category tabs ───────────────────────────────────
// Maps clothing-brand category names to line icons (Blinkit uses line icons).
IconData _fashionIconFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('women') || n.contains('ladies')) return Icons.woman_rounded;
  if (n.contains('men')) return Icons.man_rounded;
  if (n.contains('kid') || n.contains('child') || n.contains('baby')) {
    return Icons.child_care_rounded;
  }
  if (n.contains('shoe') || n.contains('foot')) {
    return Icons.directions_walk_rounded;
  }
  if (n.contains('watch') || n.contains('accessor')) return Icons.watch_rounded;
  if (n.contains('jewel') || n.contains('gold')) return Icons.diamond_outlined;
  if (n.contains('bag') || n.contains('handbag')) {
    return Icons.shopping_bag_outlined;
  }
  if (n.contains('beauty') || n.contains('makeup')) return Icons.spa_outlined;
  if (n.contains('winter') || n.contains('monsoon')) {
    return Icons.beach_access_rounded; // umbrella
  }
  if (n.contains('ethnic') || n.contains('saree') || n.contains('kurta')) {
    return Icons.auto_awesome_outlined;
  }
  return Icons.checkroom_rounded; // hanger — default for clothing
}

// ─── Blinkit-style category tab (icon + label + underline) ────────────────────
class _CategoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final dynamic responsive;

  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(AppTheme.spaceM),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? _kOnHeader : _kOnHeader.withValues(alpha: 0.85),
              size: responsive.iconSize(26.0),
            ),
            SizedBox(height: responsive.spacing(6.0)),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? _kOnHeader
                    : _kOnHeader.withValues(alpha: 0.85),
                fontSize: responsive.fontSize12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            SizedBox(height: responsive.spacing(6.0)),
            // Underline indicator (only on the active tab)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? responsive.spacing(36.0) : 0,
              height: 3,
              decoration: BoxDecoration(
                color: _kOnHeader,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Full-Bleed Hero Banner Carousel (image only) ─────────────────────────────

class _HeroBannerCarousel extends StatelessWidget {
  final List<BannerModel> banners;
  final PageController controller;
  final int activePage;
  final ValueChanged<int> onPageChanged;
  final void Function(BannerModel) onExplore;
  final dynamic responsive;

  const _HeroBannerCarousel({
    required this.banners,
    required this.controller,
    required this.activePage,
    required this.onPageChanged,
    required this.onExplore,
    required this.responsive,
  });

  // Derive a set of accent chip colors per banner index
  static const List<Color> _chipColors = [
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF2563EB),
  ];

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      onPageChanged: onPageChanged,
      itemCount: banners.length,
      itemBuilder: (context, index) {
        final banner = banners[index];
        final chipColor = _chipColors[index % _chipColors.length];

        return GestureDetector(
          onTap: () => onExplore(banner),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background Image (no color overlay) ──
              Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF1A1A2E)),
              ),

              // ── Content ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title (shadow keeps it readable without overlay)
                      Text(
                        banner.title,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                      if (banner.subtitle != null &&
                          banner.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          banner.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Chip row + Explore button ──
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: _buildChips(banner, chipColor, index),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => onExplore(banner),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Text(
                                'Explore',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildChips(BannerModel banner, Color color, int index) {
    final labels = _extractChipLabels(banner, index);
    return labels
        .take(3)
        .map(
          (label) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        )
        .toList();
  }

  List<String> _extractChipLabels(BannerModel banner, int index) {
    final words = banner.title
        .split(' ')
        .where((w) => w.length > 2)
        .take(2)
        .toList();
    if (words.length < 2) words.add('Couture');
    return [...words, 'Shop Now'];
  }
}

// ─── Placeholder when no banners ──────────────────────────────────────────────

class _HeroBannerPlaceholder extends StatelessWidget {
  final dynamic responsive;
  const _HeroBannerPlaceholder({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: const Center(
        child: Text(
          'No Promotions',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ),
    );
  }
}
