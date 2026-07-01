import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_text.dart';
import 'package:hopscotch/features/product/repositories/product_repository.dart';
import 'package:hopscotch/features/categories/repositories/category_repository.dart';
import 'package:hopscotch/features/auth/repositories/auth_repository.dart';
import 'package:hopscotch/features/profile/repositories/notification_repository.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/category_card.dart';
import '../../../core/widgets/skeleton_loaders.dart';

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

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'THE COUTURE SALE',
      'subtitle': 'Up to 30% Off New Autumwear',
      'action': 'Shop Couture',
      'image':
          'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=600&q=80',
      'categoryId': 'cat_womens',
    },
    {
      'title': 'GENTLEMAN\'S APPAREL',
      'subtitle': 'English Wool Suits & Coats',
      'action': 'Explore Tailored',
      'image':
          'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&w=600&q=80',
      'categoryId': 'cat_mens',
    },
    {
      'title': 'ITALIAN CRADLE',
      'subtitle': 'Handcrafted Full-Grain Loafers',
      'action': 'View Footwear',
      'image':
          'https://images.unsplash.com/photo-1614252369475-531eba835eb1?auto=format&fit=crop&w=600&q=80',
      'categoryId': 'cat_footwear',
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final newArrivalsAsync = ref.watch(newArrivalsProvider);
    final notifications = ref.watch(notificationProvider);
    final unreadNotifications = notifications.where((n) => !n.isRead).length;
    final responsive = context.responsive;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allCategoriesProvider);
            ref.invalidate(trendingProductsProvider);
            ref.invalidate(newArrivalsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              bottom: 120,
            ), // Leave space for floating nav bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Premium App Bar Row
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(AppTheme.spaceXL),
                    vertical: responsive.spacing(AppTheme.spaceM),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AURA COUTURE',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                  fontSize: responsive.fontSize12,
                                ),
                          ),
                          SizedBox(height: responsive.spacing(2)),
                          Text(
                            user != null
                                ? 'Hello, ${user.name.split(" ").first}'
                                : 'Discover Luxury',
                            style: responsive.headline4,
                          ),
                        ],
                      ),
                      // Notifications Icon with badge
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.notifications_none_rounded,
                                color: AppTheme.textPrimaryColor,
                                size: responsive.iconSize(24),
                              ),
                              onPressed: () => context.push('/notifications'),
                            ),
                          ),
                          if (unreadNotifications > 0)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: EdgeInsets.all(responsive.spacing(4)),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentColor,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: responsive.iconSize(16),
                                  minHeight: responsive.iconSize(16),
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

                // 2. Animated Search Bar Row
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(AppTheme.spaceXL),
                    vertical: responsive.spacing(AppTheme.spaceS),
                  ),
                  child: GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(14),
                        horizontal: responsive.spacing(20),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppTheme.textSecondaryColor,
                            size: responsive.iconSize(22),
                          ),
                          SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                          Expanded(
                            child: Text(
                              'Search luxury knitwear, suits, silks...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: responsive.bodyMedium.copyWith(
                                color: AppTheme.textLightColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                // 3. Promotional Banner Carousel
                AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeController,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _fadeController,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: SizedBox(
                          height: responsive.spacing(200),
                          child: PageView.builder(
                            controller: _bannerController,
                            onPageChanged: (index) {
                              setState(() {
                                _activeBanner = index;
                              });
                            },
                            itemCount: _promoBanners.length,
                            itemBuilder: (context, index) {
                              final banner = _promoBanners[index];
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: EdgeInsets.symmetric(
                                  horizontal: responsive.spacing(
                                    AppTheme.spaceXL,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXL,
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(banner['image']),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: AppTheme.softShadow,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => context.push(
                                      '/products?categoryId=${banner['categoryId']}&categoryName=${banner['title']}',
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusXL,
                                    ),
                                    splashColor: Colors.white.withValues(
                                      alpha: 0.2,
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusXL,
                                                  ),
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Colors.black.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(
                                            responsive.spacing(
                                              AppTheme.spaceXL,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: responsive
                                                      .spacing(8),
                                                  vertical: responsive.spacing(
                                                    4,
                                                  ),
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accentColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppTheme.radiusS,
                                                      ),
                                                ),
                                                child: Text(
                                                  'LIMITED EDITION',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        responsive.fontSize10,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: responsive.spacing(
                                                  AppTheme.spaceS,
                                                ),
                                              ),
                                              Text(
                                                banner['title'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: responsive.headline1
                                                    .copyWith(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                              SizedBox(
                                                height: responsive.spacing(4),
                                              ),
                                              Text(
                                                banner['subtitle'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: responsive.bodySmall
                                                    .copyWith(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.85,
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                // Carousel dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _promoBanners.length,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(3),
                      ),
                      width: _activeBanner == index
                          ? responsive.spacing(16)
                          : responsive.spacing(6),
                      height: responsive.spacing(6),
                      decoration: BoxDecoration(
                        color: _activeBanner == index
                            ? AppTheme.primaryColor
                            : AppTheme.borderColor,
                        borderRadius: BorderRadius.circular(
                          responsive.spacing(3),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // 4. Horizontal Categories
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
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
                                'Couture Collections',
                                style: responsive.headline5,
                              ),
                              TextButton(
                                onPressed: () => context.go('/categories'),
                                child: Text(
                                  'View All',
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
                  height: responsive.spacing(105),
                  child: categoriesAsync.when(
                    data: (categories) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(AppTheme.spaceXL),
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return TweenAnimationBuilder<double>(
                          key: ValueKey('cat_$index'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Opacity(
                                opacity: value,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: responsive.spacing(AppTheme.spaceXL),
                                  ),
                                  child: CategoryCard(
                                    category: category,
                                    isCircular: true,
                                    onTap: () => context.push(
                                      '/products?categoryId=${category.id}&categoryName=${category.name}',
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
                      itemCount: 5,
                      itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(
                          right: responsive.spacing(AppTheme.spaceXL),
                        ),
                        child: SkeletonLoader(
                          width: responsive.spacing(70),
                          height: responsive.spacing(70),
                          borderRadius: responsive.spacing(35),
                        ),
                      ),
                    ),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceL)),

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
                                'Trending Highlights',
                                style: responsive.headline5,
                              ),
                              TextButton(
                                onPressed: () => context.push(
                                  '/products?filter=trending&categoryName=Trending',
                                ),
                                child: Text(
                                  'See All',
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
                    error: (err, stack) => Center(child: Text('Error: $err')),
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
                                'The New Guard',
                                style: responsive.headline5,
                              ),
                              TextButton(
                                onPressed: () => context.push(
                                  '/products?filter=new&categoryName=New Arrivals',
                                ),
                                child: Text(
                                  'See All',
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
                    error: (err, stack) => Center(child: Text('Error: $err')),
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
