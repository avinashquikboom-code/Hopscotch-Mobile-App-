// lib/core/api_circuit_breaker.dart
// Global circuit breaker — jab tak yeh "open" hai, koi bhi API call
// nahi jaayegi. Isse infinite 429-retry-loop structurally impossible
// ho jata hai, sirf backend limit tune karne se nahi.

class ApiCircuitBreaker {
  ApiCircuitBreaker._();

  static int _consecutiveRoundFailures = 0;
  static DateTime? _openUntil;
  static const int _maxFailures = 2;
  static const Duration _cooldown = Duration(seconds: 30);

  static bool get isOpen {
    if (_openUntil == null) return false;
    if (DateTime.now().isAfter(_openUntil!)) {
      // Cooldown khatam — ek chance aur do
      _openUntil = null;
      _consecutiveRoundFailures = 0;
      return false;
    }
    return true;
  }

  static Duration? get remainingCooldown {
    if (_openUntil == null) return null;
    final remaining = _openUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  static int get remainingCooldownSeconds {
    final cooldown = remainingCooldown;
    return cooldown == null ? 0 : cooldown.inSeconds;
  }

  static void recordFailure() {
    _consecutiveRoundFailures++;
    if (_consecutiveRoundFailures >= _maxFailures) {
      _openUntil = DateTime.now().add(_cooldown);
    }
  }

  static void recordSuccess() {
    _consecutiveRoundFailures = 0;
    _openUntil = null;
  }

  static void reset() {
    _consecutiveRoundFailures = 0;
    _openUntil = null;
  }
}

// Circuit open hone par throw karne ke liye
class CircuitOpenException implements Exception {
  final Duration retryAfter;
  CircuitOpenException(this.retryAfter);

  @override
  String toString() =>
      'Too many failed attempts. Please try again in ${retryAfter.inSeconds}s.';
}
