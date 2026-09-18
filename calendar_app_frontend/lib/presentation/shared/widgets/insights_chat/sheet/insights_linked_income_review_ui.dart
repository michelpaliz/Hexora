import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/services/insights/insights_api.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import '../insights_chat_message.dart';
import '../insights_json_utils.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsLinkedIncomeReviewUi on InsightsChatSheetStateBase {
  @override
  List<Map<String, dynamic>> linkedIncomeReviewInvoices(
    Map<String, dynamic> row,
  ) {
    final raw = row['linkedInvoices'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .map(safeMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  Map<String, dynamic>? linkedIncomeReviewUnlinkAction(
    Map<String, dynamic> row,
  ) {
    final direct = safeMap(row['unlinkAction']);
    if ((direct?['endpoint']?.toString().trim().isNotEmpty ?? false)) {
      return direct;
    }
    final actions = row['actions'];
    if (actions is List) {
      for (final raw in actions) {
        final action = safeMap(raw);
        if (action == null) continue;
        final endpoint = action['endpoint']?.toString().trim() ?? '';
        if (endpoint.isEmpty) continue;
        final descriptor = normalizedInsightText([
          action['type'],
          action['name'],
          action['label'],
          action['action'],
        ].whereType<Object>().join(' '));
        final body = safeMap(action['body']);
        final invoiceIds = body?['invoiceIds'];
        final clearsInvoices = invoiceIds is List && invoiceIds.isEmpty;
        if (clearsInvoices ||
            descriptor.contains('unlink') ||
            descriptor.contains('desvinc')) {
          return action;
        }
      }
    }
    final entryId = rowEntryId(row) ?? '';
    if (entryId.isEmpty) return null;
    return <String, dynamic>{
      'endpoint': '/api/statements/entries/$entryId/invoice',
      'method': 'POST',
      'body': <String, dynamic>{'invoiceIds': <String>[]},
    };
  }

  @override
  Color linkedIncomeReviewConfidenceColor(
    Map<String, dynamic> row,
    bool isDark,
  ) {
    final percent = row['matchScorePercent'];
    if (percent is num && percent >= 80) {
      return isDark ? Colors.greenAccent : const Color(0xFF07875F);
    }
    if (percent is num && percent >= 60) {
      return isDark ? const Color(0xFFFFB45B) : const Color(0xFFA65A00);
    }
    return isDark ? const Color(0xFFFF8A80) : const Color(0xFFB33A3A);
  }

  @override
  Widget buildLinkedIncomeReviewScoreCell(
    Map<String, dynamic> row, {
    required ColorScheme cs,
    required AppTypography t,
    required bool isDark,
  }) {
    final score = row['matchScoreFormatted']?.toString().trim() ?? '';
    final color = linkedIncomeReviewConfidenceColor(row, isDark);
    return Semantics(
      label: score.isEmpty ? 'Sin puntuación' : score,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.38)),
        ),
        child: Text(
          score.isEmpty ? 'Sin puntuación' : score,
          maxLines: 1,
          style: t.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildLinkedIncomeReviewInvoicesCell(
    Map<String, dynamic> row, {
    required ColorScheme cs,
    required AppTypography t,
  }) {
    final invoices = linkedIncomeReviewInvoices(row);
    if (invoices.isEmpty) {
      return Text(
        '-',
        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 330),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < invoices.length; index++) ...[
            if (index > 0)
              Divider(
                height: 10,
                thickness: 0.5,
                color: cs.outlineVariant.withValues(alpha: 0.45),
              ),
            Text(
              (invoices[index]['invoiceNumber'] ??
                      invoices[index]['number'] ??
                      'Factura')
                  .toString(),
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              [
                invoices[index]['clientName'],
                invoices[index]['issueDate'],
                invoices[index]['amountFormatted'],
              ]
                  .map((value) => value?.toString().trim() ?? '')
                  .where((value) => value.isNotEmpty)
                  .join(' · '),
              style: t.caption.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget buildLinkedIncomeReviewReasonsCell(
    Map<String, dynamic> row, {
    required ColorScheme cs,
    required AppTypography t,
  }) {
    final reasons = stringList(row['reviewReasons']);
    if (reasons.isEmpty) {
      return Text('-', style: t.bodySmall.copyWith(color: cs.onSurfaceVariant));
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final reason in reasons)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.circle,
                      size: 4,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      reason,
                      style: t.caption.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget buildLinkedIncomeReviewActionsCell(
    ChatMessage message,
    Map<String, dynamic> row, {
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
  }) {
    final entryId = rowEntryId(row) ?? '';
    final unlinkAction = linkedIncomeReviewUnlinkAction(row);
    final unlinking = bulkUnlinkingLinkedIncome ||
        (entryId.isNotEmpty &&
            unlinkingLinkedIncomeRows.contains(
              '${messageKeyFor(message)}::$entryId',
            ));
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        Tooltip(
          message:
              isEs ? 'Revisar facturas vinculadas' : 'Review linked invoices',
          child: OutlinedButton.icon(
            onPressed:
                unlinking ? null : () => reviewLinkedIncomeRow(message, row),
            icon: const Icon(Icons.manage_search_rounded, size: 14),
            label: Text(isEs ? 'Revisar' : 'Review'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              textStyle: t.caption.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        Tooltip(
          message: unlinkAction == null
              ? (isEs
                  ? 'El servidor no proporcionó una acción para desvincular'
                  : 'The server did not provide an unlink action')
              : (isEs ? 'Desvincular facturas' : 'Unlink invoices'),
          child: TextButton.icon(
            onPressed: unlinking || unlinkAction == null
                ? null
                : () => confirmUnlinkLinkedIncome(
                      message,
                      row,
                      unlinkAction,
                    ),
            icon: unlinking
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link_off_rounded, size: 14),
            label: Text(isEs ? 'Desvincular' : 'Unlink'),
            style: TextButton.styleFrom(
              foregroundColor: cs.error,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              textStyle: t.caption.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildLinkedIncomeReviewTableCell(
    ChatMessage message,
    Map<String, dynamic> row,
    Map<String, dynamic> column, {
    required ColorScheme cs,
    required AppTypography t,
    required bool isDark,
    required bool isEs,
    required TextStyle cellStyle,
  }) {
    final key = column['key']?.toString() ?? '';
    switch (key) {
      case 'linkedInvoices':
        return buildLinkedIncomeReviewInvoicesCell(row, cs: cs, t: t);
      case 'matchScoreFormatted':
        return buildLinkedIncomeReviewScoreCell(
          row,
          cs: cs,
          t: t,
          isDark: isDark,
        );
      case 'reviewReasons':
        return buildLinkedIncomeReviewReasonsCell(row, cs: cs, t: t);
      case '__linkedIncomeReviewActions':
        return buildLinkedIncomeReviewActionsCell(
          message,
          row,
          cs: cs,
          t: t,
          isEs: isEs,
        );
      default:
        final rightAligned = column['align']?.toString() == 'right';
        return Align(
          alignment:
              rightAligned ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: key == 'concept' ? 300 : 170,
            ),
            child: Text(
              row[key]?.toString() ?? '',
              maxLines: key == 'concept' ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              textAlign: rightAligned ? TextAlign.right : TextAlign.left,
              style: cellStyle,
            ),
          ),
        );
    }
  }

  @override
  Widget buildLinkedIncomeReviewResults(
    BuildContext context, {
    required ChatMessage message,
    required List<Map<String, dynamic>> rows,
    required ColorScheme cs,
    required AppTypography t,
    required bool isDark,
    required bool isEs,
    required bool loading,
  }) {
    final borderColor =
        cs.outlineVariant.withValues(alpha: isDark ? 0.30 : 0.55);
    final mutedSurface = isDark
        ? cs.surfaceContainerHighest.withValues(alpha: 0.16)
        : cs.surfaceContainerLow.withValues(alpha: 0.55);

    Widget detailLabel(String label) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            label.toUpperCase(),
            style: t.caption.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        );

    Widget desktopRow(Map<String, dynamic> row, int index) {
      return Container(
        decoration: BoxDecoration(
          color: index.isEven ? cs.surface : mutedSurface,
          border: Border(bottom: BorderSide(color: borderColor, width: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      row['date']?.toString() ?? '',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      row['concept']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 120,
                    child: Text(
                      row['amountFormatted']?.toString() ?? '',
                      textAlign: TextAlign.right,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 125,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: buildLinkedIncomeReviewScoreCell(
                        row,
                        cs: cs,
                        t: t,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 210,
                    child: buildLinkedIncomeReviewActionsCell(
                      message,
                      row,
                      cs: cs,
                      t: t,
                      isEs: isEs,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(
                  alpha: isDark ? 0.22 : 0.34,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        detailLabel(
                          isEs ? 'Facturas vinculadas' : 'Linked invoices',
                        ),
                        buildLinkedIncomeReviewInvoicesCell(
                          row,
                          cs: cs,
                          t: t,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        detailLabel(
                          isEs ? 'Total facturas' : 'Invoice total',
                        ),
                        Text(
                          row['linkedInvoicesTotalFormatted']?.toString() ?? '',
                          textAlign: TextAlign.right,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        detailLabel(isEs ? 'Motivo' : 'Reason'),
                        buildLinkedIncomeReviewReasonsCell(
                          row,
                          cs: cs,
                          t: t,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget mobileCard(Map<String, dynamic> row) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row['date']?.toString() ?? '',
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                buildLinkedIncomeReviewScoreCell(
                  row,
                  cs: cs,
                  t: t,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              row['concept']?.toString() ?? '',
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              row['amountFormatted']?.toString() ?? '',
              style: t.bodyMedium.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Divider(height: 20),
            detailLabel(isEs ? 'Facturas vinculadas' : 'Linked invoices'),
            buildLinkedIncomeReviewInvoicesCell(row, cs: cs, t: t),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEs ? 'Total facturas' : 'Invoice total',
                    style: t.caption.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                Text(
                  row['linkedInvoicesTotalFormatted']?.toString() ?? '',
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            detailLabel(isEs ? 'Motivo' : 'Reason'),
            buildLinkedIncomeReviewReasonsCell(row, cs: cs, t: t),
            const SizedBox(height: 12),
            buildLinkedIncomeReviewActionsCell(
              message,
              row,
              cs: cs,
              t: t,
              isEs: isEs,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final content = compact
            ? Column(
                children: [
                  for (var index = 0; index < rows.length; index++) ...[
                    if (index > 0) const SizedBox(height: 8),
                    mobileCard(rows[index]),
                  ],
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      color: isDark
                          ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
                          : const Color(0xFFEAF2FF),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 100, child: Text(isEs ? 'Fecha' : 'Date')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(isEs ? 'Concepto' : 'Description')),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 120,
                            child: Text(
                              isEs ? 'Ingreso' : 'Income',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 125,
                            child: Text(isEs ? 'Coincidencia' : 'Match'),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 210,
                            child: Text(isEs ? 'Acciones' : 'Actions'),
                          ),
                        ],
                      ),
                    ),
                    for (var index = 0; index < rows.length; index++)
                      desktopRow(rows[index], index),
                  ],
                ),
              );
        return Stack(
          children: [
            content,
            if (loading)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: cs.surface.withValues(alpha: isDark ? 0.34 : 0.56),
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEs
                                ? 'Actualizando revisión...'
                                : 'Refreshing review...',
                            style: t.bodySmall
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Future<void> reviewLinkedIncomeRow(
    ChatMessage message,
    Map<String, dynamic> row,
  ) async {
    final messageKey = messageKeyFor(message);
    await pickInvoiceLinkForRow(message, row);
    if (!mounted) return;
    final latest = findMessageByKey(runtime.messages, messageKey);
    if (latest != null) {
      await refreshLinkedIncomeReview(latest);
    }
  }

  @override
  Future<void> confirmUnlinkLinkedIncome(
    ChatMessage message,
    Map<String, dynamic> row,
    Map<String, dynamic> unlinkAction,
  ) async {
    if (bulkUnlinkingLinkedIncome) return;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final invoices = linkedIncomeReviewInvoices(row);
    final concept =
        (row['concept'] ?? row['description'])?.toString().trim() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Desvincular ingreso' : 'Unlink income'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEs
                    ? 'Se eliminará la relación con ${invoices.length} factura(s). Esta acción no elimina el ingreso ni las facturas.'
                    : 'The relationship with ${invoices.length} invoice(s) will be removed. This does not delete the income or invoices.',
              ),
              if (concept.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  concept,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.of(dialogContext).bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
              if (invoices.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final invoice in invoices)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      [
                        invoice['invoiceNumber'],
                        invoice['clientName'],
                        invoice['amountFormatted'],
                      ]
                          .map((value) => value?.toString().trim() ?? '')
                          .where((value) => value.isNotEmpty)
                          .join(' · '),
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(isEs ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.link_off_rounded, size: 16),
            label: Text(isEs ? 'Desvincular' : 'Unlink'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final entryId = rowEntryId(row) ?? '';
    if (entryId.isEmpty) return;
    final messageKey = messageKeyFor(message);
    final stateKey = '$messageKey::$entryId';
    setState(() => unlinkingLinkedIncomeRows.add(stateKey));
    try {
      await runtime.executeJsonAction(unlinkAction);
      if (!mounted) return;
      final latest = findMessageByKey(runtime.messages, messageKey);
      if (latest != null) {
        await refreshLinkedIncomeReview(latest);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEs
                ? 'Ingreso desvinculado correctamente.'
                : 'Income unlinked successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final text = error is InsightsApiException
          ? error.message
          : error.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text.isEmpty
                ? (isEs
                    ? 'No se pudo desvincular el ingreso.'
                    : 'Could not unlink income.')
                : text,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => unlinkingLinkedIncomeRows.remove(stateKey));
      }
    }
  }

  @override
  Widget buildBulkUnlinkLinkedIncomeButton(
    ChatMessage message, {
    required bool isEs,
    required bool compact,
  }) {
    final rows = tableRowsFromMessage(message)
        .where((row) => row['isSummaryRow'] != true)
        .where((row) => linkedIncomeReviewUnlinkAction(row) != null)
        .toList(growable: false);
    final busy = bulkUnlinkingLinkedIncome;
    final label = busy
        ? '$bulkUnlinkingLinkedIncomeProgress/$bulkUnlinkingLinkedIncomeTotal'
        : (isEs ? 'Desvincular todos' : 'Unlink all');
    final tooltip = busy
        ? (isEs ? 'Desvinculando ingresos' : 'Unlinking income')
        : (isEs
            ? 'Desvincular los ${rows.length} ingresos pendientes'
            : 'Unlink all ${rows.length} pending income entries');
    if (compact) {
      return Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: busy || rows.isEmpty
              ? null
              : () => confirmBulkUnlinkLinkedIncome(message, rows),
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.link_off_rounded, size: 18),
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            backgroundColor:
                Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
          ),
        ),
      );
    }
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        onPressed: busy || rows.isEmpty
            ? null
            : () => confirmBulkUnlinkLinkedIncome(message, rows),
        icon: busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.link_off_rounded, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.38),
          ),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        ),
      ),
    );
  }

  @override
  Future<void> confirmBulkUnlinkLinkedIncome(
    ChatMessage message,
    List<Map<String, dynamic>> rows,
  ) async {
    if (bulkUnlinkingLinkedIncome || rows.isEmpty) return;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final invoiceLinkCount = rows.fold<int>(
      0,
      (total, row) => total + linkedIncomeReviewInvoices(row).length,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final t = AppTypography.of(dialogContext);
        return AlertDialog(
          icon: Icon(Icons.link_off_rounded, color: cs.error),
          title: Text(isEs ? 'Desvincular todos' : 'Unlink all'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEs
                      ? 'Se eliminarán los vínculos de ${rows.length} ingresos pendientes.'
                      : 'The links for ${rows.length} pending income entries will be removed.',
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isEs
                        ? '$invoiceLinkCount relaciones con facturas dejarán de estar vinculadas. No se eliminarán ingresos ni facturas.'
                        : '$invoiceLinkCount invoice relationships will be unlinked. No income entries or invoices will be deleted.',
                    style: t.bodySmall.copyWith(
                      color: cs.onErrorContainer,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isEs
                      ? 'Los resultados se actualizarán al finalizar. Esta acción no se ejecutará sin tu confirmación.'
                      : 'Results will refresh when finished. This action will not run without your confirmation.',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(isEs ? 'Cancelar' : 'Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.link_off_rounded, size: 16),
              label: Text(
                isEs
                    ? 'Desvincular ${rows.length} ingresos'
                    : 'Unlink ${rows.length} entries',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final messageKey = messageKeyFor(message);
    final failures = <String>[];
    setState(() {
      bulkUnlinkingLinkedIncome = true;
      bulkUnlinkingLinkedIncomeProgress = 0;
      bulkUnlinkingLinkedIncomeTotal = rows.length;
    });
    try {
      for (final row in rows) {
        final action = linkedIncomeReviewUnlinkAction(row);
        if (action == null) {
          failures.add(rowEntryId(row) ?? '?');
        } else {
          try {
            await runtime.executeJsonAction(action);
          } catch (_) {
            failures.add(rowEntryId(row) ?? '?');
          }
        }
        if (mounted) {
          setState(() => bulkUnlinkingLinkedIncomeProgress += 1);
        }
      }

      if (!mounted) return;
      final latest = findMessageByKey(runtime.messages, messageKey);
      if (latest != null) {
        await refreshLinkedIncomeReview(latest);
      }
      if (!mounted) return;
      final succeeded = rows.length - failures.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failures.isEmpty
                ? (isEs
                    ? 'Se desvincularon $succeeded ingresos correctamente.'
                    : '$succeeded income entries were unlinked successfully.')
                : (isEs
                    ? 'Se desvincularon $succeeded de ${rows.length} ingresos. ${failures.length} requieren reintento.'
                    : 'Unlinked $succeeded of ${rows.length} entries. ${failures.length} require retry.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          bulkUnlinkingLinkedIncome = false;
          bulkUnlinkingLinkedIncomeProgress = 0;
          bulkUnlinkingLinkedIncomeTotal = 0;
        });
      }
    }
  }

}
