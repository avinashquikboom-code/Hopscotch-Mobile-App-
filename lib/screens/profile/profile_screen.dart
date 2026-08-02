import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/profile_repository.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/api/auth_api.dart';
import 'package:hopscotch/widgets/toast_notification.dart';
import 'package:hopscotch/widgets/user_avatar.dart';
import 'package:hopscotch/l10n/app_localizations.dart';
import 'package:hopscotch/providers/loyalty_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;

    try {
      final userProfile = ref.read(profileNotifierProvider);
      final userName = userProfile?['firstName'] ?? userProfile?['name'] ?? 'User';

      final apiService = ApiService();
      final authApi = AuthApi(apiService);
      await authApi.logout();

      // Clear all in-memory state so the next user doesn't see stale data
      ref.read(profileNotifierProvider.notifier).clearProfile();
      ref.read(cartProvider.notifier).clearCart();
      ref.read(wishlistProvider.notifier).clearWishlist();

      if (context.mounted) {
        ToastNotification.show(
          context,
          message: 'Goodbye, $userName!',
          isError: false,
        );
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ToastNotification.show(
          context,
          message: 'Failed to logout: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(profileNotifierProvider);
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myPortfolio,
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            // 1. User Header Details
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/edit-profile'),
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(responsive.spacing(4)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          child: () {
                            final rawUrl = userProfile?['avatarUrl']?.toString() ??
                                userProfile?['avatar']?.toString() ??
                                userProfile?['avatar_url']?.toString() ??
                                userProfile?['profileImage']?.toString();
                            final firstName = userProfile?['firstName']?.toString() ?? '';
                            final name = userProfile?['name']?.toString() ?? '';
                            final initial = (firstName.isNotEmpty ? firstName : (name.isNotEmpty ? name : 'U')).substring(0, 1);
                            return UserAvatar(
                              avatarUrl: rawUrl,
                              initials: initial,
                              radius: responsive.iconSize(54),
                              backgroundColor: AppTheme.surfaceColor,
                              textColor: AppTheme.textPrimaryColor,
                            );
                          }(),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(responsive.spacing(6)),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: responsive.iconSize(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                  Text(
                    (() {
                      final firstName = userProfile?['firstName']?.toString() ?? '';
                      final lastName = userProfile?['lastName']?.toString() ?? '';
                      if (firstName.isNotEmpty && lastName.isNotEmpty) {
                        return '$firstName $lastName';
                      }
                      return firstName.isNotEmpty ? firstName : (userProfile?['name']?.toString() ?? l10n.fcisellerMember);
                    })(),
                    style: responsive.headline4,
                  ),
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    userProfile?['email'] ?? 'member@fciseller.com',
                    style: responsive.bodyMedium.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(14),
                      vertical: responsive.spacing(6),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                    child: Text(
                      l10n.eliteMember,
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.fontSize10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

            // 1.5 Loyalty & Rewards Summary Grid Card
            Consumer(
              builder: (context, ref, child) {
                final loyaltyState = ref.watch(loyaltyProvider);
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: responsive.spacing(AppTheme.spaceXL)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor.withOpacity(0.08), AppTheme.accentColor.withOpacity(0.08)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push('/wallet'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Text('Wallet Balance', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                        SizedBox(width: 3),
                                        Icon(Icons.add_circle_outline, size: 11, color: Colors.green),
                                      ],
                                    ),
                                    Text('₹${loyaltyState.walletBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                                    const Text('Tap to Top Up >', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Reward Points', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  Text('${loyaltyState.rewardBalance} Pts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Cashback', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                                  Text('₹${loyaltyState.cashbackBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Lifetime Earned: ${loyaltyState.lifetimeEarned} Pts', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Redeemed: ${loyaltyState.lifetimeRedeemed} Pts', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Gift Card: ₹${loyaltyState.giftCardBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

            // 2. Profile Options List
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(AppTheme.spaceXL),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildOptionTile(
                        context: context,
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'My Wallet',
                        subtitle: 'Top up balance & view wallet transactions',
                        onTap: () => context.push('/wallet'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.stars_rounded,
                        title: 'Reward Points Hub',
                        subtitle: 'View available points & conversion rate',
                        onTap: () => context.push('/rewards'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.history_toggle_off,
                        title: 'Reward History',
                        subtitle: 'Earned, redeemed & expired points log',
                        onTap: () => context.push('/reward-history'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.card_giftcard,
                        title: 'Referral Program',
                        subtitle: 'Invite friends & earn ₹100 bonus',
                        onTap: () => context.push('/referrals'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.monetization_on_outlined,
                        title: 'Cashback Earnings',
                        subtitle: 'View cashback history & pending credits',
                        onTap: () => context.push('/cashback'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.confirmation_number_outlined,
                        title: 'Gift Cards',
                        subtitle: 'Redeem gift vouchers & check balance',
                        onTap: () => context.push('/gift-cards'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.loyalty_outlined,
                        title: 'Reward Settings',
                        subtitle: 'Loyalty tier benefits & preference rules',
                        onTap: () => context.push('/loyalty-hub'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.receipt_long_rounded,
                        title: l10n.orderHistory,
                        subtitle: l10n.orderHistoryDesc,
                        onTap: () => context.push('/my-orders'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.location_on_outlined,
                        title: 'Saved Addresses',
                        subtitle: 'Manage shipping addresses and defaults',
                        onTap: () => context.push('/addresses'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.notifications_none_rounded,
                        title: l10n.notifications,
                        subtitle: l10n.notificationsDesc,
                        onTap: () => context.push('/notifications'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.settings_outlined,
                        title: l10n.settings,
                        subtitle: l10n.settingsDesc,
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),

            // 3. Support Box
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(AppTheme.spaceXL),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildOptionTile(
                        context: context,
                        icon: Icons.help_outline_rounded,
                        title: l10n.helpCenter,
                        subtitle: l10n.helpCenterDesc,
                        onTap: () => context.push('/help-center'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.gavel_rounded,
                        title: l10n.legalPolicies,
                        subtitle: l10n.legalPoliciesDesc,
                        onTap: () => context.push('/legal-policies'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

            // 4. Log Out Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(AppTheme.spaceXL),
              ),
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(
                    color: AppTheme.errorColor,
                    width: 1.5,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  minimumSize: Size(double.infinity, responsive.spacing(50)),
                ),
                icon: Icon(Icons.logout_rounded, size: responsive.iconSize(18)),
                label: Text(
                  l10n.logOut,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: responsive.fontSize14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final responsive = context.responsive;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(AppTheme.spaceL),
          vertical: responsive.spacing(8),
        ),
        leading: Container(
          padding: EdgeInsets.all(responsive.spacing(8)),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: responsive.iconSize(20),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            fontSize: responsive.fontSize14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: responsive.fontSize11,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: responsive.iconSize(14),
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        onTap: onTap,
      ),
    );
  }
}
