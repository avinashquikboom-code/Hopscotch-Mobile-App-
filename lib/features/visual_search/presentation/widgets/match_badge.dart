import 'package:flutter/material.dart';

/// Badge showing similarity percentage or "100% Match"
class MatchBadge extends StatelessWidget {
  final String label;
  final bool isExactMatch;

  const MatchBadge({
    super.key,
    required this.label,
    this.isExactMatch = false,
  });

  factory MatchBadge.percentage(double similarity) {
    return MatchBadge(
      label: '${similarity.toStringAsFixed(0)}% Match',
      isExactMatch: similarity >= 0.98,
    );
  }

  factory MatchBadge.exact() {
    return const MatchBadge(
      label: '100% Match',
      isExactMatch: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isExactMatch ? const Color(0xFF00897B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00897B),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExactMatch ? Icons.check_circle : Icons.visibility,
            size: 14,
            color: isExactMatch ? Colors.white : const Color(0xFF00897B),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isExactMatch ? Colors.white : const Color(0xFF00897B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
