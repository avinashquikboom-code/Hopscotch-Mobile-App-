import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/widgets/product_card.dart';
import 'package:hopscotch/widgets/state_widgets.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final responsive = context.responsive;

    return Scaffold(
      appBar: AppBar(
        title: Text('MY WISHLIST', style: TextStyle(fontSize: responsive.fontSize18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: wishlist.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Your Wishlist is Empty',
              description: 'Tap the heart icon on any design to save your favored luxury items here for later.',
              buttonText: 'Explore Departments',
              onButtonPressed: () => context.go('/categories'),
            )
          : GridView.builder(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)).copyWith(bottom: 120),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : (MediaQuery.of(context).size.width < 900 ? 3 : 5),
                mainAxisSpacing: responsive.spacing(AppTheme.spaceL),
                crossAxisSpacing: responsive.spacing(AppTheme.spaceL),
                childAspectRatio: 0.58,
              ),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final product = wishlist[index];
                return ProductCard(
                  product: product,
                  heroTagPrefix: 'wishlist',
                  onTap: () => context.push('/product/${product.id}?heroTagPrefix=wishlist'),
                );
              },
            ),
    );
  }
}
