import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_controller.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form/invoice_content_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form/invoice_header_fields.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/client_search_select.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/pdf_inline_preview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Dedicated mobile invoice editor.
/// Uses a [PageView] with 6 steps that match the desktop flow.
/// Each step reuses the same public widgets and the same
/// [InvoiceEditorController] so all business logic is shared.
class InvoiceEditorMobileScreen extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final String? initialClientId;
  final Invoice? initialInvoice;

  const InvoiceEditorMobileScreen({
    super.key,
    required this.group,
    required this.clients,
    this.initialClientId,
    this.initialInvoice,
  });

  @override
  State<InvoiceEditorMobileScreen> createState() =>
      _InvoiceEditorMobileScreenState();
}

class _InvoiceEditorMobileScreenState extends State<InvoiceEditorMobileScreen> {
  late final InvoiceEditorController _c;
  int _step = 0;
  bool _changed = false;

  static const _totalSteps = 4;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _c = InvoiceEditorController(
      group: widget.group,
      clients: widget.clients,
      initialClientId: widget.initialClientId,
      initialInvoice: widget.initialInvoice,
    );
    _c.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() => _changed = true);
  }

  @override
  void dispose() {
    _c.removeListener(_onControllerChanged);
    _c.dispose();
    super.dispose();
  }

  // ── navigation ─────────────────────────────────────────────────────────────

  void _goTo(int step) {
    final s = step.clamp(0, _totalSteps - 1);
    setState(() => _step = s);
    // Auto-trigger PDF preview when entering the preview step.
    if (s == 3) {
      final canPreview = _c.clientId != null &&
          _c.invoiceDate.value != null &&
          _c.hasBillableEntries &&
          _c.savedInvoice != null;
      if (canPreview) {
        Future.microtask(() {
          if (mounted) _c.previewPdf(context);
        });
      }
    }
  }

  // ── computed gate for the "Next" button ───────────────────────────────────

  bool get _canAdvance {
    final invoiceDate = _c.invoiceDate.value;
    final dueDate = _c.dueDate.value;
    final invalidDates =
        invoiceDate != null && dueDate != null && dueDate.isBefore(invoiceDate);
    return switch (_step) {
      0 => _c.clientId != null,
      1 => invoiceDate != null && !invalidDates,
      2 => _c.savedInvoice != null,
      3 => _c.previewedPdf,
      _ => false,
    };
  }

  bool get _canCompleteDraft {
    final invoiceDate = _c.invoiceDate.value;
    final dueDate = _c.dueDate.value;
    final datesComplete = invoiceDate != null;
    final invalidDates =
        invoiceDate != null && dueDate != null && dueDate.isBefore(invoiceDate);
    final step1Complete = _c.clientId != null &&
        datesComplete &&
        _c.hasBillableEntries &&
        !invalidDates;
    return !_c.saving && step1Complete && (_c.editingIssued || _c.previewedPdf);
  }

  // ── step labels ────────────────────────────────────────────────────────────

  String _stepTitle(AppLocalizations l) => switch (_step) {
        0 => l.invoiceCustomerTitle,
        1 => l.invoiceDatesTitle,
        2 => l.invoiceLinesTitle,
        3 => l.invoiceStepPreviewShort,
        _ => l.invoiceStepPreviewShort,
      };

  List<String> _mobileVisibleStepLabels(AppLocalizations l) => [
        l.invoiceStepClientShort,
        l.invoiceDatesTitle,
        l.invoiceStepLinesShort,
        l.invoiceStepPreviewShort,
      ];

  // ignore: unused_element
  List<String> _mobileStepLabels(AppLocalizations l) => [
        l.invoiceStepClientShort,
        l.invoiceDatesTitle,
        l.invoiceStepLinesShort,
        l.invoiceStepPreviewShort,
        l.invoiceStepDraftShort,
      ];

  String _draftCompletionReason(AppLocalizations l) {
    if (!_c.previewedPdf) {
      return l.invoiceReviewPdfBeforeDraft;
    }
    if (_c.clientId == null) return l.invoicePreviewNeedsClient;
    if (_c.invoiceDate.value == null) return l.invoicePreviewNeedsDate;
    if (!_c.hasBillableEntries) return l.invoicePreviewNeedsLines;

    final dueDate = _c.dueDate.value;
    final invoiceDate = _c.invoiceDate.value;
    final invalidDates =
        invoiceDate != null && dueDate != null && dueDate.isBefore(invoiceDate);
    if (invalidDates) return l.invoicePreviewInvalidDates;
    return '';
  }

  Widget _buildCompactStepFlowBar(BuildContext context, bool isSpanish) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final labels = _mobileVisibleStepLabels(l);

    Widget connector(bool active) => Container(
          width: 18,
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color:
                active ? cs.primary : cs.outlineVariant.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(99),
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _step;
          final isCompleted = index < _step;
          final canJump = index <= _step;
          final chipColor = isActive
              ? cs.primary
              : isCompleted
                  ? cs.primary.withValues(alpha: 0.18)
                  : cs.surfaceContainerHighest;
          final fgColor = isActive ? cs.onPrimary : cs.onSurfaceVariant;

          final stepChip = InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: canJump ? () => _goTo(index) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: chipColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isActive
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: isActive
                        ? cs.onPrimary.withValues(alpha: 0.2)
                        : cs.primary.withValues(alpha: 0.14),
                    child: Icon(
                      isCompleted ? Icons.check_rounded : Icons.circle,
                      size: isCompleted ? 12 : 8,
                      color: isActive ? cs.onPrimary : cs.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    labels[index],
                    style: t.bodySmall.copyWith(
                      color: fgColor,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );

          if (index == _totalSteps - 1) return stepChip;
          return Row(children: [stepChip, connector(index < _step)]);
        }),
      ),
    );
  }

  // ── step content ───────────────────────────────────────────────────────────

  Widget _buildClientStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: ClientSearchSelect(
        clients: widget.clients,
        selectedClientId: _c.clientId,
        onClientChanged: _c.setClientId,
        useDefaultPropertyKind: false,
        showAdvancedFilters: false,
        maxListHeight: 520,
      ),
    );
  }

  Widget _buildDatesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        children: [
          InvoiceHeaderFields(
            clients: widget.clients,
            clientId: _c.clientId,
            onClientChanged: _c.setClientId,
            currencyController: _c.currency,
            invoiceDate: _c.invoiceDate,
            dueDate: _c.dueDate,
            onPickInvoiceDate: () => _c.pickDate(context, _c.invoiceDate),
            onPickDueDate: () => _c.pickDate(context, _c.dueDate),
            onCurrencyChanged: (_) => _c.notifyUi(),
            showDates: true,
            showClient: false,
            showCurrency: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _c.notes,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) => _c.notifyUi(),
            decoration: const InputDecoration(
              labelText: 'Notas',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: AbsorbPointer(
        absorbing: _c.financialFieldsReadOnly,
        child: Opacity(
          opacity: _c.financialFieldsReadOnly ? 0.68 : 1,
          child: InvoiceContentSection(
            useBlocks: _c.useBlocks,
            onModeChanged: _c.setUseBlocks,
            blocks: _c.blocks,
            lines: _c.lines,
            onChanged: _c.notifyUi,
            total: _c.total,
            controller: _c,
            ocrState: _c.ocrState,
            onPickImageForLineExtraction: () =>
                _c.extractLinesFromImage(context),
            onApplyExtractedLines: _c.applyExtractedLinesToDraft,
            onClearExtractedLines: _c.clearExtractedLines,
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewStep() {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final canPreview = _c.clientId != null &&
        _c.invoiceDate.value != null &&
        _c.hasBillableEntries &&
        _c.savedInvoice != null;
    final previewBytes = _c.previewPdfBytes;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!canPreview)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  _c.savedInvoice != null
                      ? l.invoicePreviewNeedsLines
                      : l.invoicePreviewNeedsDraft,
                  style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (_c.previewing || previewBytes == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: l.refreshAction,
                icon: const Icon(Icons.refresh),
                onPressed: _c.previewing ? null : () => _c.previewPdf(context),
              ),
            ),
            PdfInlinePreview(bytes: previewBytes, height: 480),
          ],
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDraftStep() {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final fmt = NumberFormat.currency(locale: l.localeName, symbol: 'EUR ');

    final invoiceDate = _c.invoiceDate.value;
    final dueDate = _c.dueDate.value;
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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.invoiceSummaryTitle,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryRow(
                  label: l.invoiceCustomerTitle,
                  value: selectedClientName,
                ),
                _SummaryRow(
                  label: l.invoiceNumberLabel,
                  value: _c.previewInvoiceNumber,
                ),
                if (invoiceDate != null)
                  _SummaryRow(
                    label: l.invoiceDateLabel,
                    value: DateFormat.yMMMd(l.localeName).format(invoiceDate),
                  ),
                if (dueDate != null)
                  _SummaryRow(
                    label: l.invoiceDueDateLabel,
                    value: DateFormat.yMMMd(l.localeName).format(dueDate),
                  ),
                _SummaryRow(
                  label: l.invoiceTotalLabel,
                  value: fmt.format(_c.total).trim(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _canCompleteDraft
                  ? () => _c.handleSaveDraft(
                        context,
                        confirmIfEditing: false,
                      )
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: _canCompleteDraft ? 3 : 0,
                shadowColor: cs.primary.withValues(alpha: 0.35),
              ),
              icon: _c.saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _c.saving
                    ? l.savingLabel
                    : _c.editingIssued
                        ? 'Guardar cambios'
                        : l.invoiceSaveDraftCta,
              ),
            ),
          ),
          if (!_canCompleteDraft) ...[
            const SizedBox(height: 8),
            Text(
              _draftCompletionReason(l),
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  Widget _buildCurrentStepBody() {
    return switch (_step) {
      0 => _buildClientStep(),
      1 => _buildDatesStep(),
      2 => _buildLinesStep(),
      _ => _buildPreviewStep(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_step > 0) {
              _goTo(_step - 1);
            } else {
              Navigator.of(context).pop(_changed);
            }
          },
          child: Scaffold(
            backgroundColor: cs.surface,

            // ── app bar ─────────────────────────────────────────────────────
            appBar: AppBar(
              backgroundColor: cs.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () {
                  if (_step > 0) {
                    _goTo(_step - 1);
                  } else {
                    Navigator.of(context).pop(_changed);
                  }
                },
              ),
              title: Text(
                _stepTitle(l),
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              actions: [
                if (_step < _totalSteps - 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed:
                          _c.saving ? null : () => _c.handleSaveDraft(context),
                      child: _c.saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              l.invoiceStepDraftShort,
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                    ),
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: (_step + 1) / _totalSteps,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                  minHeight: 3,
                ),
              ),
            ),

            // ── body (PageView) ──────────────────────────────────────────────
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: _buildCompactStepFlowBar(context, isSpanish),
                ),
                Expanded(
                  child: Form(
                    key: _c.formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey<int>(_step),
                        child: _buildCurrentStepBody(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── bottom nav ──────────────────────────────────────────────────
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    // Back
                    if (_step > 0)
                      OutlinedButton.icon(
                        onPressed: () => _goTo(_step - 1),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(l.back),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // Step counter
                    Expanded(
                      child: Center(
                        child: Text(
                          '${_step + 1} / $_totalSteps',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Next / Save draft
                    if (_step < _totalSteps - 1)
                      FilledButton.icon(
                        onPressed: _canAdvance ? () => _goTo(_step + 1) : null,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(l.next),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: _canCompleteDraft
                            ? () => _c.handleSaveDraft(
                                  context,
                                  confirmIfEditing: false,
                                )
                            : null,
                        icon: _c.saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          _c.saving ? l.savingLabel : l.invoiceSaveDraftCta,
                        ),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _DiscountEditorSection extends StatelessWidget {
  final InvoiceEditorController controller;
  const _DiscountEditorSection({required this.controller});

  Widget _modeBtn(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.55)
                : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(7) : Radius.zero,
              right: isLast ? const Radius.circular(7) : Radius.zero,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 11, color: cs.primary),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final readOnly = controller.discountReadOnly;
    final usePercent = controller.useDiscountPercent;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: label + compact mode toggle
          Row(
            children: [
              Text(
                'Descuento',
                style: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (!readOnly)
                Container(
                  height: 28,
                  width: 148,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      _modeBtn(
                        context,
                        label: 'Importe €',
                        selected: !usePercent,
                        isFirst: true,
                        onTap: () => controller.setDiscountModePercent(false),
                      ),
                      Container(
                          width: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.35)),
                      _modeBtn(
                        context,
                        label: 'Porcentaje %',
                        selected: usePercent,
                        isLast: true,
                        onTap: () => controller.setDiscountModePercent(true),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Only the active input field
          SizedBox(
            width: 160,
            child: TextFormField(
              controller: usePercent
                  ? controller.discountPercentCtrl
                  : controller.discountAmountCtrl,
              enabled: !readOnly,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (raw) {
                final text = (raw ?? '').trim();
                if (text.isEmpty) return null;
                final parsed = num.tryParse(text.replaceAll(',', '.'));
                if (parsed == null) {
                  return usePercent
                      ? 'Porcentaje inválido'
                      : 'Importe inválido';
                }
                if (parsed < 0) return 'Debe ser ≥ 0';
                if (usePercent && parsed > 100) return '0 – 100';
                return null;
              },
              decoration: InputDecoration(
                labelText: usePercent ? 'Porcentaje (%)' : 'Importe (€)',
                hintText: '0.00',
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: usePercent
                  ? controller.setDiscountPercentText
                  : controller.setDiscountAmountText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Se aplica antes de IVA.',
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
