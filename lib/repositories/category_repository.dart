import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/utils/dev_logger.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/category_model.dart';

class CategoryRepository {
  static List<CategoryModel>? _cachedCategories;
  static DateTime? _cacheTime;
  static const Duration _cacheTtl = Duration(minutes: 10);
  static Future<List<CategoryModel>>? _inflight;

  static bool get _isCacheValid =>
      _cachedCategories != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  static void clearCache() {
    _cachedCategories = null;
    _cacheTime = null;
    _inflight = null;
  }

  final ApiService _apiService;

  CategoryRepository(this._apiService);

  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedCategories!;
    }
    if (_inflight != null) {
      return _inflight!;
    }
    _inflight = _fetchFromApi();
    try {
      final res = await _inflight!;
      _cachedCategories = res;
      _cacheTime = DateTime.now();
      return res;
    } finally {
      _inflight = null;
    }
  }

  Future<List<CategoryModel>> _fetchFromApi() async {
    try {
      final response = await _apiService.get(AppUrls.categories);
      if (response.statusCode == 200) {
        final data = response.data;
        final List? rawList = data is Map ? data['data'] : data;
        if (rawList != null) {
          return rawList.map((c) {
            final id = c['id']?.toString() ?? '';
            final name = c['name']?.toString() ?? '';
            
            String imageUrl = '';
            final iconUrlVal = c['iconUrl']?.toString() ?? c['bannerUrl']?.toString() ?? c['imageUrl']?.toString();
            if (iconUrlVal != null && iconUrlVal.isNotEmpty) {
              imageUrl = AppUrls.resolveUrl(iconUrlVal);
            }

            List<SubCategoryModel> subObjs = [];
            List<String> subs = [];

            final rawChildren = c['children'] ?? c['subcategories'];
            if (rawChildren is List) {
              for (final sub in rawChildren) {
                if (sub is Map<String, dynamic>) {
                  final subId = sub['id']?.toString() ?? '';
                  final subName = sub['name']?.toString() ?? '';
                  String subImg = '';
                  final subIconVal = sub['iconUrl']?.toString() ?? sub['bannerUrl']?.toString() ?? sub['imageUrl']?.toString();
                  if (subIconVal != null && subIconVal.isNotEmpty) {
                    subImg = AppUrls.resolveUrl(subIconVal);
                  } else {
                    subImg = imageUrl;
                  }

                  if (subName.isNotEmpty) {
                    subs.add(subName);
                    subObjs.add(SubCategoryModel(
                      id: subId.isNotEmpty ? subId : subName,
                      name: subName,
                      imageUrl: subImg,
                    ));
                  }
                } else if (sub != null) {
                  final subStr = sub.toString();
                  if (subStr.isNotEmpty) {
                    subs.add(subStr);
                    subObjs.add(SubCategoryModel(
                      id: subStr,
                      name: subStr,
                      imageUrl: imageUrl,
                    ));
                  }
                }
              }
            }

            final isFeatured = c['isFeatured'] as bool? ?? false;

            return CategoryModel(
              id: id,
              name: name,
              imageUrl: imageUrl,
              icon: c['iconUrl']?.toString(),
              subcategories: subs,
              subCategoryObjects: subObjs,
              isFeatured: isFeatured,
            );
          }).toList();
        }
      } else if (response.statusCode == 404) {
        DevLogger.logError('Categories endpoint not found', context: 'CategoryRepository');
      }
    } catch (e) {
      DevLogger.logError('Error fetching categories: $e', context: 'CategoryRepository');
      if (_cachedCategories != null) {
        return _cachedCategories!;
      }
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
