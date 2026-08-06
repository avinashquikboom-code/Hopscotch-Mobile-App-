import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/constants/app_colors.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/providers/language_provider.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/theme/theme_provider.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/widgets/currency_selector.dart';
import 'package:hopscotch/widgets/language_selector.dart';
import 'package:hopscotch/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _tabIndex = 0;
  bool _pushNotifications = true;
  bool _emailPromo = false;
  bool _biometricLogin = true;

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
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.coutureProfileSaved),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
    context.pop();
  }

  Future<void> _editMeasure({
    required String label,
    required TextEditingController controller,
    required String unit,
  }) async {
    final temp = TextEditingController(text: controller.text);
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final responsive = ctx.responsive;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.fontSize18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: responsive.spacing(16)),
              TextField(
                controller: temp,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  suffixText: unit,
                  hintText: label,
                  filled: true,
                  fillColor: AppColors.primaryBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(16)),
              FilledButton(
                onPressed: () {
                  controller.text = temp.text.trim();
                  setState(() {});
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.savePreferences,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
    temp.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _SettingsAppBar(
                title: l10n.settings,
                subtitle: l10n.settingsDesc,
                tabLabels: ['Fit', 'Alerts', l10n.appearance],
                selectedTabIndex: _tabIndex,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
                onTabSelected: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _tabIndex = i);
                },
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: KeyedSubtree(
                    key: ValueKey(_tabIndex),
                    child: _tabIndex == 0
                        ? _FitTab(
                            l10n: l10n,
                            height: _heightController.text,
                            chest: _chestController.text,
                            waist: _waistController.text,
                            onEditHeight: () => _editMeasure(
                              label: l10n.height,
                              controller: _heightController,
                              unit: 'cm',
                            ),
                            onEditChest: () => _editMeasure(
                              label: l10n.chest,
                              controller: _chestController,
                              unit: 'cm',
                            ),
                            onEditWaist: () => _editMeasure(
                              label: l10n.waist,
                              controller: _waistController,
                              unit: 'cm',
                            ),
                          )
                        : _tabIndex == 1
                            ? _AlertsTab(
                                l10n: l10n,
                                pushOn: _pushNotifications,
                                emailOn: _emailPromo,
                                biometricOn: _biometricLogin,
                                onPush: (v) =>
                                    setState(() => _pushNotifications = v),
                                onEmail: (v) =>
                                    setState(() => _emailPromo = v),
                                onBiometric: (v) =>
                                    setState(() => _biometricLogin = v),
                              )
                            : _DisplayTab(
                                l10n: l10n,
                                themeMode: themeMode,
                                languageName: language.name,
                                currencyCode: currency.code,
                                currencySymbol: currency.symbol,
                                onTheme: (mode) {
                                  HapticFeedback.selectionClick();
                                  ref
                                      .read(themeProvider.notifier)
                                      .setThemeMode(mode);
                                },
                                onLanguage: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LanguageSelector(),
                                  ),
                                ),
                                onCurrency: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CurrencySelector(),
                                  ),
                                ),
                              ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: responsive.spacing(AppTheme.spaceXL),
            right: responsive.spacing(AppTheme.spaceXL),
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Material(
              elevation: 8,
              shadowColor: AppTheme.primaryColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: _handleSaveSettings,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(16),
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryHover],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: responsive.iconSize(20),
                      ),
                      SizedBox(width: responsive.spacing(8)),
                      Text(
                        l10n.savePreferences,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: responsive.fontSize14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings app bar (title row + embedded tabs) ─────────────────

class _SettingsAppBar extends StatelessWidget {
  const _SettingsAppBar({
    required this.title,
    required this.subtitle,
    required this.tabLabels,
    required this.selectedTabIndex,
    required this.onBack,
    required this.onTabSelected,
  });

  final String title;
  final String subtitle;
  final List<String> tabLabels;
  final int selectedTabIndex;
  final VoidCallback onBack;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkPrimaryBg, AppColors.darkSurface]
              : [AppColors.primary, AppColors.primaryHover],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          responsive.spacing(AppTheme.spaceL),
          topPad + 8,
          responsive.spacing(AppTheme.spaceL),
          responsive.spacing(AppTheme.spaceL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top row: back · title · icon
            Row(
              children: [
                _FrostedIconButton(
                  icon: Icons.adaptive.arrow_back,
                  onTap: onBack,
                ),
                SizedBox(width: responsive.spacing(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsive.fontSize20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(2)),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: responsive.fontSize11,
                        ),
                      ),
                    ],
                  ),
                ),
                _FrostedIconButton(
                  icon: Icons.settings_outlined,
                  onTap: () => HapticFeedback.selectionClick(),
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            // Embedded segmented tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: List.generate(tabLabels.length, (i) {
                  final selected = i == selectedTabIndex;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < tabLabels.length - 1 ? 4 : 0,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onTabSelected(i),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: EdgeInsets.symmetric(
                              vertical: responsive.spacing(10),
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              tabLabels[i],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: responsive.fontSize11,
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? (isDark
                                        ? AppColors.darkPrimaryBg
                                        : AppTheme.primaryColor)
                                    : Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrostedIconButton extends StatelessWidget {
  const _FrostedIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: Colors.white,
            size: responsive.iconSize(22),
          ),
        ),
      ),
    );
  }
}

// ── Tab: Fit ─────────────────────────────────────────────────────

class _FitTab extends StatelessWidget {
  const _FitTab({
    required this.l10n,
    required this.height,
    required this.chest,
    required this.waist,
    required this.onEditHeight,
    required this.onEditChest,
    required this.onEditWaist,
  });

  final AppLocalizations l10n;
  final String height;
  final String chest;
  final String waist;
  final VoidCallback onEditHeight;
  final VoidCallback onEditChest;
  final VoidCallback onEditWaist;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        responsive.spacing(AppTheme.spaceXL),
        responsive.spacing(AppTheme.spaceL),
        responsive.spacing(AppTheme.spaceXL),
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.darkPrimaryLight.withValues(alpha: 0.3)
                        : AppColors.primaryLight,
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    Icons.accessibility_new_rounded,
                    size: responsive.iconSize(44),
                    color: isDark ? AppColors.darkPrimary : AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: responsive.spacing(16)),
                Text(
                  l10n.bespokeTailoringProfile,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: responsive.fontSize16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: responsive.spacing(6)),
                Text(
                  l10n.bespokeTailoringDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.fontSize11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: l10n.height,
                  value: height,
                  unit: 'cm',
                  icon: Icons.height_rounded,
                  color: AppColors.primary,
                  onTap: onEditHeight,
                ),
              ),
              SizedBox(width: responsive.spacing(12)),
              Expanded(
                child: _MetricCard(
                  label: l10n.chest,
                  value: chest,
                  unit: 'cm',
                  icon: Icons.favorite_rounded,
                  color: AppColors.accent,
                  onTap: onEditChest,
                ),
              ),
              SizedBox(width: responsive.spacing(12)),
              Expanded(
                child: _MetricCard(
                  label: l10n.waist,
                  value: waist,
                  unit: 'cm',
                  icon: Icons.radio_button_checked_rounded,
                  color: AppColors.success,
                  onTap: onEditWaist,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
          Center(
            child: Text(
              'Tap any card to update your measurements',
              style: TextStyle(
                fontSize: responsive.fontSize10,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(responsive.spacing(16)),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : color.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(responsive.spacing(10)),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: responsive.iconSize(24),
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              Text(
                value,
                style: TextStyle(
                  fontSize: responsive.fontSize20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.fontSize10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: responsive.fontSize10,
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab: Alerts ──────────────────────────────────────────────────

class _AlertsTab extends StatelessWidget {
  const _AlertsTab({
    required this.l10n,
    required this.pushOn,
    required this.emailOn,
    required this.biometricOn,
    required this.onPush,
    required this.onEmail,
    required this.onBiometric,
  });

  final AppLocalizations l10n;
  final bool pushOn;
  final bool emailOn;
  final bool biometricOn;
  final ValueChanged<bool> onPush;
  final ValueChanged<bool> onEmail;
  final ValueChanged<bool> onBiometric;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        responsive.spacing(AppTheme.spaceXL),
        responsive.spacing(AppTheme.spaceL),
        responsive.spacing(AppTheme.spaceXL),
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTIFICATIONS'.toUpperCase(),
            style: TextStyle(
              fontSize: responsive.fontSize10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          _EnhancedAlertCard(
            icon: Icons.notifications_active_rounded,
            title: l10n.pushAlerts,
            subtitle: l10n.pushAlertsDesc,
            value: pushOn,
            onChanged: onPush,
            color: AppColors.primary,
          ),
          SizedBox(height: responsive.spacing(12)),
          _EnhancedAlertCard(
            icon: Icons.local_offer_rounded,
            title: l10n.exclusiveDrops,
            subtitle: l10n.exclusiveDropsDesc,
            value: emailOn,
            onChanged: onEmail,
            color: AppColors.accent,
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
          Text(
            l10n.securityPreferences.toUpperCase(),
            style: TextStyle(
              fontSize: responsive.fontSize10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          _EnhancedAlertCard(
            icon: Icons.fingerprint_rounded,
            title: l10n.biometricAuth,
            subtitle: l10n.biometricAuthDesc,
            value: biometricOn,
            onChanged: onBiometric,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _EnhancedAlertCard extends StatelessWidget {
  const _EnhancedAlertCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(16)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(responsive.spacing(10)),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: responsive.iconSize(22),
              ),
            ),
            SizedBox(width: responsive.spacing(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: responsive.fontSize13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontSize: responsive.fontSize10,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab: Display ─────────────────────────────────────────────────

class _DisplayTab extends StatelessWidget {
  const _DisplayTab({
    required this.l10n,
    required this.themeMode,
    required this.languageName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.onTheme,
    required this.onLanguage,
    required this.onCurrency,
  });

  final AppLocalizations l10n;
  final ThemeModeOption themeMode;
  final String languageName;
  final String currencyCode;
  final String currencySymbol;
  final ValueChanged<ThemeModeOption> onTheme;
  final VoidCallback onLanguage;
  final VoidCallback onCurrency;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        responsive.spacing(AppTheme.spaceXL),
        responsive.spacing(AppTheme.spaceL),
        responsive.spacing(AppTheme.spaceXL),
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.languageCurrency.toUpperCase(),
            style: TextStyle(
              fontSize: responsive.fontSize10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          Row(
            children: [
              Expanded(
                child: _LocaleTile(
                  icon: Icons.language_rounded,
                  label: l10n.language,
                  value: languageName,
                  onTap: onLanguage,
                ),
              ),
              SizedBox(width: responsive.spacing(12)),
              Expanded(
                child: _LocaleTile(
                  icon: Icons.currency_exchange_rounded,
                  label: 'Currency',
                  value: '$currencySymbol · $currencyCode',
                  onTap: onCurrency,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
          Text(
            l10n.appearance.toUpperCase(),
            style: TextStyle(
              fontSize: responsive.fontSize10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          Row(
            children: [
              Expanded(
                child: _ThemePreviewCard(
                  label: l10n.light,
                  selected: themeMode == ThemeModeOption.light,
                  previewColors: const [Colors.white, AppColors.primaryBg],
                  onTap: () => onTheme(ThemeModeOption.light),
                ),
              ),
              SizedBox(width: responsive.spacing(8)),
              Expanded(
                child: _ThemePreviewCard(
                  label: l10n.dark,
                  selected: themeMode == ThemeModeOption.dark,
                  previewColors: const [AppColors.darkSurface, AppColors.darkBackground],
                  onTap: () => onTheme(ThemeModeOption.dark),
                ),
              ),
              SizedBox(width: responsive.spacing(8)),
              Expanded(
                child: _ThemePreviewCard(
                  label: l10n.system,
                  selected: themeMode == ThemeModeOption.system,
                  previewColors: const [Colors.white, AppColors.darkSurface],
                  splitPreview: true,
                  onTap: () => onTheme(ThemeModeOption.system),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocaleTile extends StatelessWidget {
  const _LocaleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: EdgeInsets.all(responsive.spacing(16)),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : AppTheme.primaryColor.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(responsive.spacing(8)),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppTheme.primaryColor)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.darkPrimary : AppTheme.primaryColor,
                  size: responsive.iconSize(20),
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.fontSize10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: responsive.fontSize13,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.label,
    required this.selected,
    required this.previewColors,
    required this.onTap,
    this.splitPreview = false,
  });

  final String label;
  final bool selected;
  final List<Color> previewColors;
  final VoidCallback onTap;
  final bool splitPreview;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(responsive.spacing(10)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              width: selected ? 2.5 : 1.2,
            ),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      splitPreview
                          ? Row(
                              children: [
                                Expanded(
                                  child: Container(color: previewColors[0]),
                                ),
                                Expanded(
                                  child: Container(color: previewColors[1]),
                                ),
                              ],
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: previewColors,
                                ),
                              ),
                            ),
                      if (selected)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.9),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppTheme.primaryColor,
                              weight: 800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(10)),
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.fontSize11,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? AppTheme.primaryColor
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
