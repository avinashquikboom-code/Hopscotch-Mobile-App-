import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_text.dart';
import '../../../features/product/repositories/product_repository.dart';
import '../../../core/widgets/product_card.dart';
import '../../../features/product/models/product_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  bool _isImageSearch = false;

  final List<String> _recentSearches = [
    'mulberry silk',
    'wool trench coat',
    'leather loaders'
  ];

  final List<String> _trendingSearches = [
    'Elysian Silk Dress',
    'Savile Row Suit',
    'Italian Loafers',
    'Organic Cotton Romper',
    'Milano Leather Satchel'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _isImageSearch = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isImageSearch = false;
    });

    try {
      final results = await ref.read(productRepositoryProvider).searchProducts(query);
      setState(() {
        _searchResults = results;
      });
    } catch (_) {
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _pickImageAndSearch(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;
      
      setState(() {
        _searchController.clear();
        _isSearching = true;
        _isImageSearch = true;
        _searchResults = [];
      });

      final results = await ref.read(productRepositoryProvider).searchProductsByImage(image.path);
      
      setState(() {
        _searchResults = results;
      });
    } catch (_) {
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }
  
  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageAndSearch(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageAndSearch(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: EdgeInsets.only(right: responsive.spacing(AppTheme.spaceL)),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light ? Colors.grey[100] : AppTheme.darkSurfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _performSearch,
            style: TextStyle(fontSize: responsive.fontSize14),
            decoration: InputDecoration(
              hintText: 'Search garments, accessories...',
              hintStyle: TextStyle(fontSize: responsive.fontSize14, color: AppTheme.textLightColor),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondaryColor, size: responsive.iconSize(20)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: AppTheme.textSecondaryColor, size: responsive.iconSize(20)),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : IconButton(
                      icon: Icon(Icons.camera_alt_outlined, color: AppTheme.textSecondaryColor, size: responsive.iconSize(20)),
                      onPressed: _showImageSourceBottomSheet,
                    ),
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: responsive.iconSize(24)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: (_searchController.text.isEmpty && !_isImageSearch)
          ? _buildSuggestionsView()
          : _buildSearchResultsView(),
    );
  }

  Widget _buildSuggestionsView() {
    final responsive = context.responsive;
    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: responsive.fontSize18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentSearches.length,
              itemBuilder: (context, index) {
                final query = _recentSearches[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.history_rounded, color: AppTheme.textLightColor, size: responsive.iconSize(20)),
                  title: Text(query, style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: responsive.fontSize14)),
                  trailing: Icon(Icons.north_west_rounded, size: responsive.iconSize(16), color: AppTheme.textLightColor),
                  onTap: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                );
              },
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
          ],

          // Trending Searches
          Text(
            'Trending Searches',
            style: TextStyle(
              fontSize: responsive.fontSize18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          Wrap(
            spacing: responsive.spacing(10),
            runSpacing: responsive.spacing(10),
            children: _trendingSearches.map((term) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = term;
                  _performSearch(term);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: responsive.spacing(14), vertical: responsive.spacing(8)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded, size: responsive.iconSize(16), color: AppTheme.secondaryColor),
                      SizedBox(width: responsive.spacing(6)),
                      Text(
                        term,
                        style: TextStyle(color: AppTheme.textPrimaryColor, fontSize: responsive.fontSize13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView() {
    final responsive = context.responsive;
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: responsive.iconSize(64), color: AppTheme.textLightColor),
              SizedBox(height: responsive.spacing(AppTheme.spaceL)),
              Text(
                'No Search Results',
                style: TextStyle(
                  fontSize: responsive.fontSize20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: responsive.spacing(AppTheme.spaceS)),
              Text(
                _isImageSearch
                  ? 'We couldn\'t find any couture matching your image.'
                  : 'We couldn\'t find any couture matching "${_searchController.text}".',
                style: responsive.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: responsive.spacing(AppTheme.spaceL),
        crossAxisSpacing: responsive.spacing(AppTheme.spaceL),
        childAspectRatio: 0.58,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ProductCard(
          product: product,
          heroTagPrefix: 'search',
          onTap: () => context.push('/product/${product.id}?heroTagPrefix=search'),
        );
      },
    );
  }
}
