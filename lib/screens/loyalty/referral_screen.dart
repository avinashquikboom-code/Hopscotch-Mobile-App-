import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hopscotch/providers/loyalty_provider.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(loyaltyProvider.notifier).fetchReferralData();
    });
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied to clipboard!')),
    );
  }

  void _shareReferral(String code) {
    Share.share(
      'Join Hopscotch using my referral code "$code" and get ₹100 instant bonus on your first order! Download now: https://hopscotch.in/invite/$code',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);
    final refData = loyaltyState.referralData;
    final code = loyaltyState.referralCode.isNotEmpty ? loyaltyState.referralCode : 'HOPSCH100';
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Image/Icon
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard, size: 54, color: Colors.purple),
            ),
            const SizedBox(height: 16),
            const Text(
              'Invite Friends & Earn ₹100',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Share your referral code with friends. You both get ₹100 reward points when they place their first purchase!',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Referral Code Container Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                children: [
                  const Text('YOUR EXCLUSIVE REFERRAL CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                  const SizedBox(height: 10),
                  SelectableText(
                    code,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.purple),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple,
                            side: const BorderSide(color: Colors.purple),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _copyCode(code),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy Code', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _shareReferral(code),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share Code', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Referral Stats Grid
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Referral Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildStatTile('Total Earnings', '₹${(refData?.referralEarnings ?? 0).toStringAsFixed(0)}', Colors.green, Icons.monetization_on),
                _buildStatTile('Friends Joined', '${refData?.friendsJoined ?? 0}', Colors.blue, Icons.people),
                _buildStatTile('Successful', '${refData?.successfulReferrals ?? 0}', Colors.teal, Icons.check_circle),
                _buildStatTile('Pending Rewards', '${refData?.pendingRewards ?? 0}', Colors.orange, Icons.hourglass_top),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
