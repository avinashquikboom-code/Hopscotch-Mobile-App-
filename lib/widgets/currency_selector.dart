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

    final allCurrencies =
        enabledCurrsAsync.value ?? AppCurrency.values;
    final filtered = _filter(allCurrencies);

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : AppColors.background,
      body: Column(
        children: [
          _CurrencyHeader(
            title: l10n.currency,
            subtitle: 'Choose how prices appear across the app',
            onBack: () => Navigator.pop(context),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsive.spacing(AppTheme.spaceXL),
              responsive.spacing(AppTheme.spaceM),
              responsive.spacing(AppTheme.spaceXL),
              responsive.spacing(AppTheme.spaceS),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(
                fontSize: responsive.fontSize14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search by code or country…',
                hintStyle: TextStyle(
                  fontSize: responsive.fontSize13,
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? AppColors.darkPrimary : AppTheme.primaryColor,
                ),
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(16),
                  vertical: responsive.spacing(14),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkPrimary : AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          if (enabledCurrsAsync.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          else if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.currency_exchange_rounded,
                      size: 48,
                      color: colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
                    SizedBox(height: responsive.spacing(12)),
                    Text(
                      'No currencies match your search',
                      style: TextStyle(
                        fontSize: responsive.fontSize13,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  responsive.spacing(AppTheme.spaceXL),
                  responsive.spacing(AppTheme.spaceS),
                  responsive.spacing(AppTheme.spaceXL),
                  responsive.spacing(AppTheme.spaceXXL),
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    SizedBox(height: responsive.spacing(10)),
                itemBuilder: (context, index) {
                  final currency = filtered[index];
                  final selected = currentCurrency == currency;
                  return _CurrencyCard(
                    currency: currency,
                    selected: selected,
                    onTap: () => _selectCurrency(currency),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CurrencyHeader extends StatelessWidget {
  const _CurrencyHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipPath(
      clipper: _CurrencyHeaderClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          responsive.spacing(AppTheme.spaceXL),
          MediaQuery.of(context).padding.top + 8,
          responsive.spacing(AppTheme.spaceXL),
          40,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkPrimaryBg, AppColors.darkSurface]
                : [AppColors.primary, AppColors.primaryHover],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              top: 16,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: Icon(
                    Icons.adaptive.arrow_back,
                    color: Colors.white,
                    size: responsive.iconSize(24),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                SizedBox(height: responsive.spacing(8)),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(responsive.spacing(10)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.currency_exchange_rounded,
                        color: Colors.white,
                        size: responsive.iconSize(26),
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
                              color: Colors.white,
                              fontSize: responsive.fontSize20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(4)),
                          Text(
                            subtitle,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 24);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 10,
      size.width,
      size.height - 24,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CurrencyCard extends StatelessWidget {
  const _CurrencyCard({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(16),
            vertical: responsive.spacing(14),
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: isDark ? 0.12 : 0.07)
                : (isDark ? AppColors.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? accent
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : isDark
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? accent.withValues(alpha: 0.15)
                      : (isDark
                          ? AppColors.darkPrimaryBg.withValues(alpha: 0.5)
                          : AppColors.primaryBg),
                  border: Border.all(
                    color: accent.withValues(alpha: selected ? 0.5 : 0.2),
                  ),
                ),
                child: Text(
                  currency.symbol,
                  style: TextStyle(
                    fontSize: responsive.fontSize18,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
              SizedBox(width: responsive.spacing(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency.code,
                      style: TextStyle(
                        fontSize: responsive.fontSize15,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.name,
                      style: TextStyle(
                        fontSize: responsive.fontSize11,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 22,
                ),
            ],
          ),
        ),
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
