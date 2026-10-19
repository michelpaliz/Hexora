import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/services/presupuestos/seasonal_frequency.dart';

void main() {
  test('migrates prior variable clauses but does not restore deleted items',
      () {
    final migrated = SeasonalFrequency.normalize({
      'key': 'work_frequency',
      'items': [
        'Temporada alta ([MESES_TEMPORADA_ALTA]): [SERVICIO_MANTENIMIENTO], [DIAS_TEMPORADA_ALTA].',
        'Mi condición personalizada.',
      ],
    });
    expect(migrated['generatedFrequency'], true);
    expect(migrated['items'], ['Mi condición personalizada.']);
    final deleted = {'key': 'work_frequency', 'items': <String>[]};
    expect(SeasonalFrequency.normalize(deleted), deleted);
  });
  test(
      'normalizes only stock content and preserves manual items across reopening',
      () {
    final section = {
      'key': 'work_frequency',
      'items': [
        ...SeasonalFrequency.stock,
        'Revisar el sistema de riego cada lunes.',
      ]
    };
    final normalized = SeasonalFrequency.normalize(section);
    expect(normalized['generatedFrequency'], true);
    expect(normalized['items'], ['Revisar el sistema de riego cada lunes.']);
    expect(SeasonalFrequency.normalize(normalized), normalized);
    final custom = {
      'key': 'work_frequency',
      'items': ['Servicio especial de piscina los jueves.']
    };
    expect(SeasonalFrequency.normalize(custom), custom);
    expect(
        SeasonalFrequency.normalize(
            {...section, 'generatedFrequency': false})['items'],
        section['items']);
  });
  test(
      'service and frequencies render independently without changing variables',
      () {
    for (final service in [
      'mantenimiento del jardín',
      'limpieza de la piscina',
      'mantenimiento del jardín y la piscina'
    ]) {
      final variables = {
        'SERVICIO_MANTENIMIENTO': service,
        'MESES_TEMPORADA_ALTA': 'Jun, Jul, Ago, Sep',
        'MESES_TEMPORADA_BAJA': 'Ene, Feb, Mar, Abr, May, Oct, Nov, Dic',
        'DIAS_TEMPORADA_ALTA': '4 veces por mes',
        'FRECUENCIA_TEMPORADA_BAJA': '2 visitas por mes'
      };
      final sentences = SeasonalFrequency.render(variables);
      expect(sentences, [
        'Durante los meses de junio, julio, agosto y septiembre, el servicio de $service se prestará con una frecuencia de 4 veces por mes.',
        'Durante los meses de enero, febrero, marzo, abril, mayo, octubre, noviembre y diciembre, el servicio de $service se prestará con una frecuencia de 2 visitas por mes.',
      ]);
      expect(SeasonalFrequency.render(variables), sentences);
      expect(variables['MESES_TEMPORADA_ALTA'], 'Jun, Jul, Ago, Sep');
    }
  });
  test('missing periods and custom month ranges remain compatible', () {
    expect(SeasonalFrequency.render({}).first, startsWith('En temporada alta'));
    expect(
        SeasonalFrequency.render({'MESES_TEMPORADA_ALTA': 'junio a septiembre'})
            .first,
        startsWith('Durante los meses de junio a septiembre'));
    expect(SeasonalFrequency.monthIndexes('Jun, Jul, Ago, Sep'), [5, 6, 7, 8]);
    expect(SeasonalFrequency.monthList([0, 1, 2, 3, 4, 9, 10, 11]),
        'enero, febrero, marzo, abril, mayo, octubre, noviembre y diciembre');
  });
}
