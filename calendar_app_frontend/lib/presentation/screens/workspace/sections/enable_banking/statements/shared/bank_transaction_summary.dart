import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/documents/hexora_status_badge.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import '../statements_formatters.dart';
import 'statements_shared_utils.dart';

/// Derives the linking status (label, color, icon) for a bank transaction.
///
/// Shared by [BankTransactionSummary] and the unified transaction panel
/// header, so both surfaces agree on what "linked" / "unlinked" / "not
/// applicable" mean for a given entry.
class BankTransactionStatus {
  const BankTransactionStatus._();

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static bool isLinked(Map<String, dynamic> entry) {
    final invoiceIds = _stringList(entry['invoiceIds']);
    final expenseIds =
        _stringList(entry['expenseDocumentIds'] ?? entry['expenseIds']);
    final singleLink = (entry['invoiceId'] ??
            entry['invoice_id'] ??
            entry['expenseDocumentId'] ??
            entry['expenseId'])
        ?.toString()
        .trim();
    return invoiceIds.isNotEmpty ||
        expenseIds.isNotEmpty ||
        (singleLink != null && singleLink.isNotEmpty);
  }

  static (String label, Color color, IconData icon) of(
    BuildContext context,
    Map<String, dynamic> entry, {
    String? notApplicableReason,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    String tx(String es, String en) => isEs ? es : en;
    final notApplicable = notApplicableReason?.trim() ?? '';

    if (notApplicable.isNotEmpty) {
      return (
        tx('No procede', 'Not applicable'),
        cs.onSurfaceVariant,
        Icons.block_outlined,
      );
    }
    if (isLinked(entry)) {
      return (
        tx('Vinculado', 'Linked'),
        HexoraDocumentStatus.issued.color(context),
        Icons.link_rounded,
      );
    }
    return (
      tx('Sin vincular', 'Unlinked'),
      HexoraDocumentStatus.warning.color(context),
      Icons.link_off_rounded,
    );
  }
}

/// Compact header block for a bank transaction inside the link side panel.
///
/// Shows only what is needed to link: amount, description, date and the
/// current linking status. Everything else (value date, counterparty,
/// merchant, balance, batch, linked documents, notes) sits behind a
/// "Ver detalles" expander so the panel stays focused on the matches.
class BankTransactionSummary extends StatefulWidget {
  const BankTransactionSummary({
    super.key,
    required this.entry,
    this.notApplicableReason,
    this.initiallyExpanded = false,
  });

  final Map<String, dynamic> entry;

  /// Reason recorded with "No procede", when the host tracks one.
  final String? notApplicableReason;
  final bool initiallyExpanded;

  @override
  State<BankTransactionSummary> createState() => _BankTransactionSummaryState();
}

class _BankTransactionSummaryState extends State<BankTransactionSummary> {
  late bool _expanded = widget.initiallyExpanded;

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  String _text(List<String> keys) =>
      StatementsSharedUtils.entryText(widget.entry, keys).trim();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    String tx(String es, String en) => isEs ? es : en;

    final entry = widget.entry;
    final amountRaw = _text(const ['amount']);
    final amountValue = StatementsFormatters.parseAmount(amountRaw) ?? 0;
    final isExpense = amountValue < 0;
    final amount = amountRaw.isEmpty
        ? '-'
        : StatementsFormatters.formatCurrency(context, amountRaw);
    final description =
        _text(const ['description', 'details', 'merchantNormalized']);
    final date = StatementsFormatters.formatDate(context, entry['date']);
    final valueDate =
        StatementsFormatters.formatDate(context, entry['valueDate']);
    final balanceRaw = _text(const ['balance']);
    final balance = balanceRaw.isEmpty
        ? ''
        : StatementsFormatters.formatCurrency(context, balanceRaw);
    final counterparty = _text(const [
      'clientName',
      'client_name',
      'providerName',
      'provider_name',
      'vendorName',
      'vendor_name',
      'counterpartyName',
      'counterparty_name',
    ]);
    final merchant = _text(const ['merchantNormalized']);
    final batch = _text(const ['_batchId', 'batchId']);
    final notes = _text(const ['notes']);

    final isLinked = BankTransactionStatus.isLinked(entry);
    final numbers = _stringList(entry['invoiceNumbers']);
    final linkedNumbers = numbers.isNotEmpty
        ? numbers.join(', ')
        : _text(const ['invoiceNumber', 'invoice_number']);
    final notApplicable = widget.notApplicableReason?.trim() ?? '';

    final (statusLabel, statusColor, statusIcon) = BankTransactionStatus.of(
      context,
      entry,
      notApplicableReason: widget.notApplicableReason,
    );
    final accent = isExpense ? cs.error : cs.primary;

    final details = <(String, String)>[
      if (valueDate.isNotEmpty && valueDate != date)
        (tx('Fecha valor', 'Value date'), valueDate),
      if (counterparty.isNotEmpty)
        (tx('Cliente / Proveedor', 'Customer / Vendor'), counterparty),
      if (merchant.isNotEmpty && merchant != counterparty)
        (tx('Comercio', 'Merchant'), merchant),
      if (balance.isNotEmpty) (tx('Saldo', 'Balance'), balance),
      if (isLinked && linkedNumbers.isNotEmpty)
        (tx('Documentos vinculados', 'Linked documents'), linkedNumbers),
      if (notApplicable.isNotEmpty)
        (tx('Motivo no procede', 'Not applicable reason'), notApplicable),
      if (notes.isNotEmpty) (tx('Notas', 'Notes'), notes),
      if (batch.isNotEmpty) (tx('Lote', 'Batch'), batch),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: dark ? 0.22 : 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              HexoraStatusBadge(
                label: statusLabel,
                color: statusColor,
                leading: Icon(statusIcon, size: 12, color: statusColor),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  date.isEmpty ? '-' : date,
                  style: t.caption.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              if (details.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize:
                        const Size(0, HexoraDimensions.buttonCompact),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _expanded
                        ? tx('Ocultar detalles', 'Hide details')
                        : tx('Ver detalles', 'View details'),
                    style: t.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !_expanded || details.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Divider(
                          height: 10,
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                        for (final (label, value) in details)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 128,
                                  child: Text(
                                    label,
                                    style: t.caption.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    value,
                                    style: t.caption.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
