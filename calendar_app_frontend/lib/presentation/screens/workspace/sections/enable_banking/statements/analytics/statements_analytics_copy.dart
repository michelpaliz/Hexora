import 'package:flutter/material.dart';

class StatementsAnalyticsCopy {
  static bool isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'es';

  static String splitTitle(BuildContext context) =>
      isSpanish(context) ? 'Ingresos vs Gastos' : 'Income vs Expense';

  static String splitSubtitle(BuildContext context) => isSpanish(context)
      ? 'Distribucion del importe total en el periodo seleccionado.'
      : 'Distribution of total amount across the selected period.';

  static String volumeTitle(BuildContext context) => isSpanish(context)
      ? 'Volumen de transacciones'
      : 'Transaction volume';

  static String volumeSubtitle(BuildContext context) => isSpanish(context)
      ? 'Conteo de movimientos en el tiempo para el rango filtrado.'
      : 'Transaction count over time for the filtered range.';

  static String volumeDailyLabel(BuildContext context) =>
      isSpanish(context) ? 'Vista diaria' : 'Daily view';

  static String volumePeriodLabel(BuildContext context) =>
      isSpanish(context) ? 'Vista agregada' : 'Aggregated view';

  static String ticketTitle(BuildContext context) =>
      isSpanish(context) ? 'Ticket medio' : 'Average ticket';

  static String ticketSubtitle(BuildContext context) => isSpanish(context)
      ? 'Metricas calculadas a partir de los movimientos cargados.'
      : 'Metrics calculated from the loaded transactions.';

  static String averageIncomeLabel(BuildContext context) =>
      isSpanish(context) ? 'Ingreso medio' : 'Average income';

  static String averageExpenseLabel(BuildContext context) =>
      isSpanish(context) ? 'Gasto medio' : 'Average expense';

  static String largestIncomeLabel(BuildContext context) =>
      isSpanish(context) ? 'Mayor ingreso' : 'Largest income';

  static String largestExpenseLabel(BuildContext context) =>
      isSpanish(context) ? 'Mayor gasto' : 'Largest expense';

  static String totalTransactionsLabel(BuildContext context) =>
      isSpanish(context) ? 'Total movimientos' : 'Total transactions';

  static String linkedTitle(BuildContext context) => isSpanish(context)
      ? 'Vinculadas vs no vinculadas'
      : 'Linked vs unlinked';

  static String linkedSubtitle(BuildContext context) => isSpanish(context)
      ? 'Relacion entre movimientos enlazados y pendientes de enlazar.'
      : 'Relationship between linked transactions and pending ones.';

  static String linkedLabel(BuildContext context) =>
      isSpanish(context) ? 'Vinculadas' : 'Linked';

  static String unlinkedLabel(BuildContext context) =>
      isSpanish(context) ? 'No vinculadas' : 'Unlinked';

  static String linkedRateLabel(BuildContext context) =>
      isSpanish(context) ? 'Porcentaje vinculado' : 'Linked percentage';

  static String activityTitle(BuildContext context) =>
      isSpanish(context) ? 'Actividad diaria' : 'Daily activity';

  static String activitySubtitle(BuildContext context) => isSpanish(context)
      ? 'Mapa de calor de actividad segun movimientos diarios.'
      : 'Activity heatmap based on daily transactions.';

  static String activityCountLabel(BuildContext context) =>
      isSpanish(context) ? 'Movimientos por dia' : 'Transactions per day';

  static String activityMovementLabel(BuildContext context) =>
      isSpanish(context) ? 'Movimiento absoluto' : 'Absolute movement';

  static String activityWindowLabel(BuildContext context, int days) =>
      isSpanish(context)
          ? 'Ultimos $days dias'
          : 'Last $days days';

  static String activityActiveDaysLabel(BuildContext context) =>
      isSpanish(context) ? 'Dias con actividad' : 'Active days';

  static String activityPeakDayLabel(BuildContext context) =>
      isSpanish(context) ? 'Dia mas activo' : 'Peak day';

  static String statusTitle(BuildContext context) =>
      isSpanish(context) ? 'Estado de datos' : 'Data status';

  static String statusSubtitle(BuildContext context) => isSpanish(context)
      ? 'Estado de frescura del lote o de los lotes seleccionados.'
      : 'Freshness state for the selected batch or batches.';

  static String lastTransactionLabel(BuildContext context) =>
      isSpanish(context) ? 'Ultimo movimiento' : 'Last transaction';

  static String daysSinceLabel(BuildContext context) =>
      isSpanish(context) ? 'Dias desde el ultimo' : 'Days since latest';

  static String thresholdLabel(BuildContext context) =>
      isSpanish(context) ? 'Umbral de alerta' : 'Alert threshold';

  static String freshnessLabel(BuildContext context) =>
      isSpanish(context) ? 'Frescura' : 'Freshness';

  static String freshLabel(BuildContext context) =>
      isSpanish(context) ? 'Fresco' : 'Fresh';

  static String staleLabel(BuildContext context) =>
      isSpanish(context) ? 'Atrasado' : 'Stale';

  static String mixedLabel(BuildContext context) =>
      isSpanish(context) ? 'Mixto' : 'Mixed';

  static String batchesMonitoredLabel(BuildContext context) =>
      isSpanish(context) ? 'Lotes monitorizados' : 'Batches monitored';

  static String noEntriesLabel(BuildContext context) => isSpanish(context)
      ? 'No hay movimientos cargados para este rango.'
      : 'No transactions are loaded for this range.';

  static String noStatusLabel(BuildContext context) => isSpanish(context)
      ? 'No hay estado de frescura disponible.'
      : 'No freshness status is available.';

  static String billableOverviewLabel(BuildContext context) =>
      isSpanish(context) ? 'Resumen' : 'Overview';

  static String topMerchantsMenu(BuildContext context) =>
      isSpanish(context) ? 'Top comercios' : 'Top merchants';

  static String comparisonMenu(BuildContext context) =>
      isSpanish(context) ? 'Comparacion' : 'Comparison';
}
