import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/services/ai_vision_service.dart';
import 'package:hopscotch/models/visual_search_product.dart';

final aiVisionServiceProvider = Provider<AIVisionService>((ref) {
  return MockAIVisionService();
});

final searchResultProvider = FutureProvider<VisualSearchResponse>((ref) async {
  throw UnimplementedError('Search not initiated');
});

class ImagePreviewScreen extends ConsumerStatefulWidget {
  final File image;

  const ImagePreviewScreen({super.key, required this.image});

  @override
  ConsumerState<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends ConsumerState<ImagePreviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  final List<String> _scanMessages = [
    'Analyzing image...',
    'Detecting objects...',
    'Finding exact product...',
    'Matching with catalog...',
    'Almost there...',
  ];

  int _currentMessageIndex = 0;
  bool _isScanning = false;
  VisualSearchResponse? _searchResult;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startScanning();
  }

  void _initializeAnimations() {
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scanController.repeat();
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _currentMessageIndex = 0;
    });

    // Cycle through scan messages
    for (int i = 0; i < _scanMessages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _currentMessageIndex = i;
        });
      }
    }

    // Perform actual search
    final service = ref.read(aiVisionServiceProvider);
    final result = await service.analyzeImage(widget.image);

    if (mounted) {
      setState(() {
        _isScanning = false;
        _searchResult = result;
      });

      // Navigate after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        context.push('/visual-search/results', extra: result);
      }
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Image
          Positioned.fill(
            child: Image.file(
              widget.image,
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          // Scanning animation
          if (_isScanning)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Scanning line
                      Positioned(
                        top: _scanAnimation.value *
                            MediaQuery.of(context).size.height *
                            0.8,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF00897B),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Corner brackets
                      Positioned(
                        top: 100,
                        left: 20,
                        child: _buildCorner(),
                      ),
                      Positioned(
                        top: 100,
                        right: 20,
                        child: _buildCorner(),
                      ),
                      Positioned(
                        bottom: 100,
                        left: 20,
                        child: _buildCorner(),
                      ),
                      Positioned(
                        bottom: 100,
                        right: 20,
                        child: _buildCorner(),
                      ),

                      // Pulse effect
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 200 * _pulseAnimation.value,
                              height: 200 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00897B).withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // Scan message
          if (_isScanning)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00897B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _scanMessages[_currentMessageIndex],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Result preview (after scanning)
          if (!_isScanning && _searchResult != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00897B).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Color(0xFF00897B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Search Complete',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              Text(
                                '${_searchResult!.results.length} product(s) found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.push('/visual-search/results', extra: _searchResult);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF00897B),
          width: 2,
        ),
      ),
    );
  }
}
