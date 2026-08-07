import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/constants/app_colors.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/l10n/app_localizations.dart';

class CurrencySelector extends ConsumerStatefulWidget {
  const CurrencySelector({super.key});

  @override
  ConsumerState<CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends ConsumerState<CurrencySelector> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppCurrency> _filter(List<AppCurrency> currencies) {
    if (_query.trim().isEmpty) return currencies;
    final q = _query.trim().toLowerCase();
    return currencies.where((c) {
      return c.code.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.symbol.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _selectCurrency(AppCurrency currency) async {
    HapticFeedback.selectionClick();
    await ref.read(currencyProvider.notifier).setCurrency(currency);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;
    final currentCurrency = ref.watch(currencyProvider);
    final enabledCurrsAsync = ref.watch(enabledCurrenciesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppTheme.primaryColor;

    final allCurrencies = enabledCurrsAsync.value ?? AppCurrency.values;
    final filtered = _filter(allCurrencies);

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
          l10n.currency,
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
                hintText: 'Search currency…',
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
          if (enabledCurrsAsync.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            )
          else if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No currencies found',
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
                          _CurrencyRow(
                            currency: filtered[i],
                            selected: currentCurrency == filtered[i],
                            onTap: () => _selectCurrency(filtered[i]),
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

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  final AppCurrency currency;
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
          currency.symbol,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: responsive.fontSize14,
            color: accent,
          ),
        ),
      ),
      title: Text(
        currency.code,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: responsive.fontSize14,
          color: selected ? accent : colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        currency.name,
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

class CurrencySelectorButton extends ConsumerWidget {
  const CurrencySelectorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyProvider);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: const Icon(Icons.attach_money),
        title: const Text('Currency'),
        subtitle: Text(currentCurrency.name),
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
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CurrencySelector(),
            ),
          );
        },
      ),
    );
  }
}
