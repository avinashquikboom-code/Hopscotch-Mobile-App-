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

import 'package:hopscotch/repositories/banner_repository.dart';
import 'package:hopscotch/widgets/animated_search_hint.dart';
import 'package:hopscotch/widgets/district_hero_header.dart';
import 'package:hopscotch/widgets/product_card.dart';
import 'package:hopscotch/widgets/skeleton_loaders.dart';
import 'package:hopscotch/l10n/app_localizations.dart';
import 'dart:io';
import 'package:hopscotch/widgets/visual_search_bottom_sheet.dart';
import 'package:hopscotch/repositories/profile_repository.dart';
import 'package:hopscotch/widgets/flipkart_category_strip.dart';

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
    final double childAspectRatio = isDesktop ? 0.72 : (isTablet ? 0.68 : 0.65);

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

    // Hero height: status bar + location row + search bar + 16:9 image area
    // The image bleeds behind the status bar (edge-to-edge like District / Play Store)
    final double imageArea =
        isDesktop ? 360 : (isTablet ? 300 : size.width * 9 / 16);
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: Colors.white70, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSearchHint(
                        prefix: 'Search for ',
                        hints: _searchHints,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
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
              data: (loc) =>
                  _HeroLocationText(area: loc.area, city: loc.city),
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
              (bannersAsync.value != null &&
                  bannersAsync.value!.isNotEmpty)))
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
            background: DistrictHeroHeader(
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
                  horizontalPadding, 8, horizontalPadding, 8),
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
          topPadding: 0,
        ),
      ),
    ];


    // 4. MAIN CONTENT
    if (_selectedTab == 0) {
      // Home Feed (All tab selected)
      slivers.addAll([

        // Trending Products Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.trendingHighlights, style: responsive.headline5),
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
                );
              },
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

        SliverToBoxAdapter(
          child: SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
        ),

        // New Arrivals Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.theNewGuard, style: responsive.headline5),
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
                    heroTagPrefix: 'home_new',
                    onTap: () => context.push(
                      '/product/${product.id}?heroTagPrefix=home_new',
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
                    onTap: () => context.push(
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

    final avatarUrl = userProfile?['avatarUrl'];

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
