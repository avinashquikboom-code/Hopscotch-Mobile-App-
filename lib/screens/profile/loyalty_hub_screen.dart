import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/providers/loyalty_provider.dart';
import 'package:hopscotch/api/loyalty_api.dart';

class LoyaltyHubScreen extends ConsumerStatefulWidget {
  const LoyaltyHubScreen({super.key});

  @override
  ConsumerState<LoyaltyHubScreen> createState() => _LoyaltyHubScreenState();
}

class _LoyaltyHubScreenState extends ConsumerState<LoyaltyHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoyaltyApi _api = LoyaltyApi();
  final TextEditingController _gcController = TextEditingController();

  Map<String, dynamic>? _transactions;
  bool _loadingTransactions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loadingTransactions = true);
    final data = await _api.getMasterTransactions();
    if (mounted) {
      setState(() {
        _transactions = data;
        _loadingTransactions = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gcController.dispose();
    super.dispose();
  }

  void _showRedeemGiftCardDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem Gift Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _gcController,
              decoration: const InputDecoration(
                labelText: 'Gift Card Code',
                hintText: 'e.g. GC-ABC1234',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = _gcController.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              final success = await _api.redeemGiftCard(code);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Gift card redeemed to wallet successfully!' : 'Invalid or expired gift card code.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) {
                  ref.read(loyaltyProvider.notifier).fetchSummary();
                  _loadTransactions();
                }
              }
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loyaltyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty & Wallet Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(loyaltyProvider.notifier).fetchSummary();
          await _loadTransactions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Cards Overview
              Row(
                children: [
                  // Wallet Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF059669), Colors.teal.shade800],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text('Wallet', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '₹${state.walletBalance.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.push('/wallet'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_circle_outline, color: Colors.teal.shade800, size: 12),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Top Up',
                                        style: TextStyle(color: Colors.teal.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showRedeemGiftCardDialog,
                                child: const Text(
                                  'Gift Card',
                                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Reward Points Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade600, Colors.deepPurple.shade800],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                              SizedBox(width: 6),
                              Text('Reward Points', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${state.rewardBalance} Pts',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Value: ₹${(state.rewardBalance * state.conversionRate).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Lifetime Metrics
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Lifetime Earned', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text('${state.lifetimeEarned} Pts', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber)),
                      ],
                    ),
                    Container(height: 24, width: 1, color: Colors.grey.shade300),
                    Column(
                      children: [
                        const Text('Lifetime Redeemed', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text('${state.lifetimeRedeemed} Pts', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Referral Box
              if (state.referralCode.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.share_rounded, color: Colors.amber, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your Referral Code', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              state.referralCode,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Colors.amber),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: state.referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Referral code copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Transactions Tab View
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(text: 'Wallet Ledger'),
                  Tab(text: 'Points Ledger'),
                ],
              ),

              SizedBox(
                height: 350,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Wallet Ledger
                    _buildWalletLedger(),

                    // Points Ledger
                    _buildPointsLedger(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletLedger() {
    final list = (_transactions?['wallet']?['transactions'] as List?) ?? [];
    if (_loadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return const Center(child: Text('No wallet transactions found.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, idx) {
        final item = list[idx];
        final rawAmount = item['amount'];
        final double amount = rawAmount is num
            ? rawAmount.toDouble()
            : (double.tryParse(rawAmount?.toString() ?? '') ?? 0.0);
        final isCredit = amount >= 0;
        return ListTile(
          dense: true,
          leading: Icon(
            isCredit ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
            color: isCredit ? Colors.green : Colors.red,
          ),
          title: Text(item['type'] ?? 'TRANSACTION', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(item['description'] ?? item['referenceId'] ?? '', style: const TextStyle(fontSize: 11)),
          trailing: Text(
            isCredit ? '+₹${amount.toStringAsFixed(2)}' : '-₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.green : Colors.red, fontSize: 14),
          ),
        );
      },
    );
  }

  Widget _buildPointsLedger() {
    final list = (_transactions?['rewardPoints']?['transactions'] as List?) ?? [];
    if (_loadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return const Center(child: Text('No reward point transactions found.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, idx) {
        final item = list[idx];
        final rawPoints = item['points'];
        final int points = rawPoints is num
            ? rawPoints.toInt()
            : (int.tryParse(rawPoints?.toString() ?? '') ?? (double.tryParse(rawPoints?.toString() ?? '')?.toInt() ?? 0));
        final isEarned = points >= 0;
        return ListTile(
          dense: true,
          leading: Icon(
            isEarned ? Icons.stars_rounded : Icons.history_rounded,
            color: isEarned ? Colors.amber : Colors.purple,
          ),
          title: Text(item['type'] ?? 'REWARD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(item['reason'] ?? item['orderId'] ?? '', style: const TextStyle(fontSize: 11)),
          trailing: Text(
            isEarned ? '+$points Pts' : '$points Pts',
            style: TextStyle(fontWeight: FontWeight.bold, color: isEarned ? Colors.amber.shade800 : Colors.purple, fontSize: 14),
          ),
        );
      },
    );
  }
}
