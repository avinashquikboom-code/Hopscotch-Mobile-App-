import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/category_repository.dart';
import 'package:hopscotch/widgets/category_card.dart';
import 'package:hopscotch/widgets/skeleton_loaders.dart';
import 'package:hopscotch/models/category_model.dart';
import 'package:hopscotch/l10n/app_localizations.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _showSubcategoriesSheet(BuildContext context, CategoryModel category) {
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;
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
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(AppTheme.spaceXL),
              vertical: responsive.spacing(AppTheme.spaceL),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delicate Champagne Gold Handle Indicator
                Center(
                  child: Container(
                    width: responsive.spacing(36),
                    height: responsive.spacing(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC59F3E).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(
                        responsive.spacing(2),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // Serif Luxury Title & Description
                Text(
                  category.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: responsive.fontSize(20),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: responsive.spacing(4)),
                Text(
                  l10n.exploreSubcategories,
                  style: TextStyle(
                    fontSize: responsive.fontSize12,
                    color: AppTheme.textSecondaryColor.withValues(alpha: 0.85),
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                // Premium borderless subcategories list
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount:
                        category.subcategories.length + 1, // +1 for "Shop All"
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppTheme.borderColor),
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final subcat = isAll
                          ? '${l10n.shopAll} ${category.name}'
                          : category.subcategories[index - 1];

                      return InkWell(
                        onTap: () {
                          context.pop(); // Close bottom sheet
                          if (isAll) {
                            context.push(
                              '/products?categoryId=${category.id}&categoryName=${category.name}',
                            );
                          } else {
                            context.push(
                              '/products?categoryId=${category.id}&subcategory=$subcat&categoryName=$subcat',
                            );
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.spacing(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                subcat,
                                style: TextStyle(
                                  fontSize: responsive.fontSize14,
                                  fontWeight: isAll
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isAll
                                      ? AppTheme.primaryColor
                                      : AppTheme.textPrimaryColor,
                                  letterSpacing: isAll ? 0.5 : 0.0,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: responsive.iconSize(16),
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
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.coutureDepartments,
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final width = MediaQuery.of(context).size.width;
          final crossAxisCount = width < 600 ? 1 : (width < 900 ? 2 : 3);

          if (crossAxisCount == 1) {
            return ListView.builder(
              padding: const EdgeInsets.all(
                AppTheme.spaceXL,
              ).copyWith(bottom: 120),
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
              padding: const EdgeInsets.all(
                AppTheme.spaceXL,
              ).copyWith(bottom: 120),
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
        error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
      ),
    );
  }
}
