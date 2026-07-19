import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/providers/currency_provider.dart';

class CurrencySelector extends ConsumerWidget {
  const CurrencySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyProvider);
    final enabledCurrsAsync = ref.watch(enabledCurrenciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Currency'),
        elevation: 0,
      ),
      body: ListView(
        children: (enabledCurrsAsync.value ?? AppCurrency.values).map((currency) {
          return ListTile(
            leading: Text(
              currency.symbol,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            title: Text(currency.code),
            subtitle: Text(_getCurrencyName(currency)),
            trailing: currentCurrency == currency
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () async {
              await ref.read(currencyProvider.notifier).setCurrency(currency);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  String _getCurrencyName(AppCurrency currency) {
    return currency.name;
  }
}

class CurrencySelectorButton extends ConsumerWidget {
  const CurrencySelectorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyProvider);

    return ListTile(
      leading: const Icon(Icons.attach_money),
      title: const Text('Currency'),
      subtitle: Text(_getCurrencyName(currentCurrency)),
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
            builder: (context) => const CurrencySelector(),
          ),
        );
      },
    );
  }

  String _getCurrencyName(AppCurrency currency) {
    return currency.name;
  }
}
