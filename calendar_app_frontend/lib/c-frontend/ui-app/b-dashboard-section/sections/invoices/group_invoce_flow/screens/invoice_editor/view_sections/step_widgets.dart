part of '../invoice_editor_screen.dart';

enum _StepState { complete, current, locked }

class _StepDivider extends StatelessWidget {
  final Color color;
  const _StepDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: VerticalDivider(
        width: 12,
        thickness: 1,
        color: color,
      ),
    );
  }
}

class _CompactStepsPanel extends StatelessWidget {
  final Widget stepChips;
  final VoidCallback? onSave;
  final VoidCallback? onPreview;
  final VoidCallback? onIssue;
  final bool saving;
  final bool issuing;
  final String? saveTooltip;
  final String? previewTooltip;
  final String? issueTooltip;

  const _CompactStepsPanel({
    required this.stepChips,
    required this.onSave,
    required this.onPreview,
    required this.onIssue,
    required this.saving,
    required this.issuing,
    this.saveTooltip,
    this.previewTooltip,
    this.issueTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    Widget actionIcon({
      required String? tooltip,
      required VoidCallback? onPressed,
      required Widget icon,
    }) {
      final button = IconButton(
        onPressed: onPressed,
        icon: icon,
        color: onPressed == null ? cs.onSurfaceVariant : cs.primary,
      );
      if (tooltip == null || tooltip.isEmpty) return button;
      return Tooltip(message: tooltip, child: button);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stepChips,
        const SizedBox(height: 8),
        Row(
          children: [
            actionIcon(
              tooltip: saveTooltip ?? l.invoiceSaveDraftCta,
              onPressed: onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
            actionIcon(
              tooltip: previewTooltip ?? l.invoicePreviewCta,
              onPressed: onPreview,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
            actionIcon(
              tooltip: issueTooltip ?? l.invoiceIssueCta,
              onPressed: onIssue,
              icon: issuing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}
