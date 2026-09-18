import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/service_catalog/service.dart';
import 'package:hexora/presentation/routes/appRoutes.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_formatters.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_shared.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/presentation/shared/downloads/download_jobs_store.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/event/domain/event_domain.dart';
import 'package:hexora/services/insights/insights_api.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/service_catalog/service_api_client.dart';
import 'package:hexora/services/statements/statements_api.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:provider/provider.dart';

import '../dialogs/insights_event_edit_dialog.dart';
import '../insights_action_tokens.dart';
import '../insights_chat_enums.dart';
import '../insights_chat_menu.dart';
import '../insights_chat_message.dart';
import '../insights_chat_runtime.dart';
import '../insights_chat_sheet.dart';
import '../insights_date_range.dart';
import '../insights_json_utils.dart';
import '../insights_markdown.dart';
import '../insights_pending_invoice_link_edit.dart';
import '../insights_remote_table_state.dart';
import '../widgets/insights_async_icon_button.dart';
import '../widgets/insights_chat_bubble.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsBankIncomeMatchUi on InsightsChatSheetStateBase {
  @override
  Future<void> showBankIncomeScoringInfo({
    required BuildContext sourceContext,
    required Map<String, dynamic> scoring,
    Map<String, dynamic>? groupMatching,
    required bool isEs,
  }) async {
    final weights = safeMap(scoring['weights']) ?? const <String, dynamic>{};
    final entries = <(String, dynamic)>[
      (isEs ? 'Importe' : 'Amount', weights['amount']),
      (isEs ? 'Cliente' : 'Client', weights['client']),
      (isEs ? 'Nº factura' : 'Invoice no.', weights['invoiceNumber']),
      (isEs ? 'Fecha' : 'Date', weights['date']),
    ].where((entry) => entry.$2 is num).toList(growable: false);
    if (entries.isEmpty && groupMatching == null) return;

    await showDialog<void>(
      context: sourceContext,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final t = AppTypography.of(context);
        return AlertDialog(
          title: Text(isEs ? 'Cómo se ordenan' : 'How candidates are ranked'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.$1,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          '${formatBankIncomeMatchNumber((entry.$2 as num) * 100)}%',
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (groupMatching?['enabled'] == true) ...[
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isEs ? 'Coincidencias agrupadas' : 'Grouped matches',
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final policy in <String>[
                    if (groupMatching?['sameClientOnly'] == true)
                      isEs ? 'Solo el mismo cliente' : 'Same client only',
                    if (groupMatching?['maximumInvoices'] is num)
                      isEs
                          ? 'Máximo ${groupMatching!['maximumInvoices']} facturas'
                          : 'Maximum ${groupMatching!['maximumInvoices']} invoices',
                    isEs
                        ? 'Facturas emitidas sin vincular'
                        : 'Unlinked issued invoices',
                    if (groupMatching?['invoiceDateWindowDays'] is num)
                      isEs
                          ? 'Fechas dentro de ${groupMatching!['invoiceDateWindowDays']} días'
                          : 'Invoice dates within ${groupMatching!['invoiceDateWindowDays']} days',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 15, color: cs.primary),
                          const SizedBox(width: 7),
                          Expanded(child: Text(policy, style: t.bodySmall)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isEs ? 'Cerrar' : 'Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget bankIncomeMatchDetailsContent(
    BuildContext context, {
    required Map<String, dynamic> row,
    required bool isEs,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final components =
        safeMap(row['matchComponents']) ?? const <String, dynamic>{};
    final signals = safeMap(row['matchSignals']) ?? const <String, dynamic>{};
    final grouped = isGroupedBankIncomeCandidate(row);
    final componentRows = grouped
        ? <(String, Map<String, dynamic>?)>[
            (
              isEs ? 'Importe combinado' : 'Combined amount',
              safeMap(components['amount'])
            ),
            (
              isEs ? 'Combinación única' : 'Unique combination',
              safeMap(components['combinationUniqueness'])
            ),
            (
              isEs ? 'Fechas de las facturas' : 'Invoice dates',
              safeMap(components['date'])
            ),
            (
              isEs ? 'Cliente en concepto' : 'Client in description',
              safeMap(components['client'])
            ),
            (
              isEs ? 'Referencias de factura' : 'Invoice references',
              safeMap(components['invoiceNumber'])
            ),
          ]
        : <(String, Map<String, dynamic>?)>[
            (isEs ? 'Importe' : 'Amount', safeMap(components['amount'])),
            (isEs ? 'Cliente' : 'Client', safeMap(components['client'])),
            (
              isEs ? 'Nº factura' : 'Invoice no.',
              safeMap(components['invoiceNumber'])
            ),
            (isEs ? 'Fecha' : 'Date', safeMap(components['date'])),
          ];
    final amountDelta = signals['amountDelta'];
    final dateDays = signals['dateDays'];
    final invoiceNumberMatch = signals['invoiceNumberMatch'];
    final clientName = signals['clientName']?.toString().trim() ?? '';
    final scorePercent = formatBankIncomeMatchNumber(
      row['matchScorePercent'],
    );

    Widget detailRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          grouped
              ? (isEs
                  ? 'Cómo se calcula la coincidencia agrupada'
                  : 'How the grouped match is calculated')
              : (isEs ? 'Cómo se calcula' : 'How it is calculated'),
          style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        for (final entry in componentRows)
          if (entry.$2 != null)
            detailRow(
              entry.$1,
              '${formatBankIncomeMatchNumber(entry.$2!['points'])} / '
              '${formatBankIncomeMatchNumber((entry.$2!['weight'] as num?) == null ? null : (entry.$2!['weight'] as num) * 100)} '
              '${isEs ? 'puntos' : 'points'}',
            ),
        if (grouped && components['date'] != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.36),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isEs
                  ? 'Se consideran las fechas de todas las facturas, su proximidad al ingreso y si fueron emitidas juntas.'
                  : 'All invoice dates, their proximity to the deposit, and whether they were issued together are considered.',
              style: t.caption.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
        if (scorePercent.isNotEmpty) ...[
          const Divider(height: 22),
          detailRow(
            isEs ? 'Total' : 'Total',
            '$scorePercent / 100',
          ),
        ],
        if (signals.isNotEmpty) ...[
          const Divider(height: 24),
          if (amountDelta != null)
            detailRow(
              isEs ? 'Diferencia de importe' : 'Amount difference',
              amountDelta is num
                  ? formatEuroAmount(amountDelta, 'EUR')
                  : amountDelta.toString(),
            ),
          if (dateDays != null)
            detailRow(
              isEs ? 'Diferencia de fecha' : 'Date difference',
              '${formatBankIncomeMatchNumber(dateDays)} '
              '${isEs ? 'días' : 'days'}',
            ),
          if (invoiceNumberMatch is bool)
            detailRow(
              isEs ? 'Número de factura detectado' : 'Invoice number detected',
              invoiceNumberMatch ? (isEs ? 'Sí' : 'Yes') : (isEs ? 'No' : 'No'),
            ),
          if (clientName.isNotEmpty)
            detailRow(
              isEs ? 'Cliente esperado' : 'Expected client',
              clientName,
            ),
        ],
      ],
    );
  }

  @override
  Future<void> showBankIncomeMatchDetails({
    required BuildContext sourceContext,
    required Map<String, dynamic> row,
    required bool isEs,
  }) async {
    final narrow = MediaQuery.sizeOf(sourceContext).width < 700;
    if (narrow) {
      await showModalBottomSheet<void>(
        context: sourceContext,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: bankIncomeMatchDetailsContent(
              context,
              row: row,
              isEs: isEs,
            ),
          ),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: sourceContext,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: bankIncomeMatchDetailsContent(
              context,
              row: row,
              isEs: isEs,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildBankIncomeMatchCell(
    BuildContext context, {
    required Map<String, dynamic> row,
    required bool isEs,
    bool compact = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final color = bankIncomeMatchColor(cs, row);
    final score = bankIncomeMatchScoreText(row, isEs);
    final reason = row['matchReason']?.toString().trim() ?? '';
    final confidence = bankIncomeMatchConfidence(row);
    final percent = formatBankIncomeMatchNumber(row['matchScorePercent']);
    final grouped = isGroupedBankIncomeCandidate(row);
    final invoiceCount = grouped ? bankIncomeMatchedInvoiceCount(row) : null;
    final combination =
        grouped ? bankIncomeCombinationLabel(row, isEs)?.toLowerCase() : null;
    final groupedSemantic = !grouped
        ? ''
        : combination != null
            ? ', $combination ${isEs ? 'de' : 'for'} $invoiceCount ${isEs ? 'facturas' : 'invoices'}'
            : ', $invoiceCount ${isEs ? 'facturas' : 'invoices'}';
    final semanticLabel = isEs
        ? 'Coincidencia ${percent.isEmpty ? score : '$percent por ciento'}, '
            'confianza ${confidence.isEmpty ? 'sin indicar' : confidence.toLowerCase()}$groupedSemantic.'
        : 'Match ${percent.isEmpty ? score : '$percent percent'}, '
            '${confidence.isEmpty ? 'confidence not specified' : '${confidence.toLowerCase()} confidence'}$groupedSemantic.';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: isEs ? 'Ver cómo se calcula' : 'See score details',
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showBankIncomeMatchDetails(
            sourceContext: context,
            row: row,
            isEs: isEs,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withValues(alpha: 0.30)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics_outlined, size: 13, color: color),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          score,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    maxLines: compact ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildGroupedInvoiceBadge(
    BuildContext context, {
    required Map<String, dynamic> row,
    required bool isEs,
    required bool expanded,
    required VoidCallback onPressed,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final label = bankIncomeInvoiceCountLabel(row, isEs);
    return Semantics(
      button: true,
      expanded: expanded,
      label: '$label. ${isEs ? 'Ver facturas incluidas' : 'View invoices'}',
      child: Tooltip(
        message: isEs ? 'Ver facturas incluidas' : 'View included invoices',
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 5, 4),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.primary.withValues(alpha: 0.24)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.library_books_outlined, size: 13, color: cs.primary),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: t.caption.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: cs.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildBankIncomeCombinationBadge(
    BuildContext context, {
    required Map<String, dynamic> row,
    required bool isEs,
    VoidCallback? onPressed,
  }) {
    final label = bankIncomeCombinationLabel(row, isEs);
    if (label == null) return const SizedBox.shrink();
    final t = AppTypography.of(context);
    final unique =
        row['combinationUnique'] == true && row['combinationMatchCount'] == 1;
    final color = unique ? const Color(0xFF087A55) : const Color(0xFFA65A00);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unique ? Icons.verified_outlined : Icons.alt_route_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: t.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (onPressed != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: color),
          ],
        ],
      ),
    );
    return Semantics(
      button: onPressed != null,
      label: label,
      child: onPressed == null
          ? badge
          : InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onPressed,
              child: badge,
            ),
    );
  }

}
