import 'dart:io';
import 'package:hopscotch/visual_search/domain/entities/visual_search_result.dart';
import 'package:hopscotch/repositories/image_matching_repository.dart';
import 'package:hopscotch/visual_search/data/services/local_image_matching_service.dart';

/// Local implementation of ImageMatchingRepository
/// Uses LocalImageMatchingService to search offline matching products
class LocalImageMatchingRepository implements ImageMatchingRepository {
  final LocalImageMatchingService _matchingService;

  LocalImageMatchingRepository({
    required LocalImageMatchingService matchingService,
  }) : _matchingService = matchingService;

  @override
  Future<VisualSearchResult> search(File image) async {
    return await _matchingService.matchImage(image);
  }
}
