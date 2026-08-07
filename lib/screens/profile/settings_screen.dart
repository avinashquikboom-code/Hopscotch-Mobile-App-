import 'package:flutter/cupertino.dart';
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
import 'package:hopscotch/widgets/custom_button.dart';
import 'package:hopscotch/widgets/currency_selector.dart';
import 'package:hopscotch/widgets/language_selector.dart';
import 'package:hopscotch/l10n/app_localizations.dart';

bool _isCupertino(BuildContext context) {
  final platform = Theme.of(context).platform;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailPromo = false;

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
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

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCupertino = _isCupertino(context);
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);
    final currency = ref.watch(currencyProvider);

    final body = Column(
      children: [
        Expanded(
          child: isCupertino
              ? _buildCupertinoList(
                  context,
                  l10n: l10n,
                  themeMode: themeMode,
                  language: language,
                  currency: currency,
                )
              : _buildMaterialList(
                  context,
                  l10n: l10n,
                  colorScheme: colorScheme,
                  isDark: isDark,
                  themeMode: themeMode,
                  language: language,
                  currency: currency,
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              responsive.spacing(AppTheme.spaceXL),
              responsive.spacing(AppTheme.spaceM),
              responsive.spacing(AppTheme.spaceXL),
              responsive.spacing(AppTheme.spaceM),
            ),
            child: SizedBox(
              width: double.infinity,
              height: responsive.spacing(50),
              child: isCupertino
                  ? CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: AppTheme.primaryColor,
                      onPressed: _handleSaveSettings,
                      child: Text(
                        l10n.savePreferences,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: responsive.fontSize14,
                        ),
                      ),
                    )
                  : CustomButton(
                      text: l10n.savePreferences,
                      onPressed: _handleSaveSettings,
                    ),
            ),
          ),
        ),
      ],
    );

    if (isCupertino) {
      return CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
          context,
        ),
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            l10n.settings,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: responsive.fontSize16,
            ),
          ),
          previousPageTitle: l10n.myPortfolio,
          border: null,
          leading: CupertinoNavigationBarBackButton(
            onPressed: () => _handleBack(context),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Material(
            type: MaterialType.transparency,
            child: body,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, size: responsive.iconSize(24)),
          onPressed: () => _handleBack(context),
        ),
        title: Text(
          l10n.settings,
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: body,
    );
  }

  Widget _buildCupertinoList(
    BuildContext context, {
    required AppLocalizations l10n,
    required ThemeModeOption themeMode,
    required AppLanguage language,
    required AppCurrency currency,
  }) {
    final responsive = context.responsive;

    return ListView(
      padding: EdgeInsets.only(bottom: responsive.spacing(8)),
      children: [
        CupertinoFormSection.insetGrouped(
          header: Text(l10n.notificationPreferences),
          children: [
            _SwitchTile(
              icon: Icons.notifications_active_outlined,
              title: l10n.pushAlerts,
              subtitle: l10n.pushAlertsDesc,
              value: _pushNotifications,
              onChanged: (v) => setState(() => _pushNotifications = v),
            ),
            _SwitchTile(
              icon: Icons.local_offer_outlined,
              title: l10n.exclusiveDrops,
              subtitle: l10n.exclusiveDropsDesc,
              value: _emailPromo,
              onChanged: (v) => setState(() => _emailPromo = v),
            ),
          ],
        ),
        CupertinoFormSection.insetGrouped(
          header: Text(l10n.languageCurrency),
          children: [
            _NavTile(
              icon: Icons.language_rounded,
              title: l10n.language,
              value: language.name,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguageSelector()),
              ),
            ),
            _NavTile(
              icon: Icons.currency_exchange_rounded,
              title: l10n.currency,
              value: '${currency.symbol} · ${currency.code}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CurrencySelector()),
              ),
            ),
          ],
        ),
        CupertinoFormSection.insetGrouped(
          header: Text(l10n.appearance),
          footer: Text(
            themeMode == ThemeModeOption.system
                ? l10n.systemDesc
                : themeMode == ThemeModeOption.light
                    ? l10n.lightDesc
                    : l10n.darkDesc,
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(AppTheme.spaceM),
                vertical: responsive.spacing(AppTheme.spaceM),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ThemeOption(
                      icon: Icons.light_mode_rounded,
                      label: l10n.light,
                      selected: themeMode == ThemeModeOption.light,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(themeProvider.notifier)
                            .setThemeMode(ThemeModeOption.light);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ThemeOption(
                      icon: Icons.dark_mode_rounded,
                      label: l10n.dark,
                      selected: themeMode == ThemeModeOption.dark,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(themeProvider.notifier)
                            .setThemeMode(ThemeModeOption.dark);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ThemeOption(
                      icon: Icons.brightness_auto_rounded,
                      label: l10n.system,
                      selected: themeMode == ThemeModeOption.system,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(themeProvider.notifier)
                            .setThemeMode(ThemeModeOption.system);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaterialList(
    BuildContext context, {
    required AppLocalizations l10n,
    required ColorScheme colorScheme,
    required bool isDark,
    required ThemeModeOption themeMode,
    required AppLanguage language,
    required AppCurrency currency,
  }) {
    final responsive = context.responsive;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        responsive.spacing(AppTheme.spaceXL),
        0,
        responsive.spacing(AppTheme.spaceXL),
        responsive.spacing(AppTheme.spaceL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.darkPrimaryBg, AppColors.darkSurface]
                    : [AppColors.primary, AppColors.primaryHover],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(responsive.spacing(12)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: responsive.iconSize(28),
                  ),
                ),
                SizedBox(width: responsive.spacing(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settings,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: responsive.fontSize14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.settingsDesc,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: responsive.fontSize11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
          _SectionTitle(text: l10n.notificationPreferences),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          _MaterialSettingsGroup(
            children: [
              _SwitchTile(
                icon: Icons.notifications_active_outlined,
                title: l10n.pushAlerts,
                subtitle: l10n.pushAlertsDesc,
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
              ),
              const _MaterialGroupDivider(),
              _SwitchTile(
                icon: Icons.local_offer_outlined,
                title: l10n.exclusiveDrops,
                subtitle: l10n.exclusiveDropsDesc,
                value: _emailPromo,
                onChanged: (v) => setState(() => _emailPromo = v),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
          _SectionTitle(text: l10n.languageCurrency),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          _MaterialSettingsGroup(
            children: [
              _NavTile(
                icon: Icons.language_rounded,
                title: l10n.language,
                value: language.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguageSelector()),
                ),
              ),
              const _MaterialGroupDivider(),
              _NavTile(
                icon: Icons.currency_exchange_rounded,
                title: l10n.currency,
                value: '${currency.symbol} · ${currency.code}',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CurrencySelector()),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
          _SectionTitle(text: l10n.appearance),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          _MaterialSettingsGroup(
            child: Padding(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    themeMode == ThemeModeOption.system
                        ? l10n.systemDesc
                        : themeMode == ThemeModeOption.light
                            ? l10n.lightDesc
                            : l10n.darkDesc,
                    style: TextStyle(
                      fontSize: responsive.fontSize11,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                  Row(
                    children: [
                      Expanded(
                        child: _ThemeOption(
                          icon: Icons.light_mode_rounded,
                          label: l10n.light,
                          selected: themeMode == ThemeModeOption.light,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(themeProvider.notifier)
                                .setThemeMode(ThemeModeOption.light);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ThemeOption(
                          icon: Icons.dark_mode_rounded,
                          label: l10n.dark,
                          selected: themeMode == ThemeModeOption.dark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(themeProvider.notifier)
                                .setThemeMode(ThemeModeOption.dark);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ThemeOption(
                          icon: Icons.brightness_auto_rounded,
                          label: l10n.system,
                          selected: themeMode == ThemeModeOption.system,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(themeProvider.notifier)
                                .setThemeMode(ThemeModeOption.system);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Padding(
      padding: EdgeInsets.only(left: responsive.spacing(4)),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: responsive.fontSize10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _MaterialSettingsGroup extends StatelessWidget {
  const _MaterialSettingsGroup({this.child, this.children});

  final Widget? child;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : colorScheme.outline,
        ),
        boxShadow: isDark ? null : AppTheme.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: child ?? Column(children: children ?? []),
      ),
    );
  }
}

class _MaterialGroupDivider extends StatelessWidget {
  const _MaterialGroupDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppTheme.primaryColor;

    if (_isCupertino(context)) {
      return CupertinoListTile(
        leading: Icon(icon, color: accent, size: responsive.iconSize(22)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: responsive.fontSize14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: responsive.fontSize11,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        trailing: CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: accent,
        ),
      );
    }

    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(AppTheme.spaceL),
        vertical: responsive.spacing(4),
      ),
      secondary: Container(
        padding: EdgeInsets.all(responsive.spacing(8)),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accent, size: responsive.iconSize(20)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: responsive.fontSize13,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: responsive.fontSize10,
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      value: value,
      activeThumbColor: accent,
      onChanged: onChanged,
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppTheme.primaryColor;

    if (_isCupertino(context)) {
      return CupertinoListTile(
        leading: Icon(icon, color: accent, size: responsive.iconSize(22)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: responsive.fontSize14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: responsive.fontSize11,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        trailing: const CupertinoListTileChevron(),
        onTap: onTap,
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(AppTheme.spaceL),
        vertical: responsive.spacing(4),
      ),
      leading: Container(
        padding: EdgeInsets.all(responsive.spacing(8)),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accent, size: responsive.iconSize(20)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: responsive.fontSize13,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: responsive.fontSize11,
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurface.withValues(alpha: 0.35),
      ),
      onTap: onTap,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: isDark ? 0.2 : 0.1)
                : (isDark
                    ? AppColors.darkPrimaryBg.withValues(alpha: 0.3)
                    : AppColors.primaryBg),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? accent
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                size: responsive.iconSize(22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.fontSize10,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? accent
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
