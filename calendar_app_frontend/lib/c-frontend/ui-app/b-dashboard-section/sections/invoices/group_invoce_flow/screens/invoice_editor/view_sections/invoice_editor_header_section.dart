part of '../invoice_editor_screen.dart';

class _InvoiceEditorHeaderSection extends StatelessWidget {
  const _InvoiceEditorHeaderSection({
    required this.state,
    required this.l,
    required this.t,
    required this.cs,
    required this.headerLeft,
    required this.stepsHeader,
    required this.stepChipsRow,
    required this.draftBanner,
    required this.pendingDrafts,
    required this.hasBlockingDrafts,
    required this.selectedClientName,
    required this.currency,
    required this.invoiceDate,
    required this.dueDate,
    required this.canSaveDraft,
    required this.canPreview,
    required this.canIssue,
    required this.reinforceIssue,
    required this.previewReason,
    required this.issueReason,
  });

  final _InvoiceEditorScreenState state;
  final AppLocalizations l;
  final AppTypography t;
  final ColorScheme cs;
  final Widget headerLeft;
  final Widget stepsHeader;
  final Widget stepChipsRow;
  final _DraftBanner? draftBanner;
  final List<Invoice> pendingDrafts;
  final bool hasBlockingDrafts;
  final String selectedClientName;
  final String currency;
  final DateTime? invoiceDate;
  final DateTime? dueDate;
  final bool canSaveDraft;
  final bool canPreview;
  final bool canIssue;
  final bool reinforceIssue;
  final String? previewReason;
  final String? issueReason;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, headerConstraints) {
        final headerWide = headerConstraints.maxWidth >= 980;
        final dividerColor = cs.outlineVariant.withValues(alpha: 0.35);

        const compactToggleButton = SizedBox.shrink();

        final headerContent = const SizedBox.shrink();

        final hasContextContent = draftBanner != null;

        final contextBand = hasContextContent
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    hasBlockingDrafts
                        ? AbsorbPointer(
                            child: Opacity(
                              opacity: 0.6,
                              child: headerContent,
                            ),
                          )
                        : headerContent,
                    if (draftBanner != null) ...[
                      const SizedBox(height: 4),
                      draftBanner!,
                    ],
                  ],
                ),
              )
            : const SizedBox.shrink();

        final actionContent = state._headerCompact
            ? _CompactStepsPanel(
                stepChips: stepChipsRow,
                onSave: canSaveDraft
                    ? () => state._c.handleSaveDraft(context)
                    : null,
                onPreview:
                    canPreview ? () => state._c.previewPdf(context) : null,
                onIssue: canIssue ? () => state._c.issue(context) : null,
                saving: state._c.saving,
                issuing: state._c.issuing,
                saveTooltip: hasBlockingDrafts
                    ? l.invoiceWarningPendingDrafts
                    : l.invoiceSaveDraftCta,
                previewTooltip:
                    canPreview ? l.invoicePreviewCta : previewReason,
                issueTooltip: canIssue ? l.invoiceIssueCta : issueReason,
                trailing: compactToggleButton,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: stepsHeader),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: compactToggleButton,
                      ),
                    ],
                  ),
                  if (hasBlockingDrafts) const SizedBox(height: 10),
                ],
              );

        final actionBand = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: hasBlockingDrafts
              ? AbsorbPointer(
                  child: Opacity(opacity: 0.6, child: actionContent),
                )
              : actionContent,
        );

        if (headerWide) {
          if (!hasContextContent) {
            return actionBand;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: contextBand),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: dividerColor,
                  ),
                  Expanded(child: actionBand),
                ],
              ),
            ],
          );
        }

        if (!hasContextContent) return actionBand;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            contextBand,
            Divider(height: 1, color: dividerColor),
            actionBand,
          ],
        );
      },
    );
  }
}
