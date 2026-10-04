import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/theme/typography/typography_extension.dart';

import '../insights_json_utils.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsBankIncomeCombination on InsightsChatSheetStateBase {
  @override
  Future<Map<String, dynamic>?> showBankIncomeCombinationSelector({
    required BuildContext sourceContext,
    required Map<String, dynamic> candidate,
    required bool isEs,
    String? selectedCombinationId,
  }) async {
    final options = bankIncomeCombinationOptions(candidate);
    if (options.length < 2) return null;
    final recommendedCombinationId =
        candidate['recommendedCombinationId']?.toString().trim() ?? '';
    Map<String, dynamic>? selectedOption;
    for (final option in options) {
      if (bankIncomeCombinationId(option) == selectedCombinationId) {
        selectedOption = option;
        break;
      }
    }
    if (selectedOption == null && recommendedCombinationId.isNotEmpty) {
      for (final option in options) {
        if (bankIncomeCombinationId(option) == recommendedCombinationId) {
          selectedOption = option;
          break;
        }
      }
    }
    selectedOption ??= options.cast<Map<String, dynamic>?>().firstWhere(
          (option) => option?['recommended'] == true,
          orElse: () => options.first,
        );

    Widget content(
      BuildContext context,
      StateSetter setSelectorState, {
      required bool mobile,
    }) {
      final cs = Theme.of(context).colorScheme;
      final t = AppTypography.of(context);
      return Column(
        mainAxisSize: mobile ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEs ? 'Elegir combinación' : 'Choose combination',
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            isEs
                ? 'Revisa las facturas de cada alternativa antes de continuar.'
                : 'Review the invoices in each alternative before continuing.',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                final optionId = bankIncomeCombinationId(option);
                final selected = identical(option, selectedOption) ||
                    (optionId.isNotEmpty &&
                        optionId ==
                            bankIncomeCombinationId(
                              selectedOption ?? const <String, dynamic>{},
                            ));
                final invoices = option['invoices'] is List
                    ? (option['invoices'] as List)
                        .map(safeMap)
                        .whereType<Map<String, dynamic>>()
                        .toList(growable: false)
                    : const <Map<String, dynamic>>[];
                final score =
                    (option['scoreFormatted'] ?? option['matchScoreFormatted'])
                            ?.toString()
                            .trim() ??
                        (isEs ? 'Sin puntuación' : 'No score');
                final reason =
                    (option['reason'] ?? option['matchReason'])?.toString() ??
                        '';
                final total = option['totalFormatted']?.toString() ?? '';
                final delta = option['deltaFormatted']?.toString() ?? '';
                final span = option['invoiceDateSpanDays'];
                return Semantics(
                  button: true,
                  selected: selected,
                  label:
                      '${isEs ? 'Combinación' : 'Combination'} ${index + 1}: $score',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        setSelectorState(() => selectedOption = option),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primaryContainer.withValues(alpha: 0.34)
                            : cs.surfaceContainerHighest
                                .withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? cs.primary.withValues(alpha: 0.52)
                              : cs.outlineVariant.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: selected ? cs.primary : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 5,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      score,
                                      style: t.bodySmall.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if (option['recommended'] == true ||
                                        (recommendedCombinationId.isNotEmpty &&
                                            optionId ==
                                                recommendedCombinationId))
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.primary
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          isEs ? 'Recomendada' : 'Recommended',
                                          style: t.caption.copyWith(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (reason.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    reason,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.caption.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                for (final invoice in invoices)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      [
                                        bankIncomeCandidateValue(
                                          invoice,
                                          const ['invoiceNumber', 'number'],
                                        ),
                                        bankIncomeCandidateValue(
                                          invoice,
                                          const ['issueDate', 'date'],
                                        ),
                                        bankIncomeCandidateValue(
                                          invoice,
                                          const ['amountFormatted', 'amount'],
                                        ),
                                      ]
                                          .where((value) => value.isNotEmpty)
                                          .join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.caption.copyWith(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    if (total.isNotEmpty)
                                      Text(
                                          '${isEs ? 'Total' : 'Total'}: $total',
                                          style: t.caption),
                                    if (delta.isNotEmpty)
                                      Text(
                                          '${isEs ? 'Diferencia' : 'Difference'}: $delta',
                                          style: t.caption),
                                    if (span is num)
                                      Text(
                                        isEs
                                            ? 'Intervalo: ${span.toInt()} días'
                                            : 'Date span: ${span.toInt()} days',
                                        style: t.caption,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: selectedOption == null
                  ? null
                  : () => Navigator.of(context).pop(selectedOption),
              child: Text(isEs ? 'Usar combinación' : 'Use combination'),
            ),
          ),
        ],
      );
    }

    final mobile = MediaQuery.sizeOf(sourceContext).width < 700;
    if (mobile) {
      return showModalBottomSheet<Map<String, dynamic>>(
        context: sourceContext,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setSelectorState) => FractionallySizedBox(
            heightFactor: 0.82,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: content(
                  context,
                  setSelectorState,
                  mobile: true,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return showDialog<Map<String, dynamic>>(
      context: sourceContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setSelectorState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 640),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: content(
                context,
                setSelectorState,
                mobile: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> previewMatchedInvoice(
    Map<String, dynamic> invoice,
    bool isEs,
  ) async {
    final invoiceId = invoiceIdFromInsightsInvoiceRow(invoice);
    final invoiceNumber = bankIncomeCandidateValue(
      invoice,
      const ['invoiceNumber', 'number'],
    );
    if (invoiceId.isEmpty) {
      throw Exception(
        isEs
            ? 'Esta factura no incluye un identificador para la vista previa.'
            : 'This invoice does not include an ID for preview.',
      );
    }
    final response = await invoicesApi.previewPdf(invoiceId);
    final bytes = InvoiceEditorPdf.validatePdf(response);
    final safeNumber = invoiceNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
    await pdf_launcher.launchPdfPreview(
      bytes,
      fileName: safeNumber.isEmpty
          ? 'invoice-preview.pdf'
          : 'invoice-$safeNumber.pdf',
    );
  }

}
