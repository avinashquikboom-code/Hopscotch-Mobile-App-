import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/providers.dart';
import '../../application/visual_search_state.dart';
import '../../domain/entities/visual_search_result.dart';
import '../widgets/stage_loader.dart';

/// Preview screen showing selected image with scanning animation
/// Displays StageLoader while analyzing, then navigates based on result
class VisualSearchPreviewScreen extends ConsumerStatefulWidget {
  final File image;

  const VisualSearchPreviewScreen({
    super.key,
    required this.image,
  });

  @override
  ConsumerState<VisualSearchPreviewScreen> createState() =>
      _VisualSearchPreviewScreenState();
}

class _VisualSearchPreviewScreenState
    extends ConsumerState<VisualSearchPreviewScreen> {
  @override
  void initState() {
    super.initState();
    // Start search when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(visualSearchControllerProvider.notifier)
          .runSearch(widget.image);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visualSearchControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.file(
              widget.image,
              fit: BoxFit.contain,
            ),
          ),
          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
          // Content
          Center(
            child: Builder(
              builder: (context) {
                if (state is VSIdle) {
                  return const SizedBox();
                } else if (state is VSPickingSource) {
                  return const SizedBox();
                } else if (state is VSAnalyzing) {
                  final stage = state.stage;
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: StageLoader(currentStage: stage),
                  );
                } else if (state is VSSuccess) {
                  final result = state.result;
                  // Navigate based on result type
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (result is ExactMatch) {
                      final product = result.product;
                      // Navigate to product details
                      context.push('/product/${product.id}?heroTagPrefix=visual_search');
                    } else if (result is SimilarMatches) {
                      // Navigate to results screen
                      context.push('/visual-search/results', extra: result);
                    } else if (result is NoMatchFound) {
                      // Show no match message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No exact match found'),
                          backgroundColor: Color(0xFF00897B),
                        ),
                      );
                      context.pop();
                    }
                  });
                  return const SizedBox();
                } else if (state is VSFailure) {
                  final failure = state.failure;
                  // Show error
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(failure.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                    context.pop();
                  });
                  return const SizedBox();
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}
