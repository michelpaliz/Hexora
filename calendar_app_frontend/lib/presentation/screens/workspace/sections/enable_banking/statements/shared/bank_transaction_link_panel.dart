import 'package:flutter/material.dart';

import '../statements_controller.dart';
import 'invoice_link/invoice_link_dialog.dart';
import 'statements_ai_match_suggest_dialog.dart';

/// Which linking surface [BankTransactionLinkPanel] shows.
enum BankTransactionLinkMode {
  /// Suggested invoice/expense matches, with a "link manually" escape hatch.
  suggestions,

  /// The manual invoice/expense link wizard.
  manual,
}

/// Side-panel content for linking a bank transaction to invoices or expenses.
///
/// Used by the bank transactions table and the insights chat; both dock it
/// with [HexoraSidePanelLayout] instead of pushing a route. It starts on the
/// suggested matches (or the manual wizard) and switches to the manual wizard
/// in place; the wizard's header back button returns to the suggestions.
///
/// Each surface is built once per mode and kept: the suggestion surface holds
/// its state in closures, so going back shows the matches already loaded
/// instead of querying them again.
class BankTransactionLinkPanel extends StatefulWidget {
  const BankTransactionLinkPanel({
    super.key,
    required this.controller,
    required this.entry,
    required this.expenseOnly,
    required this.onClose,
    this.initialMode = BankTransactionLinkMode.suggestions,
    this.onMarkNotApplicable,
    this.notApplicableReason,
    this.showHeader = true,
  });

  final StatementsController controller;
  final Map<String, dynamic> entry;
  final bool expenseOnly;
  final VoidCallback onClose;
  final BankTransactionLinkMode initialMode;

  /// Categorizes the transaction as "No procede" (not an invoice payment).
  /// Hidden when the host has no such flow.
  final Future<void> Function()? onMarkNotApplicable;
  final String? notApplicableReason;

  /// False when a host (the unified transaction panel) already renders a
  /// shared header with the transaction's amount, date and status, so this
  /// panel only contributes its scrollable body and footer.
  final bool showHeader;

  @override
  State<BankTransactionLinkPanel> createState() =>
      _BankTransactionLinkPanelState();
}

class _BankTransactionLinkPanelState extends State<BankTransactionLinkPanel>
    with AutomaticKeepAliveClientMixin {
  late BankTransactionLinkMode _mode = widget.initialMode;
  final Map<BankTransactionLinkMode, Widget> _surfaces = {};

  @override
  bool get wantKeepAlive => true;

  void _showMode(BankTransactionLinkMode mode) {
    if (!mounted) return;
    setState(() => _mode = mode);
  }

  Widget _buildSurface(BuildContext context, BankTransactionLinkMode mode) {
    switch (mode) {
      case BankTransactionLinkMode.suggestions:
        return StatementsAiMatchSuggestDialog.buildInline(
          context: context,
          s: widget.controller,
          entry: widget.entry,
          onClose: widget.onClose,
          onManual: () async => _showMode(BankTransactionLinkMode.manual),
          onMarkNotApplicable: widget.onMarkNotApplicable,
          notApplicableReason: widget.notApplicableReason,
          showHeader: widget.showHeader,
        );
      case BankTransactionLinkMode.manual:
        final cameFromSuggestions =
            widget.initialMode == BankTransactionLinkMode.suggestions;
        return InvoiceLinkDialog.buildInline(
          context: context,
          s: widget.controller,
          entry: widget.entry,
          expenseOnly: widget.expenseOnly,
          onClose: widget.onClose,
          onBack: cameFromSuggestions
              ? () => _showMode(BankTransactionLinkMode.suggestions)
              : null,
          notApplicableReason: widget.notApplicableReason,
          embedded: true,
          showHeader: widget.showHeader,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final surface =
        _surfaces.putIfAbsent(_mode, () => _buildSurface(context, _mode));
    return KeyedSubtree(key: ValueKey(_mode), child: surface);
  }
}
