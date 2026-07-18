import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/utils/dev_logger.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/category_model.dart';

class CategoryRepository {
  final ApiService _apiService;

  CategoryRepository(this._apiService);

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiService.get(AppUrls.categories);
      if (response.statusCode == 200) {
        final data = response.data;
        final List? rawList = data is Map ? data['data'] : data;
        if (rawList != null) {
          return rawList.map((c) {
            final id = c['id']?.toString() ?? '';
            final name = c['name']?.toString() ?? '';
            String imageUrl = 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=600&auto=format&fit=crop&q=80';
            
            final iconUrlVal = c['iconUrl']?.toString() ?? c['bannerUrl']?.toString();
            if (iconUrlVal != null && iconUrlVal.isNotEmpty) {
              imageUrl = AppUrls.resolveUrl(iconUrlVal);
            }
            
            final isFeatured = c['isFeatured'] as bool? ?? false;
            
            return CategoryModel(
              id: id,
              name: name,
              imageUrl: imageUrl,
              icon: c['iconUrl']?.toString(),
              subcategories: [],
              isFeatured: isFeatured,
            );
          }).toList();
        }
      } else if (response.statusCode == 404) {
        DevLogger.logError('Categories endpoint not found', context: 'CategoryRepository');
      }
    } catch (e) {
      DevLogger.logError('Error fetching categories: $e', context: 'CategoryRepository');
      // Return empty list instead of throwing exception
      return [];
    }

    return [];
  }

  Future<List<CategoryModel>> getFeaturedCategories() async {
    final categories = await getCategories();
    return categories.where((element) => element.isFeatured).toList();
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CategoryRepository(apiService);
});

final allCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final featuredCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).getFeaturedCategories();
});
