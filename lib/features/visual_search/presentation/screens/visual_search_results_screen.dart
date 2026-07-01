import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/visual_search_result.dart';
import '../../domain/entities/scored_product.dart';
import '../widgets/match_badge.dart';

/// Results screen showing similar products in a grid
/// Google Lens-style layout with product cards
class VisualSearchResultsScreen extends StatelessWidget {
  final VisualSearchResult result;

  const VisualSearchResultsScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Search Results'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: switch (result) {
        ExactMatch() => _buildEmptyState(context),
        SimilarMatches(matches: final matches) => _buildResultsGrid(context, matches),
        NoMatchFound() => _buildEmptyState(context),
      },
    );
  }

  Widget _buildResultsGrid(BuildContext context, List<ScoredProduct> matches) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${matches.length} similar products found',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap a product to view details',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              return _buildProductCard(context, matches[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ScoredProduct scoredProduct) {
    final product = scoredProduct.product;

    return GestureDetector(
      onTap: () {
        context.push('/product/${product.id}?heroTagPrefix=visual_search');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with badge
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                      child: Container(
                        color: const Color(0xFFF5F5F5),
                        child: product.primaryImagePath != null
                            ? Image.asset(
                                product.primaryImagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF00897B).withOpacity(0.1),
                                    child: Center(
                                      child: Icon(
                                        Icons.shopping_bag,
                                        size: 48,
                                        color: const Color(0xFF00897B).withOpacity(0.3),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: const Color(0xFF00897B).withOpacity(0.1),
                                child: Center(
                                  child: Icon(
                                    Icons.shopping_bag,
                                    size: 48,
                                    color: const Color(0xFF00897B).withOpacity(0.3),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  // Match badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: MatchBadge.percentage(scoredProduct.similarityScore),
                  ),
                ],
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00897B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No matching products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try another photo',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
