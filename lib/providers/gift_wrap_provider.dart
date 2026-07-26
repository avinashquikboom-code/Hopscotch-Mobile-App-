import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/providers/api_provider.dart';

class GiftWrapConfig {
  final bool enabled;
  final double charge;

  const GiftWrapConfig({
    required this.enabled,
    required this.charge,
  });

  factory GiftWrapConfig.fromJson(dynamic json) {
    if (json is! Map) {
      return const GiftWrapConfig(enabled: true, charge: 49.0);
    }
    final map = Map<String, dynamic>.from(json);
    final data = map['data'] is Map ? Map<String, dynamic>.from(map['data']) : map;
    final enabledVal = data['enabled'] ?? true;
    final chargeVal = data['charge'] ?? 49;
    return GiftWrapConfig(
      enabled: enabledVal == true || enabledVal.toString().toLowerCase() == 'true',
      charge: chargeVal is num ? chargeVal.toDouble() : double.tryParse('$chargeVal') ?? 49.0,
    );
  }
}

final giftWrapConfigProvider = FutureProvider<GiftWrapConfig>((ref) async {
  try {
    final apiService = ref.watch(apiServiceProvider);
    final res = await apiService.get('/api/config/gift-wrap');
    if (res.data != null) {
      return GiftWrapConfig.fromJson(res.data);
    }
  } catch (_) {}
  return const GiftWrapConfig(enabled: true, charge: 49.0);
});

class GiftWrapSelectionNotifier extends StateNotifier<bool> {
  GiftWrapSelectionNotifier() : super(false);

  void toggle(bool value) {
    state = value;
  }

  void setSelection(bool value) {
    state = value;
  }
}

final isGiftWrappedProvider = StateNotifierProvider<GiftWrapSelectionNotifier, bool>((ref) {
  return GiftWrapSelectionNotifier();
});
