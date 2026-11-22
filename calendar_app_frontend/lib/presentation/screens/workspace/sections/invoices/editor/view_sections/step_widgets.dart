part of '../invoice_editor_screen.dart';

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
            : hasDraft
                ? cs.primary
                : cs.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      label: text,
      child: AnimatedContainer(
        key: const Key('invoice-draft-status'),
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.saving)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
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
      ),
    );
  }
}

class _InvoiceFlowTopBar extends StatelessWidget {
  const _InvoiceFlowTopBar({
    required this.selectedClientName,
    required this.showBack,
    required this.backLabel,
    required this.onBack,
    required this.onClientTapped,
  });

  final String selectedClientName;
  final bool showBack;
  final String backLabel;
  final VoidCallback onBack;
  final VoidCallback onClientTapped;

  @override
  Widget build(BuildContext context) {
    final contextChips = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InvoiceClientContextChip(
          clientName: selectedClientName,
          onTap: onClientTapped,
        ),
      ],
    );
    final backButton = HexoraButton(
      key: const Key('invoice-flow-back'),
      onPressed: onBack,
      icon: Icons.arrow_back_rounded,
      label: backLabel,
      variant: HexoraButtonVariant.secondary,
    );

    return Container(
      key: const Key('invoice-flow-top-bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      // Keep the client context part of the light-blue editor canvas rather
      // than introducing a second full-width white surface above the form.
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          if (showBack) backButton,
          const Spacer(),
          contextChips,
        ],
      ),
    );
  }
}

class _InvoiceClientContextChip extends StatelessWidget {
  const _InvoiceClientContextChip({
    required this.clientName,
    required this.onTap,
  });

  final String clientName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final isSpanish = l.localeName.toLowerCase().startsWith('es');

    return Tooltip(
      message: isSpanish ? 'Cambiar cliente' : 'Change customer',
      child: InkWell(
        key: const Key('invoice-client-context'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 210),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
