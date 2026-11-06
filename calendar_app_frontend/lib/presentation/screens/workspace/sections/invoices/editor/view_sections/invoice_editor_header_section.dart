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
    return _InvoiceFlowTopBar(
      selectedClientName: selectedClientName,
      showBack: state.widget.embedded,
      backLabel: l.budgetBackCta,
      onBack: () => state._requestClose(),
      onClientTapped: () => state._goToStep(0),
    );
  }
}
