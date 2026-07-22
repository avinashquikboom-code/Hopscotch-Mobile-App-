import 'package:flutter_test/flutter_test.dart';
import 'package:hopscotch/api/api_circuit_breaker.dart';

void main() {
  setUp(() {
    ApiCircuitBreaker.reset();
  });

  group('ApiCircuitBreaker Tests', () {
    test('Initial state should be closed (isOpen == false)', () {
      expect(ApiCircuitBreaker.isOpen, isFalse);
      expect(ApiCircuitBreaker.remainingCooldownSeconds, equals(0));
    });

    test('Single failure should not open the circuit breaker', () {
      ApiCircuitBreaker.recordFailure();
      expect(ApiCircuitBreaker.isOpen, isFalse);
    });

    test('Two consecutive failures (maxFailures) MUST open circuit breaker', () {
      ApiCircuitBreaker.recordFailure();
      ApiCircuitBreaker.recordFailure();
      expect(ApiCircuitBreaker.isOpen, isTrue);
      expect(ApiCircuitBreaker.remainingCooldownSeconds, greaterThan(0));
    });

    test('Manual reset MUST close circuit breaker immediately', () {
      ApiCircuitBreaker.recordFailure();
      ApiCircuitBreaker.recordFailure();
      expect(ApiCircuitBreaker.isOpen, isTrue);

      ApiCircuitBreaker.reset();
      expect(ApiCircuitBreaker.isOpen, isFalse);
      expect(ApiCircuitBreaker.remainingCooldownSeconds, equals(0));
    });

    test('Success MUST reset consecutive failure count', () {
      ApiCircuitBreaker.recordFailure();
      ApiCircuitBreaker.recordSuccess();
      ApiCircuitBreaker.recordFailure();
      // Should still be closed because success reset the counter to 0 before the 2nd failure
      expect(ApiCircuitBreaker.isOpen, isFalse);
    });
  });
}
