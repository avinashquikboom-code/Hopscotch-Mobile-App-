import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/repositories/image_matching_repository.dart';
import 'package:hopscotch/visual_search/domain/failures/visual_search_failure.dart';
import 'package:hopscotch/visual_search/application/visual_search_state.dart';

/// Controller for visual search
/// Manages state and coordinates between UI and repository
class VisualSearchController extends StateNotifier<VisualSearchState> {
  final ImageMatchingRepository _repository;

  VisualSearchController(this._repository) : super(VSIdle());

  /// Run visual search with the given image
  /// Plays stage animation concurrently with repository call
  Future<void> runSearch(File image) async {
    state = VSAnalyzing(AnalysisStage.analyzingImage);

    // Start stage animation timer
    final stageTimer = _playStageSequence();

    // Run actual search
    try {
      final result = await _repository.search(image);
      result.queryImage = image;

      // Wait for minimum perceived duration
      await stageTimer;

      state = VSSuccess(result);
    } on VisualSearchFailure catch (failure) {
      await stageTimer;
      state = VSFailure(failure);
    } catch (e) {
      await stageTimer;
      state = VSFailure(UnknownFailure('An unexpected error occurred'));
    }
  }

  /// Reset to idle state
  void reset() {
    state = VSIdle();
  }

  /// Play stage animation sequence
  /// Returns a Future that completes after all stages
  Future<void> _playStageSequence() async {
    const stageDuration = Duration(milliseconds: 500);
    final stages = AnalysisStage.values;

    for (int i = 0; i < stages.length; i++) {
      if (mounted) {
        state = VSAnalyzing(stages[i]);
      }
      await Future.delayed(stageDuration);
    }
  }
}
