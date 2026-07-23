import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/widgets/custom_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final String? lottieUrl;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
    this.lottieUrl,
  });

  String? get _resolvedLottieUrl {
    if (lottieUrl != null && lottieUrl!.isNotEmpty) return lottieUrl;
    if (icon == Icons.shopping_bag_outlined || icon == Icons.shopping_cart_outlined) {
      return 'https://assets5.lottiefiles.com/packages/lf20_qh5z2fdq.json';
    }
    if (icon == Icons.favorite_outline_rounded || icon == Icons.favorite_border_rounded) {
      return 'https://assets9.lottiefiles.com/packages/lf20_3bp4f07l.json';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lottie = _resolvedLottieUrl;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lottie != null)
              SizedBox(
                height: 180,
                width: 180,
                child: Lottie.network(
                  lottie,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(AppTheme.spaceXL),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 64, color: AppTheme.primaryColor),
                    );
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceXL),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: AppTheme.primaryColor),
              ),
            const SizedBox(height: AppTheme.spaceXL),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppTheme.spaceXXL),
              CustomButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceXL),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 54,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),
            Text(
              'Oops! Something Went Wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceXXL),
            CustomButton(
              text: 'Try Again',
              onPressed: onRetry,
              isFullWidth: false,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
