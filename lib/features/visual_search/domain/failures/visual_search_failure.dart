/// Sealed class for visual search failures
sealed class VisualSearchFailure {
  final String message;

  VisualSearchFailure(this.message);
}

/// Failed to pick image from camera/gallery
class ImagePickFailure extends VisualSearchFailure {
  ImagePickFailure([String message = 'Failed to pick image']) : super(message);
}

/// Failed to decode/read the image file
class DecodeFailure extends VisualSearchFailure {
  DecodeFailure([String message = 'Could not read that image, try another']) : super(message);
}

/// Product catalog is empty or not ready
class EmptyCatalog extends VisualSearchFailure {
  EmptyCatalog([String message = 'No products available in catalog']) : super(message);
}

/// Unknown or unexpected error
class UnknownFailure extends VisualSearchFailure {
  UnknownFailure([String message = 'An unexpected error occurred']) : super(message);
}
