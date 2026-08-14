import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../statements_controller.dart';
import '../../statements_formatters.dart';
import '../../statements_shared.dart';
import '../../shared/statement_entry_notes_dialog.dart';
import 'statements_all_data_table_layout.dart';
import 'statements_all_data_table_theme.dart';

class StatementsAllDataTableRow extends StatelessWidget {
  const StatementsAllDataTableRow({
    super.key,
    required this.entry,
    required this.index,
    required this.isCompact,
    required this.isTablet,
    required this.controller,
    required this.selectedIds,
    required this.onToggleRow,
    required this.onShowDetails,
    required this.onSuggest,
    required this.onLink,
    required this.onLinkInvoice,
    required this.onMarkNoProcede,
    required this.noProcedeReason,
    required this.tableTheme,
  });

  final Map<String, dynamic> entry;
  final int index;
  final bool isCompact;
  final bool isTablet;
  final StatementsController controller;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleRow;
  final ValueChanged<Map<String, dynamic>> onShowDetails;
  final ValueChanged<Map<String, dynamic>> onSuggest;
  final ValueChanged<Map<String, dynamic>> onLink;
  final ValueChanged<Map<String, dynamic>> onLinkInvoice;
  final ValueChanged<Map<String, dynamic>> onMarkNoProcede;
  final String? noProcedeReason;
  final StatementsTableTheme tableTheme;
  static final InvoicesApi _invoicesApi = InvoicesApi();
  static final ExpensesApi _expensesApi = ExpensesApi();

  Widget _moneyText(
    BuildContext context,
    String amount, {
    required bool emphasize,
    required Color amountColor,
    bool asPill = false,
    TextStyle? textStyle,
  }) {
    final typography = AppTypography.of(context);
    final formatted = StatementsFormatters.formatCurrency(context, amount);
    final text = Text(
      formatted,
      textAlign: TextAlign.right,
      style: (textStyle ??
              (emphasize ? typography.bodySmall : typography.bodySmall))
          .copyWith(
        fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
        fontSize: emphasize ? 13 : 12.5,
        color: amountColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    if (!asPill) return text;
    return Container(
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: amountColor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: amountColor.withValues(alpha: 0.3)),
      ),
      child: text,
    );
  }

  Widget _actionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? activeColor,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        minimumSize: const Size(28, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: activeColor,
        disabledForegroundColor: activeColor?.withValues(alpha: 0.35),
        backgroundColor: activeColor?.withValues(alpha: 0.09),
        disabledBackgroundColor: activeColor?.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _shortBatchId(String batchId) {
    final trimmed = batchId.trim();
    if (trimmed.isEmpty) return '-';
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    final source = digitsOnly.isNotEmpty ? digitsOnly : trimmed;
    if (source.length <= 3) return source;
    return source.substring(source.length - 3);
  }

  String _displayDescription(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || RegExp(r'\d').hasMatch(trimmed)) return trimmed;
    if (trimmed != trimmed.toUpperCase()) return trimmed;
    final lower = trimmed.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    final isWide = MediaQuery.of(context).size.width > 1400;
    final balanceMaxWidth =
        isWide ? 200.0 : StatementsAllDataTableLayout.balanceMaxWidth;
    final isDesktop = !isCompact && !isTablet;
    final actionsWidth = isDesktop
        ? StatementsAllDataTableLayout.actionsWidth
        : StatementsAllDataTableLayout.compactActionsWidth;
    final entryId = (entry['_id'] ?? entry['id'])?.toString() ?? '';
    final batchId = entry['_batchId']?.toString() ?? '';
    final shortBatchId = _shortBatchId(batchId);
    final date = StatementsShared.entryText(entry, ['date']);
    final valueDate = StatementsShared.entryText(entry, ['valueDate']);
    final desc = _displayDescription(
      StatementsShared.entryText(entry, ['description']),
    );
    String rawIndex(Map<String, dynamic> entry, int index) {
      final raw = entry['raw'];
      if (raw is List && raw.length > index) {
        final value = raw[index];
        if (value != null) return value.toString();
      }
      return '';
    }

    final rawAmount = rawIndex(entry, 4);
    final rawBalance = rawIndex(entry, 5);
    final amount = rawAmount.isNotEmpty
        ? rawAmount
        : StatementsShared.entryText(entry, ['amount']);
    final balance = rawBalance.isNotEmpty
        ? rawBalance
        : StatementsShared.entryText(entry, ['balance']);
    final amountValue = StatementsFormatters.parseAmount(amount);
    final isNegative = (amountValue ?? 0) < 0;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    List<String> toStringList(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
      return const <String>[];
    }

    final invoiceIds = toStringList(entry['invoiceIds']);
    final expenseDocumentIdsRaw =
        toStringList(entry['expenseDocumentIds'] ?? entry['expenseIds']);
    final primaryInvoiceId = invoiceIds.isNotEmpty
        ? invoiceIds.first
        : (entry['invoiceId'] ?? entry['invoice_id'] ?? entry['invoice'])
            ?.toString()
            .trim();
    final effectiveExpenseDocumentIds = expenseDocumentIdsRaw.isNotEmpty
        ? expenseDocumentIdsRaw
        : (isNegative && invoiceIds.isNotEmpty ? invoiceIds : const <String>[]);
    final primaryExpenseDocumentId = effectiveExpenseDocumentIds.isNotEmpty
        ? effectiveExpenseDocumentIds.first
        : (entry['expenseDocumentId'] ??
                entry['expense_document_id'] ??
                entry['expenseId'] ??
                entry['expense_id'])
            ?.toString()
            .trim();
    final hasInvoice = !isNegative &&
        primaryInvoiceId != null &&
        primaryInvoiceId.trim().isNotEmpty;
    final hasExpenseDocument = primaryExpenseDocumentId != null &&
        primaryExpenseDocumentId.trim().isNotEmpty;
    final hasLinkedDocument = hasInvoice || hasExpenseDocument;
    final hasRepetitiveInvoiceLink =
        entry['hasRepetitiveInvoiceLink'] == true ||
            entry['has_repetitive_invoice_link'] == true;
    final invoiceLinkedRowsCount = (entry['invoiceLinkedRowsCount'] is num)
        ? (entry['invoiceLinkedRowsCount'] as num).toInt()
        : (entry['invoice_linked_rows_count'] is num)
            ? (entry['invoice_linked_rows_count'] as num).toInt()
            : 0;
    final hasNoProcede =
        noProcedeReason != null && noProcedeReason!.trim().isNotEmpty;
    final linkError = controller.linkClientError[entryId];
    final linkInvoiceError = controller.linkInvoiceError[entryId];
    final notesError = controller.entryNotesError[entryId];
    final notes = StatementsShared.entryText(entry, ['notes']).trim();
    final hasNotes = notes.isNotEmpty;
    final savingNotes = controller.savingEntryNotes[entryId] == true;
    final linking = controller.linkingClient[entryId] == true;
    final suggestLoading = controller.loadingSuggestions[entryId] == true ||
        controller.loadingInvoiceSuggestions[entryId] == true;
    final isSelected = entryId.isNotEmpty && selectedIds.contains(entryId);
    final isUnlinked = entry['clientId'] == null ||
        entry['clientId'].toString().trim().isEmpty;
    final rowColor = isSelected ? tableTheme.rowSelected : tableTheme.rowBg;
    final rowAccent =
        isNegative ? tableTheme.amountNegative : tableTheme.amountPositive;
    final amountAbs = (amountValue ?? 0).abs();
    final canLinkInvoice = amountAbs > 0;
    final canSuggest = (amountValue ?? 0) != 0;
    final aiSuggestActionLabel =
        isEs ? 'Sugerir coincidencias IA' : 'Suggest AI matches';
    final manualLinkActionLabel = isNegative
        ? (isEs ? 'Vincular gasto' : 'Link expense')
        : (isEs ? 'Vincular factura' : 'Link invoice');
    final previewActionLabel = isNegative
        ? (isEs ? 'Ver gasto vinculado' : 'View linked expense')
        : (isEs ? 'Ver factura vinculada' : 'View linked invoice');
    final notesPreview =
        notes.length > 90 ? '${notes.substring(0, 90)}...' : notes;
    final notesActionLabel = hasNotes
        ? 'Editar nota${notesPreview.isNotEmpty ? '\n$notesPreview' : ''}'
        : 'Añadir nota';

    Future<void> previewLinkedInvoice() async {
      if (hasExpenseDocument) {
        final expenseId = primaryExpenseDocumentId.trim();
        if (expenseId.isEmpty) return;
        try {
          final result = await _expensesApi.fetchExpenseFile(expenseId);
          final url = Uri.tryParse((result['url'] ?? '').toString().trim());
          if (url == null) throw Exception(l.preview);
          final opened = await launchUrl(
            url,
            mode: LaunchMode.platformDefault,
            webOnlyWindowName: '_blank',
          );
          if (!opened) throw Exception(l.preview);
          return;
        } catch (e) {
          if (!context.mounted) return;
          final msg = e.toString().replaceFirst('Exception: ', '').trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg.isEmpty ? l.preview : msg)),
          );
          return;
        }
      }

      final id = (primaryInvoiceId ?? '').trim();
      if (id.isEmpty) return;
      try {
        final r = await _invoicesApi.previewPdf(id);
        final bytes = InvoiceEditorPdf.validatePdf(r);
        await pdf_launcher.launchPdfPreview(
          bytes,
          fileName: 'invoice-preview-$id.pdf',
        );
      } catch (e) {
        if (!context.mounted) return;
        final msg = e.toString().replaceFirst('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.isEmpty ? l.preview : msg)),
        );
      }
    }

    Widget menuLabel(IconData icon, String text) {
      return Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Flexible(child: Text(text)),
        ],
      );
    }

    List<PopupMenuEntry<String>> rowMenuItems({
      bool includePrimaryActions = true,
    }) {
      return [
        if (includePrimaryActions)
          PopupMenuItem(
            value: 'suggest',
            enabled: entryId.isNotEmpty && !suggestLoading && canSuggest,
            child: menuLabel(Icons.auto_awesome, aiSuggestActionLabel),
          ),
        PopupMenuItem(
          value: 'link_client',
          enabled: entryId.isNotEmpty && !linking,
          child: menuLabel(
            Icons.person_add_alt_1_outlined,
            isEs ? 'Vincular cliente' : 'Link client',
          ),
        ),
        PopupMenuItem(
          value: 'preview',
          enabled: hasLinkedDocument,
          child: menuLabel(Icons.visibility_outlined, previewActionLabel),
        ),
        if (includePrimaryActions)
          PopupMenuItem(
            value: 'link_invoice',
            enabled: entryId.isNotEmpty && canLinkInvoice,
            child: menuLabel(Icons.receipt_long, manualLinkActionLabel),
          ),
        PopupMenuItem(
          value: 'notes',
          enabled: entryId.isNotEmpty && !savingNotes,
          child: menuLabel(
            Icons.sticky_note_2_outlined,
            hasNotes
                ? (isEs ? 'Editar nota' : 'Edit note')
                : (isEs ? 'Añadir nota' : 'Add note'),
          ),
        ),
        PopupMenuItem(
          value: 'not_applicable',
          enabled: entryId.isNotEmpty,
          child: menuLabel(
            Icons.block_outlined,
            hasNoProcede
                ? (isEs ? 'Editar no procede' : 'Edit not applicable')
                : (isEs ? 'Marcar no procede' : 'Mark not applicable'),
          ),
        ),
        PopupMenuItem(
          value: 'details',
          child: menuLabel(Icons.info_outline, l.statementsViewDetails),
        ),
      ];
    }

    void handleRowMenuSelection(String result) {
      if (result == 'suggest') {
        if (entryId.isNotEmpty && !suggestLoading && canSuggest) {
          onSuggest(entry);
        }
      } else if (result == 'link_client') {
        if (entryId.isNotEmpty && !linking) onLink(entry);
      } else if (result == 'preview') {
        if (hasLinkedDocument) previewLinkedInvoice();
      } else if (result == 'link_invoice') {
        if (entryId.isNotEmpty && canLinkInvoice) onLinkInvoice(entry);
      } else if (result == 'notes') {
        if (entryId.isNotEmpty && !savingNotes) {
          StatementEntryNotesDialog.show(context, controller, entry);
        }
      } else if (result == 'not_applicable') {
        if (entryId.isNotEmpty) onMarkNoProcede(entry);
      } else if (result == 'details') {
        onShowDetails(entry);
      }
    }

    Future<void> showRowMenu(Offset position) async {
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      final result = await showMenu<String>(
        context: context,
        position: RelativeRect.fromRect(
          Rect.fromLTWH(position.dx, position.dy, 0, 0),
          Offset.zero & overlay.size,
        ),
        items: rowMenuItems(),
      );
      if (result != null) handleRowMenuSelection(result);
    }

    final amountColor =
        isNegative ? tableTheme.amountNegative : tableTheme.amountPositive;

    return _StatementRowSurface(
      borderColor: isSelected
          ? rowAccent.withValues(alpha: 0.65)
          : tableTheme.border.withValues(alpha: 0.82),
      child: Material(
        color: rowColor,
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (details) => showRowMenu(details.globalPosition),
          onLongPressStart: (details) => showRowMenu(details.globalPosition),
          child: InkWell(
            hoverColor: tableTheme.rowHover,
            hoverDuration: const Duration(milliseconds: 150),
            borderRadius: BorderRadius.circular(12),
            onTap: () => onShowDetails(entry),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 12,
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -6,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: rowAccent.withValues(
                          alpha: isSelected ? 0.9 : 0.48,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                              width:
                                  StatementsAllDataTableLayout.leadingSpacer),
                          SizedBox(
                            width: StatementsAllDataTableLayout.checkWidth,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: entryId.isEmpty
                                  ? null
                                  : (_) => onToggleRow(entryId),
                            ),
                          ),
                          if (isDesktop) ...[
                            SizedBox(
                              width: StatementsAllDataTableLayout.batchWidth,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Tooltip(
                                      message: batchId.isEmpty ? '-' : batchId,
                                      child: Text(
                                        shortBatchId,
                                        textAlign: TextAlign.center,
                                        style: typography.bodySmall.copyWith(
                                          color: tableTheme.textSecondary,
                                          fontSize: 12.5,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  // Copy action removed per request.
                                ],
                              ),
                            ),
                            const SizedBox(
                                width: StatementsAllDataTableLayout.columnGap),
                          ],
                          SizedBox(
                            width: StatementsAllDataTableLayout.dateWidth,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  if (date.isNotEmpty) ...[
                                    const TextSpan(
                                      text: 'Op. ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: StatementsFormatters.formatDate(
                                        context,
                                        date,
                                      ),
                                    ),
                                  ],
                                  if (valueDate.isNotEmpty &&
                                      valueDate != date) ...[
                                    if (date.isNotEmpty)
                                      const TextSpan(text: '\n'),
                                    const TextSpan(
                                      text: 'Val. ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: StatementsFormatters.formatDate(
                                        context,
                                        valueDate,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              style: typography.bodySmall.copyWith(
                                color: tableTheme.textSecondary,
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(
                              width: StatementsAllDataTableLayout.columnGap),
                          if (isCompact)
                            Expanded(
                              flex: 4,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUnlinked)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.link_off_outlined,
                                        size: 16,
                                        color: tableTheme.textSecondary,
                                      ),
                                    ),
                                  if (isUnlinked) const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      desc.isEmpty
                                          ? l.statementsNoDescription
                                          : desc,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: typography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth:
                                    StatementsAllDataTableLayout.descMinWidth,
                                maxWidth:
                                    StatementsAllDataTableLayout.descMaxWidth,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUnlinked)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.link_off_outlined,
                                        size: 16,
                                        color: tableTheme.textSecondary,
                                      ),
                                    ),
                                  if (isUnlinked) const SizedBox(width: 6),
                                  Expanded(
                                    child: Tooltip(
                                      message: desc.isEmpty
                                          ? l.statementsNoDescription
                                          : desc,
                                      child: Text(
                                        desc.isEmpty
                                            ? l.statementsNoDescription
                                            : desc,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: typography.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Details column hidden for now.
                          const SizedBox(
                              width: StatementsAllDataTableLayout.columnGap),
                          SizedBox(
                            width: StatementsAllDataTableLayout.amountWidth,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _moneyText(
                                context,
                                amount,
                                emphasize: true,
                                amountColor: amountColor,
                                asPill: true,
                              ),
                            ),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(
                                width: StatementsAllDataTableLayout.columnGap),
                            SizedBox(
                              width: balanceMaxWidth,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _moneyText(
                                  context,
                                  balance,
                                  emphasize: false,
                                  amountColor: tableTheme.textSecondary,
                                  textStyle: typography.bodySmall,
                                ),
                              ),
                            ),
                          ],
                          if (!isCompact) ...[
                            SizedBox(
                              width: isTablet
                                  ? 12
                                  : StatementsAllDataTableLayout
                                      .balanceClientGap,
                            ),
                            Expanded(
                              child: () {
                                final displayName =
                                    StatementsSharedUtils.clientLabel(
                                        l, controller, entry);
                                return Tooltip(
                                  message: displayName,
                                  child: isUnlinked
                                      ? Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: tableTheme.chipBg,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: tableTheme.border,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  size: 6,
                                                  color: tableTheme
                                                      .textSecondary
                                                      .withValues(alpha: 0.7),
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    displayName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: typography.bodySmall
                                                        .copyWith(
                                                      fontSize: 12.5,
                                                      color: tableTheme
                                                          .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: typography.bodySmall.copyWith(
                                            fontSize: 12.5,
                                            color: tableTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                );
                              }(),
                            ),
                            if (isDesktop) ...[
                              const SizedBox(
                                  width: StatementsAllDataTableLayout
                                      .columnGapWide),
                              SizedBox(
                                width: StatementsAllDataTableLayout.notesWidth,
                                child: Tooltip(
                                  message: hasNotes ? notes : 'Añadir nota',
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: entryId.isEmpty || savingNotes
                                        ? null
                                        : () => StatementEntryNotesDialog.show(
                                              context,
                                              controller,
                                              entry,
                                            ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hasNotes
                                            ? cs.primary.withValues(alpha: 0.08)
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: hasNotes
                                            ? Border.all(
                                                color: cs.primary
                                                    .withValues(alpha: 0.20),
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (hasNotes) ...[
                                            Icon(
                                              Icons.sticky_note_2,
                                              size: 14,
                                              color: cs.primary,
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Flexible(
                                            child: Text(
                                              hasNotes ? notes : '\u2014',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  typography.bodySmall.copyWith(
                                                fontSize: 12.5,
                                                color: hasNotes
                                                    ? tableTheme.textPrimary
                                                    : tableTheme.textSecondary
                                                        .withValues(
                                                            alpha: 0.72),
                                                fontWeight: hasNotes
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(
                              width:
                                  StatementsAllDataTableLayout.columnGapWide),
                          SizedBox(
                            width: StatementsAllDataTableLayout.invoiceWidth,
                            child: Align(
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 130),
                                child: () {
                                  final invoiceNumbers = toStringList(
                                    entry['invoiceNumbers'],
                                  );
                                  final expenseDocumentNumbersRaw =
                                      toStringList(
                                    entry['expenseDocumentNumbers'] ??
                                        entry['expenseNumbers'],
                                  );
                                  final invoiceNumber =
                                      (entry['invoiceNumber'] ??
                                                  entry['invoice_number'])
                                              ?.toString()
                                              .trim() ??
                                          '';
                                  final expenseNumber =
                                      (entry['expenseNumber'] ??
                                                  entry['expense_number'])
                                              ?.toString()
                                              .trim() ??
                                          '';
                                  final expenseDocumentNumber = (entry[
                                                  'expenseDocumentNumber'] ??
                                              entry['expense_document_number'])
                                          ?.toString()
                                          .trim() ??
                                      '';
                                  final effectiveInvoiceNumbers =
                                      invoiceNumbers.isNotEmpty
                                          ? invoiceNumbers
                                          : (invoiceNumber.isNotEmpty
                                              ? <String>[invoiceNumber]
                                              : const <String>[]);
                                  final effectiveExpenseNumbers =
                                      expenseDocumentNumbersRaw.isNotEmpty
                                          ? expenseDocumentNumbersRaw
                                          : (isNegative &&
                                                  effectiveInvoiceNumbers
                                                      .isNotEmpty
                                              ? effectiveInvoiceNumbers
                                              : expenseDocumentNumber.isNotEmpty
                                                  ? <String>[
                                                      expenseDocumentNumber
                                                    ]
                                                  : expenseNumber.isNotEmpty
                                                      ? <String>[expenseNumber]
                                                      : const <String>[]);
                                  final docNumber = isNegative
                                      ? effectiveExpenseNumbers.join(', ')
                                      : effectiveInvoiceNumbers.join(', ');
                                  final String displayText;
                                  final Color textColor;
                                  if (hasNoProcede) {
                                    displayText = 'No procede';
                                    textColor = cs.tertiary;
                                  } else if (docNumber.isNotEmpty) {
                                    displayText = docNumber;
                                    textColor = tableTheme.textPrimary;
                                  } else if (isNegative &&
                                      hasExpenseDocument &&
                                      effectiveExpenseDocumentIds.isNotEmpty) {
                                    displayText = isEs
                                        ? 'Gasto vinculado'
                                        : 'Linked expense';
                                    textColor = tableTheme.textPrimary;
                                  } else if (!isNegative && hasInvoice) {
                                    displayText = isEs
                                        ? 'Factura vinculada'
                                        : 'Linked invoice';
                                    textColor = tableTheme.textPrimary;
                                  } else {
                                    displayText = l.statementsUnlinked;
                                    textColor = tableTheme.textSecondary;
                                  }
                                  final pillColor = hasNoProcede
                                      ? cs.tertiary
                                      : hasLinkedDocument
                                          ? tableTheme.amountPositive
                                          : tableTheme.textSecondary;
                                  return Tooltip(
                                    message: hasNoProcede
                                        ? noProcedeReason!
                                        : (hasRepetitiveInvoiceLink
                                            ? l.statementsRepetitiveInvoiceTooltip(
                                                (invoiceLinkedRowsCount > 0
                                                        ? invoiceLinkedRowsCount
                                                        : 2)
                                                    .toString(),
                                              )
                                            : docNumber),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: pillColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: pillColor.withValues(
                                                alpha: 0.28,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            displayText,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style:
                                                typography.bodySmall.copyWith(
                                              color: textColor,
                                              fontWeight: docNumber.isNotEmpty
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (hasInvoice &&
                                            hasRepetitiveInvoiceLink &&
                                            !hasNoProcede) ...[
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cs.tertiaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              l.statementsRepetitiveInvoiceBadge,
                                              style:
                                                  typography.bodySmall.copyWith(
                                                color: cs.onTertiaryContainer,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }(),
                              ),
                            ),
                          ),
                          const SizedBox(
                              width:
                                  StatementsAllDataTableLayout.columnGapWide),
                          SizedBox(
                            width: actionsWidth,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconTheme(
                                data: IconThemeData(
                                    color: tableTheme.textPrimary),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!isDesktop) ...[
                                      _actionButton(
                                        tooltip: aiSuggestActionLabel,
                                        onPressed: (!canSuggest ||
                                                suggestLoading ||
                                                entryId.isEmpty)
                                            ? null
                                            : () => onSuggest(entry),
                                        icon: Icons.auto_awesome,
                                        activeColor: cs.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      _actionButton(
                                        tooltip: manualLinkActionLabel,
                                        onPressed:
                                            (!canLinkInvoice || entryId.isEmpty)
                                                ? null
                                                : () => onLinkInvoice(entry),
                                        icon: Icons.receipt_long,
                                        activeColor: cs.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      PopupMenuButton<String>(
                                        tooltip: isEs
                                            ? 'Más acciones'
                                            : 'More actions',
                                        padding: EdgeInsets.zero,
                                        position: PopupMenuPosition.under,
                                        menuPadding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        surfaceTintColor: Colors.transparent,
                                        style: IconButton.styleFrom(
                                          backgroundColor: tableTheme.chipBg,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(9),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.more_horiz_rounded,
                                          size: 17,
                                        ),
                                        itemBuilder: (_) => rowMenuItems(
                                          includePrimaryActions: false,
                                        ),
                                        onSelected: handleRowMenuSelection,
                                      ),
                                    ],
                                    if (isDesktop) ...[
                                      _actionButton(
                                        tooltip: aiSuggestActionLabel,
                                        onPressed: (!canSuggest ||
                                                suggestLoading ||
                                                entryId.isEmpty)
                                            ? null
                                            : () => onSuggest(entry),
                                        icon: Icons.auto_awesome,
                                        activeColor: cs.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      _actionButton(
                                        tooltip: previewActionLabel,
                                        onPressed: hasLinkedDocument
                                            ? previewLinkedInvoice
                                            : null,
                                        icon: Icons.visibility_outlined,
                                      ),
                                      const SizedBox(width: 4),
                                      _actionButton(
                                        tooltip: manualLinkActionLabel,
                                        onPressed:
                                            (!canLinkInvoice || entryId.isEmpty)
                                                ? null
                                                : () => onLinkInvoice(entry),
                                        icon: Icons.receipt_long,
                                        activeColor: cs.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      _actionButton(
                                        tooltip: notesActionLabel,
                                        onPressed: (entryId.isEmpty ||
                                                savingNotes)
                                            ? null
                                            : () =>
                                                StatementEntryNotesDialog.show(
                                                  context,
                                                  controller,
                                                  entry,
                                                ),
                                        icon: savingNotes
                                            ? Icons.hourglass_top_rounded
                                            : hasNotes
                                                ? Icons.sticky_note_2
                                                : Icons.sticky_note_2_outlined,
                                        activeColor:
                                            hasNotes ? cs.primary : null,
                                      ),
                                      const SizedBox(width: 4),
                                      _actionButton(
                                        tooltip: hasNoProcede
                                            ? 'Editar no procede'
                                            : 'Marcar no procede',
                                        onPressed: entryId.isEmpty
                                            ? null
                                            : () => onMarkNoProcede(entry),
                                        icon: hasNoProcede
                                            ? Icons.block
                                            : Icons.block_outlined,
                                        activeColor:
                                            hasNoProcede ? cs.tertiary : null,
                                      ),
                                      const SizedBox(width: 4),
                                      _actionButton(
                                        tooltip: l.statementsViewDetails,
                                        onPressed: () => onShowDetails(entry),
                                        icon: Icons.info_outline,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (linkError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 44, top: 4),
                          child: Text(linkError,
                              style: TextStyle(color: cs.error)),
                        ),
                      if (linkInvoiceError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 44, top: 4),
                          child: Text(linkInvoiceError,
                              style: TextStyle(color: cs.error)),
                        ),
                      if (notesError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 44, top: 4),
                          child: Text(notesError,
                              style: TextStyle(color: cs.error)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatementRowSurface extends StatefulWidget {
  const _StatementRowSurface({
    required this.borderColor,
    required this.child,
  });

  final Color borderColor;
  final Widget child;

  @override
  State<_StatementRowSurface> createState() => _StatementRowSurfaceState();
}

class _StatementRowSurfaceState extends State<_StatementRowSurface> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.borderColor),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.075),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: widget.child,
      ),
    );
  }
}
