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
    final steps = [
      l.invoiceCustomerTitle,
      l.invoiceDatesTitle,
      l.invoiceLinesTitle,
      l.invoiceStepPreviewShort,
    ];

    return AnimatedBuilder(
      animation: state._tabController,
      builder: (context, _) {
        return _InvoiceFlowTopBar(
          steps: steps,
          currentStep: state._tabController.index,
          selectedClientName: selectedClientName,
          showBack: state.widget.embedded,
          backLabel: l.budgetBackCta,
          onBack: () => state._requestClose(),
          onStepTapped: state._goToStep,
          onClientTapped: () => state._goToStep(0),
        );
      },
    );
  }
}
