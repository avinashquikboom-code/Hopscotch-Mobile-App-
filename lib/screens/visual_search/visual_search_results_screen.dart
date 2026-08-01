import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/visual_search/domain/entities/visual_search_result.dart';
import 'package:hopscotch/visual_search/domain/entities/product.dart';
import 'package:hopscotch/providers/currency_provider.dart';

/// Interactive Visual Search Results Screen
/// Shows Exact Matches and Similar Matches returned from Gemini Vision + PostgreSQL search
class VisualSearchResultsScreen extends ConsumerStatefulWidget {
  final VisualSearchResult result;

  const VisualSearchResultsScreen({
    super.key,
    required this.result,
  });

  @override
  ConsumerState<VisualSearchResultsScreen> createState() => _VisualSearchResultsScreenState();
}

class _VisualSearchResultsScreenState extends ConsumerState<VisualSearchResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final res = widget.result;

    final exactMatches = res.exactMatches;
    final similarMatches = res.similarMatches;
    final attrs = res.extractedAttributes;

    final bool isEmpty = exactMatches.isEmpty && similarMatches.isEmpty;

    if (isEmpty) {
      return _buildEmptyState(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Visual Search Results',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Uploaded Image Summary & Extracted Attributes Header
            _buildExtractedAttributesBanner(attrs),

            // 2. Exact Matches Section
            if (exactMatches.isNotEmpty)
              _buildProductSection(
                title: 'EXACT MATCHES',
                subtitle: 'Products that match your image details closely',
                products: exactMatches,
                currency: currency,
                badgeColor: const Color(0xFF0D9488),
              ),

            // 3. Similar Matches Section ("You Might Also Like")
            if (similarMatches.isNotEmpty)
              _buildProductSection(
                title: 'YOU MIGHT ALSO LIKE',
                subtitle: 'Similar styles, colors, or categories from our catalog',
                products: similarMatches,
                currency: currency,
                badgeColor: const Color(0xFF4F46E5),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedAttributesBanner(Map<String, dynamic>? attrs) {
    final queryImage = widget.result.queryImage;
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: queryImage != null
                      ? Image.file(queryImage, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          child: const Icon(Icons.image, color: Color(0xFF0D9488)),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Visual Search Analysis',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      attrs != null && attrs['confidence'] != null
                          ? 'Attributes extracted with ${(attrs['confidence'] * 100).toStringAsFixed(0)}% confidence'
                          : 'Showing matched products for your image',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF0D9488)),
                onPressed: () => context.pop(),
                tooltip: 'Retake photo',
              ),
            ],
          ),
          if (attrs != null && attrs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (attrs['category'] != null) _buildAttributeChip('Category', attrs['category'].toString()),
                if (attrs['color'] != null) _buildAttributeChip('Color', attrs['color'].toString()),
                if (attrs['material'] != null) _buildAttributeChip('Material', attrs['material'].toString()),
                if (attrs['pattern'] != null) _buildAttributeChip('Pattern', attrs['pattern'].toString()),
                if (attrs['style'] != null) _buildAttributeChip('Style', attrs['style'].toString()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttributeChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
      ),
    );
  }

  Widget _buildProductSection({
    required String title,
    required String subtitle,
    required List<Product> products,
    required dynamic currency,
    required Color badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product, currency);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product p, dynamic currency) {
    return GestureDetector(
      onTap: () {
        context.push('/product/${p.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                child: SizedBox(
                  width: double.infinity,
                  child: _buildProductImage(p.primaryImagePath ?? p.thumbnail),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.brand.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currency.formatPrice(p.price),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0D9488)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ],
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Visual Search Results'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded, size: 56, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              const Text(
                'No matching products found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'We could not find exact or similar items in our catalog matching your uploaded image. Try taking another photo or explore our categories.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/categories');
                },
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text('Browse Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Try Another Image', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: Icon(Icons.checkroom_outlined, size: 36, color: Color(0xFF94A3B8)),
        ),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(child: Icon(Icons.broken_image, size: 36, color: Color(0xFF94A3B8))),
        ),
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(child: Icon(Icons.broken_image, size: 36, color: Color(0xFF94A3B8))),
      ),
    );
  }
}
