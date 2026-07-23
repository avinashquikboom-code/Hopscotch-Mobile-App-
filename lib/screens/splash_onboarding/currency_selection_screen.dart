import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';

class CurrencySelectionScreen extends ConsumerStatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  ConsumerState<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState
    extends ConsumerState<CurrencySelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final currentCurrency = ref.watch(currencyProvider);
    final enabledCurrsAsync = ref.watch(enabledCurrenciesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
          child: Column(
            children: [
              SizedBox(height: responsive.spacing(48)),
              
              // Logo/Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: responsive.spacing(80),
                      height: responsive.spacing(80),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFC59F3E).withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(responsive.spacing(12)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: responsive.spacing(64),
                          height: responsive.spacing(64),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                    Text(
                      'FCI SELLER E-COMMERCE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: responsive.fontSize20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                    Text(
                      'Select Currency',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                        fontSize: responsive.fontSize14,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: responsive.spacing(48)),

              // Currency Options
              Expanded(
                child: ListView(
                  children: (enabledCurrsAsync.value ?? AppCurrency.values).map((currency) {
                    final isSelected = currentCurrency == currency;
                    return GestureDetector(
                      onTap: () async {
                        await ref.read(currencyProvider.notifier).setCurrency(currency);
                        if (mounted) {
                          context.go('/onboarding');
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: responsive.spacing(AppTheme.spaceM),
                        ),
                        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFC59F3E).withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFC59F3E)
                                : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              currency.symbol,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFC59F3E)
                                    : AppTheme.textSecondaryColor,
                                fontSize: responsive.fontSize28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getCurrencyName(currency),
                                    style: TextStyle(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: responsive.fontSize16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: responsive.spacing(AppTheme.spaceXS)),
                                  Text(
                                    currency.code,
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                                      fontSize: responsive.fontSize12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: const Color(0xFFC59F3E),
                                size: responsive.spacing(28),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Continue Button
              Padding(
                padding: EdgeInsets.only(bottom: responsive.spacing(AppTheme.spaceL)),
                child: SizedBox(
                  width: double.infinity,
                  height: responsive.spacing(56),
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/onboarding');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC59F3E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: responsive.fontSize16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrencyName(AppCurrency currency) {
    return currency.name;
  }
}
