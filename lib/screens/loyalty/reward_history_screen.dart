import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/providers/loyalty_provider.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:intl/intl.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: const Text('Reward History', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final filter = _filters[i];
                final selected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppTheme.primaryColor,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: selected
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withValues(alpha: 0.25),
                  ),
                  onSelected: (v) {
                    if (!v) return;
                    setState(() => _selectedFilter = filter);
                    ref.read(loyaltyProvider.notifier).fetchRewardHistory(filter: filter);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: loyaltyState.rewardHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.history_toggle_off_rounded, size: 34, color: AppTheme.primaryColor.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No history yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Points activity for $_selectedFilter will show here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.55)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: loyaltyState.rewardHistory.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = loyaltyState.rewardHistory[i];
                      final isEarned = item.points > 0;
                      final accent = isEarned ? const Color(0xFFEA580C) : const Color(0xFF2563EB);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? colorScheme.outline : colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          boxShadow: isDark
                              ? null
                              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEarned ? Icons.stars_rounded : Icons.shopping_bag_outlined,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${dateFmt.format(item.createdAt)} · ${item.type.name.toUpperCase()}',
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isEarned ? '+' : ''}${item.points} Pts',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isEarned ? AppTheme.successColor : accent),
                            ),
                          ],
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
