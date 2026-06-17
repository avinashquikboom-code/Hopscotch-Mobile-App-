import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1)
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
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryColor
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceXS),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS & FIT PROFILE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
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
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Bespoke Size Profile Section
            Text(
              'Bespoke Tailoring Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Input your measurements below. Our European design mills will recommend customized garments based on your exact structure.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.spaceM),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                          decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                            prefixIcon: Icon(Icons.height_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceL),
                      Expanded(
                        child: TextFormField(
                          controller: _chestController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Chest (cm)',
                            prefixIcon: Icon(Icons.accessibility_new_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  TextFormField(
                    controller: _waistController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Waist (cm)',
                      prefixIcon: Icon(Icons.straighten_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceXXL),

            // 2. Alert Prefs
            Text(
              'Notification Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Container(
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
                    SwitchListTile(
                      title: const Text('Push Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Order dispatches, shipping status', style: TextStyle(fontSize: 11)),
                      value: _pushNotifications,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        setState(() {
                          _pushNotifications = val;
                        });
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Exclusive Drops', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Limited runs, VIP sales, designer news', style: TextStyle(fontSize: 11)),
                      value: _emailPromo,
                      activeColor: AppTheme.primaryColor,
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
            const SizedBox(height: AppTheme.spaceXXL),

            // 3. Security Prefs
            Text(
              'Security Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                boxShadow: AppTheme.softShadow,
              ),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                clipBehavior: Clip.antiAlias,
                child: SwitchListTile(
                  title: const Text('Biometric Authentication', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Access billing and purchase secure keys instantly', style: TextStyle(fontSize: 11)),
                  value: _biometricLogin,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (val) {
                    setState(() {
                      _biometricLogin = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceXXL),

            // 4. Theme Selection
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Column(
              children: [
                _buildThemeOption(
                  context: context,
                  option: ThemeModeOption.system,
                  icon: Icons.brightness_auto_rounded,
                  label: 'System',
                  description: 'Follow device settings',
                  isSelected: ref.watch(themeProvider) == ThemeModeOption.system,
                  onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeModeOption.system),
                ),
                const SizedBox(height: AppTheme.spaceM),
                _buildThemeOption(
                  context: context,
                  option: ThemeModeOption.light,
                  icon: Icons.light_mode_rounded,
                  label: 'Light',
                  description: 'Always light mode',
                  isSelected: ref.watch(themeProvider) == ThemeModeOption.light,
                  onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeModeOption.light),
                ),
                const SizedBox(height: AppTheme.spaceM),
                _buildThemeOption(
                  context: context,
                  option: ThemeModeOption.dark,
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark',
                  description: 'Always dark mode',
                  isSelected: ref.watch(themeProvider) == ThemeModeOption.dark,
                  onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeModeOption.dark),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // 5. Save Button
            CustomButton(
              text: 'SAVE PREFERENCES',
              onPressed: _handleSaveSettings,
            ),
            const SizedBox(height: AppTheme.spaceXL),
          ],
        ),
      ),
    );
  }
}
