import 'dart:typed_data';

/// Abstract interface for image matching algorithms
/// Pure function - no IO, no database access
abstract class ImageMatcher {
  /// Compute signature of an image
  Future<ImageSignature> computeSignature(Uint8List imageBytes);

  /// Compare two signatures and return similarity score (0.0 - 1.0)
  double compare(ImageSignature a, ImageSignature b);
}

/// Image signature containing perceptual hash and color histogram
class ImageSignature {
  final BigInt dHash;
  final List<double> hsvHistogram;

  ImageSignature({
    required this.dHash,
    required this.hsvHistogram,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageSignature &&
        other.dHash == dHash &&
        _listEquals(other.hsvHistogram, hsvHistogram);
  }

  @override
  int get hashCode => dHash.hashCode ^ hsvHistogram.hashCode;

  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.001) return false;
    }
    return true;
  }
}
