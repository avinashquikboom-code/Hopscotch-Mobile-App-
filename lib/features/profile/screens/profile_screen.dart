import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_text.dart';
import 'package:hopscotch/features/auth/repositories/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider);
    final responsive = context.responsive;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MY PORTFOLIO',
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
                            backgroundImage: user?.avatarUrl != null
                                ? NetworkImage(user!.avatarUrl!)
                                : null,
                            child: user?.avatarUrl == null
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
                    user?.name ?? 'Aura Member',
                    style: responsive.headline4,
                  ),
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    user?.email ?? 'member@auracouture.com',
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
                      'ELITE MEMBER',
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
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildOptionTile(
                        context: context,
                        icon: Icons.receipt_long_rounded,
                        title: 'Order History',
                        subtitle: 'Track status and view purchases',
                        onTap: () => context.push('/my-orders'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Offers, discounts, and dispatch logs',
                        onTap: () => context.push('/notifications'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'Security, privacy, and measurements',
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
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _buildOptionTile(
                        context: context,
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center',
                        subtitle: '24/7 dedicated elite concierge chat',
                        onTap: () => context.push('/help-center'),
                      ),
                      const Divider(height: 1),
                      _buildOptionTile(
                        context: context,
                        icon: Icons.gavel_rounded,
                        title: 'Legal Policies',
                        subtitle: 'Terms of service and privacy rules',
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
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  context.go('/login');
                },
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
                  'LOG OUT FROM APP',
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
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(AppTheme.spaceL),
        vertical: responsive.spacing(8),
      ),
      leading: Container(
        padding: EdgeInsets.all(responsive.spacing(8)),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.04),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: responsive.iconSize(20),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
          fontSize: responsive.fontSize14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondaryColor,
          fontSize: responsive.fontSize11,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: responsive.iconSize(14),
        color: AppTheme.textLightColor,
      ),
      onTap: onTap,
    );
  }
}
