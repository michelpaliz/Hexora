part of 'invoice_editor_screen.dart';

class _InvoiceEditorView extends StatelessWidget {
  const _InvoiceEditorView({required this.state});

  final _InvoiceEditorScreenState state;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: state._c,
      builder: (context, _) {
        final l = AppLocalizations.of(context)!;
        final hasClient = state._c.clientId != null;
        final hasLines = state._c.hasBillableEntries;
        final invoiceDate = state._c.invoiceDate.value;
        final dueDate = state._c.dueDate.value;
        final datesComplete = invoiceDate != null;
        final invalidDates =
            invoiceDate != null && dueDate != null && dueDate.isBefore(invoiceDate);
        final hasSavedDraft = state._c.savedInvoice != null;
        final step1Complete =
            hasClient && datesComplete && hasLines && !invalidDates;
        final canSaveDraft = !state._c.saving;
        final canPreview = step1Complete && hasSavedDraft;
        final canIssue =
            !state._c.issuing && step1Complete && state._c.previewedPdf;
        final reinforceIssue = canIssue && state._c.previewedPdf;

        final step1Missing = <String>[
          if (!hasClient) l.invoicePreviewNeedsClient,
          if (!datesComplete) l.invoicePreviewNeedsDate,
          if (invalidDates) l.invoicePreviewInvalidDates,
          if (!hasLines) l.invoicePreviewNeedsLines,
        ];
        final previewReason = !canPreview
            ? (step1Missing.isNotEmpty
                ? step1Missing.first
                : (hasSavedDraft ? '' : l.invoicePreviewNeedsDraft))
            : null;
        final issueReason = !canIssue
            ? (!state._c.previewedPdf
                ? l.invoiceIssueNeedsPreview
                : (step1Missing.isNotEmpty ? step1Missing.first : ''))
            : null;

        final step1State =
            step1Complete ? _StepState.complete : _StepState.current;
        final step2State = state._c.previewedPdf
            ? _StepState.complete
            : (canPreview ? _StepState.current : _StepState.locked);
        final step3State = canIssue ? _StepState.current : _StepState.locked;

        Widget stepChip({
          required String label,
          required _StepState stateValue,
          VoidCallback? onTap,
          String? tooltip,
        }) {
          final compact = stateValue == _StepState.complete;
          final bg = stateValue == _StepState.complete
              ? cs.tertiaryContainer
              : stateValue == _StepState.current
                  ? cs.primaryContainer
                  : cs.surfaceContainerHighest;
          final fg = stateValue == _StepState.complete
              ? cs.onTertiaryContainer
              : stateValue == _StepState.current
                  ? cs.onPrimaryContainer
                  : cs.onSurfaceVariant;
          final icon = stateValue == _StepState.complete
              ? Icons.check_circle
              : stateValue == _StepState.current
                  ? Icons.circle
                  : Icons.lock_outline;
          final effectiveTooltip = compact ? label : tooltip;
          final chip = Container(
            padding: compact
                ? const EdgeInsets.all(6)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: fg,
                ),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: t.bodySmall.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );

          final tappable = onTap != null
              ? InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  focusColor: cs.primary.withValues(alpha: 0.12),
                  hoverColor: cs.primary.withValues(alpha: 0.08),
                  child: chip,
                )
              : chip;
          if (effectiveTooltip == null || effectiveTooltip.isEmpty) {
            return tappable;
          }
          return Tooltip(message: effectiveTooltip, child: tappable);
        }

        void showStep1Missing() {
          if (step1Missing.isEmpty) return;
          showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l.invoiceStepCreateTitle),
              content: Text(step1Missing.map((e) => '• $e').join('\n')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            ),
          );
        }

        final content = Scaffold(
          backgroundColor: cs.surfaceContainerLowest,
          appBar: kIsWeb
              ? null
              : InvoiceEditorAppBar(
                  titleStyle: t.titleLarge,
                  saving: state._c.saving,
                  issuing: state._c.issuing,
                  onSaveDraft: () => state._c.handleSaveDraft(context),
                  onIssue: () => state._c.issue(context),
                  showClose: state.widget.embedded,
                  onClose: state.widget.embedded ? state._handleClose : null,
                ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final headerLeft = InvoiceHeaderFields(
                clients: state.widget.clients,
                clientId: state._c.clientId,
                onClientChanged: state._c.setClientId,
                currencyController: state._c.currency,
                invoiceDate: state._c.invoiceDate,
                dueDate: state._c.dueDate,
                onPickInvoiceDate: () =>
                    state._c.pickDate(context, state._c.invoiceDate),
                onPickDueDate: () =>
                    state._c.pickDate(context, state._c.dueDate),
              );

              final draft = state._c.savedInvoice?.status == 'draft'
                  ? state._c.savedInvoice
                  : null;
              final pendingDrafts = state._c.pendingDrafts
                  .where((inv) => inv.status == 'draft')
                  .where((inv) => draft == null || inv.id != draft.id)
                  .toList();
              final hasBlockingDrafts = pendingDrafts.isNotEmpty;
              final draftBanner = draft == null
                  ? null
                  : _DraftBanner(
                      draft: draft,
                      previewing: state._c.previewedPdf,
                      deleting: state._c.deletingDraft,
                      onPreview: () => state._c.previewPdf(context),
                      onDelete: () => state._c.deleteDraft(context),
                    );

              final stepChipsRow = Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  stepChip(
                    label: l.invoiceStepCreateShort,
                    stateValue: step1State,
                    onTap: step1Missing.isNotEmpty ? showStep1Missing : null,
                    tooltip: step1Missing.isNotEmpty
                        ? step1Missing.map((e) => '• $e').join('\n')
                        : null,
                  ),
                  _StepDivider(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  stepChip(
                    label: l.invoiceStepPreviewShort,
                    stateValue: step2State,
                  ),
                  _StepDivider(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  stepChip(
                    label: l.invoiceStepIssueShort,
                    stateValue: step3State,
                  ),
                ],
              );

              final stepsHeader = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  stepChipsRow,
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, actionConstraints) {
                      final actionWide = actionConstraints.maxWidth >= 820;

                      Widget actionColumn({
                        required Widget button,
                        String? helper,
                        String? helperBadge,
                      }) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            button,
                            if (helper != null && helper.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 280),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (helperBadge != null &&
                                        helperBadge.isNotEmpty) ...[
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: cs.outlineVariant
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          helperBadge,
                                          style: t.bodySmall.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        helper,
                                        style: t.bodySmall.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      }

                      final saveButton = OutlinedButton.icon(
                        onPressed: canSaveDraft
                            ? () => state._c.handleSaveDraft(context)
                            : null,
                        icon: state._c.saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          state._c.saving ? l.savingLabel : l.invoiceSaveDraftCta,
                        ),
                      );

                      final previewColumn = actionColumn(
                        button: OutlinedButton.icon(
                          onPressed:
                              canPreview ? () => state._c.previewPdf(context) : null,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(l.invoicePreviewCta),
                        ),
                        helper: previewReason,
                        helperBadge: '2',
                      );

                      final issueColumn = actionColumn(
                        button: FilledButton.icon(
                          onPressed: canIssue ? () => state._c.issue(context) : null,
                          style: reinforceIssue
                              ? FilledButton.styleFrom(
                                  elevation: 3,
                                  shadowColor:
                                      cs.primary.withValues(alpha: 0.35),
                                )
                              : null,
                          icon: state._c.issuing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            state._c.issuing
                                ? l.invoiceIssuingLabel
                                : l.invoiceIssueCta,
                          ),
                        ),
                        helper: issueReason,
                        helperBadge: '3',
                      );

                      if (actionWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: actionColumn(button: saveButton),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: previewColumn),
                            const SizedBox(width: 16),
                            Expanded(child: issueColumn),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          actionColumn(button: saveButton),
                          const SizedBox(height: 10),
                          previewColumn,
                          const SizedBox(height: 10),
                          issueColumn,
                        ],
                      );
                    },
                  ),
                ],
              );

              final selectedClientName = state._c.clientId == null
                  ? l.invoiceSelectClientLabel
                  : state.widget.clients
                      .firstWhere(
                        (c) => c.id == state._c.clientId,
                        orElse: () => GroupClient(
                          id: state._c.clientId!,
                          name: l.invoiceSelectClientLabel,
                          isActive: true,
                        ),
                      )
                      .name;

              final currency = state._c.currency.text.trim().isEmpty
                  ? 'EUR'
                  : state._c.currency.text.trim();

              final headerBar = Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: LayoutBuilder(
                  builder: (context, headerConstraints) {
                    final headerWide = headerConstraints.maxWidth >= 980;
                    final dividerColor =
                        cs.outlineVariant.withValues(alpha: 0.35);

                    final headerToggle = Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6, top: 4),
                        child: IconButton(
                          tooltip: state._headerCompact
                              ? l.invoiceHeaderExpandCta
                              : l.invoiceHeaderCompactCta,
                          icon: Icon(
                            state._headerCompact
                                ? Icons.unfold_more
                                : Icons.unfold_less,
                          ),
                          onPressed: () => state.setState(
                            () => state._headerCompact = !state._headerCompact,
                          ),
                        ),
                      ),
                    );

                    final headerContent = state._headerCompact
                        ? _HeaderCompactSummary(
                            clientName: selectedClientName,
                            currency: currency,
                            invoiceDate: invoiceDate,
                            dueDate: dueDate,
                          )
                        : headerLeft;

                    final contextBand = Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
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
                            const SizedBox(height: 12),
                            draftBanner,
                          ],
                          if (pendingDrafts.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _PendingDraftsList(
                              drafts: pendingDrafts,
                              clients: state.widget.clients,
                              deleting: state._c.deletingDraft,
                              onPreview: (draft) =>
                                  state._c.previewDraft(context, draft),
                              onDelete: (draft) =>
                                  state._c.deleteDraftById(context, draft),
                            ),
                          ],
                        ],
                      ),
                    );

                    final actionContent = state._headerCompact
                        ? _CompactStepsPanel(
                            stepChips: stepChipsRow,
                            onSave: canSaveDraft
                                ? () => state._c.handleSaveDraft(context)
                                : null,
                            onPreview:
                                canPreview ? () => state._c.previewPdf(context) : null,
                            onIssue:
                                canIssue ? () => state._c.issue(context) : null,
                            saving: state._c.saving,
                            issuing: state._c.issuing,
                            saveTooltip: hasBlockingDrafts
                                ? l.invoiceWarningPendingDrafts
                                : l.invoiceSaveDraftCta,
                            previewTooltip:
                                canPreview ? l.invoicePreviewCta : previewReason,
                            issueTooltip:
                                canIssue ? l.invoiceIssueCta : issueReason,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              stepsHeader,
                              if (hasBlockingDrafts) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: cs.errorContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          size: 18, color: cs.onErrorContainer),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l.invoiceWarningPendingDrafts,
                                          style: t.bodySmall.copyWith(
                                            color: cs.onErrorContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );

                    final actionBand = Container(
                      padding: const EdgeInsets.all(16),
                      child: hasBlockingDrafts
                          ? AbsorbPointer(
                              child: Opacity(opacity: 0.6, child: actionContent),
                            )
                          : actionContent,
                    );

                    if (headerWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerToggle,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: contextBand),
                              Container(
                                width: 1,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8),
                                color: dividerColor,
                              ),
                              Expanded(child: actionBand),
                            ],
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerToggle,
                        contextBand,
                        Divider(height: 1, color: dividerColor),
                        actionBand,
                      ],
                    );
                  },
                ),
              );

              final linesSection = InvoiceContentSection(
                useBlocks: state._c.useBlocks,
                onModeChanged: state._c.setUseBlocks,
                blocks: state._c.blocks,
                lines: state._c.lines,
                onChanged: state._c.notifyUi,
                total: state._c.total,
              );

              final gatedLinesSection = hasBlockingDrafts
                  ? AbsorbPointer(
                      child: Opacity(
                        opacity: 0.6,
                        child: linesSection,
                      ),
                    )
                  : linesSection;

              return Form(
                key: state._c.formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      headerBar,
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(child: gatedLinesSection),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        if (state.widget.embedded) return content;

        return WillPopScope(
          onWillPop: () async {
            state._handleClose();
            return false;
          },
          child: content,
        );
      },
    );
  }
}

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

class _HeaderCompactSummary extends StatelessWidget {
  final String clientName;
  final String currency;
  final DateTime? invoiceDate;
  final DateTime? dueDate;

  const _HeaderCompactSummary({
    required this.clientName,
    required this.currency,
    required this.invoiceDate,
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final dateFmt = DateFormat.yMMMd();
    final inv = invoiceDate == null ? '-' : dateFmt.format(invoiceDate!);
    final due = dueDate == null ? '-' : dateFmt.format(dueDate!);

    Widget currencyPill() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          currency.toUpperCase(),
          style: t.bodySmall.copyWith(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clientName,
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '${l.invoiceDateLabel}: $inv • ${l.invoiceDueDateLabel}: $due',
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        currencyPill(),
      ],
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

class _DraftBanner extends StatelessWidget {
  final Invoice draft;
  final bool previewing;
  final bool deleting;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  const _DraftBanner({
    required this.draft,
    required this.previewing,
    required this.deleting,
    required this.onPreview,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final number = draft.invoiceNumber.trim().isEmpty
        ? l.statusDraft
        : '${l.statusDraft} • ${draft.invoiceNumber}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note_outlined, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              number,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: l.invoicePreviewCta,
            onPressed: previewing ? null : onPreview,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: l.remove,
            onPressed: deleting ? null : onDelete,
            icon: Icon(Icons.delete_outline, color: cs.error),
          ),
        ],
      ),
    );
  }
}

class _PendingDraftsList extends StatelessWidget {
  final List<Invoice> drafts;
  final List<GroupClient> clients;
  final bool deleting;
  final ValueChanged<Invoice> onPreview;
  final ValueChanged<Invoice> onDelete;

  const _PendingDraftsList({
    required this.drafts,
    required this.clients,
    required this.deleting,
    required this.onPreview,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final dateFmt = DateFormat.yMMMd();

    String clientName(String id) {
      return clients
          .firstWhere(
            (c) => c.id == id,
            orElse: () => GroupClient(id: id, name: l.unknownClient, isActive: true),
          )
          .name;
    }

    String draftSubtitle(Invoice inv) {
      final date = inv.registeredAt ?? inv.issueDate;
      if (date == null) return clientName(inv.clientId);
      return '${clientName(inv.clientId)} • ${dateFmt.format(date)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.invoicePendingDraftsLabel,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final inv in drafts) ...[
            Row(
              children: [
                Icon(Icons.edit_note_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.invoiceNumber.trim().isEmpty
                            ? l.statusDraft
                            : inv.invoiceNumber,
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        draftSubtitle(inv),
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l.invoicePreviewCta,
                  onPressed: () => onPreview(inv),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                ),
                IconButton(
                  tooltip: l.remove,
                  onPressed: deleting ? null : () => onDelete(inv),
                  icon: Icon(Icons.delete_outline, color: cs.error),
                ),
              ],
            ),
            if (inv != drafts.last)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}
