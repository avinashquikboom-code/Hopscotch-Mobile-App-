import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/providers.dart';
import '../../application/visual_search_state.dart';
import '../../domain/entities/visual_search_result.dart';
import '../../domain/entities/scored_product.dart';
import '../widgets/stage_loader.dart';
import '../widgets/match_badge.dart';

/// Preview screen showing selected image with an interactive crop box,
/// animated scanning line, interactive hotspots, and slide-up results.
class VisualSearchPreviewScreen extends ConsumerStatefulWidget {
  final File image;

  const VisualSearchPreviewScreen({
    super.key,
    required this.image,
  });

  @override
  ConsumerState<VisualSearchPreviewScreen> createState() =>
      _VisualSearchPreviewScreenState();
}

class _VisualSearchPreviewScreenState
    extends ConsumerState<VisualSearchPreviewScreen>
    with SingleTickerProviderStateMixin {
  
  // Crop box dimensions
  double _cropLeft = 60.0;
  double _cropTop = 160.0;
  double _cropWidth = 260.0;
  double _cropHeight = 360.0;

  // Handles parameters
  final double _handleSize = 28.0;

  // Scanning animation controller
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  // Hotspots definitions
  final List<Map<String, dynamic>> _hotspots = [
    {
      'name': 'Ethnic Kurta',
      'x': 180.0,
      'y': 240.0,
      'cropWidth': 220.0,
      'cropHeight': 280.0,
    },
    {
      'name': 'Footwear',
      'x': 200.0,
      'y': 560.0,
      'cropWidth': 180.0,
      'cropHeight': 180.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Setup scanning line animation
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // Initial search on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerSearch();
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    ref.read(visualSearchControllerProvider.notifier).runSearch(widget.image);
  }

  void _selectHotspot(Map<String, dynamic> hotspot) {
    setState(() {
      _cropWidth = hotspot['cropWidth'] as double;
      _cropHeight = hotspot['cropHeight'] as double;
      _cropLeft = (hotspot['x'] as double) - (_cropWidth / 2);
      _cropTop = (hotspot['y'] as double) - (_cropHeight / 2);
    });
    _triggerSearch();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visualSearchControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Search Clothes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _triggerSearch,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Clamp crop box to keep inside viewport
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          _cropWidth = _cropWidth.clamp(100.0, maxWidth - 40.0);
          _cropHeight = _cropHeight.clamp(100.0, maxHeight - 40.0);
          _cropLeft = _cropLeft.clamp(20.0, maxWidth - _cropWidth - 20.0);
          _cropTop = _cropTop.clamp(20.0, maxHeight - _cropHeight - 20.0);

          return Stack(
            children: [
              // 1. Background image
              Positioned.fill(
                child: Image.file(
                  widget.image,
                  fit: BoxFit.cover,
                ),
              ),

              // 2. Semi-transparent overlay with crop viewport cutout
              Positioned.fill(
                child: CustomPaint(
                  painter: VisualSearchCutoutPainter(
                    rect: Rect.fromLTWH(_cropLeft, _cropTop, _cropWidth, _cropHeight),
                  ),
                ),
              ),

              // 3. Draggable Crop Box Border & Corners
              Positioned(
                left: _cropLeft,
                top: _cropTop,
                width: _cropWidth,
                height: _cropHeight,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF00FFCC), width: 2.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),

              // Corner Handles for resizing
              // Top-Left
              Positioned(
                left: _cropLeft - (_handleSize / 4),
                top: _cropTop - (_handleSize / 4),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final deltaX = details.delta.dx;
                      final deltaY = details.delta.dy;
                      _cropLeft += deltaX;
                      _cropTop += deltaY;
                      _cropWidth -= deltaX;
                      _cropHeight -= deltaY;
                    });
                  },
                  onPanEnd: (_) => _triggerSearch(),
                  child: _buildHandle(Icons.crop_square),
                ),
              ),

              // Top-Right
              Positioned(
                left: _cropLeft + _cropWidth - (_handleSize * 3 / 4),
                top: _cropTop - (_handleSize / 4),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final deltaX = details.delta.dx;
                      final deltaY = details.delta.dy;
                      _cropTop += deltaY;
                      _cropWidth += deltaX;
                      _cropHeight -= deltaY;
                    });
                  },
                  onPanEnd: (_) => _triggerSearch(),
                  child: _buildHandle(Icons.crop_square),
                ),
              ),

              // Bottom-Left
              Positioned(
                left: _cropLeft - (_handleSize / 4),
                top: _cropTop + _cropHeight - (_handleSize * 3 / 4),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final deltaX = details.delta.dx;
                      final deltaY = details.delta.dy;
                      _cropLeft += deltaX;
                      _cropWidth -= deltaX;
                      _cropHeight += deltaY;
                    });
                  },
                  onPanEnd: (_) => _triggerSearch(),
                  child: _buildHandle(Icons.crop_square),
                ),
              ),

              // Bottom-Right
              Positioned(
                left: _cropLeft + _cropWidth - (_handleSize * 3 / 4),
                top: _cropTop + _cropHeight - (_handleSize * 3 / 4),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final deltaX = details.delta.dx;
                      final deltaY = details.delta.dy;
                      _cropWidth += deltaX;
                      _cropHeight += deltaY;
                    });
                  },
                  onPanEnd: (_) => _triggerSearch(),
                  child: _buildHandle(Icons.crop_square),
                ),
              ),

              // Center Drag area to move box
              Positioned(
                left: _cropLeft + _handleSize,
                top: _cropTop + _handleSize,
                width: _cropWidth - (_handleSize * 2),
                height: _cropHeight - (_handleSize * 2),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _cropLeft += details.delta.dx;
                      _cropTop += details.delta.dy;
                    });
                  },
                  onPanEnd: (_) => _triggerSearch(),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),

              // 4. Scanning line animation
              if (state is VSAnalyzing)
                Positioned(
                  left: _cropLeft + 2,
                  width: _cropWidth - 4,
                  height: 3.0,
                  top: _cropTop + 2 + (_scanAnimation.value * (_cropHeight - 6)),
                  child: Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00FFCC),
                          blurRadius: 8.0,
                          spreadRadius: 2.0,
                        ),
                      ],
                      color: Color(0xFF00FFCC),
                    ),
                  ),
                ),

              // 5. Hotspot Pulsing dots
              ..._hotspots.map((hotspot) {
                final hx = hotspot['x'] as double;
                final hy = hotspot['y'] as double;
                return Positioned(
                  left: hx - 16,
                  top: hy - 16,
                  child: GestureDetector(
                    onTap: () => _selectHotspot(hotspot),
                    child: const VisualHotspotDot(),
                  ),
                );
              }),

              // 6. Analyzing Overlay/Stage Loader
              if (state is VSAnalyzing)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10),
                      ],
                    ),
                    child: StageLoader(currentStage: state.stage),
                  ),
                ),

              // 7. Results Panel (Draggable Scrollable Bottom Sheet)
              if (state is VSSuccess)
                _buildResultsPanel(context, state.result),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHandle(IconData icon) {
    return Container(
      width: _handleSize,
      height: _handleSize,
      decoration: const BoxDecoration(
        color: Color(0xFF00FFCC),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: const Center(
        child: Icon(
          Icons.drag_handle,
          size: 14,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildResultsPanel(BuildContext context, VisualSearchResult result) {
    final List<ScoredProduct> matches = result is SimilarMatches
        ? result.matches
        : result is ExactMatch
            ? [ScoredProduct(product: result.product, similarityScore: 1.0)]
            : [];

    if (matches.isEmpty) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          height: 120,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'No items found. Try adjusting the search frame.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.20,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 10)],
          ),
          child: Column(
            children: [
              // Bottom sheet drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${matches.length} matching items found',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      child: const Text('Try Another'),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final scoredProduct = matches[index];
                    final product = scoredProduct.product;
                    return GestureDetector(
                      onTap: () {
                        context.push('/product/${product.id}?heroTagPrefix=visual_search');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(11)),
                                      child: Container(
                                        color: const Color(0xFFF5F5F5),
                                        child: product.primaryImagePath != null
                                            ? Image.asset(
                                                product.primaryImagePath!,
                                                fit: BoxFit.cover,
                                              )
                                            : const Center(
                                                child: Icon(Icons.shopping_bag,
                                                    size: 40, color: Colors.grey),
                                              ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: MatchBadge.percentage(
                                        scoredProduct.similarityScore),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${product.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00897B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter to draw a dark translucent overlay with a clear rectangular cutout.
class VisualSearchCutoutPainter extends CustomPainter {
  final Rect rect;

  VisualSearchCutoutPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    
    // Draw background overlay with crop box cutout path
    canvas.drawPath(
      Path.combine(
        ui.PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8.0))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant VisualSearchCutoutPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}

/// Pulsing hotspot dot widget resembling Flipkart's interactive search points
class VisualHotspotDot extends StatefulWidget {
  const VisualHotspotDot({super.key});

  @override
  State<VisualHotspotDot> createState() => _VisualHotspotDotState();
}

class _VisualHotspotDotState extends State<VisualHotspotDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing translucent outer circle
              Container(
                width: _pulseAnimation.value,
                height: _pulseAnimation.value,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.0),
                ),
              ),
              // Inner solid white core
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 3,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
