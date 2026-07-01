import 'package:flutter/material.dart';
import '../../application/visual_search_state.dart';

/// Animated loader showing analysis stages
/// Displays the 4 stage messages with progress animation
class StageLoader extends StatelessWidget {
  final AnalysisStage currentStage;

  const StageLoader({
    super.key,
    required this.currentStage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress indicator
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00897B)),
          ),
        ),
        const SizedBox(height: 24),
        // Stage text
        Text(
          currentStage.displayText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Stage dots
        Row(
          mainAxisSize: MainAxisSize.min,
          children: AnalysisStage.values.map((stage) {
            final isActive = stage.index <= currentStage.index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF00897B) : Colors.grey[300],
                shape: BoxShape.circle,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
