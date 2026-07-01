import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/responsive_text.dart';
import '../../../core/widgets/custom_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailPromo = false;
  bool _biometricLogin = true;

  // Fit profile measurements for custom tailoring simulation
  final _heightController = TextEditingController(text: '178');
  final _chestController = TextEditingController(text: '98');
  final _waistController = TextEditingController(text: '82');

  @override
  void dispose() {
    _heightController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    super.dispose();
  }

  void _handleSaveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Couture profile saved! ✨'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeModeOption option,
    required IconData icon,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final responsive = context.responsive;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceM)),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                size: responsive.iconSize(24),
              ),
            ),
            SizedBox(width: responsive.spacing(AppTheme.spaceL)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: responsive.fontSize12,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceXS)),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: responsive.fontSize10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXS)),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: responsive.iconSize(16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SETTINGS & FIT PROFILE',
          style: TextStyle(
            fontSize: responsive.fontSize16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: responsive.iconSize(24)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Bespoke Size Profile Section
            Text(
              'Bespoke Tailoring Profile',
              style: TextStyle(
                fontSize: responsive.fontSize16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceS)),
            Text(
              'Input your measurements below. Our European design mills will recommend customized garments based on your exact structure.',
              style: responsive.bodySmall,
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            Container(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: responsive.fontSize12),
                          decoration: InputDecoration(
                            labelText: 'Height (cm)',
                            labelStyle: TextStyle(
                              fontSize: responsive.fontSize12,
                            ),
                            prefixIcon: Icon(
                              Icons.height_rounded,
                              size: responsive.iconSize(20),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: responsive.spacing(AppTheme.spaceL)),
                      Expanded(
                        child: TextFormField(
                          controller: _chestController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: responsive.fontSize12),
                          decoration: InputDecoration(
                            labelText: 'Chest (cm)',
                            labelStyle: TextStyle(
                              fontSize: responsive.fontSize12,
                            ),
                            prefixIcon: Icon(
                              Icons.accessibility_new_rounded,
                              size: responsive.iconSize(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                  TextFormField(
                    controller: _waistController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: responsive.fontSize12),
                    decoration: InputDecoration(
                      labelText: 'Waist (cm)',
                      labelStyle: TextStyle(fontSize: responsive.fontSize12),
                      prefixIcon: Icon(
                        Icons.straighten_rounded,
                        size: responsive.iconSize(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

            // 2. Alert Prefs
            Text(
              'Notification Preferences',
              style: TextStyle(
                fontSize: responsive.fontSize16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Push Alerts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsive.fontSize12,
                        ),
                      ),
                      subtitle: Text(
                        'Order dispatches, shipping status',
                        style: TextStyle(fontSize: responsive.fontSize10),
                      ),
                      value: _pushNotifications,
                      activeThumbColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        setState(() {
                          _pushNotifications = val;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        'Exclusive Drops',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsive.fontSize12,
                        ),
                      ),
                      subtitle: Text(
                        'Limited runs, VIP sales, designer news',
                        style: TextStyle(fontSize: responsive.fontSize10),
                      ),
                      value: _emailPromo,
                      activeThumbColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        setState(() {
                          _emailPromo = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

            // 3. Security Prefs
            Text(
              'Security Preferences',
              style: TextStyle(
                fontSize: responsive.fontSize16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile(
                  title: Text(
                    'Biometric Authentication',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: responsive.fontSize12,
                    ),
                  ),
                  subtitle: Text(
                    'Access billing and purchase secure keys instantly',
                    style: TextStyle(fontSize: responsive.fontSize10),
                  ),
                  value: _biometricLogin,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (val) {
                    setState(() {
                      _biometricLogin = val;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

            // 4. Theme Selection
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: responsive.fontSize16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            Column(
              children: [
                _buildThemeOption(
                  context: context,
                  option: ThemeModeOption.system,
                  icon: Icons.brightness_auto_rounded,
                  label: 'System',
                  description: 'Follow device settings',
                  isSelected:
                      ref.watch(themeProvider) == ThemeModeOption.system,
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeModeOption.system),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                _buildThemeOption(
                  context: context,
                  option: ThemeModeOption.light,
                  icon: Icons.light_mode_rounded,
                  label: 'Light',
                  description: 'Always light mode',
                  isSelected: ref.watch(themeProvider) == ThemeModeOption.light,
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeModeOption.light),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                _buildThemeOption(
                  context: context,
                  option: ThemeModeOption.dark,
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark',
                  description: 'Always dark mode',
                  isSelected: ref.watch(themeProvider) == ThemeModeOption.dark,
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeModeOption.dark),
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(60)),

            // 5. Save Button
            SizedBox(
              width: double.infinity,
              height: responsive.spacing(48),
              child: CustomButton(
                text: 'SAVE PREFERENCES',
                onPressed: _handleSaveSettings,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
          ],
        ),
      ),
    );
  }
}
