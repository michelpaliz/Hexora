import 'package:flutter/material.dart';

class ColorManager {
  /// App palette (no white).
  static final List<Color> eventColors = <Color>[
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.deepOrange,
  ];

  /// Canonical (language-agnostic) base names for each color.
  /// Keys are the ARGB int values for stability.
  static final Map<int, String> _baseNameByColorValue = <int, String>{
    Colors.red.toARGB32(): 'Red',
    Colors.blue.toARGB32(): 'Blue',
    Colors.green.toARGB32(): 'Green',
    Colors.yellow.toARGB32(): 'Yellow',
    Colors.orange.toARGB32(): 'Orange',
    Colors.purple.toARGB32(): 'Purple',
    Colors.pink.toARGB32(): 'Pink',
    Colors.teal.toARGB32(): 'Teal',
    Colors.indigo.toARGB32(): 'Indigo',
    Colors.deepOrange.toARGB32(): 'Deep Orange',
  };

  /// Localized labels for base names.
  /// Add more locales here as needed.
  static const Map<String, Map<String, String>> _labels = {
    'en': {
      'Red': 'Red',
      'Blue': 'Blue',
      'Green': 'Green',
      'Yellow': 'Yellow',
      'Orange': 'Orange',
      'Purple': 'Purple',
      'Pink': 'Pink',
      'Teal': 'Teal',
      'Indigo': 'Indigo',
      'Deep Orange': 'Deep Orange',
    },
    'es': {
      'Red': 'Rojo',
      'Blue': 'Azul',
      'Green': 'Verde',
      'Yellow': 'Amarillo',
      'Orange': 'Naranja',
      'Purple': 'Morado',
      'Pink': 'Rosa',
      'Teal': 'Verde azulado',
      'Indigo': 'Índigo',
      'Deep Orange': 'Naranja intenso',
    },
  };

  /// Get a localized name for a color.
  /// [localeCode] like 'en', 'es'. Defaults to 'en' if unknown.
  static String getColorName(
    Color color, {
    String localeCode = 'en',
  }) {
    final base = _baseNameByColorValue[color.toARGB32()];
    if (base == null) {
      debugPrint('⚠️ Unknown color: ${color.toARGB32().toRadixString(16)}');
      return localeCode == 'es' ? 'Desconocido' : 'Unknown';
    }
    final localeMap = _labels[localeCode] ?? _labels['en']!;
    return localeMap[base] ?? base; // fallback to base/English
  }

  /// Map a localized label back to a Color.
  /// Accepts either localized or base (English) names.
  static Color? colorFromName(String name, {String localeCode = 'en'}) {
    // Build reverse map for the target locale.
    final localeMap = _labels[localeCode] ?? _labels['en']!;
    // Try exact (localized) match first.
    final baseFromLocalized = localeMap.entries
        .firstWhere(
          (e) => e.value.toLowerCase() == name.toLowerCase(),
          orElse: () => const MapEntry<String, String>('', ''),
        )
        .key;

    final baseName = (baseFromLocalized.isNotEmpty)
        ? baseFromLocalized
        : // If not localized match, maybe they passed the base name directly.
        _labels['en']!.keys.firstWhere(
              (k) => k.toLowerCase() == name.toLowerCase(),
              orElse: () => '',
            );

    if (baseName.isEmpty) return null;

    // Find the color value for that base name.
    final colorValue = _baseNameByColorValue.entries
        .firstWhere(
          (e) => e.value == baseName,
          orElse: () => const MapEntry<int, String>(0, ''),
        )
        .key;

    if (colorValue == 0) return null;
    return Color(colorValue);
  }

  /// Palette helpers
  int getColorIndex(Color color) {
    final index =
        eventColors.indexWhere((c) => c.toARGB32() == color.toARGB32());
    return index != -1 ? index : 0;
  }

  Color getColor(int index) {
    if (index >= 0 && index < eventColors.length) {
      return eventColors[index];
    }
    return Colors.grey; // fallback
  }

  /// Convenience: get localized labels in palette order
  static List<String> paletteLabels({String localeCode = 'en'}) {
    return eventColors
        .map((c) => getColorName(c, localeCode: localeCode))
        .toList(growable: false);
  }
}
