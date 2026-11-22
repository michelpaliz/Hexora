// lib/presentation/c-group-calendar-section/screens/group/show-groups/group_card_widget/group_thumbnail.dart
import 'package:flutter/material.dart';

class GroupThumbnail extends StatelessWidget {
  const GroupThumbnail({
    super.key,
    required this.photoUrl,
    this.size = 56,
    this.backgroundIsWhite = true,
    this.fallbackAsset,
    this.headers, // ← NEW (for auth-protected images)
    this.fit = BoxFit.cover,
  });

  final String? photoUrl;
  final double size;
  final bool backgroundIsWhite;
  final String? fallbackAsset;
  final Map<String, String>? headers; // ← NEW
  final BoxFit fit; // ← NEW

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
          color: bgColor,
          border:
              Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: _buildImageOrFallback(scheme),
      ),
    );
  }

  Widget _buildImageOrFallback(ColorScheme scheme) {
    final url = photoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        key: ValueKey(url), // ðŸ‘ˆ add this line
        fit: fit,
        headers: headers,
        gaplessPlayback: true,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (ctx, error, stack) {
          debugPrint('GroupThumbnail: failed to load "$url": $error');
          return _fallbackWidget(scheme);
        },
      );
    }
    return _fallbackWidget(scheme);
  }

  Widget _fallbackWidget(ColorScheme scheme) {
    if (fallbackAsset != null && fallbackAsset!.isNotEmpty) {
      return Image.asset(fallbackAsset!, fit: BoxFit.contain);
    }
    // Keep the no-photo state aligned with the business cards' avatar style:
    // a compact, branded mark instead of the generic people icon.
    final diameter = (size * .68).clamp(30.0, 52.0);
    return Center(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(scheme.primary, Colors.white, .16)!,
              Color.lerp(scheme.primary, Colors.black, .12)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: .2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.business_rounded,
          color: Colors.white,
          size: diameter * .58,
        ),
      ),
    );
  }
}
