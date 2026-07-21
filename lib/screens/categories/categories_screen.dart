import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/repositories/category_repository.dart';
import 'package:hopscotch/models/category_model.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/repositories/product_repository.dart';
import 'package:hopscotch/utils/navigation_utils.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final productsAsync = ref.watch(allProductsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Text(
          'All Categories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          final selectedCategory = categories[_selectedCategoryIndex < categories.length ? _selectedCategoryIndex : 0];
          
          // Get products from backend API for fallback / direct product binding
          final allProducts = productsAsync.asData?.value ?? [];
          final categoryProducts = allProducts.where(
            (p) => p.categoryId == selectedCategory.id || p.categoryId.toLowerCase() == selectedCategory.id.toLowerCase()
          ).toList();

          // Extract API subcategories strictly from backend
          final List<SubCategoryModel> liveSubcategories = [];
          if (selectedCategory.subCategoryObjects.isNotEmpty) {
            liveSubcategories.addAll(selectedCategory.subCategoryObjects);
          } else if (selectedCategory.subcategories.isNotEmpty) {
            for (final name in selectedCategory.subcategories) {
              liveSubcategories.add(SubCategoryModel(
                id: name,
                name: name,
                imageUrl: selectedCategory.imageUrl,
              ));
            }
          }

          // If no subcategories in category record, pull subcategories from live products in backend
          if (liveSubcategories.isEmpty) {
            final Set<String> addedSubs = {};
            for (final p in categoryProducts) {
              if (p.subcategory.isNotEmpty && !addedSubs.contains(p.subcategory.toLowerCase())) {
                addedSubs.add(p.subcategory.toLowerCase());
                liveSubcategories.add(SubCategoryModel(
                  id: p.subcategory,
                  name: p.subcategory,
                  imageUrl: p.imageUrl.isNotEmpty ? p.imageUrl : selectedCategory.imageUrl,
                ));
              }
            }
          }

          return Row(
            children: [
              // LEFT SIDEBAR: Clean inline indicator & category list (Strictly from API)
              Container(
                width: 96,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : const Color(0xFFF1F5F9),
                  border: Border(
                    right: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = index == _selectedCategoryIndex;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        height: 96,
                        color: isSelected
                            ? (isDark ? colorScheme.surface : Colors.white)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            // Flipkart Active Blue Left Strip
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: isSelected ? 4 : 0,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                            ),

                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Circular Category Image Avatar (API Image)
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? const Color(0xFFEFF6FF)
                                            : colorScheme.surface,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : colorScheme.outline.withValues(alpha: 0.12),
                                          width: isSelected ? 1.8 : 1,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: cat.imageUrl.isNotEmpty
                                            ? Image.network(
                                                cat.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Center(
                                                  child: Icon(
                                                    Icons.category_outlined,
                                                    size: 22,
                                                    color: isSelected ? AppTheme.primaryColor : colorScheme.onSurface.withValues(alpha: 0.5),
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons.category_outlined,
                                                  size: 22,
                                                  color: isSelected ? AppTheme.primaryColor : colorScheme.onSurface.withValues(alpha: 0.5),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cat.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : colorScheme.onSurface.withValues(alpha: 0.8),
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // RIGHT SIDE: Stable Top Banner Card + Scrollable Subcategories & Products
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: Container(
                    key: ValueKey('cat_${selectedCategory.id}_$_selectedCategoryIndex'),
                    color: colorScheme.surface,
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. STABLE / FIXED HERO PROMOTIONAL BANNER CARD (PINNED AT TOP)
                        GestureDetector(
                          onTap: () {
                            safeNavigate(
                              context,
                              '/products?categoryId=${selectedCategory.id}&categoryName=${selectedCategory.name}',
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEBF3FF), Color(0xFFD6E4FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedCategory.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Explore top offers in ${selectedCategory.name}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'View All',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 8.5),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selectedCategory.imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      selectedCategory.imageUrl,
                                      width: 68,
                                      height: 68,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 68,
                                        height: 68,
                                        color: Colors.white.withValues(alpha: 0.5),
                                        child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 2. SCROLLABLE CONTENT AREA UNDERNEATH STABLE TOP CARD
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subcategories Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${selectedCategory.name} Stores',
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        safeNavigate(
                                          context,
                                          '/products?categoryId=${selectedCategory.id}&categoryName=${selectedCategory.name}',
                                        );
                                      },
                                      child: const Text(
                                        'See All',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Subcategories Layout (API driven)
                                if (liveSubcategories.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 28.0),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(Icons.style_outlined, size: 32, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text(
                                          'No subcategories available',
                                          style: TextStyle(color: Colors.grey, fontSize: 12.5),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (liveSubcategories.length == 1)
                                  // Single Subcategory Feature Banner Card
                                  Builder(
                                    builder: (context) {
                                      final sub = liveSubcategories.first;
                                      return GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          safeNavigate(
                                            context,
                                            '/products?categoryId=${selectedCategory.id}&subcategory=${sub.name}&categoryName=${sub.name}',
                                          );
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: colorScheme.outline.withValues(alpha: 0.1),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.02),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  color: const Color(0xFFEFF6FF),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: sub.imageUrl.isNotEmpty
                                                      ? Image.network(
                                                          sub.imageUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                                            Icons.style_outlined,
                                                            color: AppTheme.primaryColor,
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.style_outlined,
                                                          color: AppTheme.primaryColor,
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      sub.name,
                                                      style: const TextStyle(
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Explore ${sub.name} collection',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 13,
                                                color: AppTheme.primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                else
                                  // Multi-Subcategory 3-Column Grid
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.78,
                                    ),
                                    itemCount: liveSubcategories.length,
                                    itemBuilder: (context, index) {
                                      final sub = liveSubcategories[index];

                                      return GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          safeNavigate(
                                            context,
                                            '/products?categoryId=${selectedCategory.id}&subcategory=${sub.name}&categoryName=${sub.name}',
                                          );
                                        },
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFC),
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: colorScheme.outline.withValues(alpha: 0.1),
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.02),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(14),
                                                  child: sub.imageUrl.isNotEmpty
                                                      ? Image.network(
                                                          sub.imageUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => Center(
                                                            child: Icon(
                                                              Icons.style_outlined,
                                                              color: AppTheme.primaryColor.withValues(alpha: 0.5),
                                                              size: 24,
                                                            ),
                                                          ),
                                                        )
                                                      : Center(
                                                          child: Icon(
                                                            Icons.style_outlined,
                                                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                                                            size: 24,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              sub.name,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface.withValues(alpha: 0.9),
                                                height: 1.15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                const SizedBox(height: 20),

                                // Products Section from Backend API
                                if (categoryProducts.isNotEmpty) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Products in ${selectedCategory.name}',
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF047857).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'BUY NOW',
                                          style: TextStyle(
                                            color: Color(0xFF047857),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.70,
                                    ),
                                    itemCount: categoryProducts.length > 6 ? 6 : categoryProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = categoryProducts[index];

                                      return GestureDetector(
                                        onTap: () {
                                          HapticFeedback.heavyImpact();
                                          ref.read(cartProvider.notifier).addToCart(product);
                                          safeNavigate(context, '/checkout');
                                        },
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF8FAFC),
                                                        borderRadius: BorderRadius.circular(14),
                                                        border: Border.all(
                                                          color: colorScheme.outline.withValues(alpha: 0.08),
                                                        ),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(14),
                                                        child: Image.network(
                                                          product.imageUrl,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.style_outlined),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 0,
                                                    left: 0,
                                                    right: 0,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                                      decoration: const BoxDecoration(
                                                        color: AppTheme.accentColor,
                                                        borderRadius: BorderRadius.only(
                                                          bottomLeft: Radius.circular(14),
                                                          bottomRight: Radius.circular(14),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'BUY NOW',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 8.5,
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '₹${product.price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
