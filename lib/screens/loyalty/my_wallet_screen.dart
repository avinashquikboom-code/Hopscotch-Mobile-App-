import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/providers/loyalty_provider.dart';

class MyWalletScreen extends ConsumerStatefulWidget {
  const MyWalletScreen({super.key});

  @override
  ConsumerState<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends ConsumerState<MyWalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _topupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topupController.dispose();
    super.dispose();
  }

  void _showTopupDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Up Wallet',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add funds to your digital wallet for instant 1-click checkout.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _topupController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: 'Enter amount (e.g. 500)',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [500, 1000, 2000, 5000].map((amt) {
                  return ChoiceChip(
                    label: Text('₹$amt'),
                    selected: _topupController.text == amt.toString(),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _topupController.text = amt.toString();
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Theme.of(ctx).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final double? amt = double.tryParse(_topupController.text);
                    if (amt != null && amt > 0) {
                      Navigator.pop(ctx);
                      final success = await ref.read(loyaltyProvider.notifier).topupWallet(amt);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success ? '₹${amt.toStringAsFixed(2)} added to wallet successfully!' : 'Top up failed. Please try again.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Proceed to Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Digital Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Wallet Balance Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
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
                      'Available Balance',
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
                          Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('100% Secure', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${loyaltyState.walletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _showTopupDialog,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('Add Money to Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Transactions Filter Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: 'All Transactions'),
              Tab(text: 'Refund History'),
              Tab(text: 'Cashback History'),
              Tab(text: 'Admin Credits'),
              Tab(text: 'Wallet Payments'),
            ],
          ),

          // Transaction List Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(5, (index) {
                if (loyaltyState.walletTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your wallet activities will appear here.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: loyaltyState.walletTransactions.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final tx = loyaltyState.walletTransactions[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tx.type.name == 'credit' ? Colors.green.shade50 : Colors.red.shade50,
                        child: Icon(
                          tx.type.name == 'credit' ? Icons.arrow_downward : Icons.arrow_upward,
                          color: tx.type.name == 'credit' ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}', style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        '${tx.type.name == 'credit' ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: tx.type.name == 'credit' ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
