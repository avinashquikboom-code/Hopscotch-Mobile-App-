import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/providers/loyalty_provider.dart';
import 'package:hopscotch/routes/app_routes.dart';

class RewardPointsScreen extends ConsumerWidget {
  const RewardPointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyaltyState = ref.watch(loyaltyProvider);
    final primaryColor = Theme.of(context).primaryColor;

    final double discountEquivalent = loyaltyState.rewardBalance * loyaltyState.conversionRate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward Points Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master Reward Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Reward Points',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.stars, color: Colors.yellow, size: 16),
                            SizedBox(width: 4),
                            Text('VIP Rewards', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${loyaltyState.rewardBalance} Pts',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Equivalent to ₹${discountEquivalent.toStringAsFixed(2)} discount on checkout',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            context.push(AppRoutes.cart);
                          },
                          icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                          label: const Text('Redeem Now', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            context.push('/reward-history');
                          },
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('View History', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Conversion Rate Banner Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.currency_exchange, color: Colors.orange),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reward Conversion Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 2),
                          Text('100 Points = ₹1.00 Instant Discount', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lifetime Stats Grid
            const Text('Lifetime Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GridTileBar(
              earned: loyaltyState.lifetimeEarned,
              redeemed: loyaltyState.lifetimeRedeemed,
              expiring: loyaltyState.pointsExpiringSoon,
            ),
            const SizedBox(height: 24),

            // How to Earn Points Section
            const Text('How to Earn More Points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildEarnTile(
              icon: Icons.shopping_basket,
              color: Colors.blue,
              title: 'Shop Products',
              subtitle: 'Earn 10-100 Reward Points on every successful delivery.',
            ),
            _buildEarnTile(
              icon: Icons.group_add,
              color: Colors.purple,
              title: 'Refer Friends',
              subtitle: 'Get 500 Bonus Points when your friend places their first order.',
            ),
            _buildEarnTile(
              icon: Icons.rate_review,
              color: Colors.teal,
              title: 'Write Product Reviews',
              subtitle: 'Earn 50 Points for every verified product review with photo.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridTileBar extends StatelessWidget {
  final int earned;
  final int redeemed;
  final int expiring;

  const GridTileBar({
    super.key,
    required this.earned,
    required this.redeemed,
    required this.expiring,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatCard('Lifetime Earned', '$earned Pts', Colors.green, Icons.trending_up),
        const SizedBox(width: 12),
        _buildStatCard('Redeemed', '$redeemed Pts', Colors.blue, Icons.shopping_cart),
        const SizedBox(width: 12),
        _buildStatCard('Expiring Soon', '$expiring Pts', Colors.red, Icons.timer),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
