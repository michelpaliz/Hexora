import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_controller.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_app_bar.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoiceEditorScreen extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final String? initialClientId;
  final bool embedded;
  final ValueChanged<bool>? onClose;
  final VoidCallback? onDataChanged;

  const InvoiceEditorScreen({
    super.key,
    required this.group,
    required this.clients,
    this.initialClientId,
    this.embedded = false,
    this.onClose,
    this.onDataChanged,
  });

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  late final InvoiceEditorController _c;
  bool _changed = false;
  String? _lastSavedInvoiceId;
  String? _lastSavedInvoiceStatus;
  bool _headerCompact = false;

  @override
  void initState() {
    super.initState();
    _c = InvoiceEditorController(
      group: widget.group,
      clients: widget.clients,
      initialClientId: widget.initialClientId,
    );
    _c.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _c.removeListener(_handleControllerChange);
    _c.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    final saved = _c.savedInvoice;
    if (!_changed && saved != null) {
      _changed = true;
    }
    if (saved != null && widget.onDataChanged != null) {
      if (saved.id != _lastSavedInvoiceId ||
          saved.status != _lastSavedInvoiceStatus) {
        _lastSavedInvoiceId = saved.id;
        _lastSavedInvoiceStatus = saved.status;
        widget.onDataChanged!();
      }
    }
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!(_changed);
      return;
    }
    Navigator.of(context).pop(_changed);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final l = AppLocalizations.of(context)!;
        final hasClient = _c.clientId != null;
        final hasLines = _c.hasBillableEntries;
        final invoiceDate = _c.invoiceDate.value;
        final dueDate = _c.dueDate.value;
        final datesComplete = invoiceDate != null;
        final invalidDates =
            invoiceDate != null && dueDate != null && dueDate.isBefore(invoiceDate);
        final hasSavedDraft = _c.savedInvoice != null;
        final step1Complete =
            hasClient && datesComplete && hasLines && !invalidDates;
        final canSaveDraft = !_c.saving;
        final canPreview = step1Complete && hasSavedDraft;
        final canIssue =
            !_c.issuing && step1Complete && _c.previewedPdf;
        final reinforceIssue = canIssue && _c.previewedPdf;

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
            ? (!_c.previewedPdf
                ? l.invoiceIssueNeedsPreview
                : (step1Missing.isNotEmpty ? step1Missing.first : ''))
            : null;

        final step1State =
            step1Complete ? _StepState.complete : _StepState.current;
        final step2State = _c.previewedPdf
            ? _StepState.complete
            : (canPreview ? _StepState.current : _StepState.locked);
        final step3State =
            canIssue ? _StepState.current : _StepState.locked;

        Widget stepChip({
          required String label,
          required _StepState state,
          VoidCallback? onTap,
          String? tooltip,
        }) {
          final compact = state == _StepState.complete;
          final bg = state == _StepState.complete
              ? cs.tertiaryContainer
              : state == _StepState.current
                  ? cs.primaryContainer
                  : cs.surfaceContainerHighest;
          final fg = state == _StepState.complete
              ? cs.onTertiaryContainer
              : state == _StepState.current
                  ? cs.onPrimaryContainer
                  : cs.onSurfaceVariant;
          final icon = state == _StepState.complete
              ? Icons.check_circle
              : state == _StepState.current
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
                  child:
                      Text(MaterialLocalizations.of(context).okButtonLabel),
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
                  saving: _c.saving,
                  issuing: _c.issuing,
                  onSaveDraft: () => _c.handleSaveDraft(context),
                  onIssue: () => _c.issue(context),
                  showClose: widget.embedded,
                  onClose: widget.embedded ? _handleClose : null,
                ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final headerLeft = InvoiceHeaderFields(
                clients: widget.clients,
                clientId: _c.clientId,
                onClientChanged: _c.setClientId,
                currencyController: _c.currency,
                invoiceDate: _c.invoiceDate,
                dueDate: _c.dueDate,
                onPickInvoiceDate: () => _c.pickDate(context, _c.invoiceDate),
                onPickDueDate: () => _c.pickDate(context, _c.dueDate),
              );

              final draft = _c.savedInvoice?.status == 'draft'
                  ? _c.savedInvoice
                  : null;
              final pendingDrafts = _c.pendingDrafts
                  .where((inv) => inv.status == 'draft')
                  .where((inv) => draft == null || inv.id != draft.id)
                  .toList();
              final hasBlockingDrafts = pendingDrafts.isNotEmpty;
              final draftBanner = draft == null
                  ? null
                  : _DraftBanner(
                      draft: draft,
                      previewing: _c.previewedPdf,
                      deleting: _c.deletingDraft,
                      onPreview: () => _c.previewPdf(context),
                      onDelete: () => _c.deleteDraft(context),
                    );

              final stepChipsRow = Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  stepChip(
                    label: l.invoiceStepCreateShort,
                    state: step1State,
                    onTap: step1Missing.isNotEmpty ? showStep1Missing : null,
                    tooltip: step1Missing.isNotEmpty
                        ? step1Missing.map((e) => '• $e').join('\n')
                        : null,
                  ),
                  _StepDivider(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  stepChip(
                    label: l.invoiceStepPreviewShort,
                    state: step2State,
                  ),
                  _StepDivider(color: cs.outlineVariant.withValues(alpha: 0.5)),
                  stepChip(
                    label: l.invoiceStepIssueShort,
                    state: step3State,
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
                        bool primary = false,
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
                        onPressed:
                            canSaveDraft ? () => _c.handleSaveDraft(context) : null,
                        icon: _c.saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _c.saving ? l.savingLabel : l.invoiceSaveDraftCta,
                        ),
                      );

                      final previewColumn = actionColumn(
                        button: OutlinedButton.icon(
                          onPressed:
                              canPreview ? () => _c.previewPdf(context) : null,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(l.invoicePreviewCta),
                        ),
                        helper: previewReason,
                        helperBadge: '2',
                      );

                      final issueColumn = actionColumn(
                        button: FilledButton.icon(
                          onPressed: canIssue ? () => _c.issue(context) : null,
                          style: reinforceIssue
                              ? FilledButton.styleFrom(
                                  elevation: 3,
                                  shadowColor:
                                      cs.primary.withValues(alpha: 0.35),
                                )
                              : null,
                          icon: _c.issuing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _c.issuing
                                ? l.invoiceIssuingLabel
                                : l.invoiceIssueCta,
                          ),
                        ),
                        helper: issueReason,
                        helperBadge: '3',
                        primary: true,
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

              final selectedClientName = _c.clientId == null
                  ? l.invoiceSelectClientLabel
                  : widget.clients
                      .firstWhere(
                        (c) => c.id == _c.clientId,
                        orElse: () => GroupClient(
                          id: _c.clientId!,
                          name: l.invoiceSelectClientLabel,
                          isActive: true,
                        ),
                      )
                      .name;

              final currency = _c.currency.text.trim().isEmpty
                  ? 'EUR'
                  : _c.currency.text.trim();

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
                          tooltip: _headerCompact
                              ? l.invoiceHeaderExpandCta
                              : l.invoiceHeaderCompactCta,
                          icon: Icon(
                            _headerCompact
                                ? Icons.unfold_more
                                : Icons.unfold_less,
                          ),
                          onPressed: () => setState(
                            () => _headerCompact = !_headerCompact,
                          ),
                        ),
                      ),
                    );

                    final headerContent = _headerCompact
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
                              clients: widget.clients,
                              deleting: _c.deletingDraft,
                              onPreview: (draft) =>
                                  _c.previewDraft(context, draft),
                              onDelete: (draft) =>
                                  _c.deleteDraftById(context, draft),
                            ),
                          ],
                        ],
                      ),
                    );

                    final actionContent = _headerCompact
                        ? _CompactStepsPanel(
                            stepChips: stepChipsRow,
                            onSave: canSaveDraft
                                ? () => _c.handleSaveDraft(context)
                                : null,
                            onPreview:
                                canPreview ? () => _c.previewPdf(context) : null,
                            onIssue: canIssue ? () => _c.issue(context) : null,
                            saving: _c.saving,
                            issuing: _c.issuing,
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
                useBlocks: _c.useBlocks,
                onModeChanged: _c.setUseBlocks,
                blocks: _c.blocks,
                lines: _c.lines,
                onChanged: _c.notifyUi,
                total: _c.total,
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
                key: _c.formKey,
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

        if (widget.embedded) return content;

        return WillPopScope(
          onWillPop: () async {
            _handleClose();
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
