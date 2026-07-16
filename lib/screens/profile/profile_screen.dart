import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/profile_repository.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/api/auth_api.dart';
import 'package:hopscotch/widgets/toast_notification.dart';
import 'package:hopscotch/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      final apiService = ApiService();
      final authApi = AuthApi(apiService);
      await authApi.logout();
      
      if (context.mounted) {
        ToastNotification.show(
          context,
          message: 'Logged out successfully',
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
                          child: CircleAvatar(
                            radius: responsive.iconSize(54),
                            backgroundImage: userProfile?['avatarUrl'] != null
                                ? NetworkImage(userProfile!['avatarUrl'])
                                : null,
                            child: userProfile?['avatarUrl'] == null
                                ? Icon(
                                    Icons.person,
                                    size: responsive.iconSize(54),
                                  )
                                : null,
                          ),
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
                    userProfile?['firstName'] ?? userProfile?['name'] ?? l10n.auraMember,
                    style: responsive.headline4,
                  ),
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    userProfile?['email'] ?? 'member@auracouture.com',
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
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

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
                        icon: Icons.receipt_long_rounded,
                        title: l10n.orderHistory,
                        subtitle: l10n.orderHistoryDesc,
                        onTap: () => context.push('/my-orders'),
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
    return ListTile(
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
    );
  }
}
