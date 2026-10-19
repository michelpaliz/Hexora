/// Generated frequency content stays separate from user-authored list items.
class SeasonalFrequency {
  static const months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  static const templates = [
    'Durante los meses de [MESES_TEMPORADA_ALTA], el servicio de [SERVICIO_MANTENIMIENTO] se prestará con una frecuencia de [DIAS_TEMPORADA_ALTA].',
    'Durante los meses de [MESES_TEMPORADA_BAJA], el servicio de [SERVICIO_MANTENIMIENTO] se prestará con una frecuencia de [FRECUENCIA_TEMPORADA_BAJA].',
  ];
  static const stock = {
    ...templates,
    'En los meses de junio, julio, agosto y septiembre el segado del jardín se realizará cada semana.',
    'En los meses de [MESES_TEMPORADA_ALTA] el segado del jardín se realizará cada semana.',
    'El segado del jardín se realizará una vez cada quince días, según las necesidades del césped, el resto del año.',
    'La limpieza de la piscina se realizará tres días por semana en temporada alta: [DIAS_TEMPORADA_ALTA].',
    'La limpieza de la piscina se realizará [DIAS_TEMPORADA_ALTA] en temporada alta.',
    'En temporada baja la limpieza de la piscina se realizará [FRECUENCIA_TEMPORADA_BAJA].',
  };
  static const keys = {
    'SERVICIO_MANTENIMIENTO', 'MESES_TEMPORADA_ALTA', 'MESES_TEMPORADA_BAJA',
    'DIAS_TEMPORADA_ALTA', 'FRECUENCIA_TEMPORADA_BAJA',
  };

  static Map<String, dynamic> normalize(Map<String, dynamic> section) {
    if (section['key'] != 'work_frequency') return section;
    final items = (section['items'] as List? ?? []).map((e) => e.toString()).toList();
    final generated = section['generatedFrequency'] == true ||
        (!section.containsKey('generatedFrequency') && items.any((item) =>
          stock.contains(item) && (item.contains('DIAS_TEMPORADA_ALTA') || item.contains('FRECUENCIA_TEMPORADA_BAJA'))));
    if (!generated) return section;
    return {...section, 'generatedFrequency': true,
      'items': items.where((item) => !stock.contains(item)).toList()};
  }

  static List<int>? monthIndexes(String value) {
    if (value.trim().isEmpty) return [];
    final result = <int>[];
    for (final part in value.toLowerCase().split(RegExp(r'\s*[,;]\s*|\s+y\s+'))) {
      final token = part.trim().replaceFirst(RegExp(r'\.$'), '');
      final index = months.indexWhere((name) => token == name || token == name.substring(0, 3) || (name == 'septiembre' && token == 'sept'));
      if (index < 0) return null; // Preserve custom ranges until the user changes chips.
      result.add(index);
    }
    return result;
  }

  static String monthList(Iterable<int> indexes) {
    final names = indexes.map((index) => months[index]).toList();
    if (names.length < 2) return names.join();
    return '${names.take(names.length - 1).join(', ')} y ${names.last}';
  }

  static List<String> render(Map<String, String> variables) {
    final service = variables['SERVICIO_MANTENIMIENTO']?.trim();
    return List.generate(2, (index) {
      final high = index == 0;
      final monthKey = high ? 'MESES_TEMPORADA_ALTA' : 'MESES_TEMPORADA_BAJA';
      final rawMonths = variables[monthKey]?.trim() ?? '';
      final parsed = monthIndexes(rawMonths);
      final period = rawMonths.isEmpty
          ? 'En temporada ${high ? 'alta' : 'baja'}'
          : 'Durante los meses de ${parsed == null ? rawMonths : monthList(parsed)}';
      final frequencyKey = high ? 'DIAS_TEMPORADA_ALTA' : 'FRECUENCIA_TEMPORADA_BAJA';
      final frequency = variables[frequencyKey];
      final displayFrequency = frequency == null || frequency.isEmpty
          ? (high ? 'tres días por semana' : '[$frequencyKey]') : frequency;
      return '$period, el servicio de ${service == null || service.isEmpty ? 'limpieza de la piscina' : service} se prestará con una frecuencia de $displayFrequency.';
    });
  }
}
