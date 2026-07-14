import 'dart:io';
import 'package:hopscotch/visual_search/domain/entities/visual_search_result.dart';

/// Abstract repository for image matching
/// This is the swap point - implementations can be swapped without changing UI
/// LocalImageMatchingRepository uses local SQLite + perceptual hashing
/// Future GeminiImageMatchingRepository would use real AI service
abstract class ImageMatchingRepository {
  /// Takes a picked image file and returns either an exact product,
  /// a ranked list of similar products, or a typed failure
  /// Throws VisualSearchFailure on error
  Future<VisualSearchResult> search(File image);
}
