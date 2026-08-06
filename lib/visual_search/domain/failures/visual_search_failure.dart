/// Sealed class for visual search failures
sealed class VisualSearchFailure {
  final String message;

  VisualSearchFailure(this.message);
}

/// Failed to pick image from camera/gallery
class ImagePickFailure extends VisualSearchFailure {
  ImagePickFailure([super.message = 'Failed to pick image']);
}

/// Failed to decode/read the image file
class DecodeFailure extends VisualSearchFailure {
  DecodeFailure([super.message = 'Could not read that image, try another']);
}

/// Product catalog is empty or not ready
class EmptyCatalog extends VisualSearchFailure {
  EmptyCatalog([super.message = 'No products available in catalog']);
}

/// Unknown or unexpected error
class UnknownFailure extends VisualSearchFailure {
  UnknownFailure([super.message = 'An unexpected error occurred']);
}

/// Network or API failure
class NetworkFailure extends VisualSearchFailure {
  NetworkFailure([super.message = 'Failed to connect to service']);
}
