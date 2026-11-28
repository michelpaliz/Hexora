import 'package:flutter/material.dart';

/// Bundled branding sources. Use the widgets below for application UI.
abstract final class HexoraBrandAssets {
  static const icon = 'assets/images/branding/logo_icon.png';
  static const wordmark = 'assets/images/branding/logo_hexora.png';
  static const defaultBusinessImage = 'assets/images/def_business_img.png';
}

/// Clean wordmark for neutral surfaces, using the existing brand silhouette.
class HexoraSurfaceWordmark extends StatelessWidget {
  const HexoraSurfaceWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Hexora',
      image: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
            child: ColorFiltered(
              // The cream mark has high red values; the navy backdrop has
              // low red values. Extract an alpha mask without a new bitmap.
              colorFilter: const ColorFilter.matrix([
                0,
                0,
                0,
                0,
                255,
                0,
                0,
                0,
                0,
                255,
                0,
                0,
                0,
                0,
                255,
                2,
                0,
                0,
                0,
                -180,
              ]),
              child: Image.asset(HexoraBrandAssets.icon,
                  width: 64, height: 64, fit: BoxFit.contain),
            ),
          ),
          Text('Hexora',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: colors.onSurface,
              )),
        ],
      ),
    );
  }
}

class HexoraBrandIcon extends StatelessWidget {
  const HexoraBrandIcon({
    super.key,
    this.size = 40,
    this.excludeFromSemantics = false,
  });

  final double size;

  /// Set when adjacent visible text already identifies Hexora.
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          HexoraBrandAssets.icon,
          width: size,
          height: size,
          fit: BoxFit.cover,
          semanticLabel: excludeFromSemantics ? null : 'Hexora',
          excludeFromSemantics: excludeFromSemantics,
        ),
      );
}

class HexoraWordmark extends StatelessWidget {
  const HexoraWordmark({
    super.key,
    this.width = 220,
    this.excludeFromSemantics = false,
  });

  final double width;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) => Image.asset(
        HexoraBrandAssets.wordmark,
        width: width,
        fit: BoxFit.contain,
        semanticLabel: excludeFromSemantics ? null : 'Hexora',
        excludeFromSemantics: excludeFromSemantics,
      );
}
