import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late PageController _bannerController;
  int _activeBanner = 0;

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'THE COUTURE SALE',
      'subtitle': 'Up to 30% Off New Autumwear',
      'action': 'Shop Couture',
      'image': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=600&q=80',
      'categoryId': 'cat_womens'
    },
    {
      'title': 'GENTLEMAN\'S APPAREL',
      'subtitle': 'English Wool Suits & Coats',
      'action': 'Explore Tailored',
      'image': 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&w=600&q=80',
      'categoryId': 'cat_mens'
    },
    {
      'title': 'ITALIAN CRADLE',
      'subtitle': 'Handcrafted Full-Grain Loafers',
      'action': 'View Footwear',
      'image': 'https://images.unsplash.com/photo-1614252369475-531eba835eb1?auto=format&fit=crop&w=600&q=80',
      'categoryId': 'cat_footwear'
    }
  ];

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final trendingAsync = ref.watch(trendingProductsProvider);
    final newArrivalsAsync = ref.watch(newArrivalsProvider);
    final notifications = ref.watch(notificationProvider);
    final unreadNotifications = notifications.where((n) => !n.isRead).length;

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
            padding: const EdgeInsets.only(bottom: 120), // Leave space for floating nav bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Premium App Bar Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL, vertical: AppTheme.spaceM),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AURA COUTURE',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user != null ? 'Hello, ${user.name.split(" ").first}' : 'Discover Luxury',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                              icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textPrimaryColor),
                              onPressed: () => context.push('/notifications'),
                            ),
                          ),
                          if (unreadNotifications > 0)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentColor,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadNotifications.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
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
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL, vertical: AppTheme.spaceS),
                  child: GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppTheme.textSecondaryColor, size: 22),
                          const SizedBox(width: AppTheme.spaceM),
                          Expanded(
                            child: Text(
                              'Search luxury knitwear, suits, silks...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textLightColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),

                // 3. Promotional Banner Carousel
                SizedBox(
                  height: 200,
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
                      return GestureDetector(
                        onTap: () => context.push('/products?categoryId=${banner['categoryId']}&categoryName=${banner['title']}'),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                            image: DecorationImage(
                              image: NetworkImage(banner['image']),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.black.withOpacity(0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(AppTheme.spaceXL),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                      ),
                                      child: Text(
                                        'LIMITED EDITION',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spaceS),
                                    Text(
                                      banner['title'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      banner['subtitle'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                // Carousel dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _promoBanners.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _activeBanner == index ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _activeBanner == index ? AppTheme.primaryColor : AppTheme.borderColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),

                // 4. Horizontal Categories
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Couture Collections',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => context.go('/categories'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                SizedBox(
                  height: 105,
                  child: categoriesAsync.when(
                    data: (categories) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: AppTheme.spaceXL),
                          child: CategoryCard(
                            category: category,
                            isCircular: true,
                            onTap: () => context.push('/products?categoryId=${category.id}&categoryName=${category.name}'),
                          ),
                        );
                      },
                    ),
                    loading: () => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                      itemCount: 5,
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(right: AppTheme.spaceXL),
                        child: SkeletonLoader(width: 70, height: 70, borderRadius: 35),
                      ),
                    ),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),

                // 5. Trending Products
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trending Highlights',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => context.push('/products?filter=trending&categoryName=Trending'),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                SizedBox(
                  height: 290,
                  child: trendingAsync.when(
                    data: (products) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Container(
                          width: 175,
                          margin: const EdgeInsets.only(right: AppTheme.spaceL),
                          child: ProductCard(
                            product: product,
                            heroTagPrefix: 'home_trending',
                            onTap: () => context.push('/product/${product.id}?heroTagPrefix=home_trending'),
                          ),
                        );
                      },
                    ),
                    loading: () => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        width: 175,
                        margin: const EdgeInsets.only(right: AppTheme.spaceL),
                        child: const ProductCardSkeleton(),
                      ),
                    ),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),

                // 6. New Arrivals
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'The New Guard',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => context.push('/products?filter=new&categoryName=New Arrivals'),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                SizedBox(
                  height: 290,
                  child: newArrivalsAsync.when(
                    data: (products) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Container(
                          width: 175,
                          margin: const EdgeInsets.only(right: AppTheme.spaceL),
                          child: ProductCard(
                            product: product,
                            heroTagPrefix: 'home_new',
                            onTap: () => context.push('/product/${product.id}?heroTagPrefix=home_new'),
                          ),
                        );
                      },
                    ),
                    loading: () => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                      itemCount: 3,
                      itemBuilder: (context, index) => Container(
                        width: 175,
                        margin: const EdgeInsets.only(right: AppTheme.spaceL),
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
