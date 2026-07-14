import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/providers/language_provider.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/l10n/app_localizations.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final currentLanguage = ref.watch(languageProvider);
    final currentCurrency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context)!;

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
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: const Color(0xFFC59F3E),
                          fontSize: responsive.fontSize48,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                    Text(
                      'AURA COUTURE',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: responsive.fontSize24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                    Text(
                      l10n.selectLanguage,
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

              // Language Options
              Expanded(
                child: ListView(
                  children: AppLanguage.values.map((language) {
                    final isSelected = currentLanguage == language;
                    return GestureDetector(
                      onTap: () async {
                        await ref.read(languageProvider.notifier).setLanguage(language);
                        if (mounted) {
                          context.go('/currency-selection');
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
                            Icon(
                              _getLanguageIcon(language),
                              color: isSelected
                                  ? const Color(0xFFC59F3E)
                                  : AppTheme.textSecondaryColor,
                              size: responsive.spacing(28),
                            ),
                            SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getLanguageName(language, l10n),
                                    style: TextStyle(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: responsive.fontSize16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: responsive.spacing(AppTheme.spaceXS)),
                                  Text(
                                    '${l10n.currency}: ${currentCurrency.symbol}',
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
                      context.go('/currency-selection');
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

  IconData _getLanguageIcon(AppLanguage language) {
    return Icons.language;
  }

  String _getLanguageName(AppLanguage language, AppLocalizations l10n) {
    return language.name;
  }
}
