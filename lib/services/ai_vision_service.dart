import 'dart:io';
import 'package:hopscotch/models/visual_search_product.dart';

/// Interface for AI Vision Service
/// Can be replaced with real Gemini Vision API implementation later
abstract class AIVisionService {
  Future<VisualSearchResponse> analyzeImage(File image);
}

/// Mock implementation using local data
/// Simulates AI processing with dummy matching logic
class MockAIVisionService implements AIVisionService {
  static const List<VisualSearchProduct> _mockProducts = [
    VisualSearchProduct(
      id: '1',
      name: 'Cute Cat Embroidery T-Shirt',
      category: 'Women T-Shirt',
      color: 'Cream',
      price: 899.0,
      image: 'assets/products/cat_tshirt.png',
      description: 'Premium cotton t-shirt with adorable cat embroidery',
      rating: 4.5,
      reviewCount: 128,
      isAvailable: true,
      brand: 'Aura Couture',
    ),
    VisualSearchProduct(
      id: '2',
      name: 'Floral Summer Dress',
      category: 'Women Dress',
      color: 'Multi',
      price: 1499.0,
      image: 'assets/products/dress1.png',
      description: 'Beautiful floral print summer dress',
      rating: 4.7,
      reviewCount: 89,
      isAvailable: true,
      brand: 'Aura Couture',
    ),
    VisualSearchProduct(
      id: '3',
      name: 'White Sneakers',
      category: 'Footwear',
      color: 'White',
      price: 2199.0,
      image: 'assets/products/shoes1.png',
      description: 'Classic white sneakers for everyday wear',
      rating: 4.3,
      reviewCount: 256,
      isAvailable: true,
      brand: 'Aura Couture',
    ),
    VisualSearchProduct(
      id: '4',
      name: 'Pink Handbag',
      category: 'Accessories',
      color: 'Pink',
      price: 1299.0,
      image: 'assets/products/bag1.png',
      description: 'Elegant pink handbag with premium finish',
      rating: 4.6,
      reviewCount: 67,
      isAvailable: true,
      brand: 'Aura Couture',
    ),
    VisualSearchProduct(
      id: '5',
      name: 'Denim Jacket',
      category: 'Women Jacket',
      color: 'Blue',
      price: 1799.0,
      image: 'assets/products/jacket1.png',
      description: 'Stylish denim jacket for casual outings',
      rating: 4.4,
      reviewCount: 145,
      isAvailable: true,
      brand: 'Aura Couture',
    ),
    VisualSearchProduct(
      id: '6',
      name: 'Gold Earrings',
      category: 'Jewelry',
      color: 'Gold',
      price: 799.0,
      image: 'assets/products/earrings1.png',
      description: 'Elegant gold earrings for special occasions',
      rating: 4.8,
      reviewCount: 92,
      isAvailable: true,
      brand: 'Aura Couture',
    ),
    VisualSearchProduct(
      id: '7',
      name: 'Black Watch',
      category: 'Accessories',
      color: 'Black',
      price: 3499.0,
      image: 'assets/products/watch1.png',
      description: 'Premium black watch with leather strap',
      rating: 4.2,
      reviewCount: 178,
      isAvailable: true,
      brand: 'Aura Couture',
    ),
    VisualSearchProduct(
      id: '8',
      name: 'Red Scarf',
      category: 'Accessories',
      color: 'Red',
      price: 499.0,
      image: 'assets/products/scarf1.png',
      description: 'Soft red scarf for winter styling',
      rating: 4.5,
      reviewCount: 54,
      isAvailable: true,
      brand: 'Aura Couture',
    ),
  ];

  @override
  Future<VisualSearchResponse> analyzeImage(File image) async {
    final startTime = DateTime.now();

    // Simulate AI processing delay (2-3 seconds)
    await Future.delayed(const Duration(milliseconds: 2500));

    // Simulate image analysis based on filename
    final imageName = image.path.split('/').last.toLowerCase();

    // Check for exact match based on filename
    VisualSearchProduct? exactMatch;
    for (final product in _mockProducts) {
      if (imageName.contains(product.image.split('/').last.toLowerCase())) {
        exactMatch = product;
        break;
      }
    }

    if (exactMatch != null) {
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      return VisualSearchResponse(
        results: [
          VisualSearchResult(
            product: exactMatch,
            similarityScore: 100.0,
            matchType: 'exact',
            matchedAttributes: ['category', 'color', 'pattern'],
          ),
        ],
        status: 'success',
        message: 'Exact match found in catalog',
        processingTimeMs: processingTime,
      );
    }

    // No exact match - return similar products
    final similarProducts = _getSimilarProducts(imageName);
    final processingTime = DateTime.now().difference(startTime).inMilliseconds;

    return VisualSearchResponse(
      results: similarProducts,
      status: similarProducts.isEmpty ? 'no_match' : 'partial_match',
      message: similarProducts.isEmpty
          ? 'No similar products found'
          : 'Found visually similar products',
      processingTimeMs: processingTime,
    );
  }

  List<VisualSearchResult> _getSimilarProducts(String imageName) {
    // Simulate similarity scoring based on image characteristics
    // In real implementation, this would use actual AI comparison
    final similarities = <VisualSearchResult>[];
    final random = DateTime.now().millisecond;

    // Shuffle and pick top 5 with decreasing similarity scores
    final shuffled = List<VisualSearchProduct>.from(_mockProducts);
    shuffled.shuffle();

    for (int i = 0; i < shuffled.length && i < 5; i++) {
      final product = shuffled[i];
      final baseScore = 96.0 - (i * 3.0); // 96%, 93%, 90%, 87%, 84%
      final variation = (random % 5).toDouble();
      final similarityScore = (baseScore - variation).clamp(80.0, 99.0);

      similarities.add(VisualSearchResult(
        product: product,
        similarityScore: similarityScore,
        matchType: 'similar',
        matchedAttributes: ['style', 'category'],
      ));
    }

    // Sort by similarity score descending
    similarities.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
    return similarities;
  }
}
