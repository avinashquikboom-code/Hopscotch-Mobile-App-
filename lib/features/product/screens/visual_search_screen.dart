import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_text.dart';
import '../../../core/widgets/product_card.dart';
import '../repositories/product_repository.dart';
import '../models/product_model.dart';

enum VisualSearchState {
  preview,
  scanning,
  analyzing,
  results,
}

class VisualHotspot {
  final String label;
  final String categoryId;
  final String subcategory;
  final Rect rect;
  final List<String> logs;

  const VisualHotspot({
    required this.label,
    required this.categoryId,
    required this.subcategory,
    required this.rect,
    required this.logs,
  });
}

class VisualSearchScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const VisualSearchScreen({super.key, required this.imagePath});

  @override
  ConsumerState<VisualSearchScreen> createState() => _VisualSearchScreenState();
}

class _VisualSearchScreenState extends ConsumerState<VisualSearchScreen> with TickerProviderStateMixin {
  VisualSearchState _currentState = VisualSearchState.preview;
  
  // Animation Controllers
  late AnimationController _scannerController;
  late AnimationController _pulseController;
  late AnimationController _boxFadeController;

  // Selected hotspot index
  int _selectedHotspotIndex = 0;

  // Visual Hotspots definitions
  final List<VisualHotspot> _hotspots = const [
    VisualHotspot(
      label: 'Wool Trench Coat',
      categoryId: 'cat_womens',
      subcategory: 'Outerwear',
      rect: Rect.fromLTWH(0.15, 0.15, 0.7, 0.6),
      logs: [
        'Analyzing weave density of wool fibers...',
        'Detecting style outlines: Double-Breasted Trench...',
        'Scanning horn button accents...',
        'Matching earth-tone coats in database...',
      ],
    ),
    VisualHotspot(
      label: 'Silk Wrap Dress',
      categoryId: 'cat_womens',
      subcategory: 'Dresses',
      rect: Rect.fromLTWH(0.25, 0.25, 0.5, 0.5),
      logs: [
        'Analyzing mulberry silk reflection profile...',
        'Detecting style outlines: Elegant Wrap Silhouette...',
        'Scanning tie-waist band...',
        'Matching premium dresses in database...',
      ],
    ),
    VisualHotspot(
      label: 'Leather Satchel Bag',
      categoryId: 'cat_accessories',
      subcategory: 'Bags',
      rect: Rect.fromLTWH(0.35, 0.55, 0.3, 0.25),
      logs: [
        'Analyzing leather grain texture...',
        'Detecting details: Gold hardware accents...',
        'Scanning strap attachment configurations...',
        'Matching designer bags in database...',
      ],
    ),
    VisualHotspot(
      label: 'Oxford Cotton Shirt',
      categoryId: 'cat_mens',
      subcategory: 'Shirts',
      rect: Rect.fromLTWH(0.2, 0.2, 0.6, 0.5),
      logs: [
        'Analyzing Oxford cotton weave texture...',
        'Detecting style outlines: Classic Tailored Shirt...',
        'Scanning button-down collar profile...',
        'Matching cotton shirts in database...',
      ],
    ),
  ];

  // Scanning phase status logs
  int _currentLogIndex = 0;
  List<String> _scanLogs = [];
  Timer? _logTimer;

  List<ProductModel> _matchedProducts = [];
  bool _isLoadingResults = false;

  @override
  void initState() {
    super.initState();
    
    // Auto-detect matching hotspot from the image path/filename keywords
    final pathLower = widget.imagePath.toLowerCase();
    if (pathLower.contains('dress') || pathLower.contains('silk')) {
      _selectedHotspotIndex = 1;
    } else if (pathLower.contains('coat') || pathLower.contains('trench') || pathLower.contains('wool') || pathLower.contains('jacket')) {
      _selectedHotspotIndex = 0;
    } else if (pathLower.contains('bag') || pathLower.contains('satchel') || pathLower.contains('purse') || pathLower.contains('leather')) {
      _selectedHotspotIndex = 2;
    } else if (pathLower.contains('shirt') || pathLower.contains('oxford') || pathLower.contains('top') || pathLower.contains('tee') || pathLower.contains('tshirt') || pathLower.contains('blouse')) {
      _selectedHotspotIndex = 3;
    } else {
      _selectedHotspotIndex = 0; // Default fallback
    }

    // Scanner laser animation
    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Pulse effects for hotspots
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Box fade animations
    _boxFadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _pulseController.dispose();
    _boxFadeController.dispose();
    _logTimer?.cancel();
    super.dispose();
  }

  void _startScanning() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentState = VisualSearchState.scanning;
    });

    _scannerController.repeat(reverse: true);
    _boxFadeController.forward();

    // Set up status logs for the selected hotspot
    final hotspot = _hotspots[_selectedHotspotIndex];
    _scanLogs = [
      'Initializing neural network...',
      'Isolating garment contours...',
      ...hotspot.logs,
      'Querying Aura Couture database...',
      'Generating recommendation rank...',
    ];

    // After 3.5 seconds of scanning, go to state
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      _scannerController.stop();
      _boxFadeController.reverse();
      
      setState(() {
        _currentState = VisualSearchState.analyzing;
      });

      _startStatusLogs();
      _loadMockSimilarProducts();
    });
  }

  void _startStatusLogs() {
    _currentLogIndex = 0;
    _logTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      if (_currentLogIndex < _scanLogs.length - 1) {
        setState(() {
          _currentLogIndex++;
        });
        HapticFeedback.lightImpact();
      } else {
        timer.cancel();
        // Go to results
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() {
            _currentState = VisualSearchState.results;
          });
          HapticFeedback.heavyImpact();
        });
      }
    });
  }

  Future<void> _loadMockSimilarProducts() async {
    setState(() {
      _isLoadingResults = true;
    });
    
    try {
      final repository = ref.read(productRepositoryProvider);
      final allProducts = await repository.getProducts();
      final targetHotspot = _hotspots[_selectedHotspotIndex];

      // Identify the exact matching product ID
      String exactProductId = '';
      if (targetHotspot.label == 'Wool Trench Coat') {
        exactProductId = 'prod_002';
      } else if (targetHotspot.label == 'Silk Wrap Dress') {
        exactProductId = 'prod_001';
      } else if (targetHotspot.label == 'Leather Satchel Bag') {
        exactProductId = 'prod_009';
      } else if (targetHotspot.label == 'Oxford Cotton Shirt') {
        exactProductId = 'prod_012';
      }

      // Filter products by the chosen category and subcategory
      final matches = allProducts.where((p) {
        return p.categoryId == targetHotspot.categoryId &&
               p.subcategory == targetHotspot.subcategory;
      }).toList();

      // Locate the exact product model
      ProductModel? exactProduct;
      try {
        exactProduct = allProducts.firstWhere((p) => p.id == exactProductId);
      } catch (_) {}

      final List<ProductModel> filteredResults = [];
      if (exactProduct != null) {
        filteredResults.add(exactProduct);
      }

      for (var p in matches) {
        if (p.id != exactProductId) {
          filteredResults.add(p);
        }
      }

      if (filteredResults.isEmpty) {
        // Fallback filter
        _matchedProducts = allProducts.where((p) => p.categoryId == targetHotspot.categoryId).toList();
      } else {
        _matchedProducts = filteredResults;
      }
    } catch (_) {
      // Fallback
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingResults = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: _currentState == VisualSearchState.results 
          ? Theme.of(context).scaffoldBackgroundColor 
          : Colors.black,
      body: Stack(
        children: [
          // Background/Main content
          Positioned.fill(
            child: _buildMainContent(responsive),
          ),
          
          // Custom Back Navigation
          if (_currentState != VisualSearchState.results)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: AppTheme.spaceL,
              child: ClipOval(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ResponsiveText responsive) {
    switch (_currentState) {
      case VisualSearchState.preview:
        return _buildPreviewView(responsive);
      case VisualSearchState.scanning:
        return _buildScanningView(responsive);
      case VisualSearchState.analyzing:
        return _buildAnalyzingView(responsive);
      case VisualSearchState.results:
        return _buildResultsView(responsive);
    }
  }

  // --- 1. Preview View ---
  Widget _buildPreviewView(ResponsiveText responsive) {
    final activeHotspot = _hotspots[_selectedHotspotIndex];

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Loaded Image
              Positioned.fill(
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&w=600&q=80',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              // Crop guidelines / highlight area
              Positioned.fill(
                child: CustomPaint(
                  painter: CropOverlayPainter(cropRect: activeHotspot.rect),
                ),
              ),
              
              // Bounding Crop corners
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final left = activeHotspot.rect.left * constraints.maxWidth;
                    final top = activeHotspot.rect.top * constraints.maxHeight;
                    final width = activeHotspot.rect.width * constraints.maxWidth;
                    final height = activeHotspot.rect.height * constraints.maxHeight;
                    
                    return Stack(
                      children: [
                        Positioned(
                          left: left - 2,
                          top: top - 2,
                          width: width + 4,
                          height: height + 4,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primaryColor, width: 2),
                              borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Interactive Hotspot Badge Buttons overlayed
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: _hotspots.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final hs = entry.value;
                        
                        // Center dot of each hotspot's region
                        final double posX = (hs.rect.left + hs.rect.width / 2) * constraints.maxWidth;
                        final double posY = (hs.rect.top + hs.rect.height / 2) * constraints.maxHeight;
                        final isSelected = idx == _selectedHotspotIndex;

                        return Positioned(
                          left: posX - 40,
                          top: posY - 40,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedHotspotIndex = idx;
                              });
                            },
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pulsing outer circle (if active)
                                  if (isSelected)
                                    AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return Container(
                                          width: 16 + (_pulseController.value * 24),
                                          height: 16 + (_pulseController.value * 24),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 1 - _pulseController.value),
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      },
                                    ),
                                  // Center Dot
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : Colors.white60,
                                      border: Border.all(color: AppTheme.primaryColor, width: 3),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Popup target label card
                                  Positioned(
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.primaryColor : Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: isSelected ? Colors.white24 : Colors.transparent),
                                      ),
                                      child: Text(
                                        hs.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Control bar at bottom
        Container(
          color: Colors.black,
          padding: EdgeInsets.only(
            left: responsive.spacing(AppTheme.spaceXL),
            right: responsive.spacing(AppTheme.spaceXL),
            top: responsive.spacing(AppTheme.spaceXL),
            bottom: responsive.spacing(AppTheme.spaceXL) + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AURA AI MULTI-OBJECT DETECTED',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: responsive.fontSize12,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceS)),
              Text(
                'Tap matching hotspots on the image to locate related luxury wear.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: responsive.fontSize12,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                      ),
                      onPressed: () => context.pop(),
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                        elevation: 4,
                        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                      ),
                      onPressed: _startScanning,
                      child: const Text('Scan & Search', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. Scanning View ---
  Widget _buildScanningView(ResponsiveText responsive) {
    final activeHotspot = _hotspots[_selectedHotspotIndex];

    return Stack(
      children: [
        // Main Image
        Positioned.fill(
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.network(
                'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&w=600&q=80',
                fit: BoxFit.cover,
              );
            },
          ),
        ),

        // Dark dim screen
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.3)),
        ),

        // Scanning boundary box highlighting the selected item
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final left = activeHotspot.rect.left * constraints.maxWidth;
              final top = activeHotspot.rect.top * constraints.maxHeight;
              final width = activeHotspot.rect.width * constraints.maxWidth;
              final height = activeHotspot.rect.height * constraints.maxHeight;
 
              return Stack(
                children: [
                  Positioned(
                    left: left,
                    top: top,
                    width: width,
                    height: height,
                    child: FadeTransition(
                      opacity: _boxFadeController,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.6),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Target: ${activeHotspot.label} (99.1%)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Vertical scanning laser
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _scannerController,
            builder: (context, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final topOffset = _scannerController.value * constraints.maxHeight;
                  return Stack(
                    children: [
                      Positioned(
                        top: topOffset - 2,
                        left: 0,
                        right: 0,
                        height: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.8),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: topOffset,
                        left: 0,
                        right: 0,
                        height: 2,
                        child: Container(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),

        // Bottom HUD Panel
        Positioned(
          left: AppTheme.spaceL,
          right: AppTheme.spaceL,
          bottom: MediaQuery.of(context).padding.bottom + 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'AURA SCANNING OBJECTS',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scanning related products for ${activeHotspot.label}...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. Analyzing View ---
  Widget _buildAnalyzingView(ResponsiveText responsive) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 160 + (_pulseController.value * 60),
                        height: 160 + (_pulseController.value * 60),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 1 - _pulseController.value),
                            width: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 120 + (_pulseController.value * 40),
                        height: 120 + (_pulseController.value * 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: (1 - _pulseController.value) * 0.7),
                            width: 1.0,
                          ),
                        ),
                      );
                    },
                  ),
                  // Source image mini thumbnail
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                      image: DecorationImage(
                        image: FileImage(File(widget.imagePath)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Log feed box
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terminal_rounded, color: Colors.white60, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'AURA SEARCH LOGGER',
                        style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _scanLogs.isNotEmpty ? _scanLogs[_currentLogIndex] : 'Analyzing...',
                        key: ValueKey<int>(_currentLogIndex),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontFamily: 'Courier',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Text(
              'Aura style matching engine running...',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- 4. Results View ---
  Widget _buildResultsView(ResponsiveText responsive) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final activeHotspot = _hotspots[_selectedHotspotIndex];
    
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                image: DecorationImage(
                  image: FileImage(File(widget.imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Visual Search Matches',
                    style: TextStyle(
                      fontSize: responsive.fontSize15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Item: ${activeHotspot.label}',
                    style: TextStyle(
                      fontSize: responsive.fontSize11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan',
            onPressed: () {
              setState(() {
                _currentState = VisualSearchState.preview;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match quality info bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Found ${_matchedProducts.length} high-confidence matches in our catalog matching "${activeHotspot.label}".',
                    style: TextStyle(
                      fontSize: responsive.fontSize12,
                      color: isDark ? Colors.teal[200] : Colors.teal[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Results Grid
          Expanded(
            child: _isLoadingResults
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: responsive.spacing(AppTheme.spaceM),
                      crossAxisSpacing: responsive.spacing(AppTheme.spaceM),
                      childAspectRatio: 0.58,
                    ),
                    itemCount: _matchedProducts.length,
                    itemBuilder: (context, index) {
                      final product = _matchedProducts[index];
                      return ProductCard(
                        product: product,
                        heroTagPrefix: 'visual_search',
                        onTap: () => context.push('/product/${product.id}?heroTagPrefix=visual_search'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Crop Preview bounding overlay
class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // Outer rect is canvas size
    final Path outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Inner rect is crop dimensions
    final Path innerPath = Path()..addRect(
      Rect.fromLTWH(
        cropRect.left * size.width,
        cropRect.top * size.height,
        cropRect.width * size.width,
        cropRect.height * size.height,
      ),
    );

    // Difference leaves the frame dim
    final Path overlayPath = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) => oldDelegate.cropRect != cropRect;
}
