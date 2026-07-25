import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hopscotch/constants/app_urls.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? initials;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.initials,
    this.radius = 24.0,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBgColor = backgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.1);
    final effectiveTextColor = textColor ?? theme.colorScheme.primary;

    final resolvedUrl = (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
        ? AppUrls.resolveUrl(avatarUrl!)
        : null;

    final hasValidUrl = resolvedUrl != null && resolvedUrl.isNotEmpty;

    Widget avatarContent;

    if (hasValidUrl) {
      avatarContent = CachedNetworkImage(
        imageUrl: resolvedUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundColor: effectiveBgColor,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: effectiveBgColor,
          child: _buildFallback(effectiveTextColor),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: effectiveBgColor,
          child: _buildFallback(effectiveTextColor),
        ),
      );
    } else {
      avatarContent = CircleAvatar(
        radius: radius,
        backgroundColor: effectiveBgColor,
        child: _buildFallback(effectiveTextColor),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarContent,
      );
    }

    return avatarContent;
  }

  Widget _buildFallback(Color color) {
    if (initials != null && initials!.trim().isNotEmpty) {
      return Text(
        initials!.trim().toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      );
    }
    return Icon(
      Icons.person,
      size: radius * 1.1,
      color: color,
    );
  }
}
