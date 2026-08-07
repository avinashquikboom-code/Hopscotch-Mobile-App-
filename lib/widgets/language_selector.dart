import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/constants/app_colors.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/providers/language_provider.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/l10n/app_localizations.dart';

class LanguageSelector extends ConsumerStatefulWidget {
  const LanguageSelector({super.key});

  @override
  ConsumerState<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends ConsumerState<LanguageSelector> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppLanguage> _filter(List<AppLanguage> languages) {
    if (_query.trim().isEmpty) return languages;
    final q = _query.trim().toLowerCase();
    return languages.where((lang) {
      return lang.code.toLowerCase().contains(q) ||
          lang.name.toLowerCase().contains(q) ||
          lang.countryCode.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _selectLanguage(AppLanguage language) async {
    HapticFeedback.selectionClick();
    await ref.read(languageProvider.notifier).setLanguage(language);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(languageProvider);
    final enabledLangsAsync = ref.watch(enabledLanguagesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppTheme.primaryColor;

    final fallback = AppLanguage.values
        .where((l) =>
            l.code == 'en' ||
            l.code == 'hi' ||
            l.code == 'es' ||
            l.code == 'fr')
        .toList();
    final allLanguages = enabledLangsAsync.value ?? fallback;
    final filtered = _filter(allLanguages);

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, size: responsive.iconSize(24)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.selectLanguage,
          style: TextStyle(
            fontSize: responsive.fontSize16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsive.spacing(AppTheme.spaceXL),
              0,
              responsive.spacing(AppTheme.spaceXL),
              responsive.spacing(AppTheme.spaceM),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(
                fontSize: responsive.fontSize14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search language…',
                prefixIcon: Icon(Icons.search_rounded, color: accent),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
              ),
            ),
          ),
          if (enabledLangsAsync.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            )
          else if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No languages found',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: responsive.fontSize13,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  responsive.spacing(AppTheme.spaceXL),
                  0,
                  responsive.spacing(AppTheme.spaceXL),
                  responsive.spacing(AppTheme.spaceXXL),
                ),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : colorScheme.outline,
                      ),
                      boxShadow: isDark ? null : AppTheme.softShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < filtered.length; i++) ...[
                          _LanguageRow(
                            language: filtered[i],
                            selected: currentLanguage == filtered[i],
                            onTap: () => _selectLanguage(filtered[i]),
                          ),
                          if (i < filtered.length - 1)
                            Divider(
                              height: 1,
                              indent: 56,
                              color: colorScheme.outline.withValues(alpha: 0.5),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppTheme.primaryColor;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(AppTheme.spaceL),
        vertical: responsive.spacing(4),
      ),
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.15)
              : accent.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? accent : accent.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          language.code.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: responsive.fontSize11,
            color: accent,
          ),
        ),
      ),
      title: Text(
        language.name,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: responsive.fontSize14,
          color: selected ? accent : colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        language.countryCode,
        style: TextStyle(
          fontSize: responsive.fontSize11,
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: accent, size: 22)
          : Icon(
              Icons.radio_button_unchecked_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.25),
              size: 22,
            ),
    );
  }
}

class LanguageSelectorButton extends ConsumerWidget {
  const LanguageSelectorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final currentCurrency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: const Icon(Icons.language),
        title: Text(l10n.language),
        subtitle: Text(currentLanguage.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentCurrency.symbol,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LanguageSelector(),
            ),
          );
        },
      ),
    );
  }
}
