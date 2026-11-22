import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/utils/recurring_invoices_helpers.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_generated_panel.dart';
import 'package:hexora/services/invoicing/recurring_invoices_api.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Right-side details drawer for a selected recurrence.
///
/// Reads top-down as Client → Service → Configuration → Actions → Generated
/// invoices. The header stays pinned; the generated-invoice list scrolls in
/// the remaining space.
class RecurringSeriesDrawer extends StatelessWidget {
  const RecurringSeriesDrawer({
    super.key,
    required this.series,
    required this.clientName,
    required this.client,
    required this.frequencyLabel,
    required this.nextIssueDate,
    required this.canManage,
    required this.onClose,
    required this.onEdit,
    required this.onPreviewUpcoming,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.api,
    this.receiptsMode = false,
    this.onPreviewInvoice,
  });

  final Map<String, dynamic> series;

  /// Resolved client name, or null when it can't be determined.
  final String? clientName;
  final GroupClient? client;
  final String frequencyLabel;
  final DateTime? nextIssueDate;
  final bool canManage;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onPreviewUpcoming;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final RecurringInvoicesApi? api;
  final bool receiptsMode;
  final ValueChanged<Invoice>? onPreviewInvoice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final es = l.localeName.startsWith('es');
    final status = (series['status'] ?? 'active').toString().toLowerCase();

    final service = (series['name'] ??
            series['concept'] ??
            series['description'] ??
            series['serviceDescription'] ??
            '')
        .toString()
        .trim();

    return Material(
      elevation: 8,
      color: cs.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            clientName: clientName,
            service: service,
            status: status,
            frequencyLabel: frequencyLabel,
            onClose: onClose,
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .5)),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final top = <Widget>[
                _Summary(
                  series: series,
                  frequencyLabel: frequencyLabel,
                  nextIssueDate: nextIssueDate,
                ),
                if (canManage) ...[
                  const SizedBox(height: 12),
                  _Actions(
                    status: status,
                    es: es,
                    onEdit: onEdit,
                    onPause: onPause,
                    onResume: onResume,
                    onCancel: onCancel,
                    onPreviewUpcoming: onPreviewUpcoming,
                  ),
                ],
                const SizedBox(height: 18),
              ];
              final generated = api == null
                  ? const SizedBox.shrink()
                  : RecurringSeriesGeneratedPanel(
                      key: ValueKey('generated-${seriesId(series)}'),
                      api: api!,
                      series: series,
                      client: client,
                      receiptsMode: receiptsMode,
                      dense: true,
                      onPreviewInvoice: onPreviewInvoice,
                    );

              // On short viewports everything scrolls together and the list
              // gets a fixed window, so it never collapses to nothing.
              if (box.maxHeight < 560) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [...top, SizedBox(height: 380, child: generated)],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [...top, Expanded(child: generated)],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.clientName,
    required this.service,
    required this.status,
    required this.frequencyLabel,
    required this.onClose,
  });

  final String? clientName;
  final String service;
  final String status;
  final String frequencyLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final es = l.localeName.startsWith('es');
    final hasClient = (clientName ?? '').trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasClient
                      ? clientName!.trim()
                      : (es ? 'Cliente no disponible' : 'Client unavailable'),
                  key: const ValueKey('recurring-drawer-client'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w600,
                    color: hasClient ? cs.onSurface : cs.onSurfaceVariant,
                    fontStyle: hasClient ? null : FontStyle.italic,
                  ),
                ),
                if (service.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    service,
                    key: const ValueKey('recurring-drawer-service'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusPill(status: status),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.repeat,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        frequencyLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l.close,
            onPressed: onClose,
            icon: const Icon(LucideIcons.x, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';
    final (label, color) = switch (status) {
      'paused' => (es ? 'Pausada' : 'Paused', const Color(0xFFD48806)),
      'cancelled' ||
      'canceled' =>
        (es ? 'Cancelada' : 'Cancelled', cs.onSurfaceVariant),
      _ => (es ? 'Activa' : 'Active', const Color(0xFF17B26A)),
    };
    return Container(
      key: const ValueKey('recurring-drawer-status'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// One white surface: amount + next issue as the primary pair, then the rest
/// of the configuration as compact label/value rows.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.series,
    required this.frequencyLabel,
    required this.nextIssueDate,
  });

  final Map<String, dynamic> series;
  final String frequencyLabel;
  final DateTime? nextIssueDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final es = l.localeName.startsWith('es');
    final currency = (series['currency'] ?? 'EUR').toString().trim();
    final money = NumberFormat.simpleCurrency(
      locale: l.localeName,
      name: currency.isEmpty ? 'EUR' : currency,
    );
    final amount = money.format(seriesTotalAmount(series) ?? 0);
    final next = nextIssueDate == null
        ? (es ? 'Sin programar' : 'Not scheduled')
        : DateFormat('d MMM y', l.localeName).format(nextIssueDate!);

    final mode = recurringInvoiceDateModeFrom(series);
    final day = recurringInvoiceDateDayFrom(series);
    final offset = recurringInvoiceDateOffsetDaysFrom(series);
    final clamp = recurringInvoiceDateClampPolicyFrom(series);
    final invoiceDate = switch (mode) {
      'fixed_day' => es ? 'Día fijo ${day ?? 1}' : 'Fixed day ${day ?? 1}',
      'offset_days' => () {
          final n = offset ?? 0;
          final sign = n >= 0 ? '+' : '';
          return es
              ? 'Fecha de ejecución $sign$n día(s)'
              : 'Execution date $sign$n day(s)';
        }(),
      _ => es ? 'Misma fecha de ejecución' : 'Same as execution date',
    };
    final rule = series['rule'];
    final schedule = rule is Map ? ruleSummary(rule, l) : null;

    final rows = <(String, String)>[
      (es ? 'Frecuencia' : 'Frequency', frequencyLabel),
      if (schedule != null &&
          schedule.trim().isNotEmpty &&
          schedule.trim().toLowerCase() != frequencyLabel.trim().toLowerCase())
        (es ? 'Programación' : 'Schedule', schedule),
      (es ? 'Fecha de factura' : 'Invoice date', invoiceDate),
      if (mode == 'fixed_day')
        (
          es ? 'Ajuste de fecha' : 'Date adjustment',
          clamp == 'error'
              ? (es
                  ? 'Error si el día no existe'
                  : 'Error if the day does not exist')
              : (es ? 'Fin de mes' : 'End of month'),
        ),
    ];

    return Container(
      key: const ValueKey('recurring-drawer-summary'),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Metric(
                    label: es ? 'Importe' : 'Amount',
                    value: amount,
                    valueKey: const ValueKey('recurring-drawer-amount'),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: cs.outlineVariant.withValues(alpha: .5),
                ),
                Expanded(
                  child: _Metric(
                    label: es ? 'Próxima emisión' : 'Next issue',
                    value: next,
                    valueKey: const ValueKey('recurring-drawer-next'),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .5)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _InfoRow(label: rows[i].$1, value: rows[i].$2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.valueKey});
  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            key: valueKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 128,
          child: Text(
            label,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.status,
    required this.es,
    required this.onEdit,
    required this.onPreviewUpcoming,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  final String status;
  final bool es;
  final VoidCallback onEdit;
  final VoidCallback onPreviewUpcoming;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const buttonPadding = EdgeInsets.symmetric(horizontal: 14);
    const minSize = Size(0, 38);
    final canCancel = status == 'active' || status == 'paused';

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey('recurring-drawer-edit'),
            onPressed: onEdit,
            style: FilledButton.styleFrom(
              padding: buttonPadding,
              minimumSize: minSize,
            ),
            icon: const Icon(LucideIcons.pencil, size: 16),
            label: Text(
              es ? 'Editar recurrencia' : 'Edit recurrence',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (status == 'active' || status == 'paused') ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            key: const ValueKey('recurring-drawer-toggle'),
            onPressed: status == 'active' ? onPause : onResume,
            style: OutlinedButton.styleFrom(
              padding: buttonPadding,
              minimumSize: minSize,
            ),
            icon: Icon(
              status == 'active' ? LucideIcons.pause : LucideIcons.play,
              size: 16,
            ),
            label: Text(status == 'active'
                ? (es ? 'Pausar' : 'Pause')
                : (es ? 'Reanudar' : 'Resume')),
          ),
        ],
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          key: const ValueKey('recurring-drawer-more'),
          tooltip: es ? 'Más acciones' : 'More actions',
          icon: const Icon(LucideIcons.ellipsisVertical, size: 18),
          onSelected: (action) {
            switch (action) {
              case 'upcoming':
                onPreviewUpcoming();
              case 'cancel':
                // Confirmation (and "issued invoices stay untouched") is
                // handled by the existing cancel handler.
                onCancel?.call();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'upcoming',
              child: Row(children: [
                const Icon(LucideIcons.calendarClock, size: 16),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    es ? 'Ver próximas facturas' : 'View upcoming invoices',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
            if (canCancel && onCancel != null) ...[
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'cancel',
                child: Row(children: [
                  Icon(LucideIcons.ban, size: 16, color: cs.error),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      es ? 'Cancelar recurrencia' : 'Cancel recurrence',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.error),
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
