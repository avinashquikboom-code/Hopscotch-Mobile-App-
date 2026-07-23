import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hopscotch/api/api_circuit_breaker.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/utils/dev_logger.dart';
import 'package:hopscotch/repositories/product_repository.dart';
import 'package:hopscotch/repositories/category_repository.dart';

import 'package:hopscotch/repositories/banner_repository.dart';
import 'package:hopscotch/widgets/animated_search_hint.dart';
import 'package:hopscotch/widgets/district_hero_header.dart';
import 'package:hopscotch/widgets/product_card.dart';
import 'package:hopscotch/widgets/trending_product_card.dart';
import 'package:hopscotch/widgets/skeleton_loaders.dart';
import 'package:hopscotch/l10n/app_localizations.dart';
import 'dart:io';
import 'package:hopscotch/widgets/visual_search_bottom_sheet.dart';
import 'package:hopscotch/repositories/profile_repository.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/widgets/flipkart_category_strip.dart';
import 'package:hopscotch/utils/navigation_utils.dart';

// ─────────────────────────────────────────────────────────────
// LOCATION PROVIDER — Geolocates user address details
// ─────────────────────────────────────────────────────────────

class UserLocation {
  final String area; // "Sector 8"
  final String city; // "Kopar Khairane, Navi Mumbai"
  const UserLocation({required this.area, required this.city});
}

final userLocationProvider = FutureProvider<UserLocation>((ref) async {
  try {
    // 1. Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const UserLocation(
        area: 'Location disabled',
        city: 'Enable GPS & tap to retry',
      );
    }

    // 2. Check & Request permissions
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const UserLocation(
        area: 'Permission denied',
        city: 'Tap to grant permission',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      return const UserLocation(
        area: 'Permission blocked',
        city: 'Enable in settings & tap',
      );
    }

    // 3. Try to get last known position first (instant)
    Position? pos = await Geolocator.getLastKnownPosition();

    // 4. If last known is null, request current position with a timeout
    if (pos == null) {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 4));
    }

    // 5. Geocode the coordinates with a timeout
    final placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    ).timeout(const Duration(seconds: 4));

    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      final area = p.subLocality?.isNotEmpty == true
          ? p.subLocality!
          : (p.locality?.isNotEmpty == true
                ? p.locality!
                : (p.subAdministrativeArea ?? 'Detected Location'));

      final city = [
        p.locality,
        p.administrativeArea,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      return UserLocation(area: area, city: city);
    }
  } catch (e) {
    DevLogger.logError(
      'Error getting location: $e',
      context: 'UserLocationProvider',
    );
    try {
      final fallbackPos = await Geolocator.getLastKnownPosition();
      if (fallbackPos != null) {
        final placemarks = await placemarkFromCoordinates(
          fallbackPos.latitude,
          fallbackPos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final area = p.subLocality?.isNotEmpty == true
              ? p.subLocality!
              : (p.locality ?? 'Detected Location');
          final city = [
            p.locality,
            p.administrativeArea,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          return UserLocation(area: area, city: city);
        }
      }
    } catch (_) {}
  }
  return const UserLocation(
    area: 'Set location',
    city: 'Tap to retry location detection',
  );
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
  late final ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      if (offset != _scrollOffset) {
        setState(() {
          _scrollOffset = offset;
        });
      }
    }
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
    // Card uses Expanded for image — childAspectRatio controls total cell height.
    // 0.65 gives a nice tall card with plenty of image + room for info.
    final double childAspectRatio = isDesktop ? 0.72 : (isTablet ? 0.70 : 0.72);

    final double trendingHeight = isDesktop ? 270 : (isTablet ? 250 : 230);

    final location = ref.watch(userLocationProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    final categoriesAsync = ref.watch(allCategoriesProvider);
    final categories = categoriesAsync.value ?? [];

    final trendingAsync = ref.watch(trendingProductsProvider);
    final newArrivalsAsync = ref.watch(newArrivalsProvider);
    final bannersAsync = ref.watch(bannersProvider);

    final bool hasCircuitBreakerError = ApiCircuitBreaker.isOpen ||
        (categoriesAsync.hasError && trendingAsync.hasError && bannersAsync.hasError);

    if (hasCircuitBreakerError) {
      return Scaffold(
        body: SafeArea(
          child: _CircuitBreakerErrorView(
            onRetry: () {
              ApiCircuitBreaker.reset();
              ref.invalidate(allCategoriesProvider);
              ref.invalidate(trendingProductsProvider);
              ref.invalidate(newArrivalsProvider);
              ref.invalidate(bannersProvider);
              ref.invalidate(userLocationProvider);
            },
          ),
        ),
      );
    }

    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;

    // Hero height: status bar + location row + search bar + 16:9 image area
    // The image bleeds behind the status bar (edge-to-edge like District / Play Store)
    final double imageArea = isDesktop
        ? 360
        : (isTablet ? 300 : size.width * 9 / 16);
    final double heroHeight = isDesktop
        ? 420
        : (isTablet ? 400 : topPadding + 116 + imageArea);

    // Rotating search hints (Flipkart style)
    const _searchHints = [
      'silk sarees',
      'kurtas',
      'lehengas',
      'co-ord sets',
      'dresses',
      'dupattas',
      'ethnic wear',
      'western tops',
    ];

    // ── Search bar widget (shared between banner overlay & tab header) ──
    final Widget searchBarWidget = Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search'),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.white70, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSearchHint(
                        prefix: 'Search for ',
                        hints: _searchHints,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            padding: const EdgeInsets.only(right: 16),
            constraints: const BoxConstraints(),
            onPressed: _showImageSourceBottomSheet,
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );

    // ── Location row for banner overlay (white text + white icon) ──
    final Widget heroLocationRow = Row(
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.white, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => ref.invalidate(userLocationProvider),
            child: location.when(
              loading: () =>
                  const _HeroLocationText(area: 'Detecting…', city: ' '),
              error: (_, __) => const _HeroLocationText(
                area: 'Set location',
                city: 'Tap to choose',
              ),
              data: (loc) => _HeroLocationText(area: loc.area, city: loc.city),
            ),
          ),
        ),
        const _ProfileAvatarButton(),
      ],
    );

    final List<Widget> slivers = [
      // ── HERO: full-bleed banner that bleeds behind the status bar ──
      if (_selectedTab == 0 &&
          (bannersAsync.isLoading ||
              (bannersAsync.value != null && bannersAsync.value!.isNotEmpty)))
        SliverAppBar(
          expandedHeight: heroHeight,
          collapsedHeight: 0,
          toolbarHeight: 0,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          pinned: false,
          floating: false,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.none,
            background: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              child: DistrictHeroHeader(
                height: heroHeight,
                isLoading: bannersAsync.isLoading,
                banners: bannersAsync.value ?? const [],
                onExplore: (banner) {
                  final link = banner.link;
                  if (link != null) context.push(link);
                },
                topRow: heroLocationRow,
                searchBar: searchBarWidget,
              ),
            ),
          ),
        )
      else ...[
        // ── STICKY HEADER for category tabs (location + themed search bar) ──
        SliverAppBar(
          pinned: true,
          floating: false,
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          toolbarHeight: topPadding + 110,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref.invalidate(userLocationProvider),
                          child: location.when(
                            loading: () => const _LocationText(
                              area: 'Detecting…',
                              city: ' ',
                            ),
                            error: (_, __) => const _LocationText(
                              area: 'Set location',
                              city: 'Tap to choose',
                            ),
                            data: (loc) =>
                                _LocationText(area: loc.area, city: loc.city),
                          ),
                        ),
                      ),
                      const _ProfileAvatarButton(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSearchBar(context, responsive, l10n, 0),
                ],
              ),
            ),
          ),
        ),
      ],

      // ── FLIPKART MORPHING CATEGORY STRIP ──
      SliverPersistentHeader(
        pinned: true,
        delegate: FlipkartCategoryStripDelegate(
          categories: categories,
          selectedIndex: _selectedTab,
          onChanged: (i) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0.0);
            }
            setState(() => _selectedTab = i);
          },
          horizontalPadding: horizontalPadding,
          topPadding: _selectedTab == 0 ? topPadding : 0,
        ),
      ),
    ];

    // 4. MAIN CONTENT
    if (_selectedTab == 0) {
      // Home Feed (All tab selected)
      slivers.addAll([
        // Trending Products Header — Premium styled
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: _TrendingHighlightsSectionHeader(
              title: l10n.trendingHighlights,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: responsive.spacing(AppTheme.spaceS)),
        ),

        // Trending list
        SliverToBoxAdapter(
          child: SizedBox(
            height: trendingHeight,
            child: trendingAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Container(
                    height: trendingHeight,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 44,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No trending products available',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: responsive.fontSize14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Container(
                      width: responsive.spacing(160),
                      margin: EdgeInsets.only(
                        right: responsive.spacing(12),
                      ),
                      child: TrendingProductCard(
                        product: product,
                        heroTagPrefix: 'home_trending',
                        onTap: () => safeNavigate(
                          context,
                          '/product/${product.id}?heroTagPrefix=home_trending',
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                itemCount: 3,
                itemBuilder: (context, index) => Container(
                  width: responsive.spacing(160),
                  margin: EdgeInsets.only(
                    right: responsive.spacing(12),
                  ),
                  child: const ProductCardSkeleton(),
                ),
              ),
              error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
        ),

        // New Arrivals Header — Premium "The New Guard" Card
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: _NewGuardSectionHeader(
              title: l10n.theNewGuard,
              onSeeAll: () => safeNavigate(
                context,
                '/products?section=new_arrivals',
              ),
              seeAllLabel: 'Show All',
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: responsive.spacing(AppTheme.spaceS)),
        ),

        // New Arrivals Grid
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: newArrivalsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.new_releases_outlined,
                          size: 44,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No new arrivals available',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: responsive.fontSize14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final displayProducts = products.take(4).toList();
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: mainAxisSpacing,
                  crossAxisSpacing: crossAxisSpacing,
                  childAspectRatio: childAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = displayProducts[index];
                  return ProductCard(
                    product: product,
                    heroTagPrefix: 'home_new',
                    onTap: () => safeNavigate(
                      context,
                      '/product/${product.id}?heroTagPrefix=home_new',
                    ),
                  );
                }, childCount: displayProducts.length),
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
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]);
    } else {
      // Category Tab Selected
      final selectedCategory = categories[_selectedTab - 1];
      final categoryProductsAsync = ref.watch(
        categoryProductsProvider(selectedCategory.id.toString()),
      );

      slivers.addAll([
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(selectedCategory.name, style: responsive.headline5),
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    heroTagPrefix: 'category_${selectedCategory.id}',
                    onTap: () => safeNavigate(
                      context,
                      '/product/${product.id}?heroTagPrefix=category_${selectedCategory.id}',
                    ),
                  );
                }, childCount: products.length),
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
      controller: _scrollController,
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
        edgeOffset: topPadding,
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

  Widget _buildSearchBar(
    BuildContext context,
    dynamic responsive,
    AppLocalizations l10n,
    double horizontalPadding,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/search'),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedSearchHint(
                          prefix: 'Search for ',
                          hints: const [
                            'silk sarees',
                            'kurtas',
                            'lehengas',
                            'co-ord sets',
                            'dresses',
                            'dupattas',
                            'ethnic wear',
                            'western tops',
                          ],
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
            IconButton(
              padding: const EdgeInsets.only(right: 16),
              constraints: const BoxConstraints(),
              onPressed: _showImageSourceBottomSheet,
              icon: Icon(
                Icons.camera_alt_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
          ],
        ),
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
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: onSurface),
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
// REDESIGNED PREMIUM USER PROFILE AVATAR BUTTON
// ─────────────────────────────────────────────────────────────

class _ProfileAvatarButton extends ConsumerStatefulWidget {
  const _ProfileAvatarButton();

  @override
  ConsumerState<_ProfileAvatarButton> createState() =>
      _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends ConsumerState<_ProfileAvatarButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(profileNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    String? initials;
    if (userProfile != null) {
      final name = userProfile['firstName'] ?? userProfile['name'];
      if (name != null && name.toString().isNotEmpty) {
        initials = name.toString().trim().substring(0, 1).toUpperCase();
      }
    }

    final rawAvatarUrl = userProfile?['avatarUrl']?.toString();
    final avatarUrl = (rawAvatarUrl != null && rawAvatarUrl.isNotEmpty)
        ? AppUrls.resolveUrl(rawAvatarUrl)
        : null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () => context.push('/profile'),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.8),
                colorScheme.secondary.withValues(alpha: 0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(2.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
            ),
            clipBehavior: Clip.antiAlias,
            child: CircleAvatar(
              backgroundColor: colorScheme.surface,
              backgroundImage:
                  (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              onBackgroundImageError:
                  (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                  ? (exception, stackTrace) {}
                  : null,
              child: (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                  ? null
                  : (initials != null
                        ? Text(
                            initials,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          )),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WHITE LOCATION TEXT — overlaid on banner image
// ─────────────────────────────────────────────────────────────

class _HeroLocationText extends StatelessWidget {
  final String area;
  final String city;
  const _HeroLocationText({required this.area, required this.city});

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(color: Colors.black54, blurRadius: 6)];
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: shadow,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Colors.white,
            ),
          ],
        ),
        if (city.isNotEmpty)
          Text(
            city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              shadows: shadow,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREMIUM "TRENDING HIGHLIGHTS" SECTION HEADER
// ─────────────────────────────────────────────────────────────

class _TrendingHighlightsSectionHeader extends StatefulWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final String? seeAllLabel;

  const _TrendingHighlightsSectionHeader({
    required this.title,
    this.onSeeAll,
    this.seeAllLabel,
  });

  @override
  State<_TrendingHighlightsSectionHeader> createState() =>
      _TrendingHighlightsSectionHeaderState();
}

class _TrendingHighlightsSectionHeaderState
    extends State<_TrendingHighlightsSectionHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Trending uses a refined teal palette matching the app theme
    const accentA = Color(0xFF0d9488); // teal-600
    const accentB = Color(0xFF14b8a6); // teal-500

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface
            : const Color(0xFF0d9488).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: const Color(0xFF0d9488)
              .withValues(alpha: isDark ? 0.22 : 0.14),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ── Gradient accent bar (orange) ──────────────────────
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accentA, accentB],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: accentA.withValues(alpha: 0.40),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Title + "HOT" badge ───────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Animated shimmer "HOT" badge
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: const [
                                Color(0xFF0d9488),
                                Color(0xFF2dd4bf),
                                Color(0xFF0d9488),
                              ],
                              stops: [
                                (_shimmerController.value - 0.3)
                                    .clamp(0.0, 1.0),
                                _shimmerController.value.clamp(0.0, 1.0),
                                (_shimmerController.value + 0.3)
                                    .clamp(0.0, 1.0),
                              ],
                            ).createShader(bounds);
                          },
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentA.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                            color: accentA.withValues(alpha: 0.30),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          '🔥 HOT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'What everyone is shopping right now',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          // ── See All pill (orange gradient) ────────────────────
          if (widget.onSeeAll != null && widget.seeAllLabel != null)
            GestureDetector(
              onTap: widget.onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [accentA, accentB],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: accentA.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.seeAllLabel!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREMIUM "THE NEW GUARD" SECTION HEADER
// ─────────────────────────────────────────────────────────────

class _NewGuardSectionHeader extends StatefulWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final String? seeAllLabel;

  const _NewGuardSectionHeader({
    required this.title,
    this.onSeeAll,
    this.seeAllLabel,
  });

  @override
  State<_NewGuardSectionHeader> createState() => _NewGuardSectionHeaderState();
}

class _NewGuardSectionHeaderState extends State<_NewGuardSectionHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface
            : AppTheme.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.20 : 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ── Gradient left accent bar ──────────────────────────
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0d9488), Color(0xFF14b8a6)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Title + "NEW" badge ───────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Animated shimmer "NEW" badge
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: const [
                                Color(0xFF0d9488),
                                Color(0xFF5eead4),
                                Color(0xFF0d9488),
                              ],
                              stops: [
                                (_shimmerController.value - 0.3).clamp(
                                  0.0,
                                  1.0,
                                ),
                                _shimmerController.value.clamp(0.0, 1.0),
                                (_shimmerController.value + 0.3).clamp(
                                  0.0,
                                  1.0,
                                ),
                              ],
                            ).createShader(bounds);
                          },
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.30,
                            ),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Freshest arrivals, just for you',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          // ── See All pill button ───────────────────────────────
          if (widget.onSeeAll != null && widget.seeAllLabel != null)
            GestureDetector(
              onTap: widget.onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0d9488), Color(0xFF14b8a6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.seeAllLabel!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircuitBreakerErrorView extends ConsumerWidget {
  final VoidCallback onRetry;
  const _CircuitBreakerErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ApiCircuitBreaker.remainingCooldownSeconds;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              "Can't connect right now",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              remaining > 0
                  ? "Too many requests. Please wait $remaining seconds before trying again."
                  : "We're having trouble connecting to the server.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
