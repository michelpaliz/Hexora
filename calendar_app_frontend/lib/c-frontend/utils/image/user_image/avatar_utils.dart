// lib/f-themes/utilities/avatar_utils.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AvatarUtils {
  // ---------- Private helpers ----------
  static Color _adaptiveBg(BuildContext context, [Color? override]) {
    if (override != null) return override;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return theme.brightness == Brightness.dark
        ? cs.surfaceContainerHighest
        : cs.surfaceContainerLow;
  }

  static Color _iconColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.9);

  static Widget _circleAvatar({
    required BuildContext context,
    required double radius,
    required IconData fallbackIcon,
    required ImageProvider<Object>? image,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 0,
  }) {
    final bg = _adaptiveBg(context, backgroundColor);
    final iconColor = _iconColor(context);

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      foregroundImage: image,
      onForegroundImageError: (_, __) {}, // avoid the red error overlay
      child: image != null
          ? null
          : Icon(fallbackIcon, size: radius, color: iconColor),
    );

    if (borderWidth > 0) {
      return Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
              color: borderColor ?? Theme.of(context).dividerColor,
              width: borderWidth),
        ),
        child: avatar,
      );
    }
    return avatar;
  }

  // ---------- Public widgets ----------
  /// USER avatar (Widget). Falls back to person icon.
  static Widget profileAvatar(
    BuildContext context,
    String? imageUrl, {
    double radius = 30,
    IconData icon = Icons.person,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 0,
  }) {
    final img = (imageUrl != null && imageUrl.isNotEmpty)
        ? CachedNetworkImageProvider(imageUrl)
        : null;

    return _circleAvatar(
      context: context,
      radius: radius,
      fallbackIcon: icon,
      image: img,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );
  }

  /// GROUP avatar (Widget). Falls back to groups icon.
  static Widget groupAvatar(
    BuildContext context,
    String? imageUrl, {
    double radius = 30,
    IconData icon = Icons.groups,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 0,
  }) {
    final img = (imageUrl != null && imageUrl.isNotEmpty)
        ? CachedNetworkImageProvider(imageUrl)
        : null;

    return _circleAvatar(
      context: context,
      radius: radius,
      fallbackIcon: icon,
      image: img,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );
  }

  // ---------- ImageProviders (unchanged behavior, just consistent) ----------
  /// USER image provider variant for widgets that expect an ImageProvider.
  /// Returns network provider if available, else an asset provider.
  static ImageProvider<Object> profileImageProvider(
    String? imageUrl, {
    String assetFallback = 'assets/images/default_user.png',
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImageProvider(imageUrl);
    }
    return AssetImage(assetFallback);
  }

  /// GROUP image provider: network if present, else asset fallback.
  static ImageProvider<Object> groupImageProvider(
    String? imageUrl, {
    String assetFallback = 'assets/images/default_group.png',
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImageProvider(imageUrl);
    }
    return AssetImage(assetFallback);
  }
}
