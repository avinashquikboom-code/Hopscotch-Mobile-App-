import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/utils/dev_logger.dart';
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

// ─────────────────────────────────────────────────────────────
// LOCATION PROVIDER — Geolocates user address details
// ─────────────────────────────────────────────────────────────

class UserLocation {
  final String area;    // "Sector 8"
  final String city;    // "Kopar Khairane, Navi Mumbai"
  const UserLocation({required this.area, required this.city});
}

final userLocationProvider = FutureProvider<UserLocation>((ref) async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const UserLocation(area: 'Set location', city: 'Tap to choose');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      return UserLocation(
        area: p.subLocality?.isNotEmpty == true ? p.subLocality! : (p.locality ?? 'Detected Location'),
        city: [p.locality, p.administrativeArea]
            .where((e) => e != null && e.isNotEmpty)
            .join(', '),
      );
    }
  } catch (e) {
    DevLogger.logError('Error getting location: $e', context: 'UserLocationProvider');
  }
  return const UserLocation(area: 'Set location', city: 'Tap to choose');
});

// ─────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0;
  int _activeBanner = 0;
  late PageController _bannerController;

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _bannerController.dispose();
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
    final size = MediaQuery.of(context).size;
    final width = size.width;
    
    // Check viewport category
    final isDesktop = width > 1200;
    final isTablet = width > 600 && width <= 1200;

    // Responsive design dimensions
    final double horizontalPadding = isDesktop ? 64 : (isTablet ? 32 : 20);
    final double mainAxisSpacing = isDesktop ? 24 : 16;
    final double crossAxisSpacing = isDesktop ? 24 : 16;
    final int crossAxisCount = isDesktop ? 5 : (isTablet ? 3 : 2);
    final double childAspectRatio = isDesktop ? 0.72 : (isTablet ? 0.68 : 0.65);
    final double bannerHeight = isDesktop ? 350 : (isTablet ? 260 : 180);
    final double trendingHeight = isDesktop ? 340 : (isTablet ? 310 : 290);

    final location = ref.watch(userLocationProvider);
    final topPadding = MediaQuery.of(context).padding.top;
    
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final categories = categoriesAsync.value ?? [];
    
    final trendingAsync = ref.watch(trendingProductsProvider);
    final newArrivalsAsync = ref.watch(newArrivalsProvider);
    final bannersAsync = ref.watch(bannersProvider);
    
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;

    // Construct the sliver list dynamically based on selection tab
    final List<Widget> slivers = [
      // 1. LOCATION HEADER — scrolls away
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, topPadding + 12, horizontalPadding, 4),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined,
                  color: Theme.of(context).colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.invalidate(userLocationProvider);
                  },
                  child: location.when(
                    loading: () => const _LocationText(
                        area: 'Detecting…', city: ' '),
                    error: (_, __) => const _LocationText(
                        area: 'Set location', city: 'Tap to choose'),
                    data: (loc) =>
                        _LocationText(area: loc.area, city: loc.city),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => context.push('/wishlist'),
                icon: const Icon(Icons.bookmark_border_rounded),
                color: Theme.of(context).colorScheme.onSurface,
              ),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: Icon(Icons.person_outline,
                      size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ),
      ),

      // 2. SEARCH BAR — pinned, always visible
      SliverPersistentHeader(
        pinned: true,
        delegate: _SearchBarDelegate(
          topPadding: topPadding,
          horizontalPadding: horizontalPadding,
          onSearchTap: () => context.push('/search'),
          onCameraTap: _showImageSourceBottomSheet,
          placeholderText: l10n.searchPlaceholder,
        ),
      ),

      // 3. CATEGORY TABS — pinned; stick under search bar on scroll
      SliverPersistentHeader(
        pinned: true,
        delegate: _CategoryTabsDelegate(
          categories: categories,
          selectedIndex: _selectedTab,
          onChanged: (i) => setState(() {
            _selectedTab = i;
          }),
          horizontalPadding: horizontalPadding,
        ),
      ),
    ];

    // 4. MAIN CONTENT
    if (_selectedTab == 0) {
      // Home Feed (All tab selected)
      slivers.addAll([
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        
        // Promo Banners Carousel
        SliverToBoxAdapter(
          child: SizedBox(
            height: bannerHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
          ),
        ),

        // Dot indicators
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: bannersAsync.maybeWhen(
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
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ),
        
        SliverToBoxAdapter(child: SizedBox(height: responsive.spacing(AppTheme.spaceXL))),

        // Trending Products Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                    style: TextStyle(fontSize: responsive.fontSize14),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: responsive.spacing(AppTheme.spaceS))),
        
        // Trending list
        SliverToBoxAdapter(
          child: SizedBox(
            height: trendingHeight,
            child: trendingAsync.when(
              data: (products) => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Container(
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
                  );
                },
              ),
              loading: () => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                itemCount: 3,
                itemBuilder: (context, index) => Container(
                  width: responsive.spacing(175),
                  margin: EdgeInsets.only(
                    right: responsive.spacing(AppTheme.spaceL),
                  ),
                  child: const ProductCardSkeleton(),
                ),
              ),
              error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
            ),
          ),
        ),

        SliverToBoxAdapter(child: SizedBox(height: responsive.spacing(AppTheme.spaceXL))),

        // New Arrivals Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                    style: TextStyle(fontSize: responsive.fontSize14),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: responsive.spacing(AppTheme.spaceS))),

        // New Arrivals Grid
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: newArrivalsAsync.when(
            data: (products) => SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
                childAspectRatio: childAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    heroTagPrefix: 'home_new',
                    onTap: () => context.push(
                      '/product/${product.id}?heroTagPrefix=home_new',
                    ),
                  );
                },
                childCount: products.length,
              ),
            ),
            loading: () => SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
                childAspectRatio: childAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => const ProductCardSkeleton(),
                childCount: 4,
              ),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: Center(child: Text('${l10n.error}: $err')),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ]);
    } else {
      // Category Tab Selected
      final selectedCategory = categories[_selectedTab - 1];
      final categoryProductsAsync = ref.watch(categoryProductsProvider(selectedCategory.id.toString()));

      slivers.addAll([
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              selectedCategory.name,
              style: responsive.headline5,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Category Products Grid
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: categoryProductsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Text(
                      'No products found in this category',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: responsive.fontSize14,
                      ),
                    ),
                  ),
                );
              }
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: mainAxisSpacing,
                  crossAxisSpacing: crossAxisSpacing,
                  childAspectRatio: childAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      heroTagPrefix: 'category_${selectedCategory.id}',
                      onTap: () => context.push(
                        '/product/${product.id}?heroTagPrefix=category_${selectedCategory.id}',
                      ),
                    );
                  },
                  childCount: products.length,
                ),
              );
            },
            loading: () => SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
                childAspectRatio: childAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => const ProductCardSkeleton(),
                childCount: 4,
              ),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: Center(child: Text('${l10n.error}: $err')),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ]);
    }

    Widget body = CustomScrollView(
      slivers: slivers,
    );

    // Limit screen width on large monitors/desktop builds to ensure a premium centered look
    if (isDesktop) {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: body,
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allCategoriesProvider);
          ref.invalidate(trendingProductsProvider);
          ref.invalidate(newArrivalsProvider);
          ref.invalidate(bannersProvider);
          ref.invalidate(userLocationProvider);
        },
        child: body,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOCATION TEXT
// ─────────────────────────────────────────────────────────────

class _LocationText extends StatelessWidget {
  final String area;
  final String city;
  const _LocationText({required this.area, required this.city});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                area,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: onSurface),
          ],
        ),
        if (city.isNotEmpty)
          Text(
            city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PINNED SEARCH BAR DELEGATE
// ─────────────────────────────────────────────────────────────

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final double horizontalPadding;
  final VoidCallback onSearchTap;
  final VoidCallback onCameraTap;
  final String placeholderText;

  _SearchBarDelegate({
    required this.topPadding,
    required this.horizontalPadding,
    required this.onSearchTap,
    required this.onCameraTap,
    required this.placeholderText,
  });

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 64;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final pinnedAtTop = shrinkOffset > 0 || overlapsContent;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
          horizontalPadding, pinnedAtTop ? 0 : 6, horizontalPadding, 8),
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outline,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onSearchTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.5), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          placeholderText,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // AI image search entry point
            IconButton(
              padding: const EdgeInsets.only(right: 16),
              constraints: const BoxConstraints(),
              onPressed: onCameraTap,
              icon: Icon(Icons.camera_alt_outlined,
                  color: colorScheme.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarDelegate old) =>
      old.topPadding != topPadding ||
      old.horizontalPadding != horizontalPadding ||
      old.placeholderText != placeholderText;
}

// ─────────────────────────────────────────────────────────────
// PINNED CATEGORY TABS DELEGATE
// ─────────────────────────────────────────────────────────────

class _CategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  final List<dynamic> categories;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double horizontalPadding;

  _CategoryTabsDelegate({
    required this.categories,
    required this.selectedIndex,
    required this.onChanged,
    required this.horizontalPadding,
  });

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: overlapsContent
                ? colorScheme.outline
                : Colors.transparent,
            width: 0.5,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          final String label = i == 0 ? 'All' : categories[i - 1].name;
          
          return GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 0.3,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2.5,
                  width: selected ? 24 : 0,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryTabsDelegate old) =>
      old.selectedIndex != selectedIndex ||
      old.categories != categories ||
      old.horizontalPadding != horizontalPadding;
}

// ─────────────────────────────────────────────────────────────
// PROMO BANNER CAROUSEL
// ─────────────────────────────────────────────────────────────

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
              Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF1A1A2E)),
              ),
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

// ─────────────────────────────────────────────────────────────
// BANNER CAROUSEL FALLBACK PLACEHOLDER
// ─────────────────────────────────────────────────────────────

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
