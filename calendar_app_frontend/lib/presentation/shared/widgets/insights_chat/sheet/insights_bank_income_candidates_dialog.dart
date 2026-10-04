import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import 'insights_chat_sheet_base.dart';

mixin InsightsBankIncomeCandidatesDialog on InsightsChatSheetStateBase {
  @override
  Future<Map<String, dynamic>?> showBankIncomeCandidatesDialog({
    required Future<Map<String, dynamic>> responseFuture,
    required Map<String, dynamic> invoiceRow,
    required Future<void> Function(Map<String, dynamic> candidate)
        onLinkCandidate,
    required bool isEs,
  }) async {
    int? selectedCandidateIndex;
    final expandedCandidateIndexes = <int>{};
    final selectedCombinationIds = <int, String>{};
    var linkingCandidate = false;
    String? linkError;
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (routeContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final cs = Theme.of(dialogContext).colorScheme;
            final t = AppTypography.of(dialogContext);
            final screenSize = MediaQuery.sizeOf(dialogContext);
            final narrow = screenSize.width < 700;
            return AlertDialog(
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: narrow ? 12 : 28,
                vertical: narrow ? 16 : 28,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.45)),
              ),
              titlePadding: const EdgeInsets.fromLTRB(22, 18, 14, 0),
              contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.24),
                          cs.secondaryContainer.withValues(alpha: 0.42),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEs ? 'Ingresos candidatos' : 'Income candidates',
                      style: t.titleLarge.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: isEs ? 'Cerrar' : 'Close',
                    child: IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 960,
                height: (screenSize.height * (narrow ? 0.68 : 0.52))
                    .clamp(340.0, 480.0),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: responseFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(strokeWidth: 2.5),
                            const SizedBox(height: 12),
                            Text(
                              isEs
                                  ? 'Buscando ingresos bancarios...'
                                  : 'Searching bank income...',
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      final msg = snapshot.error
                          .toString()
                          .replaceFirst('Exception: ', '')
                          .trim();
                      return Center(
                        child: Text(
                          msg.isEmpty
                              ? (isEs
                                  ? 'No se pudo buscar ingresos.'
                                  : 'Could not search income.')
                              : msg,
                          textAlign: TextAlign.center,
                          style: t.bodySmall.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }

                    final response = snapshot.data;
                    final rows = bankIncomeCandidateRowsFromResponse(response);
                    final columns = bankIncomeCandidateColumnsFromResponse(
                      response,
                      rows,
                    );
                    final scoring = bankIncomeScoringFromResponse(response);
                    final groupMatching =
                        bankIncomeGroupMatchingFromResponse(response);
                    final hasGroupedMatches =
                        rows.any(isGroupedBankIncomeCandidate);
                    final hasCombinationData = rows.any(
                      (row) => bankIncomeCombinationLabel(row, isEs) != null,
                    );
                    final hasScores = rows.any(bankIncomeCandidateHasScore) ||
                        hasGroupedMatches;
                    debugPrint(
                      'bank income search response rows=${rows.length} columns=${columns.length}',
                    );
                    if (rows.isEmpty) {
                      debugPrint(
                        'bank income search response ${jsonEncode(response)}',
                      );
                      return Center(
                        child: Text(
                          isEs
                              ? 'No hay ingresos candidatos para esta factura.'
                              : 'No income candidates found for this invoice.',
                          textAlign: TextAlign.center,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }

                    final bestCandidateIndex =
                        highestBankIncomeMatchIndex(rows);
                    selectedCandidateIndex ??= bestCandidateIndex;

                    Map<String, dynamic> candidateAt(int index) {
                      final candidate = rows[index];
                      final selectedId = selectedCombinationIds[index];
                      if (selectedId == null || selectedId.isEmpty) {
                        return candidate;
                      }
                      Map<String, dynamic>? selectedOption;
                      for (final option
                          in bankIncomeCombinationOptions(candidate)) {
                        if (bankIncomeCombinationId(option) == selectedId) {
                          selectedOption = option;
                          break;
                        }
                      }
                      return bankIncomeCandidateForCombination(
                        candidate,
                        selectedOption,
                      );
                    }

                    Future<void> chooseCombination(int index) async {
                      final candidate = rows[index];
                      final option = await showBankIncomeCombinationSelector(
                        sourceContext: dialogContext,
                        candidate: candidate,
                        isEs: isEs,
                        selectedCombinationId: selectedCombinationIds[index],
                      );
                      if (option == null || !dialogContext.mounted) return;
                      final combinationId = bankIncomeCombinationId(option);
                      if (combinationId.isEmpty) return;
                      setDialogState(() {
                        selectedCombinationIds[index] = combinationId;
                      });
                    }

                    final columnWidths = [
                      for (final column in columns)
                        bankIncomeCandidateColumnWidth(column),
                    ];
                    final matchColumnWidth = hasCombinationData
                        ? 420.0
                        : hasGroupedMatches
                            ? 340.0
                            : 250.0;
                    const actionColumnWidth = 64.0;
                    const tableHorizontalPadding = 52.0;
                    final requiredTableWidth = columnWidths.fold<double>(
                          0,
                          (sum, width) => sum + width,
                        ) +
                        (hasScores ? matchColumnWidth : 0) +
                        actionColumnWidth +
                        tableHorizontalPadding;
                    final tableWidth =
                        requiredTableWidth < 720 ? 720.0 : requiredTableWidth;

                    Widget summaryHeader() {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEs
                                      ? '${rows.length} ingreso${rows.length == 1 ? '' : 's'} encontrado${rows.length == 1 ? '' : 's'}'
                                      : '${rows.length} income candidate${rows.length == 1 ? '' : 's'} found',
                                  style: t.caption.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (hasScores) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    isEs
                                        ? 'Ordenados según importe, cliente, número de factura y proximidad de fecha.'
                                        : 'Ranked by amount, client, invoice number, and date proximity.',
                                    style: t.caption.copyWith(
                                      color: cs.onSurfaceVariant,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (scoring != null || groupMatching != null) ...[
                            const SizedBox(width: 8),
                            Semantics(
                              button: true,
                              label: isEs
                                  ? 'Información sobre la puntuación'
                                  : 'Scoring information',
                              child: Tooltip(
                                message: isEs
                                    ? 'Ver pesos de coincidencia'
                                    : 'View match weights',
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => showBankIncomeScoringInfo(
                                    sourceContext: dialogContext,
                                    scoring:
                                        scoring ?? const <String, dynamic>{},
                                    groupMatching: groupMatching,
                                    isEs: isEs,
                                  ),
                                  icon: const Icon(Icons.info_outline_rounded),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    }

                    Widget selectionFooter() {
                      final selectedIndex = selectedCandidateIndex;
                      final selectedRow = selectedIndex != null &&
                              selectedIndex >= 0 &&
                              selectedIndex < rows.length
                          ? candidateAt(selectedIndex)
                          : null;
                      final action = selectedRow == null
                          ? null
                          : linkInvoiceToEntryAction(selectedRow);
                      final score = selectedRow == null ||
                              !bankIncomeCandidateHasScore(selectedRow)
                          ? ''
                          : bankIncomeMatchScoreText(selectedRow, isEs);
                      final selectedLabel = Text(
                        score.isEmpty
                            ? (isEs
                                ? 'Selecciona un ingreso para continuar.'
                                : 'Select an income to continue.')
                            : '${isEs ? 'Seleccionado' : 'Selected'}: $score',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.caption.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                      final linkButton = FilledButton.icon(
                        onPressed: action == null || linkingCandidate
                            ? null
                            : () async {
                                setDialogState(() {
                                  linkingCandidate = true;
                                  linkError = null;
                                });
                                try {
                                  final linked =
                                      await confirmBankIncomeCandidateLink(
                                    sourceContext: dialogContext,
                                    row: selectedRow!,
                                    isEs: isEs,
                                    onConfirm: () =>
                                        onLinkCandidate(selectedRow),
                                  );
                                  if (linked && dialogContext.mounted) {
                                    Navigator.of(dialogContext)
                                        .pop(selectedRow);
                                    return;
                                  }
                                } catch (error) {
                                  linkError = error
                                      .toString()
                                      .replaceFirst('Exception: ', '')
                                      .trim();
                                }
                                if (dialogContext.mounted) {
                                  setDialogState(() {
                                    linkingCandidate = false;
                                  });
                                }
                              },
                        icon: linkingCandidate
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.link_rounded, size: 16),
                        label: Text(
                          narrow
                              ? (isEs ? 'Vincular' : 'Link')
                              : (isEs
                                  ? 'Vincular seleccionado'
                                  : 'Link selected'),
                        ),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (linkError != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  linkError!,
                                  style: t.caption.copyWith(
                                    color: cs.onErrorContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (narrow) ...[
                              selectedLabel,
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: linkButton,
                              ),
                            ] else
                              Row(
                                children: [
                                  Expanded(child: selectedLabel),
                                  const SizedBox(width: 12),
                                  linkButton,
                                ],
                              ),
                          ],
                        ),
                      );
                    }

                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildTargetInvoiceSummary(
                            context,
                            invoiceRow: invoiceRow,
                            isEs: isEs,
                          ),
                          const SizedBox(height: 10),
                          summaryHeader(),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.separated(
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final baseCandidate = rows[index];
                                final row = candidateAt(index);
                                final combinationOptions =
                                    bankIncomeCombinationOptions(
                                  baseCandidate,
                                );
                                final action = linkInvoiceToEntryAction(row);
                                final canLink = action != null;
                                final isSelected =
                                    selectedCandidateIndex == index;
                                final isRecommended =
                                    index == bestCandidateIndex;
                                final grouped =
                                    isGroupedBankIncomeCandidate(row);
                                final expanded =
                                    expandedCandidateIndexes.contains(index);
                                final date = bankIncomeCandidateValue(
                                  row,
                                  const ['date', 'fecha'],
                                );
                                final description = bankIncomeCandidateValue(
                                  row,
                                  const ['description', 'concept', 'concepto'],
                                );
                                final amount = bankIncomeCandidateValue(
                                  row,
                                  const [
                                    'amountFormatted',
                                    'importeFormatted',
                                    'amount',
                                    'importe',
                                  ],
                                );
                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: canLink
                                      ? () => setDialogState(
                                            () =>
                                                selectedCandidateIndex = index,
                                          )
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? cs.primaryContainer
                                              .withValues(alpha: 0.34)
                                          : cs.surfaceContainerHighest
                                              .withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? cs.primary.withValues(alpha: 0.55)
                                            : cs.outlineVariant
                                                .withValues(alpha: 0.24),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                description,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: t.bodySmall.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              amount,
                                              style: t.bodySmall.copyWith(
                                                color: cs.primary,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (date.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            date,
                                            style: t.caption.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                        if (bankIncomeCandidateHasScore(
                                            row)) ...[
                                          const SizedBox(height: 10),
                                          buildBankIncomeMatchCell(
                                            context,
                                            row: row,
                                            isEs: isEs,
                                            compact: true,
                                          ),
                                        ],
                                        if (grouped) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              buildGroupedInvoiceBadge(
                                                context,
                                                row: row,
                                                isEs: isEs,
                                                expanded: expanded,
                                                onPressed: () =>
                                                    setDialogState(() {
                                                  if (expanded) {
                                                    expandedCandidateIndexes
                                                        .remove(index);
                                                  } else {
                                                    expandedCandidateIndexes
                                                        .add(index);
                                                  }
                                                }),
                                              ),
                                              if (bankIncomeCombinationLabel(
                                                    row,
                                                    isEs,
                                                  ) !=
                                                  null)
                                                buildBankIncomeCombinationBadge(
                                                  context,
                                                  row: row,
                                                  isEs: isEs,
                                                  onPressed: combinationOptions
                                                              .length >
                                                          1
                                                      ? () => chooseCombination(
                                                            index,
                                                          )
                                                      : null,
                                                ),
                                            ],
                                          ),
                                          if (expanded)
                                            buildGroupedBankIncomeDetails(
                                              context,
                                              row: row,
                                              isEs: isEs,
                                            ),
                                        ],
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isRecommended) ...[
                                                Icon(
                                                  Icons.auto_awesome_rounded,
                                                  size: 13,
                                                  color: cs.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isEs
                                                      ? 'Mejor coincidencia'
                                                      : 'Best match',
                                                  style: t.caption.copyWith(
                                                    color: cs.primary,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                              ],
                                              Icon(
                                                isSelected
                                                    ? Icons.check_circle_rounded
                                                    : Icons.circle_outlined,
                                                size: 18,
                                                color: isSelected
                                                    ? cs.primary
                                                    : cs.onSurfaceVariant,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          selectionFooter(),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTargetInvoiceSummary(
                          context,
                          invoiceRow: invoiceRow,
                          isEs: isEs,
                        ),
                        const SizedBox(height: 10),
                        summaryHeader(),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest
                                            .withValues(alpha: 0.42),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: cs.outlineVariant
                                              .withValues(alpha: 0.28),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          for (int i = 0;
                                              i < columns.length;
                                              i++)
                                            SizedBox(
                                              width: columnWidths[i],
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 18,
                                                ),
                                                child: Text(
                                                  columns[i]['label']
                                                          ?.toString() ??
                                                      columns[i]['key']
                                                          ?.toString() ??
                                                      '',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign:
                                                      isBankIncomeCandidateAmountColumn(
                                                    columns[i],
                                                  )
                                                          ? TextAlign.right
                                                          : TextAlign.left,
                                                  style: t.caption.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (hasScores)
                                            SizedBox(
                                              width: matchColumnWidth,
                                              child: Text(
                                                isEs ? 'Coincidencia' : 'Match',
                                                style: t.caption.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          SizedBox(
                                            width: actionColumnWidth,
                                            child: Center(
                                              child: Text(
                                                isEs ? 'Elegir' : 'Select',
                                                style: t.caption.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: rows.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 6),
                                        itemBuilder: (_, index) {
                                          final baseCandidate = rows[index];
                                          final row = candidateAt(index);
                                          final combinationOptions =
                                              bankIncomeCombinationOptions(
                                            baseCandidate,
                                          );
                                          final action =
                                              linkInvoiceToEntryAction(row);
                                          final canLink = action != null;
                                          final isSelected =
                                              selectedCandidateIndex == index;
                                          final isRecommended =
                                              index == bestCandidateIndex;
                                          final grouped =
                                              isGroupedBankIncomeCandidate(
                                            row,
                                          );
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? cs.primaryContainer
                                                      .withValues(alpha: 0.30)
                                                  : cs.surfaceContainerHighest
                                                      .withValues(alpha: 0.22),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isSelected
                                                    ? cs.primary
                                                        .withValues(alpha: 0.52)
                                                    : cs.outlineVariant
                                                        .withValues(
                                                            alpha: 0.20),
                                                width: isSelected ? 1.5 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                for (int i = 0;
                                                    i < columns.length;
                                                    i++)
                                                  SizedBox(
                                                    width: columnWidths[i],
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        right: 18,
                                                      ),
                                                      child: Text(
                                                        row[columns[i]['key']
                                                                        ?.toString() ??
                                                                    '']
                                                                ?.toString() ??
                                                            '',
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            isBankIncomeCandidateAmountColumn(
                                                          columns[i],
                                                        )
                                                                ? TextAlign
                                                                    .right
                                                                : TextAlign
                                                                    .left,
                                                        style: t.bodySmall
                                                            .copyWith(
                                                          color:
                                                              isBankIncomeCandidateAmountColumn(
                                                            columns[i],
                                                          )
                                                                  ? cs.primary
                                                                  : cs.onSurface,
                                                          fontWeight:
                                                              isBankIncomeCandidateAmountColumn(
                                                            columns[i],
                                                          )
                                                                  ? FontWeight
                                                                      .w900
                                                                  : FontWeight
                                                                      .w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                if (hasScores)
                                                  SizedBox(
                                                    width: matchColumnWidth,
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Expanded(
                                                          child: bankIncomeCandidateHasScore(
                                                            row,
                                                          )
                                                              ? buildBankIncomeMatchCell(
                                                                  context,
                                                                  row: row,
                                                                  isEs: isEs,
                                                                )
                                                              : Text(
                                                                  isEs
                                                                      ? 'Sin puntuación'
                                                                      : 'No score',
                                                                  style: t
                                                                      .caption
                                                                      .copyWith(
                                                                    color: cs
                                                                        .onSurfaceVariant,
                                                                  ),
                                                                ),
                                                        ),
                                                        if (grouped) ...[
                                                          const SizedBox(
                                                              width: 8),
                                                          buildGroupedInvoiceBadge(
                                                            context,
                                                            row: row,
                                                            isEs: isEs,
                                                            expanded: false,
                                                            onPressed: () =>
                                                                showGroupedBankIncomeDetails(
                                                              sourceContext:
                                                                  dialogContext,
                                                              row: row,
                                                              isEs: isEs,
                                                            ),
                                                          ),
                                                          if (bankIncomeCombinationLabel(
                                                                row,
                                                                isEs,
                                                              ) !=
                                                              null) ...[
                                                            const SizedBox(
                                                                width: 8),
                                                            buildBankIncomeCombinationBadge(
                                                              context,
                                                              row: row,
                                                              isEs: isEs,
                                                              onPressed: combinationOptions
                                                                          .length >
                                                                      1
                                                                  ? () =>
                                                                      chooseCombination(
                                                                        index,
                                                                      )
                                                                  : null,
                                                            ),
                                                          ],
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                SizedBox(
                                                  width: actionColumnWidth,
                                                  child: Center(
                                                    child: Semantics(
                                                      button: true,
                                                      label: isEs
                                                          ? '${isSelected ? 'Ingreso seleccionado' : 'Seleccionar ingreso'}${isRecommended ? ', mejor coincidencia' : ''}'
                                                          : '${isSelected ? 'Income selected' : 'Select income'}${isRecommended ? ', best match' : ''}',
                                                      child: Tooltip(
                                                        message: isRecommended
                                                            ? (isEs
                                                                ? 'Mejor coincidencia'
                                                                : 'Best match')
                                                            : (isEs
                                                                ? 'Seleccionar ingreso'
                                                                : 'Select income'),
                                                        child: IconButton(
                                                          visualDensity:
                                                              VisualDensity
                                                                  .compact,
                                                          onPressed: canLink
                                                              ? () =>
                                                                  setDialogState(
                                                                    () => selectedCandidateIndex =
                                                                        index,
                                                                  )
                                                              : null,
                                                          icon: Icon(
                                                            isSelected
                                                                ? Icons
                                                                    .check_circle_rounded
                                                                : Icons
                                                                    .radio_button_unchecked_rounded,
                                                            size: 20,
                                                            color: isSelected
                                                                ? cs.primary
                                                                : cs.onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        selectionFooter(),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

}
