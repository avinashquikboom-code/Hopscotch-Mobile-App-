import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:hopscotch/features/categories/repositories/category_repository.dart';
import '../../../core/widgets/category_card.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import 'package:hopscotch/features/categories/models/category_model.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _showSubcategoriesSheet(BuildContext context, CategoryModel category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8FAFC), // Premium light ivory canvas
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXXL),
          topRight: Radius.circular(AppTheme.radiusXXL),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL, vertical: AppTheme.spaceL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delicate Champagne Gold Handle Indicator
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC59F3E).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                
                // Serif Luxury Title & Description
                Text(
                  category.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore hand-curated luxury subdivisions.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor.withOpacity(0.85),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                
                // Premium borderless subcategories list
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: category.subcategories.length + 1, // +1 for "Shop All"
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderColor),
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final subcat = isAll ? 'Shop All ${category.name}' : category.subcategories[index - 1];
                      
                      return InkWell(
                        onTap: () {
                          context.pop(); // Close bottom sheet
                          if (isAll) {
                            context.push('/products?categoryId=${category.id}&categoryName=${category.name}');
                          } else {
                            context.push('/products?categoryId=${category.id}&subcategory=$subcat&categoryName=$subcat');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                subcat,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isAll ? FontWeight.bold : FontWeight.w500,
                                  color: isAll ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                                  letterSpacing: isAll ? 0.5 : 0.0,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: AppTheme.textLightColor,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('COUTURE DEPARTMENTS'),
        elevation: 0,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final width = MediaQuery.of(context).size.width;
          final crossAxisCount = width < 600 ? 1 : (width < 900 ? 2 : 3);

          if (crossAxisCount == 1) {
            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spaceXL).copyWith(bottom: 120),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceL),
                  child: CategoryCard(
                    category: category,
                    isCircular: false,
                    onTap: () => _showSubcategoriesSheet(context, category),
                  ),
                );
              },
            );
          } else {
            return GridView.builder(
              padding: const EdgeInsets.all(AppTheme.spaceXL).copyWith(bottom: 120),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppTheme.spaceL,
                mainAxisSpacing: AppTheme.spaceL,
                childAspectRatio: 1.8,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return CategoryCard(
                  category: category,
                  isCircular: false,
                  onTap: () => _showSubcategoriesSheet(context, category),
                );
              },
            );
          }
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceXL),
          itemCount: 4,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spaceL),
            child: CategoryCardSkeleton(),
          ),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
