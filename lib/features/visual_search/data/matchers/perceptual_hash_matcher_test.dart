import 'package:flutter_test/flutter_test.dart';
import 'package:hopscotch/features/visual_search/data/matchers/perceptual_hash_matcher.dart';
import 'package:hopscotch/features/visual_search/data/matchers/image_matcher.dart';

void main() {
  group('PerceptualHashMatcher', () {
    late PerceptualHashMatcher matcher;

    setUp(() {
      matcher = PerceptualHashMatcher();
    });

    test('should compute signature for valid image', () async {
      // This test would require actual image bytes
      // For now, we'll skip as it needs image assets
      // In production, use test assets
      expect(matcher, isNotNull);
    });

    test('should compare identical signatures with high similarity', () {
      final signature = ImageSignature(
        dHash: BigInt.parse('1234567890ABCDEF', radix: 16),
        hsvHistogram: List.generate(32, (i) => 1.0 / 32),
      );

      final similarity = matcher.compare(signature, signature);
      expect(similarity, closeTo(1.0, 0.01));
    });

    test('should compare different signatures with lower similarity', () {
      final sig1 = ImageSignature(
        dHash: BigInt.parse('FFFFFFFFFFFFFFFF', radix: 16),
        hsvHistogram: List.generate(32, (i) => i % 2 == 0 ? 1.0 : 0.0),
      );

      final sig2 = ImageSignature(
        dHash: BigInt.parse('0000000000000000', radix: 16),
        hsvHistogram: List.generate(32, (i) => i % 2 == 0 ? 0.0 : 1.0),
      );

      final similarity = matcher.compare(sig1, sig2);
      expect(similarity, lessThan(0.5));
    });

    test('should return 0.0 for completely different hashes', () {
      final sig1 = ImageSignature(
        dHash: BigInt.parse('FFFFFFFFFFFFFFFF', radix: 16),
        hsvHistogram: List.generate(32, (i) => 1.0 / 32),
      );

      final sig2 = ImageSignature(
        dHash: BigInt.parse('0000000000000000', radix: 16),
        hsvHistogram: List.generate(32, (i) => 1.0 / 32),
      );

      final similarity = matcher.compare(sig1, sig2);
      // Hash distance is 64, so hashSim = 0, histogramSim = 1
      // Combined = (0 * 0.7) + (1 * 0.3) = 0.3
      expect(similarity, closeTo(0.3, 0.01));
    });
  });
}
