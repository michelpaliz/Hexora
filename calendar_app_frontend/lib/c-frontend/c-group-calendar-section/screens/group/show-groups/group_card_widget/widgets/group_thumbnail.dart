// lib/c-frontend/c-group-calendar-section/screens/group/show-groups/group_card_widget/group_thumbnail.dart
import 'package:flutter/material.dart';

class GroupThumbnail extends StatelessWidget {
  const GroupThumbnail({
    super.key,
    required this.photoUrl,
    this.size = 56,
    this.backgroundIsWhite = true, // keep white even in dark mode
    this.fallbackAsset, // optional: your own default image asset
  });

  final String? photoUrl;
  final double size;
  final bool backgroundIsWhite;
  final String? fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = backgroundIsWhite ? Colors.white : scheme.surface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor, // ✅ hard white if backgroundIsWhite = true
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
        ),
        child: _buildImageOrFallback(scheme),
      ),
    );
  }

  Widget _buildImageOrFallback(ColorScheme scheme) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        // keep old image until new one is available to avoid flicker
        gaplessPlayback: true,
        // If the network image fails, show fallback
        errorBuilder: (_, __, ___) => _fallbackWidget(scheme),
        // Make sure transparent PNGs still show white behind them
        // (the white comes from the parent Container color).
      );
    }
    return _fallbackWidget(scheme);
  }

  Widget _fallbackWidget(ColorScheme scheme) {
    if (fallbackAsset != null && fallbackAsset!.isNotEmpty) {
      return Image.asset(
        fallbackAsset!,
        fit: BoxFit.contain,
      );
    }
    // Fallback icon if you don't provide an asset
    return Center(
      child: Icon(Icons.groups_rounded, color: scheme.primary, size: 28),
    );
  }
}
