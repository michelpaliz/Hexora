import 'package:flutter/material.dart';

/// Marks the neutral light palette so navigation surfaces can stay light too.
class HexoraThemeVariant extends ThemeExtension<HexoraThemeVariant> {
  const HexoraThemeVariant({required this.neutralLight});

  final bool neutralLight;

  @override
  HexoraThemeVariant copyWith({bool? neutralLight}) => HexoraThemeVariant(
        neutralLight: neutralLight ?? this.neutralLight,
      );

  @override
  HexoraThemeVariant lerp(
    covariant HexoraThemeVariant? other,
    double t,
  ) {
    if (other == null) return this;
    return HexoraThemeVariant(
        neutralLight: t < 0.5 ? neutralLight : other.neutralLight);
  }
}
