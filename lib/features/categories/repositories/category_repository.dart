import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/providers/api_provider.dart';
import '../../../../core/dummy_data/dummy_data.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final ApiService _apiService;

  CategoryRepository(this._apiService);

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiService.get('/api/categories');
      if (response.statusCode == 200) {
        final data = response.data;
        final List? rawList = data is Map ? data['data'] : data;
        if (rawList != null) {
          const apiBase = ApiService.baseUrl;
          return rawList.map((c) {
            final id = c['id']?.toString() ?? '';
            final name = c['name']?.toString() ?? '';
            String imageUrl = 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=600&auto=format&fit=crop&q=80';
            
            final iconUrlVal = c['iconUrl']?.toString() ?? c['bannerUrl']?.toString();
            if (iconUrlVal != null && iconUrlVal.isNotEmpty) {
              imageUrl = iconUrlVal.startsWith('http') ? iconUrlVal : '$apiBase/$iconUrlVal';
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
      }
    } catch (e) {
      print('[CategoryRepository] Error fetching categories: $e');
    }

    await Future.delayed(const Duration(milliseconds: 300));
    return DummyData.dummyCategories.map((e) => CategoryModel.fromJson(e)).toList();
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
