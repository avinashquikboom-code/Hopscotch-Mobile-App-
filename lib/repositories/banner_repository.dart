import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/providers/api_provider.dart';
import 'package:hopscotch/utils/dev_logger.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/banner_model.dart';

class BannerRepository {
  static List<BannerModel>? _cachedBanners;
  static DateTime? _cacheTime;
  static const Duration _cacheTtl = Duration(minutes: 10);
  static Future<List<BannerModel>>? _inflight;

  static bool get _isCacheValid =>
      _cachedBanners != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  static void clearCache() {
    _cachedBanners = null;
    _cacheTime = null;
    _inflight = null;
  }

  final ApiService _apiService;

  BannerRepository(this._apiService);

  Future<List<BannerModel>> getBanners({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedBanners!;
    }
    if (_inflight != null) {
      return _inflight!;
    }
    _inflight = _fetchFromApi();
    try {
      final res = await _inflight!;
      _cachedBanners = res;
      _cacheTime = DateTime.now();
      return res;
    } finally {
      _inflight = null;
    }
  }

  Future<List<BannerModel>> _fetchFromApi() async {
    try {
      final response = await _apiService.get(AppUrls.banners);
      if (response.statusCode == 200) {
        final data = response.data;
        final List? rawList = data is Map ? data['data'] : data;
        if (rawList != null) {
          return rawList.map((b) {
            final id = b['id']?.toString() ?? '';
            final imageUrl = b['imageUrl']?.toString() ?? b['image']?.toString() ?? '';
            final fullImageUrl = AppUrls.resolveUrl(imageUrl);
            
            return BannerModel(
              id: id,
              imageUrl: fullImageUrl,
              title: b['title']?.toString() ?? '',
              subtitle: (b['subtitle'] ?? b['description'])?.toString(),
              link: b['link']?.toString(),
              order: b['order'] as int? ?? 0,
              isActive: b['isActive'] as bool? ?? b['active'] as bool? ?? true,
            );
          }).toList();
        }
      } else if (response.statusCode == 404) {
        DevLogger.logError('Banners endpoint not found', context: 'BannerRepository');
      }
    } catch (e) {
      DevLogger.logError('Error fetching banners: $e', context: 'BannerRepository');
      if (_cachedBanners != null) {
        return _cachedBanners!;
      }
    }

    return [];
  }
}

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return BannerRepository(apiService);
});

final bannersProvider = FutureProvider<List<BannerModel>>((ref) {
  return ref.watch(bannerRepositoryProvider).getBanners();
});
