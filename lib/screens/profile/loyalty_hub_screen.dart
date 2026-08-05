import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/api/loyalty_api.dart';
import 'package:hopscotch/providers/loyalty_provider.dart';
import 'package:hopscotch/theme/app_theme.dart';

class LoyaltyHubScreen extends ConsumerStatefulWidget {
  const LoyaltyHubScreen({super.key});

  @override
  ConsumerState<LoyaltyHubScreen> createState() => _LoyaltyHubScreenState();
}

class _LoyaltyHubScreenState extends ConsumerState<LoyaltyHubScreen>
    with SingleTickerProviderStateMixin {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Redeem Gift Card',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _gcController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Gift Card Code',
                    hintText: 'e.g. GC-ABC1234',
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final code = _gcController.text.trim();
                      if (code.isEmpty) return;
                      Navigator.pop(ctx);
                      final success = await _api.redeemGiftCard(code);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Gift card redeemed to wallet!' : 'Invalid or expired gift card.'),
                          backgroundColor: success ? AppTheme.primaryColor : Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      if (success) {
                        ref.read(loyaltyProvider.notifier).fetchSummary();
                        _loadTransactions();
                      }
                    },
                    child: const Text('Redeem', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loyaltyProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: const Text('Reward Settings', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          await ref.read(loyaltyProvider.notifier).fetchSummary();
          await _loadTransactions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _BalanceMiniCard(
                      title: 'Wallet',
                      value: '₹${state.walletBalance.toStringAsFixed(2)}',
                      colors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      icon: Icons.account_balance_wallet_rounded,
                      actionLabel: 'Top Up',
                      onAction: () => context.push('/wallet'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BalanceMiniCard(
                      title: 'Rewards',
                      value: '${state.rewardBalance} Pts',
                      colors: const [Color(0xFFEA580C), Color(0xFFF97316)],
                      icon: Icons.stars_rounded,
                      actionLabel: 'View',
                      onAction: () => context.push('/rewards'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? colorScheme.outline : AppTheme.primaryColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    _LifeCell('Earned', '${state.lifetimeEarned} Pts', AppTheme.successColor),
                    Container(width: 1, height: 28, color: colorScheme.outline.withValues(alpha: 0.5)),
                    _LifeCell('Redeemed', '${state.lifetimeRedeemed} Pts', const Color(0xFFEA580C)),
                    Container(width: 1, height: 28, color: colorScheme.outline.withValues(alpha: 0.5)),
                    _LifeCell(
                      'Value',
                      '₹${(state.rewardBalance * state.conversionRate).toStringAsFixed(0)}',
                      AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.card_giftcard_rounded,
                      label: 'Gift Card',
                      color: AppTheme.primaryColor,
                      onTap: _showRedeemGiftCardDialog,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.group_add_rounded,
                      label: 'Referrals',
                      color: const Color(0xFF7C3AED),
                      onTap: () => context.push('/referrals'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.savings_rounded,
                      label: 'Cashback',
                      color: const Color(0xFF2563EB),
                      onTap: () => context.push('/cashback'),
                    ),
                  ),
                ],
              ),

              if (state.referralCode.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.share_rounded, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Referral Code',
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.55)),
                            ),
                            Text(
                              state.referralCode,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF7C3AED)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: state.referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied'), behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.45),
                indicatorColor: AppTheme.primaryColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                tabs: const [
                  Tab(text: 'Wallet Ledger'),
                  Tab(text: 'Points Ledger'),
                ],
              ),
              SizedBox(
                height: 360,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWalletLedger(isDark, colorScheme),
                    _buildPointsLedger(isDark, colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletLedger(bool isDark, ColorScheme colorScheme) {
    final list = (_transactions?['wallet']?['transactions'] as List?) ?? [];
    if (_loadingTransactions) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) {
      return Center(
        child: Text('No wallet transactions', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5))),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final item = list[idx];
        final rawAmount = item['amount'];
        final amount = rawAmount is num ? rawAmount.toDouble() : (double.tryParse(rawAmount?.toString() ?? '') ?? 0.0);
        final isCredit = amount >= 0;
        final accent = isCredit ? AppTheme.successColor : const Color(0xFFDC2626);
        return _LedgerTile(
          icon: isCredit ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
          title: item['type']?.toString() ?? 'TRANSACTION',
          subtitle: item['description']?.toString() ?? item['referenceId']?.toString() ?? '',
          trailing: isCredit ? '+₹${amount.toStringAsFixed(2)}' : '-₹${amount.abs().toStringAsFixed(2)}',
          accent: accent,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildPointsLedger(bool isDark, ColorScheme colorScheme) {
    final list = (_transactions?['rewardPoints']?['transactions'] as List?) ?? [];
    if (_loadingTransactions) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) {
      return Center(
        child: Text('No points transactions', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5))),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final item = list[idx];
        final rawPoints = item['points'];
        final points = rawPoints is num
            ? rawPoints.toInt()
            : (int.tryParse(rawPoints?.toString() ?? '') ?? (double.tryParse(rawPoints?.toString() ?? '')?.toInt() ?? 0));
        final isEarned = points >= 0;
        final accent = isEarned ? const Color(0xFFEA580C) : const Color(0xFF7C3AED);
        return _LedgerTile(
          icon: isEarned ? Icons.stars_rounded : Icons.history_rounded,
          title: item['type']?.toString() ?? 'REWARD',
          subtitle: item['reason']?.toString() ?? item['orderId']?.toString() ?? '',
          trailing: isEarned ? '+$points Pts' : '$points Pts',
          accent: accent,
          isDark: isDark,
        );
      },
    );
  }
}

class _BalanceMiniCard extends StatelessWidget {
  const _BalanceMiniCard({
    required this.title,
    required this.value,
    required this.colors,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String value;
  final List<Color> colors;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(color: colors.first.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text(actionLabel, style: TextStyle(color: colors.first, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeCell extends StatelessWidget {
  const _LifeCell(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.16)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.accent,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? colorScheme.outline : colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: colorScheme.onSurface)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Text(trailing, style: TextStyle(fontWeight: FontWeight.w800, color: accent, fontSize: 13)),
        ],
      ),
    );
  }
}
