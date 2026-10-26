import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InvoiceActionCard extends StatelessWidget {
  final bool issuing;
  final bool saving;
  final bool canIssue;
  final bool canSave;
  final bool canPreview;
  final VoidCallback onIssue;
  final VoidCallback onSaveDraft;
  final VoidCallback onPreviewPdf;

  const InvoiceActionCard({
    super.key,
    required this.issuing,
    required this.saving,
    required this.canIssue,
    required this.canSave,
    required this.canPreview,
    required this.onIssue,
    required this.onSaveDraft,
    required this.onPreviewPdf,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.invoiceActionsTitle,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: HexoraButton(
                onPressed: !canIssue ? null : onIssue,
                icon: Icons.check_circle_outline,
                label: l.issueInvoice,
                loading: issuing,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: HexoraButton(
                onPressed: !canSave ? null : onSaveDraft,
                icon: Icons.save_outlined,
                label: l.saveDraft,
                variant: HexoraButtonVariant.secondary,
                loading: saving,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: HexoraButton(
                onPressed: canPreview ? onPreviewPdf : null,
                icon: Icons.picture_as_pdf_outlined,
                label: l.invoicePdfPreviewTitle,
                variant: HexoraButtonVariant.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
