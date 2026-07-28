import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/providers/loyalty_provider.dart';

class RewardHistoryScreen extends ConsumerStatefulWidget {
  const RewardHistoryScreen({super.key});

  @override
  ConsumerState<RewardHistoryScreen> createState() => _RewardHistoryScreenState();
}

class _RewardHistoryScreenState extends ConsumerState<RewardHistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(loyaltyProvider.notifier).fetchRewardHistory(filter: _selectedFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward History', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Chips Bar
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final filter = _filters[i];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      ref.read(loyaltyProvider.notifier).fetchRewardHistory(filter: filter);
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // History List
          Expanded(
            child: loyaltyState.rewardHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No history found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text('Your points transactions for $_selectedFilter will appear here.', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: loyaltyState.rewardHistory.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = loyaltyState.rewardHistory[i];
                      final bool isEarned = item.points > 0;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isEarned ? Colors.amber.shade50 : Colors.blue.shade50,
                          child: Icon(
                            isEarned ? Icons.stars : Icons.shopping_bag_outlined,
                            color: isEarned ? Colors.orange : Colors.blue,
                          ),
                        ),
                        title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year} · ${item.type.name.toUpperCase()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '${isEarned ? '+' : ''}${item.points} Pts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isEarned ? Colors.green : Colors.blue,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
