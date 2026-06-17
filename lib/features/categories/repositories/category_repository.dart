import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/dummy_data/dummy_data.dart';
import '../models/category_model.dart';

class CategoryRepository {
  Future<List<CategoryModel>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DummyData.dummyCategories.map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<List<CategoryModel>> getFeaturedCategories() async {
    final categories = await getCategories();
    return categories.where((element) => element.isFeatured).toList();
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final allCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final featuredCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).getFeaturedCategories();
});
