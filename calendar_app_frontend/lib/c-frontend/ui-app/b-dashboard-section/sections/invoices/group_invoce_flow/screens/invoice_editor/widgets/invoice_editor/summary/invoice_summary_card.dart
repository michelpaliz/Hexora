import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InvoiceSummaryCard extends StatelessWidget {
  final bool hasClient;
  final bool hasLines;
  final bool datesComplete;
  final bool invalidDates;
  final bool canPreview;
  final bool canSaveDraft;
  final bool canIssue;
  final bool savingDraft;
  final bool issuing;
  final bool reinforceIssue;
  final bool previewedPdf;
  final bool hasBlockingDrafts;
  final VoidCallback onSaveDraft;
  final VoidCallback onPreviewPdf;
  final VoidCallback onIssue;
  final bool fillHeight;

  const InvoiceSummaryCard({
    super.key,
    required this.hasClient,
    required this.hasLines,
    required this.datesComplete,
    required this.invalidDates,
    required this.canPreview,
    required this.canSaveDraft,
    required this.canIssue,
    required this.savingDraft,
    required this.issuing,
    required this.reinforceIssue,
    required this.previewedPdf,
    required this.hasBlockingDrafts,
    required this.onSaveDraft,
    required this.onPreviewPdf,
    required this.onIssue,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final warnings = <String>[];
    if (invalidDates) {
      warnings.add(l.invoiceWarningDueDateBefore);
    }
    if (hasBlockingDrafts) {
      warnings.add(l.invoiceWarningPendingDrafts);
    }

    String? previewReason() {
      if (hasBlockingDrafts) return l.invoiceWarningPendingDrafts;
      if (!hasClient) return l.invoicePreviewNeedsClient;
      if (!datesComplete) return l.invoicePreviewNeedsDate;
      if (invalidDates) return l.invoicePreviewInvalidDates;
      if (!hasLines) return l.invoicePreviewNeedsLines;
      return null;
    }

    String? issueReason() {
      if (!previewedPdf) {
        return l.localeName.startsWith('es')
            ? 'Revisa la factura en vista previa antes de guardar el borrador.'
            : 'Review the invoice preview before saving the draft.';
      }
      if (hasBlockingDrafts) return l.invoiceWarningPendingDrafts;
      if (!hasClient) return l.invoicePreviewNeedsClient;
      if (!datesComplete) return l.invoicePreviewNeedsDate;
      if (invalidDates) return l.invoicePreviewInvalidDates;
      if (!hasLines) return l.invoicePreviewNeedsLines;
      return null;
    }

    final stepsPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.invoiceStepsTitle,
          style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.invoiceStepCreateTitle,
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _ChecklistItem(
                label: l.invoiceChecklistClient,
                done: hasClient,
              ),
              const SizedBox(height: 6),
              _ChecklistItem(
                label: l.invoiceChecklistDates,
                done: datesComplete && !invalidDates,
              ),
              const SizedBox(height: 6),
              _ChecklistItem(
                label: l.invoiceChecklistLines,
                done: hasLines,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: canSaveDraft && !savingDraft ? onSaveDraft : null,
                  icon: savingDraft
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    savingDraft ? l.savingLabel : l.invoiceSaveDraftCta,
                  ),
                ),
              ),
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  l.invoiceWarningsTitle,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                for (final w in warnings) _WarningItem(label: w),
              ],
              const SizedBox(height: 12),
              Text(
                l.invoiceStepPreviewTitle,
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _ChecklistItem(
                label: previewedPdf
                    ? l.invoicePreviewReviewedStatus
                    : l.invoicePreviewPendingLabel,
                done: previewedPdf,
                accent: canPreview ? cs.primary : cs.outline,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: canPreview ? onPreviewPdf : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l.invoicePreviewCta),
                ),
              ),
              if (!canPreview) ...[
                const SizedBox(height: 6),
                Text(
                  previewReason() ?? '',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (previewedPdf) ...[
                const SizedBox(height: 6),
                Text(
                  l.invoicePreviewReviewedLabel,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                l.statusDraft,
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: canIssue && !issuing ? onIssue : null,
                  style: reinforceIssue
                      ? FilledButton.styleFrom(
                          elevation: 3,
                          shadowColor: cs.primary.withValues(alpha: 0.35),
                        )
                      : null,
                  icon: issuing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    issuing ? l.savingLabel : l.invoiceSaveDraftCta,
                  ),
                ),
              ),
                if (!canIssue) ...[
                  const SizedBox(height: 6),
                  Text(
                    issueReason() ?? '',
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
        ),
      ],
    );

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: stepsPanel,
    );

    return Card(
      elevation: 1,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: content,
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String label;
  final bool done;
  final Color? accent;

  const _ChecklistItem({
    required this.label,
    required this.done,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final iconColor = done ? (accent ?? cs.primary) : cs.outline;
    final textColor = done ? cs.onSurface : cs.onSurfaceVariant;

    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: t.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _WarningItem extends StatelessWidget {
  final String label;

  const _WarningItem({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: cs.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
