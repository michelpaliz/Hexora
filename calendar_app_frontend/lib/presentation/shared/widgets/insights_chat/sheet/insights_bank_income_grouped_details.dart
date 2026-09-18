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

mixin InsightsBankIncomeGroupedDetails on InsightsChatSheetStateBase {
  @override
  Widget buildGroupedBankIncomeDetails(
    BuildContext context, {
    required Map<String, dynamic> row,
    required bool isEs,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final invoices = bankIncomeMatchedInvoices(row);
    final invoiceTotal = bankIncomeCandidateValue(
      row,
      const ['matchedInvoicesTotalFormatted', 'matchedInvoicesTotal'],
    );
    final bankAmount = bankIncomeCandidateValue(
      row,
      const ['amountFormatted', 'amount', 'importe'],
    );
    final delta = bankIncomeCandidateValue(
      row,
      const ['deltaFormatted', 'delta'],
    );
    final combinationCount = row['combinationMatchCount'] is num
        ? (row['combinationMatchCount'] as num).toInt()
        : null;
    final combinationValue =
        row['combinationUnique'] == true && combinationCount == 1
            ? (isEs ? 'Única' : 'Unique')
            : combinationCount != null && combinationCount > 1
                ? (isEs
                    ? '$combinationCount posibles'
                    : '$combinationCount possible')
                : null;
    final invoiceDateSpanDays = row['invoiceDateSpanDays'] is num
        ? (row['invoiceDateSpanDays'] as num).toInt()
        : null;

    Widget summaryValue(String label, String value) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: t.caption.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(
            value,
            style: t.caption.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      );
    }

    Widget invoiceLine(Map<String, dynamic> invoice) {
      final number = bankIncomeCandidateValue(
        invoice,
        const ['invoiceNumber', 'number'],
      );
      final date = bankIncomeCandidateValue(
        invoice,
        const ['issueDate', 'date'],
      );
      final amount = bankIncomeCandidateValue(
        invoice,
        const ['amountFormatted', 'amount'],
      );
      final canPreview = invoiceIdFromInsightsInvoiceRow(invoice).isNotEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.56),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 15,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number.isEmpty
                        ? (isEs ? 'Factura' : 'Invoice')
                        : '${isEs ? 'Factura' : 'Invoice'} $number',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (date.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 12, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: t.caption.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      if (amount.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payments_outlined,
                                size: 13, color: cs.primary),
                            const SizedBox(width: 4),
                            Text(
                              amount,
                              style: t.caption.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InsightsAsyncIconButton(
              tooltip: isEs ? 'Vista previa PDF' : 'PDF preview',
              semanticLabel: isEs
                  ? 'Ver vista previa de la factura $number'
                  : 'Preview invoice $number',
              errorFallback: isEs
                  ? 'No se pudo abrir la vista previa.'
                  : 'Could not open the preview.',
              onPressed: canPreview
                  ? () => previewMatchedInvoice(invoice, isEs)
                  : null,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEs ? 'Facturas incluidas' : 'Included invoices',
            style: t.caption.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          for (final invoice in invoices) invoiceLine(invoice),
          const Divider(height: 18),
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              summaryValue(
                isEs ? 'Total facturas' : 'Invoice total',
                invoiceTotal,
              ),
              summaryValue(
                isEs ? 'Ingreso bancario' : 'Bank income',
                bankAmount,
              ),
              summaryValue(isEs ? 'Diferencia' : 'Difference', delta),
              if (combinationValue != null)
                summaryValue(
                  isEs ? 'Combinación' : 'Combination',
                  combinationValue,
                ),
              if (invoiceDateSpanDays != null)
                summaryValue(
                  isEs ? 'Intervalo entre fechas' : 'Invoice date span',
                  isEs
                      ? '$invoiceDateSpanDays días'
                      : '$invoiceDateSpanDays days',
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Future<void> showGroupedBankIncomeDetails({
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
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: buildGroupedBankIncomeDetails(
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
      builder: (context) => AlertDialog(
        title: Text(isEs ? 'Facturas incluidas' : 'Included invoices'),
        content: SizedBox(
          width: 520,
          child: buildGroupedBankIncomeDetails(
            context,
            row: row,
            isEs: isEs,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isEs ? 'Cerrar' : 'Close'),
          ),
        ],
      ),
    );
  }

}
