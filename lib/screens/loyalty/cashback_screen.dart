import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/providers/loyalty_provider.dart';

class CashbackScreen extends ConsumerStatefulWidget {
  const CashbackScreen({super.key});

  @override
  ConsumerState<CashbackScreen> createState() => _CashbackScreenState();
}

class _CashbackScreenState extends ConsumerState<CashbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(loyaltyProvider.notifier).fetchCashbackData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashback Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Cashback Balance Header Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00B0FF), Color(0xFF0081CB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Cashback Balance', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(
                  '₹${loyaltyState.cashbackBalance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text('Automatically credited to your Wallet upon order completion.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          // Tabs for Credited, Pending, Expired
          TabBar(
            controller: _tabController,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: 'All Cashback'),
              Tab(text: 'Pending'),
              Tab(text: 'Expired'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(3, (index) {
                if (loyaltyState.cashbackHistory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monetization_on_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No cashback history', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: loyaltyState.cashbackHistory.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final item = loyaltyState.cashbackHistory[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                      ),
                      title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}', style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        '+₹${item.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
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
