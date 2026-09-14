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
  final Widget? trailing;

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
    this.trailing,
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
        if (trailing != null) ...[
          const SizedBox(height: 6),
          trailing!,
        ],
      ],
    );
  }
}

class _InvoiceDraftStatusChip extends StatelessWidget {
  const _InvoiceDraftStatusChip({
    required this.controller,
    required this.t,
    required this.cs,
  });

  final InvoiceEditorController controller;
  final AppTypography t;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final hasDraft = controller.savedInvoice != null ||
        (controller.editingDraftId ?? '').trim().isNotEmpty;
    final text = controller.draftSaveFailed
        ? (isEs ? 'No se pudo guardar' : 'Save failed')
        : controller.saving
            ? (isEs ? 'Guardando...' : 'Saving...')
            : controller.draftDirty
                ? (isEs ? 'Cambios sin guardar' : 'Unsaved changes')
                : hasDraft
                    ? (isEs ? 'Borrador guardado' : 'Draft saved')
                    : (isEs ? 'Sin guardar' : 'Not saved');
    final icon = controller.draftSaveFailed
        ? Icons.cloud_off_outlined
        : controller.saving
            ? Icons.sync_rounded
            : controller.draftDirty
                ? Icons.edit_note_rounded
                : hasDraft
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_queue_outlined;
    final color = controller.draftSaveFailed
        ? cs.error
        : controller.saving || controller.draftDirty
            ? cs.tertiary
            : cs.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: t.bodySmall.copyWith(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
