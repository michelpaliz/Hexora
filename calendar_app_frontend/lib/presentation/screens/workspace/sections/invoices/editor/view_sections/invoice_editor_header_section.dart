part of '../invoice_editor_screen.dart';

class _InvoiceEditorHeaderSection extends StatelessWidget {
  const _InvoiceEditorHeaderSection({
    required this.state,
    required this.l,
    required this.selectedClientName,
  });

  final _InvoiceEditorScreenState state;
  final AppLocalizations l;
  final String selectedClientName;

  @override
  Widget build(BuildContext context) {
    // The client step already shows the selected client in the details column.
    // Do not spend a full header row repeating that identity above the wizard.
    // Keep the context chip for later steps where it remains useful as a
    // shortcut back to client selection.
    if (state._tabController.index == 0) {
      return const SizedBox.shrink();
    }
    return _InvoiceFlowTopBar(
      selectedClientName: selectedClientName,
      // The workspace tab already provides a close/back affordance. Keeping a
      // second one above the wizard rail duplicates that action.
      showBack: false,
      backLabel: l.budgetBackCta,
      onBack: () => state._requestClose(),
      onClientTapped: () => state._goToStep(0),
    );
  }
}
