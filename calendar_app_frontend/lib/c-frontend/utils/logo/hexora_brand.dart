import 'package:flutter/material.dart';

/// Bundled branding sources. Use the widgets below for application UI.
abstract final class HexoraBrandAssets {
  static const icon = 'assets/images/branding/logo_icon.png';
  static const wordmark = 'assets/images/branding/logo_hexora.png';
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
