import 'package:flutter/material.dart';

class RewardBadgeCard extends StatelessWidget {
  final int rewardEarned;
  final int maxRedeemable;
  final bool allowRedemption;
  final bool allowEarning;
  final String? appliedRuleType;

  const RewardBadgeCard({
    super.key,
    required this.rewardEarned,
    required this.maxRedeemable,
    this.allowRedemption = true,
    this.allowEarning = true,
    this.appliedRuleType,
  });

  @override
  Widget build(BuildContext context) {
    if (!allowEarning && !allowRedemption) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.purple.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade400,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (allowEarning && rewardEarned > 0) ...[
                  Row(
                    children: [
                      Text(
                        'Earn ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        '$rewardEarned Reward Points',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const Text(' ✨'),
                    ],
                  ),
                ],
                if (allowRedemption && maxRedeemable > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Redeem up to $maxRedeemable points (₹${(maxRedeemable * 0.01).toStringAsFixed(0)} discount)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
