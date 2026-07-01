import '../domain/entities/visual_search_result.dart';
import '../domain/failures/visual_search_failure.dart';

/// Sealed class for visual search state
sealed class VisualSearchState {}

/// Idle state - no action in progress
class VSIdle extends VisualSearchState {}

/// User is selecting image source (camera/gallery)
class VSPickingSource extends VisualSearchState {}

/// Analyzing image - shows stage animation
class VSAnalyzing extends VisualSearchState {
  final AnalysisStage stage;

  VSAnalyzing(this.stage);
}

/// Search completed successfully
class VSSuccess extends VisualSearchState {
  final VisualSearchResult result;

  VSSuccess(this.result);
}

/// Search failed
class VSFailure extends VisualSearchState {
  final VisualSearchFailure failure;

  VSFailure(this.failure);
}

/// Analysis stages for animation
enum AnalysisStage {
  analyzingProduct, // "Analyzing Product..."
  detectingItem, // "Detecting Fashion Item..."
  searchingCatalog, // "Searching Catalog..."
  findingBestMatch, // "Finding Best Match..."
}

/// Get display text for each stage
extension AnalysisStageExtension on AnalysisStage {
  String get displayText {
    switch (this) {
      case AnalysisStage.analyzingProduct:
        return 'Analyzing Product...';
      case AnalysisStage.detectingItem:
        return 'Detecting Fashion Item...';
      case AnalysisStage.searchingCatalog:
        return 'Searching Catalog...';
      case AnalysisStage.findingBestMatch:
        return 'Finding Best Match...';
    }
  }
}
