import 'package:flutter/material.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/l10n/app_localizations.dart';

import '../statements_controller.dart';
import '../statements_formatters.dart';
import 'statements_shared_utils.dart';

class StatementsInvoiceSuggestDialog {
  static final InvoicesApi _invoicesApi = InvoicesApi();

  static Future<void> show(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry,
  ) async {
    final entryId = (entry['_id'] ?? entry['id'])?.toString();
    if (entryId == null || entryId.isEmpty) return;

    final amountText = StatementsSharedUtils.entryText(entry, ['amount']);
    final amountValue = StatementsFormatters.parseAmount(amountText);
    final type =
        (amountValue != null && amountValue < 0) ? 'expense' : 'income';
    final expenseOnly = type == 'expense';

    final options = await s.suggestInvoices(entryId, type: type);
    if (!context.mounted) return;

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.statementsNoInvoiceSuggestions,
          ),
        ),
      );
      return;
    }

    var currentOptions = List<Map<String, dynamic>>.from(options);
    var tolerance = 0.01;
    var selectedType = type;
    var refreshing = false;
    int? linkingIdx;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        final cs = Theme.of(dialogContext).colorScheme;
        final tt = Theme.of(dialogContext).textTheme;

        final entryDate =
            StatementsSharedUtils.entryText(entry, ['date', 'valueDate']);
        final entryDescription =
            StatementsSharedUtils.entryText(entry, ['description']);
        final entryAmount =
            StatementsSharedUtils.entryText(entry, ['amount']);
        final entryClientId =
            (entry['clientId'] ?? entry['client_id'])?.toString().trim() ?? '';
        final isIncome = !expenseOnly;

        String resolveClientNameById(String? clientId) {
          if (clientId == null || clientId.isEmpty) return l.statementsUnlinked;
          final match = s.clients.firstWhere(
            (c) =>
                c['id']?.toString() == clientId ||
                c['_id']?.toString() == clientId,
            orElse: () => const <String, dynamic>{},
          );
          if (match.isNotEmpty) {
            final name = match['name']?.toString().trim();
            if (name != null && name.isNotEmpty) return name;
          }
          return l.statementsUnlinked;
        }

        String? extractSuggestedClientId(Map<String, dynamic> inv) {
          dynamic raw = inv['clientId'] ?? inv['client_id'] ?? inv['client'];
          if (raw is Map) {
            raw = raw['_id'] ?? raw['id'];
          }
          final id = raw?.toString().trim() ?? '';
          if (id.isEmpty) return null;
          final looksMongoId = RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(id);
          return looksMongoId ? id : null;
        }

        String resolveClientName(Map<String, dynamic> inv) {
          final directName =
              (inv['clientName'] ?? inv['client_name'] ?? inv['client'])
                  ?.toString()
                  .trim();
          if (directName != null &&
              directName.isNotEmpty &&
              directName.toLowerCase() != 'null') {
            return directName;
          }
          return resolveClientNameById(extractSuggestedClientId(inv));
        }

        String resolveStatusLabel(String raw) {
          final normalized = raw.trim().toLowerCase();
          if (normalized.isEmpty) return '';
          if (normalized.contains('draft')) return l.statusDraft;
          if (normalized.contains('issue')) return l.statusIssued;
          if (normalized.contains('paid')) return l.statusPaid;
          if (normalized.contains('pending')) return l.pending;
          if (normalized.contains('cancel')) return l.cancel;
          if (normalized.contains('overdue')) return l.expired;
          return raw;
        }

        Future<void> previewSuggestedInvoice(Map<String, dynamic> inv) async {
          final invoiceId =
              (inv['_id'] ?? inv['id'])?.toString().trim() ?? '';
          if (invoiceId.isEmpty) return;
          try {
            final response = await _invoicesApi.previewPdf(invoiceId);
            final bytes = InvoiceEditorPdf.validatePdf(response);
            final number = inv['invoiceNumber']?.toString().trim() ?? '';
            final fileName = number.isNotEmpty
                ? 'invoice-$number.pdf'
                : 'invoice-preview-$invoiceId.pdf';
            await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
          } catch (e) {
            if (!dialogContext.mounted) return;
            final msg =
                e.toString().replaceFirst('Exception: ', '').trim();
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              SnackBar(content: Text(msg.isEmpty ? l.preview : msg)),
            );
          }
        }

        // ── Left panel: bank transaction details ──
        Widget transactionPanel() {
          final formattedAmount = entryAmount.isEmpty
              ? '-'
              : StatementsFormatters.formatCurrency(dialogContext, entryAmount);
          final formattedDate = entryDate.isEmpty
              ? '-'
              : StatementsFormatters.formatDate(dialogContext, entryDate);
          final clientName = resolveClientNameById(entryClientId);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primaryContainer.withValues(alpha: 0.18),
                  cs.surfaceContainerHighest.withValues(alpha: 0.25),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.2),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.statementsRowDetailsTitle,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Amount highlight
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: (isIncome ? cs.primary : cs.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l.statementsHeaderAmount,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedAmount,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isIncome ? cs.primary : cs.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _iconDetailRow(
                  tt,
                  cs,
                  Icons.calendar_today_outlined,
                  l.statementsHeaderDate,
                  formattedDate,
                ),
                const SizedBox(height: 10),
                _iconDetailRow(
                  tt,
                  cs,
                  Icons.description_outlined,
                  l.statementsHeaderDescription,
                  entryDescription.isEmpty
                      ? l.statementsNoDescription
                      : entryDescription,
                ),
                const SizedBox(height: 10),
                _iconDetailRow(
                  tt,
                  cs,
                  Icons.person_outline,
                  l.statementsHeaderClient,
                  clientName,
                ),
              ],
            ),
          );
        }

        // ── Suggestions list ──
        Widget suggestionsPanel(StateSetter setState) {
          Map<String, dynamic>? findLinkedEntryByInvoice(String invoiceId) {
            if (invoiceId.trim().isEmpty) return null;
            for (final e in s.allEntries) {
              final eId = (e['_id'] ?? e['id'])?.toString() ?? '';
              if (eId == entryId) continue;
              final linkedInvoiceId =
                  (e['invoiceId'] ?? e['invoice_id'] ?? e['invoice'])
                          ?.toString()
                          .trim() ??
                      '';
              if (linkedInvoiceId == invoiceId) return e;
            }
            return null;
          }

          Future<bool> confirmAlreadyLinked() async {
            final confirmed = await showDialog<bool>(
              context: dialogContext,
              builder: (context) => AlertDialog(
                title: Text(l.statementsInvoiceAlreadyLinkedTitle),
                content: Text(l.statementsInvoiceAlreadyLinkedBody),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l.statementsInvoiceLinkAnyway),
                  ),
                ],
              ),
            );
            return confirmed == true;
          }

          return ListView.separated(
            shrinkWrap: true,
            itemCount: currentOptions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final inv = currentOptions[i];
              final invId =
                  inv['_id']?.toString() ?? inv['id']?.toString() ?? '';
              final suggestedClientId =
                  extractSuggestedClientId(inv) ?? '';
              final invoiceNumber =
                  inv['invoiceNumber']?.toString() ?? '-';
              final issueDate = inv['issueDate']?.toString() ?? '';
              final status =
                  resolveStatusLabel(inv['status']?.toString() ?? '');
              final totals = inv['totals'];
              final total = (totals is Map) ? totals['total'] : null;
              final totalFormatted = total != null
                  ? StatementsFormatters.formatCurrency(dialogContext, total)
                  : '-';
              final clientName = resolveClientName(inv);
              final canLink = invId.isNotEmpty;
              final linkedElsewhere = findLinkedEntryByInvoice(invId);
              final alreadyLinkedByApi = inv['alreadyLinked'] == true ||
                  inv['isAlreadyLinked'] == true;
              final linkedEntriesCount =
                  (inv['linkedEntriesCount'] is num)
                      ? (inv['linkedEntriesCount'] as num).toInt()
                      : 0;
              final linkedEntryDate =
                  (inv['linkedEntryDate']?.toString().trim() ?? '');
              final linkedEntryAmountRaw =
                  (inv['linkedEntryAmount']?.toString().trim() ?? '');
              final linkedEntryDescription =
                  (inv['linkedEntryDescription']?.toString().trim() ?? '');
              final isAlreadySelected =
                  alreadyLinkedByApi || linkedElsewhere != null;
              final isLinking = linkingIdx == i;
              final actionsEnabled = canLink && linkingIdx == null;
              final isBestMatch = i == 0 && !isAlreadySelected;
              final accentColor =
                  isBestMatch ? cs.primary : cs.outlineVariant;

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isAlreadySelected
                        ? cs.outlineVariant.withValues(alpha: 0.3)
                        : isBestMatch
                            ? cs.primary.withValues(alpha: 0.4)
                            : cs.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left accent bar
                        Container(
                          width: 4,
                          color: isAlreadySelected
                              ? cs.tertiary.withValues(alpha: 0.5)
                              : accentColor.withValues(alpha: 0.7),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                                14, 12, 14, 12),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Header: number + badges + total
                                Row(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 18,
                                      color: isAlreadySelected
                                          ? cs.onSurfaceVariant
                                          : cs.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              invoiceNumber,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style:
                                                  tt.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (isAlreadySelected) ...[
                                            const SizedBox(width: 8),
                                            _badge(
                                              tt,
                                              l.statementsInvoiceAlreadyLinkedBadge,
                                              cs.tertiaryContainer,
                                              cs.onTertiaryContainer,
                                            ),
                                          ],
                                          if (isBestMatch) ...[
                                            const SizedBox(width: 8),
                                            _badge(
                                              tt,
                                              l.statementsBestMatchBadge,
                                              cs.primaryContainer,
                                              cs.onPrimaryContainer,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      totalFormatted,
                                      style: tt.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: isAlreadySelected
                                            ? cs.onSurfaceVariant
                                            : cs.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Metadata row
                                Row(
                                  children: [
                                    if (issueDate.isNotEmpty) ...[
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 13,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        StatementsFormatters.formatDate(
                                          dialogContext,
                                          issueDate,
                                        ),
                                        style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                    ],
                                    Icon(
                                      Icons.person_outline,
                                      size: 13,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        clientName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    if (status.isNotEmpty) ...[
                                      const SizedBox(width: 14),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerHighest
                                              .withValues(alpha: 0.6),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status,
                                          style: tt.labelSmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                // Already-linked warning
                                if (isAlreadySelected) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: cs.errorContainer
                                          .withValues(alpha: 0.18),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 15,
                                              color: cs.error,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                l.statementsInvoiceAlreadySelected,
                                                style:
                                                    tt.bodySmall?.copyWith(
                                                  color: cs.error,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l.statementsSuggestionAlreadyLinkedSubtext,
                                          style: tt.bodySmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l.statementsInvoiceAlreadyLinkedMeta(
                                            linkedEntryDate.isEmpty
                                                ? '-'
                                                : linkedEntryDate,
                                            linkedEntriesCount > 0
                                                ? linkedEntriesCount
                                                    .toString()
                                                : '1',
                                          ),
                                          style: tt.bodySmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                        if (linkedEntryAmountRaw
                                                .isNotEmpty ||
                                            linkedEntryDescription
                                                .isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    top: 4),
                                            child: Text(
                                              [
                                                if (linkedEntryAmountRaw
                                                    .isNotEmpty)
                                                  StatementsFormatters
                                                      .formatCurrency(
                                                    dialogContext,
                                                    linkedEntryAmountRaw,
                                                  ),
                                                if (linkedEntryDescription
                                                    .isNotEmpty)
                                                  linkedEntryDescription,
                                              ].join(' · '),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style:
                                                  tt.bodySmall?.copyWith(
                                                color:
                                                    cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                // Action buttons
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: actionsEnabled
                                          ? () =>
                                              previewSuggestedInvoice(inv)
                                          : null,
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 17,
                                      ),
                                      label: Text(l.preview),
                                    ),
                                    const SizedBox(width: 6),
                                    isLinking
                                        ? FilledButton.icon(
                                            onPressed: null,
                                            icon: const SizedBox(
                                              width: 17,
                                              height: 17,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            label: Text(
                                                l.statementsActionLink),
                                          )
                                        : FilledButton.icon(
                                            onPressed: actionsEnabled
                                                ? () async {
                                                    if (isAlreadySelected) {
                                                      final confirmed =
                                                          await confirmAlreadyLinked();
                                                      if (!confirmed) {
                                                        return;
                                                      }
                                                    }
                                                    setState(() =>
                                                        linkingIdx = i);
                                                    try {
                                                      final outcome =
                                                          await s
                                                              .linkInvoice(
                                                        entryId: entryId,
                                                        invoiceId: invId,
                                                        invoiceDisplayNumber:
                                                            invoiceNumber
                                                                    .trim()
                                                                    .isEmpty
                                                                ? null
                                                                : invoiceNumber
                                                                    .trim(),
                                                        expenseOnly:
                                                            expenseOnly,
                                                      );
                                                      if (!dialogContext
                                                          .mounted) {
                                                        return;
                                                      }
                                                      if (!outcome
                                                          .success) {
                                                        final msg = outcome
                                                                .errorMessage ??
                                                            '';
                                                        if (outcome.statusCode ==
                                                                400 &&
                                                            msg
                                                                .toLowerCase()
                                                                .contains(
                                                                    'invalid invoiceid')) {
                                                          ScaffoldMessenger
                                                                  .of(
                                                                      dialogContext)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content:
                                                                  Text(
                                                                l.statementsInvalidInvoiceToast,
                                                              ),
                                                            ),
                                                          );
                                                        } else if (outcome
                                                                    .statusCode ==
                                                                404 &&
                                                            msg
                                                                .toLowerCase()
                                                                .contains(
                                                                    'invoice not found')) {
                                                          ScaffoldMessenger
                                                                  .of(
                                                                      dialogContext)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content:
                                                                  Text(
                                                                l.statementsInvoiceNotFoundToast,
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger
                                                                  .of(
                                                                      dialogContext)
                                                              .showSnackBar(
                                                            SnackBar(
                                                                content:
                                                                    Text(
                                                                        msg)),
                                                          );
                                                        }
                                                        return;
                                                      }
                                                      if (outcome
                                                          .alreadyLinked) {
                                                        ScaffoldMessenger
                                                                .of(
                                                                    dialogContext)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              l.statementsInvoiceAlreadyLinkedToast,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      if (outcome
                                                          .hasRepetitiveInvoiceLink) {
                                                        ScaffoldMessenger
                                                                .of(
                                                                    dialogContext)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              l.statementsRepetitiveInvoiceLinkedToast(
                                                                (outcome.invoiceLinkedRowsCount >
                                                                            0
                                                                        ? outcome
                                                                            .invoiceLinkedRowsCount
                                                                        : 2)
                                                                    .toString(),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      final currentClientId =
                                                          (entry['clientId'] ??
                                                                      entry[
                                                                          'client_id'])
                                                                  ?.toString()
                                                                  .trim() ??
                                                              '';
                                                      if (suggestedClientId
                                                              .isNotEmpty &&
                                                          suggestedClientId !=
                                                              currentClientId) {
                                                        await s.linkClient(
                                                          entryId: entryId,
                                                          clientId:
                                                              suggestedClientId,
                                                        );
                                                        if (!dialogContext
                                                            .mounted) {
                                                          return;
                                                        }
                                                      }
                                                      Navigator.of(
                                                              dialogContext)
                                                          .pop();
                                                    } finally {
                                                      if (dialogContext
                                                          .mounted) {
                                                        setState(() =>
                                                            linkingIdx =
                                                                null);
                                                      }
                                                    }
                                                  }
                                                : null,
                                            icon: const Icon(Icons.link,
                                                size: 17),
                                            label: Text(
                                                l.statementsActionLink),
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Theme.of(dialogContext).canvasColor,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 920,
                  maxHeight: 600,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 18, 16, 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: cs.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.statementsSuggestedInvoicesTitle,
                                  style: tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${currentOptions.length} ${currentOptions.length == 1 ? 'resultado' : 'resultados'}',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                            tooltip: l.close,
                          ),
                        ],
                      ),
                    ),
                    // ── Toolbar ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            height: 40,
                            child: TextFormField(
                              initialValue: '0.01',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: tt.bodySmall,
                              decoration: InputDecoration(
                                labelText:
                                    l.statementsInvoiceSuggestTolerance,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (v) {
                                final parsed = double.tryParse(v);
                                if (parsed != null) tolerance = parsed;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: Text(l.statementsSummaryIncome),
                            selected: selectedType == 'income',
                            onSelected: (_) =>
                                setState(() => selectedType = 'income'),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: Text(l.statementsSummaryExpense),
                            selected: selectedType == 'expense',
                            onSelected: (_) =>
                                setState(() => selectedType = 'expense'),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            tooltip: l.refreshAction,
                            onPressed: refreshing
                                ? null
                                : () async {
                                    setState(() => refreshing = true);
                                    final newOptions =
                                        await s.suggestInvoices(
                                      entryId,
                                      type: selectedType,
                                      tolerance: tolerance,
                                    );
                                    if (!dialogContext.mounted) return;
                                    setState(() {
                                      currentOptions = newOptions;
                                      refreshing = false;
                                    });
                                  },
                            icon: const Icon(Icons.refresh, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Body ──
                    Flexible(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(24, 0, 24, 20),
                        child: refreshing
                            ? const Center(
                                child: CircularProgressIndicator())
                            : currentOptions.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons
                                              .search_off_outlined,
                                          size: 48,
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.4),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l.statementsNoInvoiceSuggestions,
                                          style: tt.bodyMedium?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isNarrow =
                                          constraints.maxWidth < 680;
                                      if (isNarrow) {
                                        return Column(
                                          children: [
                                            transactionPanel(),
                                            const SizedBox(height: 12),
                                            Expanded(
                                              child: suggestionsPanel(setState),
                                            ),
                                          ],
                                        );
                                      }
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 280,
                                            child: transactionPanel(),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: suggestionsPanel(setState),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _badge(
    TextTheme tt,
    String text,
    Color bg,
    Color fg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: tt.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Widget _iconDetailRow(
    TextTheme tt,
    ColorScheme cs,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
