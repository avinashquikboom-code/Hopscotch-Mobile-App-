import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hopscotch/repositories/config_repository.dart';

enum AppCurrency {
  inr('INR', '₹', 'Indian Rupee', 1.0),
  usd('USD', '\$', 'US Dollar', 0.012),
  eur('EUR', '€', 'Euro', 0.011),
  aed('AED', 'AED', 'UAE Dirham', 0.044),
  gbp('GBP', '£', 'British Pound', 0.009),
  jpy('JPY', '¥', 'Japanese Yen', 1.73),
  cny('CNY', '¥', 'Chinese Yuan', 0.087),
  aud('AUD', 'A\$', 'Australian Dollar', 0.018),
  cad('CAD', 'C\$', 'Canadian Dollar', 0.016),
  chf('CHF', 'Fr', 'Swiss Franc', 0.011),
  sar('SAR', '﷼', 'Saudi Riyal', 0.045),
  kwd('KWD', 'د.ك', 'Kuwaiti Dinar', 0.0037),
  qar('QAR', '﷼', 'Qatari Riyal', 0.044),
  omr('OMR', '﷼', 'Omani Rial', 0.0046),
  bhd('BHD', 'BD', 'Bahraini Dinar', 0.0045),
  myr('MYR', 'RM', 'Malaysian Ringgit', 0.056),
  sgd('SGD', 'S\$', 'Singapore Dollar', 0.016),
  hkd('HKD', 'HK\$', 'Hong Kong Dollar', 0.093),
  nzd('NZD', 'NZ\$', 'New Zealand Dollar', 0.020),
  sek('SEK', 'kr', 'Swedish Krona', 0.13),
  nok('NOK', 'kr', 'Norwegian Krone', 0.13),
  dkk('DKK', 'kr', 'Danish Krone', 0.084),
  pln('PLN', 'zł', 'Polish Zloty', 0.048),
  rub('RUB', '₽', 'Russian Ruble', 1.08),
  // New countries
  mur('MUR', '₨', 'Mauritian Rupee', 0.55),
  fjd('FJD', 'FJ\$', 'Fijian Dollar', 0.027),
  gyd('GYD', 'G\$', 'Guyanese Dollar', 2.51),
  srd('SRD', 'Sr\$', 'Surinamese Dollar', 0.39),
  ttd('TTD', 'TT\$', 'Trinidad & Tobago Dollar', 0.081);

  final String code;
  final String symbol;
  final String name;
  final double rateFromINR; // Conversion rate from INR to this currency

  const AppCurrency(this.code, this.symbol, this.name, this.rateFromINR);

  /// Convert INR price to this currency
  double convertFromINR(double inrPrice) {
    return inrPrice * rateFromINR;
  }

  /// Format price with this currency symbol
  String formatPrice(double priceInINR) {
    final convertedPrice = convertFromINR(priceInINR);
    if (convertedPrice == convertedPrice.truncate()) {
      return '$symbol${convertedPrice.toInt()}';
    }
    return '$symbol${convertedPrice.toStringAsFixed(2)}';
  }
}

class CurrencyNotifier extends StateNotifier<AppCurrency> {
  CurrencyNotifier() : super(AppCurrency.inr) {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString('currency_code') ?? 'INR';
    state = AppCurrency.values.firstWhere(
      (currency) => currency.code == currencyCode,
      orElse: () => AppCurrency.inr,
    );
  }

  Future<void> setCurrency(AppCurrency currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', currency.code);
    state = currency;
  }

  String get currencySymbol => state.symbol;
  String get currencyCode => state.code;
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, AppCurrency>((ref) {
  return CurrencyNotifier();
});

final currencySymbolProvider = Provider<String>((ref) {
  return ref.watch(currencyProvider.notifier).currencySymbol;
});

final currencyCodeProvider = Provider<String>((ref) {
  return ref.watch(currencyProvider.notifier).currencyCode;
});

final enabledCurrenciesProvider = FutureProvider<List<AppCurrency>>((ref) async {
  final configRepo = ref.watch(configRepositoryProvider);
  final apiCurrs = await configRepo.fetchCurrencies();
  if (apiCurrs.isEmpty) {
    return AppCurrency.values;
  }
  
  final List<AppCurrency> matched = [];
  for (final curr in AppCurrency.values) {
    final apiCurr = apiCurrs.firstWhere(
      (c) => c['code'].toString().toUpperCase() == curr.code.toUpperCase() && c['isEnabled'] == true,
      orElse: () => {},
    );
    if (apiCurr.isNotEmpty) {
      matched.add(curr);
    }
  }
  return matched.isNotEmpty ? matched : AppCurrency.values;
});
