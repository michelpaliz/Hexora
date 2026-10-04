import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/services/insights/insights_api.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import '../insights_chat_message.dart';
import '../insights_json_utils.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsBankIncomeLinking on InsightsChatSheetStateBase {
  @override
  void applyLinkedCandidatePatches({
    required ChatMessage message,
    required Map<String, dynamic> originalInvoiceRow,
    required Map<String, dynamic> candidate,
    required Map<String, dynamic> linkAction,
    required bool isEs,
  }) {
    final body = safeMap(linkAction['body']);
    final actionInvoiceIds = body?['invoiceIds'];
    final invoiceIds = actionInvoiceIds is List
        ? actionInvoiceIds
            .map((id) => id.toString().trim())
            .where((id) => id.isNotEmpty)
            .toList(growable: false)
        : <String>[];
    final originalInvoiceId =
        invoiceIdFromInsightsInvoiceRow(originalInvoiceRow);
    final affectedIds = invoiceIds.isNotEmpty
        ? invoiceIds
        : <String>[if (originalInvoiceId.isNotEmpty) originalInvoiceId];
    final tableRows = tableRowsFromMessage(message);
    final matchedInvoices = bankIncomeMatchedInvoices(candidate);

    setState(() {
      for (final invoiceId in affectedIds) {
        Map<String, dynamic>? affectedRow;
        for (final tableRow in tableRows) {
          if (invoiceIdFromInsightsInvoiceRow(tableRow) == invoiceId) {
            affectedRow = tableRow;
            break;
          }
        }
        if (affectedRow == null) {
          for (final matchedInvoice in matchedInvoices) {
            if (invoiceIdFromInsightsInvoiceRow(matchedInvoice) == invoiceId) {
              affectedRow = matchedInvoice;
              break;
            }
          }
        }
        affectedRow ??= originalInvoiceRow;
        final stateKey = '${messageKeyFor(message)}::$invoiceId';
        pendingInsightsInvoiceRowPatches[stateKey] = linkedInvoiceRowPatch(
          invoiceRow: affectedRow,
          incomeRow: candidate,
          isEs: isEs,
        );
      }
    });
  }

  @override
  Future<void> linkBankIncomeCandidate({
    required ChatMessage message,
    required Map<String, dynamic> invoiceRow,
    required Map<String, dynamic> candidate,
    required String stateKey,
    required bool isEs,
  }) async {
    final linkAction = linkInvoiceToEntryAction(candidate);
    if (linkAction == null) {
      throw Exception(isEs
          ? 'El ingreso no incluye acción de vínculo.'
          : 'The income candidate has no link action.');
    }
    if (mounted) {
      setState(() => linkingBankIncomeRows.add(stateKey));
    }
    try {
      await runtime.executeJsonAction(linkAction);
      if (mounted) {
        applyLinkedCandidatePatches(
          message: message,
          originalInvoiceRow: invoiceRow,
          candidate: candidate,
          linkAction: linkAction,
          isEs: isEs,
        );
      }
      if (messageUsesRemoteTableData(message)) {
        await reloadRemoteTableForMessage(message);
      } else {
        try {
          await runtime.refreshMessageFromSourceAction(
            message: message,
            groupId: widget.groupId,
          );
        } on InsightsApiException catch (error) {
          debugPrint(
            '[insights_link_income] post-link chat refresh skipped: '
            'status=${error.statusCode} code=${error.code} '
            'message=${error.message}',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => linkingBankIncomeRows.remove(stateKey));
      }
    }
  }

  @override
  Future<void> searchAndLinkBankIncomeForInvoiceRow(
    ChatMessage message,
    Map<String, dynamic> row,
    bool isEs,
  ) async {
    final searchAction = rowBankIncomeSearchAction(row);
    if (searchAction == null) return;
    final invoiceId = invoiceIdFromInsightsInvoiceRow(row);
    final stateKey = '${messageKeyFor(message)}::$invoiceId';
    if (searchingBankIncomeRows.contains(stateKey) ||
        linkingBankIncomeRows.contains(stateKey)) {
      return;
    }
    setState(() => searchingBankIncomeRows.add(stateKey));
    try {
      final responseFuture = runtime.executeJsonAction(searchAction);
      final candidate = await showBankIncomeCandidatesDialog(
        responseFuture: responseFuture,
        invoiceRow: row,
        onLinkCandidate: (candidate) => linkBankIncomeCandidate(
          message: message,
          invoiceRow: row,
          candidate: candidate,
          stateKey: stateKey,
          isEs: isEs,
        ),
        isEs: isEs,
      );
      if (!mounted || candidate == null) return;
      final grouped = isGroupedBankIncomeCandidate(candidate);
      final count = bankIncomeMatchedInvoiceCount(candidate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            grouped
                ? (isEs
                    ? 'Ingreso vinculado correctamente con $count facturas.'
                    : 'Income linked successfully to $count invoices.')
                : (isEs ? 'Ingreso vinculado a la factura.' : 'Income linked.'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.isEmpty
                ? (isEs ? 'No se pudo vincular.' : 'Could not link.')
                : msg,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          searchingBankIncomeRows.remove(stateKey);
          linkingBankIncomeRows.remove(stateKey);
        });
      }
    }
  }

  @override
  Widget buildBankIncomeSearchCell(
    BuildContext context, {
    required ChatMessage message,
    required Map<String, dynamic> row,
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
  }) {
    final action = rowBankIncomeSearchAction(row);
    if (action == null) return const SizedBox.shrink();
    final invoiceId = invoiceIdFromInsightsInvoiceRow(row);
    final stateKey = '${messageKeyFor(message)}::$invoiceId';
    final loading = searchingBankIncomeRows.contains(stateKey) ||
        linkingBankIncomeRows.contains(stateKey);
    final label = action['label']?.toString().trim().isNotEmpty == true
        ? action['label'].toString().trim()
        : (isEs ? 'Buscar ingreso' : 'Find income');
    return Tooltip(
      message: label,
      child: IconButton.filledTonal(
        onPressed: loading
            ? null
            : () => searchAndLinkBankIncomeForInvoiceRow(message, row, isEs),
        icon: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              )
            : const Icon(Icons.manage_search_rounded, size: 16),
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: cs.primary.withValues(alpha: 0.16),
          foregroundColor: cs.primary,
          disabledBackgroundColor:
              cs.surfaceContainerHighest.withValues(alpha: 0.35),
          disabledForegroundColor: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget buildUnlinkedInvoiceStatusCell({
    required String value,
    required ColorScheme cs,
    required AppTypography t,
    required bool isDark,
  }) {
    const accent = Color(0xFFFFB020);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link_off_rounded,
            size: 13,
            color: isDark ? accent : const Color(0xFF9A5B00),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.caption.copyWith(
              color: isDark ? accent : const Color(0xFF7A4600),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildLinkedInvoiceStatusCell({
    required String value,
    required ColorScheme cs,
    required AppTypography t,
    required bool isDark,
  }) {
    final accent = isDark ? Colors.greenAccent : const Color(0xFF0F9F72);
    final label = value.trim().isEmpty ? 'Vinculada/pagada' : value.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.16 : 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: 13, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.caption.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

}
