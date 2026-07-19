import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/providers/language_provider.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/l10n/app_localizations.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final enabledLangsAsync = ref.watch(enabledLanguagesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
        elevation: 0,
      ),
      body: ListView(
        children: (enabledLangsAsync.value ?? AppLanguage.values.where((l) => l.code == 'en' || l.code == 'hi' || l.code == 'es' || l.code == 'fr').toList()).map((language) {
          return ListTile(
            leading: Icon(_getLanguageIcon(language)),
            title: Text(_getLanguageName(language, l10n)),
            trailing: currentLanguage == language
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () async {
              await ref.read(languageProvider.notifier).setLanguage(language);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
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

class LanguageSelectorButton extends ConsumerWidget {
  const LanguageSelectorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final currentCurrency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      subtitle: Text(_getLanguageName(currentLanguage, l10n)),
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
    );
  }

  String _getLanguageName(AppLanguage language, AppLocalizations l10n) {
    return language.name;
  }
}
