import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/documents/hexora_status_badge.dart';
import 'package:hexora/presentation/shared/widgets/hexora_section_tabs.dart';
import 'package:hexora/presentation/shared/widgets/panels/hexora_side_panel.dart';

import '../shared/bank_transaction_link_panel.dart';
import '../shared/bank_transaction_summary.dart';
import '../statements_controller.dart';
import '../statements_formatters.dart';
import '../statements_shared.dart';
import 'statements_all_data_details.dart';

/// Which section of [StatementsTransactionDetailLinkPanel] is active.
///
/// Declaration order matches the tab/TabBarView order, so `.index` (details
/// = 0, link = 1) doubles as the [TabController.initialIndex].
enum StatementsTransactionPanelTab { details, link }

/// Unified transaction side panel with two compact tabs: "Detalles" and
/// "Vincular".
///
/// One shared header (title, amount, date and linking status) sits above the
/// tabs, so neither tab repeats that summary. Both tabs are backed by a
/// [TabBarView], which keeps both mounted — switching tabs never re-issues
/// the suggested-matches request or loses the manual wizard's progress, and
/// each tab shows only the footer actions relevant to it.
class StatementsTransactionDetailLinkPanel extends StatefulWidget {
  const StatementsTransactionDetailLinkPanel({
    super.key,
    required this.controller,
    required this.entry,
    required this.onClose,
    this.initialTab = StatementsTransactionPanelTab.details,
    this.initialLinkMode = BankTransactionLinkMode.suggestions,
    this.onMarkNotApplicable,
    this.notApplicableReason,
  });

  final StatementsController controller;
  final Map<String, dynamic> entry;
  final VoidCallback onClose;
  final StatementsTransactionPanelTab initialTab;
  final BankTransactionLinkMode initialLinkMode;

  /// Categorizes the transaction as "No procede" (not an invoice payment).
  /// Hidden on the Vincular tab when the host has no such flow.
  final Future<void> Function()? onMarkNotApplicable;
  final String? notApplicableReason;

  @override
  State<StatementsTransactionDetailLinkPanel> createState() =>
      _StatementsTransactionDetailLinkPanelState();
}

class _StatementsTransactionDetailLinkPanelState
    extends State<StatementsTransactionDetailLinkPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab.index,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');

    final entry = widget.entry;
    final amountText = StatementsShared.entryText(entry, ['amount']);
    final amountValue = StatementsFormatters.parseAmount(amountText) ?? 0;
    final isExpense = amountValue < 0;
    final accent = isExpense ? cs.error : cs.primary;
    final amount = amountText.isEmpty
        ? '-'
        : StatementsFormatters.formatCurrency(context, amountText);
    final date = StatementsFormatters.formatDate(context, entry['date']);
    final description =
        StatementsShared.entryText(entry, ['description', 'details']).trim();
    final title =
        description.isEmpty ? (isEs ? 'Movimiento' : 'Transaction') : description;
    final (statusLabel, statusColor, statusIcon) = BankTransactionStatus.of(
      context,
      entry,
      notApplicableReason: widget.notApplicableReason,
    );

    return HexoraSidePanel(
      embedded: true,
      onDismiss: widget.onClose,
      padding: EdgeInsets.zero,
      header: HexoraSidePanelHeader(
        leading: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            size: 17,
            color: accent,
          ),
        ),
        title: title,
        subtitle: '$amount · ${date.isEmpty ? '-' : date}',
        trailing: HexoraStatusBadge(
          label: statusLabel,
          color: statusColor,
          leading: Icon(statusIcon, size: 12, color: statusColor),
        ),
        onClose: widget.onClose,
        closeTooltip: l.close,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: HexoraSectionTabs(
              controller: _tabController,
              compact: true,
              tabs: [
                Tab(text: isEs ? 'Detalles' : 'Details'),
                Tab(text: isEs ? 'Vincular' : 'Link'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StatementsAllDataDetails.buildDetailsBody(
                  context,
                  l,
                  entry,
                  widget.controller,
                ),
                BankTransactionLinkPanel(
                  controller: widget.controller,
                  entry: entry,
                  expenseOnly: isExpense,
                  initialMode: widget.initialLinkMode,
                  onClose: widget.onClose,
                  onMarkNotApplicable: widget.onMarkNotApplicable,
                  notApplicableReason: widget.notApplicableReason,
                  showHeader: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
