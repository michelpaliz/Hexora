import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/services/insights/insights_api.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:intl/intl.dart';

import '../insights_chat_message.dart';
import '../insights_json_utils.dart';
import 'insights_chat_sheet_base.dart';
import 'linked_income_evidence.dart';

mixin InsightsLinkedIncomeReviewUi on InsightsChatSheetStateBase {
  /// Expanded review rows and the active filter, per message.
  final Set<String> _linkedIncomeExpanded = <String>{};
  final Map<String, String> _linkedIncomeFilters = <String, String>{};

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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.09),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          score.isEmpty ? 'Sin puntuación' : score,
          maxLines: 1,
          style: t.caption.copyWith(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
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
    // Review is the primary action; unlinking is destructive, so it lives in
    // the overflow menu and still goes through its confirmation dialog.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: isEs
              ? 'Revisar o cambiar las facturas vinculadas'
              : 'Review or change the linked invoices',
          child: FilledButton.tonalIcon(
            onPressed:
                unlinking ? null : () => reviewLinkedIncomeRow(message, row),
            icon: const Icon(Icons.manage_search_rounded, size: 16),
            label: Text(isEs ? 'Revisar' : 'Review'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 30),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: t.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 32,
          height: 32,
          child: unlinking
              ? const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : PopupMenuButton<String>(
                  tooltip: isEs ? 'Más acciones' : 'More actions',
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                  onSelected: (_) {
                    if (unlinkAction == null) return;
                    confirmUnlinkLinkedIncome(message, row, unlinkAction);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'unlink',
                      enabled: unlinkAction != null,
                      child: Tooltip(
                        message: unlinkAction == null
                            ? (isEs
                                ? 'El servidor no proporcionó una acción para desvincular'
                                : 'The server did not provide an unlink action')
                            : '',
                        child: Row(children: [
                          Icon(Icons.link_off_rounded,
                              size: 16, color: cs.error),
                          const SizedBox(width: 8),
                          Text(
                            isEs ? 'Desvincular…' : 'Unlink…',
                            style: TextStyle(color: cs.error),
                          ),
                        ]),
                      ),
                    ),
                  ],
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
    final locale = Localizations.localeOf(context).toString();
    final money = NumberFormat.currency(locale: locale, symbol: '€');
    final warn = isDark ? const Color(0xFFFFB45B) : const Color(0xFFA65A00);
    final okColor = isDark ? Colors.greenAccent : const Color(0xFF07875F);
    final messageKey = messageKeyFor(message);
    final filter = _linkedIncomeFilters[messageKey] ?? 'all';
    final threshold = message.table?['threshold'] ?? 60;

    final evidence = [
      for (final row in rows)
        LinkedIncomeEvidence.fromRow(row, linkedIncomeReviewInvoices(row)),
    ];
    final diffCount = evidence.where((e) => e.hasAmountDifference).length;
    final payerCount = evidence.where((e) => e.payerMissing).length;
    final visible = <int>[
      for (var i = 0; i < rows.length; i++)
        if (filter == 'all' ||
            (filter == 'amount' && evidence[i].hasAmountDifference) ||
            (filter == 'payer' && evidence[i].payerMissing))
          i,
    ];

    String rowKey(Map<String, dynamic> row, int index) =>
        '$messageKey::${rowEntryId(row) ?? 'row$index'}';

    String formatDate(Object? raw) {
      final d = DateTime.tryParse(raw?.toString().trim() ?? '');
      return d == null
          ? (raw?.toString() ?? '')
          : DateFormat.yMMMd(locale).format(d);
    }

    Widget sectionLabel(String label) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: t.caption.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        );

    Widget filterChip(String value, String label, int count) {
      final selected = filter == value;
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: ChoiceChip(
          label: Text('$label · $count'),
          selected: selected,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelStyle: t.caption.copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
          side: BorderSide(
            color: selected
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
          selectedColor: cs.primary.withValues(alpha: 0.10),
          backgroundColor: Colors.transparent,
          onSelected: (_) =>
              setState(() => _linkedIncomeFilters[messageKey] = value),
        ),
      );
    }

    final thresholdLabel = formatBankIncomeMatchNumber(threshold);
    final summary = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 6,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.fact_check_outlined, size: 16, color: warn),
            const SizedBox(width: 6),
            Text(
              isEs
                  ? 'Coincidencia inferior al $thresholdLabel% · confirma antes de dar por buena la vinculación'
                  : 'Match below $thresholdLabel% · confirm before accepting the link',
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ]),
        ),
        filterChip('all', isEs ? 'Todos' : 'All', rows.length),
        if (diffCount > 0 || filter == 'amount')
          filterChip('amount',
              isEs ? 'Diferencia de importe' : 'Amount difference', diffCount),
        if (payerCount > 0 || filter == 'payer')
          filterChip('payer',
              isEs ? 'Pagador no identificado' : 'Payer not found', payerCount),
      ],
    );

    Widget checksList(LinkedIncomeEvidence e, Map<String, dynamic> row) {
      final reasons = stringList(row['reviewReasons']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final check in e.checks(isEs: isEs, money: money.format))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    switch (check.state) {
                      EvidenceState.ok => Icons.check_circle_outline_rounded,
                      EvidenceState.warning => Icons.error_outline_rounded,
                      EvidenceState.unknown => Icons.help_outline_rounded,
                    },
                    size: 15,
                    color: switch (check.state) {
                      EvidenceState.ok => okColor,
                      EvidenceState.warning => warn,
                      EvidenceState.unknown => cs.onSurfaceVariant,
                    },
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      check.label,
                      style: t.caption.copyWith(
                        color: cs.onSurface,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              isEs ? 'Según el análisis automático:' : 'Automatic analysis:',
              style: t.caption.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            buildLinkedIncomeReviewReasonsCell(row, cs: cs, t: t),
          ],
        ],
      );
    }

    Widget details(
      Map<String, dynamic> row,
      LinkedIncomeEvidence e,
      bool stacked,
    ) {
      final original =
          (row['concept'] ?? row['description'])?.toString().trim() ?? '';
      final bank = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          sectionLabel(isEs ? 'Movimiento bancario' : 'Bank transaction'),
          SelectableText(
            original.isEmpty ? '-' : original,
            style: t.bodySmall.copyWith(color: cs.onSurface, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            [formatDate(row['date']), row['amountFormatted']?.toString() ?? '']
                .where((v) => v.trim().isNotEmpty)
                .join(' · '),
            style: t.caption.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      );
      final totalLabel = row['linkedInvoicesTotalFormatted']?.toString() ?? '';
      final invoices = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          sectionLabel(isEs ? 'Facturas vinculadas' : 'Linked invoices'),
          buildLinkedIncomeReviewInvoicesCell(row, cs: cs, t: t),
          if (totalLabel.isNotEmpty &&
              linkedIncomeReviewInvoices(row).length > 1) ...[
            const SizedBox(height: 4),
            Text(
              'Total: $totalLabel',
              style: t.caption.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      );
      final checks = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          sectionLabel(isEs ? 'Comprobaciones' : 'Checks'),
          checksList(e, row),
        ],
      );
      return Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(stacked ? 12 : 38, 0, 12, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.18 : 0.30,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bank,
                  const SizedBox(height: 12),
                  invoices,
                  const SizedBox(height: 12),
                  checks,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: bank),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: invoices),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: checks),
                ],
              ),
      );
    }

    Widget reviewRow(int index, bool stacked) {
      final row = rows[index];
      final e = evidence[index];
      final key = rowKey(row, index);
      final expanded = _linkedIncomeExpanded.contains(key);
      final invoices = linkedIncomeReviewInvoices(row);
      final original =
          (row['concept'] ?? row['description'])?.toString().trim() ?? '';
      final cleaned = LinkedIncomeEvidence.cleanConcept(original);
      final numbers = invoices
          .map((i) => (i['invoiceNumber'] ?? i['number'])?.toString() ?? '')
          .where((v) => v.trim().isNotEmpty)
          .join(' + ');
      final client = invoices.isEmpty
          ? ''
          : (invoices.first['clientName']?.toString().trim() ?? '');
      final meta = [
        formatDate(row['date']),
        numbers,
        if (client.isNotEmpty)
          invoices.length > 1 ? '$client +${invoices.length - 1}' : client,
      ].where((v) => v.trim().isNotEmpty).join(' · ');

      final diff = e.amountDifference;
      final invoiceTotalLabel =
          row['linkedInvoicesTotalFormatted']?.toString() ??
              money.format(e.invoiceTotal ?? 0);
      final amount = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            row['amountFormatted']?.toString() ?? '',
            maxLines: 1,
            style: t.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (e.hasAmountDifference && diff != null)
            Tooltip(
              message: isEs
                  ? 'Facturas: $invoiceTotalLabel'
                  : 'Invoices: $invoiceTotalLabel',
              child: Text(
                '${diff > 0 ? '+' : '−'}${money.format(diff.abs())} ${isEs ? 'vs facturas' : 'vs invoices'}',
                style: t.caption.copyWith(
                  color: warn,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      );

      final summaryText = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: original == cleaned ? '' : original,
            child: Text(
              cleaned.isEmpty ? '-' : cleaned,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.caption.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11.5,
            ),
          ),
        ],
      );

      final chevron = AnimatedRotation(
        turns: expanded ? 0.25 : 0,
        duration: const Duration(milliseconds: 150),
        child: Icon(Icons.chevron_right_rounded,
            size: 18, color: cs.onSurfaceVariant),
      );
      final score = buildLinkedIncomeReviewScoreCell(
        row,
        cs: cs,
        t: t,
        isDark: isDark,
      );
      final actions = buildLinkedIncomeReviewActionsCell(
        message,
        row,
        cs: cs,
        t: t,
        isEs: isEs,
      );

      final header = stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  chevron,
                  const SizedBox(width: 6),
                  Expanded(child: summaryText),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const SizedBox(width: 24),
                  amount,
                  const SizedBox(width: 10),
                  score,
                  const Spacer(),
                  actions,
                ]),
              ],
            )
          : Row(children: [
              chevron,
              const SizedBox(width: 8),
              Expanded(child: summaryText),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: Align(alignment: Alignment.centerRight, child: amount),
              ),
              const SizedBox(width: 14),
              SizedBox(width: 92, child: score),
              const SizedBox(width: 6),
              actions,
            ]);

      return Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: expanded,
              child: InkWell(
                onTap: () => setState(() {
                  if (!_linkedIncomeExpanded.remove(key)) {
                    _linkedIncomeExpanded.add(key);
                  }
                }),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: header,
                  ),
                ),
              ),
            ),
            if (expanded) details(row, e, stacked),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            summary,
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        isEs
                            ? 'Ningún ingreso coincide con este filtro.'
                            : 'No income matches this filter.',
                        textAlign: TextAlign.center,
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final index in visible) reviewRow(index, stacked),
                      ],
                    ),
            ),
          ],
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
                                .copyWith(fontWeight: FontWeight.w600),
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
    final cs = Theme.of(context).colorScheme;
    // A bulk destructive action shouldn't sit next to the title; it lives in
    // an overflow menu and still requires the confirmation dialog.
    if (busy) {
      return Tooltip(
        message: tooltip,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ]),
      );
    }
    return PopupMenuButton<String>(
      tooltip: isEs ? 'Más acciones' : 'More actions',
      icon: Icon(Icons.more_vert_rounded, size: 18, color: cs.onSurfaceVariant),
      onSelected: (_) => confirmBulkUnlinkLinkedIncome(message, rows),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'unlinkAll',
          enabled: rows.isNotEmpty,
          child: Row(children: [
            Icon(Icons.link_off_rounded, size: 16, color: cs.error),
            const SizedBox(width: 8),
            Text(
              isEs
                  ? 'Desvincular los ${rows.length} ingresos…'
                  : 'Unlink all ${rows.length} entries…',
              style: TextStyle(color: cs.error),
            ),
          ]),
        ),
      ],
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
