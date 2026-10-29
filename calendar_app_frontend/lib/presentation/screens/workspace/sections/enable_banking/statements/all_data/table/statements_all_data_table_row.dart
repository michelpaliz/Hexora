import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:hexora/services/expenses/expenses_api.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/statement_entry_notes_dialog.dart';
import '../../statements_controller.dart';
import '../../statements_formatters.dart';
import '../../statements_shared.dart';
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
    this.activeEntryId,
    required this.onToggleRow,
    required this.onShowDetails,
    required this.onSuggest,
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
  final String? activeEntryId;
  final ValueChanged<String> onToggleRow;
  final ValueChanged<Map<String, dynamic>> onShowDetails;
  final ValueChanged<Map<String, dynamic>> onSuggest;
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
        fontSize: 12,
        color: amountColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return text;
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
    final showNotes = !isCompact;
    final actionsWidth = isDesktop
        ? StatementsAllDataTableLayout.actionsWidth
        : StatementsAllDataTableLayout.compactActionsWidth;
    final entryId = (entry['_id'] ?? entry['id'])?.toString() ?? '';
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
    final suggestLoading = controller.loadingSuggestions[entryId] == true ||
        controller.loadingInvoiceSuggestions[entryId] == true;
    final isSelected = entryId.isNotEmpty && selectedIds.contains(entryId);
    final isUnlinked = entry['clientId'] == null ||
        entry['clientId'].toString().trim().isEmpty;
    final isActive = entryId.isNotEmpty && entryId == activeEntryId;
    final rowColor = isActive
        ? tableTheme.rowActive
        : isSelected
            ? tableTheme.rowSelected
            : tableTheme.rowBg;
    final rowAccent =
        isNegative ? tableTheme.amountNegative : tableTheme.amountPositive;
    final amountAbs = (amountValue ?? 0).abs();
    final canLinkInvoice = amountAbs > 0;
    final canSuggest = (amountValue ?? 0) != 0;
    // A single link action, shared with the insights chat: unlinked rows open
    // the suggested matches (which also offer "Vincular manualmente"); linked
    // rows edit the existing link in the manual wizard.
    final linkActionLabel = hasLinkedDocument
        ? (isEs ? 'Editar vínculo' : 'Edit link')
        : (isEs ? 'Vincular' : 'Link');
    final linkActionEnabled = entryId.isNotEmpty &&
        (hasLinkedDocument ? canLinkInvoice : (canSuggest && !suggestLoading));
    void openLinkAction() =>
        hasLinkedDocument ? onLinkInvoice(entry) : onSuggest(entry);
    final previewActionLabel = isNegative
        ? (isEs ? 'Ver gasto vinculado' : 'View linked expense')
        : (isEs ? 'Ver factura vinculada' : 'View linked invoice');
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

    List<PopupMenuEntry<String>> rowMenuItems() {
      return [
        NavigationPopupMenuItem(
          value: 'link',
          enabled: linkActionEnabled,
          child: menuLabel(
            Icons.link_rounded,
            linkActionLabel,
          ),
        ),
        NavigationPopupMenuItem(
          value: 'preview',
          enabled: hasLinkedDocument,
          child: menuLabel(Icons.visibility_outlined, previewActionLabel),
        ),
        NavigationPopupMenuItem(
          value: 'notes',
          enabled: entryId.isNotEmpty && !savingNotes,
          child: menuLabel(
            Icons.sticky_note_2_outlined,
            hasNotes
                ? (isEs ? 'Editar nota' : 'Edit note')
                : (isEs ? 'Añadir nota' : 'Add note'),
          ),
        ),
        NavigationPopupMenuItem(
          value: 'not_applicable',
          enabled: entryId.isNotEmpty,
          child: menuLabel(
            Icons.block_outlined,
            hasNoProcede
                ? (isEs ? 'Editar no procede' : 'Edit not applicable')
                : (isEs ? 'Marcar no procede' : 'Mark not applicable'),
          ),
        ),
        NavigationPopupMenuItem(
          value: 'details',
          child: menuLabel(Icons.info_outline, l.statementsViewDetails),
        ),
      ];
    }

    void handleRowMenuSelection(String result) {
      if (result == 'link') {
        openLinkAction();
      } else if (result == 'preview') {
        if (hasLinkedDocument) previewLinkedInvoice();
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
      borderColor: isActive || isSelected
          ? rowAccent.withValues(alpha: 0.45)
          : Colors.transparent,
      child: Material(
        color: rowColor,
        borderRadius: BorderRadius.zero,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (details) => showRowMenu(details.globalPosition),
          onLongPressStart: (details) => showRowMenu(details.globalPosition),
          child: InkWell(
            hoverColor: tableTheme.rowHover,
            hoverDuration: const Duration(milliseconds: 150),
            borderRadius: BorderRadius.zero,
            onTap: () => onShowDetails(entry),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 12,
              ),
              child: Stack(
                children: [
                  if (isSelected || isActive)
                    Positioned(
                      left: -6,
                      top: 8,
                      bottom: 8,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: rowAccent.withValues(alpha: 0.85),
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
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: entryId.isEmpty
                                  ? null
                                  : (_) => onToggleRow(entryId),
                            ),
                          ),
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
                                          fontSize: 12.5,
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
                                      ? Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: typography.bodySmall.copyWith(
                                            fontSize: 12.5,
                                            color: tableTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
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
                            if (showNotes) ...[
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
                                  return Tooltip(
                                    message: hasNoProcede
                                        ? noProcedeReason!
                                        : (hasRepetitiveInvoiceLink
                                            ? l
                                                .statementsRepetitiveInvoiceTooltip(
                                                (invoiceLinkedRowsCount > 0
                                                        ? invoiceLinkedRowsCount
                                                        : 2)
                                                    .toString(),
                                              )
                                            : docNumber.isEmpty
                                                ? (isEs
                                                    ? 'Sin factura vinculada'
                                                    : 'No linked invoice')
                                                : docNumber),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          hasLinkedDocument || hasNoProcede
                                              ? displayText
                                              : '—',
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: typography.bodySmall.copyWith(
                                            color: textColor,
                                            fontWeight: docNumber.isNotEmpty
                                                ? FontWeight.w600
                                                : FontWeight.w500,
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
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      surfaceTintColor: Colors.transparent,
                                      style: IconButton.styleFrom(
                                        minimumSize: const Size(30, 30),
                                        backgroundColor: Colors.transparent,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.more_horiz_rounded,
                                        size: 17,
                                      ),
                                      itemBuilder: (_) => rowMenuItems(),
                                      onSelected: handleRowMenuSelection,
                                    ),
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
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: Border(bottom: BorderSide(color: widget.borderColor)),
        ),
        child: widget.child,
      ),
    );
  }
}
