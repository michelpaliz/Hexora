import 'package:flutter/material.dart';
import 'package:hexora/services/invoicing/recurring_invoices_api.dart';
import 'package:intl/intl.dart';

class RecurringInvoiceActivityTab extends StatefulWidget {
  const RecurringInvoiceActivityTab({
    super.key,
    required this.api,
    required this.seriesId,
    this.receiptsMode = false,
  });

  final RecurringInvoicesApi api;
  final String seriesId;
  final bool receiptsMode;

  @override
  State<RecurringInvoiceActivityTab> createState() =>
      _RecurringInvoiceActivityTabState();
}

class _RecurringInvoiceActivityTabState
    extends State<RecurringInvoiceActivityTab> {
  late Future<({List<Map<String, dynamic>> items, bool limited})> _activity;

  @override
  void initState() {
    super.initState();
    _activity = widget.api.listActivity(widget.seriesId);
  }

  void _reload() {
    setState(() => _activity = widget.api.listActivity(widget.seriesId));
  }

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final colors = Theme.of(context).colorScheme;
    String title(String type) => switch (type) {
          'created' => isEs ? 'Recurrencia creada' : 'Recurrence created',
          'updated' => isEs ? 'Recurrencia actualizada' : 'Recurrence updated',
          'generated' => widget.receiptsMode
              ? (isEs ? 'Recibo borrador generado' : 'Draft receipt generated')
              : (isEs
                  ? 'Factura borrador generada'
                  : 'Draft invoice generated'),
          'skipped' => isEs ? 'Ejecución omitida' : 'Run skipped',
          'failed' => isEs ? 'Error de generación' : 'Generation failed',
          'canceled' => isEs ? 'Recurrencia cancelada' : 'Recurrence canceled',
          'completed' =>
            isEs ? 'Recurrencia completada' : 'Recurrence completed',
          _ => type,
        };

    return FutureBuilder<({List<Map<String, dynamic>> items, bool limited})>(
      future: _activity,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final items = snapshot.data?.items ?? const <Map<String, dynamic>>[];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Text(isEs ? 'Historial de actividad' : 'Activity history',
                      style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  IconButton(
                    tooltip: isEs ? 'Actualizar' : 'Refresh',
                    onPressed: loading ? null : _reload,
                    icon: const Icon(Icons.refresh, size: 19),
                  ),
                ],
              ),
            ),
            if (loading) const LinearProgressIndicator(minHeight: 2),
            if (snapshot.data?.limited == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  isEs
                      ? 'Se muestran los movimientos más recientes.'
                      : 'Showing the most recent activity.',
                  style:
                      TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                ),
              ),
            Expanded(
              child: snapshot.hasError
                  ? Center(
                      child: TextButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: Text(isEs
                            ? 'No se pudo cargar. Reintentar'
                            : 'Could not load. Retry'),
                      ),
                    )
                  : items.isEmpty
                      ? Center(
                          child: Text(loading
                              ? (isEs
                                  ? 'Cargando historial…'
                                  : 'Loading history…')
                              : (isEs
                                  ? 'Todavía no hay actividad registrada.'
                                  : 'No activity recorded yet.')))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final type = item['type']?.toString() ?? '';
                            final at =
                                DateTime.tryParse(item['at']?.toString() ?? '')
                                    ?.toLocal();
                            final actor = item['user'] is Map
                                ? (item['user'] as Map)['name']?.toString()
                                : null;
                            final occurrence =
                                item['occurrenceDate']?.toString();
                            final reason = item['reason']?.toString();
                            final fields = item['changedFields'] is List
                                ? (item['changedFields'] as List)
                                    .map((value) => value.toString())
                                    .join(', ')
                                : '';
                            final detail = [
                              if (actor != null && actor.isNotEmpty) actor,
                              if (occurrence != null && occurrence.isNotEmpty)
                                '${isEs ? 'Ejecución' : 'Run'}: $occurrence',
                              if (fields.isNotEmpty)
                                '${isEs ? 'Campos' : 'Fields'}: $fields',
                              if (reason != null && reason.isNotEmpty) reason,
                            ].join(' · ');
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Icon(
                                  type == 'failed'
                                      ? Icons.error_outline
                                      : Icons.history,
                                  size: 20,
                                  color: type == 'failed'
                                      ? colors.error
                                      : colors.primary,
                                ),
                                title: Text(title(type),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                subtitle: detail.isEmpty
                                    ? null
                                    : Text(detail,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                trailing: at == null
                                    ? null
                                    : Text(
                                        DateFormat.yMMMd(locale)
                                            .add_Hm()
                                            .format(at),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: colors.onSurfaceVariant)),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
