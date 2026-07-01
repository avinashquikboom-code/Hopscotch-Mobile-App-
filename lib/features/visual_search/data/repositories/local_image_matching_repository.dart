import 'dart:io';
import '../../domain/entities/visual_search_result.dart';
import '../../domain/repositories/image_matching_repository.dart';
import '../services/local_image_matching_service.dart';

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
