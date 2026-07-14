import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:hopscotch/visual_search/data/matchers/image_matcher.dart';

/// Perceptual hash matcher using dHash + HSV histogram
/// dHash: resize to 9x8, compare adjacent pixels, 64-bit hash
/// HSV histogram: 32 buckets for color similarity
class PerceptualHashMatcher implements ImageMatcher {
  @override
  Future<ImageSignature> computeSignature(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Compute dHash
    final dHash = await _computeDHash(image);

    // Compute HSV histogram
    final histogram = await _computeHSVHistogram(image);

    image.dispose();

    return ImageSignature(
      dHash: dHash,
      hsvHistogram: histogram,
    );
  }

  @override
  double compare(ImageSignature a, ImageSignature b) {
    // dHash similarity (70% weight)
    final hashDistance = _hammingDistance(a.dHash, b.dHash);
    final hashSim = 1 - (hashDistance / 64);

    // HSV histogram similarity (30% weight)
    final histSim = _cosineSimilarity(a.hsvHistogram, b.hsvHistogram);

    // Combined score
    return (hashSim * 0.7) + (histSim * 0.3);
  }

  Future<BigInt> _computeDHash(ui.Image image) async {
    // Resize to 9x8 grayscale
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('Failed to get image data');

    final width = 9;
    final height = 8;
    final pixels = byteData.buffer.asUint8List();

    // Simple downsampling (in production, use proper resizing)
    final List<int> grayscale = [];
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final srcX = (x * image.width) ~/ width;
        final srcY = (y * image.height) ~/ height;
        final idx = (srcY * image.width + srcX) * 4;
        final gray = (0.299 * pixels[idx] + 0.587 * pixels[idx + 1] + 0.114 * pixels[idx + 2]).round();
        grayscale.add(gray);
      }
    }

    // Compute hash by comparing adjacent pixels
    BigInt hash = BigInt.zero;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width - 1; x++) {
        final idx = y * width + x;
        final bit = grayscale[idx] < grayscale[idx + 1] ? 1 : 0;
        hash = (hash << 1) | BigInt.from(bit);
      }
    }

    return hash;
  }

  Future<List<double>> _computeHSVHistogram(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('Failed to get image data');

    final pixels = byteData.buffer.asUint8List();
    final histogram = List<double>.filled(32, 0.0);
    int totalPixels = 0;

    // Sample pixels (every 10th pixel for performance)
    for (int i = 0; i < pixels.length; i += 40) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];

      // Convert to HSV
      final hsv = _rgbToHsv(r, g, b);
      
      // Quantize into 32 buckets (4x8: 4 hue ranges, 8 saturation/value ranges)
      final hueBucket = (hsv[0] / 90).floor().clamp(0, 3);
      final svBucket = (((hsv[1] + hsv[2]) / 2) * 8).floor().clamp(0, 7);
      final bucket = hueBucket * 8 + svBucket;

      histogram[bucket]++;
      totalPixels++;
    }

    // Normalize
    if (totalPixels > 0) {
      for (int i = 0; i < histogram.length; i++) {
        histogram[i] /= totalPixels;
      }
    }

    return histogram;
  }

  List<double> _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;

    final max = [rf, gf, bf].reduce((a, b) => a > b ? a : b);
    final min = [rf, gf, bf].reduce((a, b) => a < b ? a : b);
    final delta = max - min;

    double h, s, v;

    v = max;

    if (delta < 0.00001) {
      h = 0;
      s = 0;
    } else {
      s = delta / max;

      if (max == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (max == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else {
        h = 60 * (((rf - gf) / delta) + 4);
      }

      if (h < 0) h += 360;
    }

    return [h, s, v];
  }

  int _hammingDistance(BigInt a, BigInt b) {
    final xor = a ^ b;
    return xor.toRadixString(2).split('1').length - 1;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0.0;

    return dotProduct / (normA * normB).abs();
  }
}
