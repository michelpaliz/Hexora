import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
              'Actions',
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (!canIssue || issuing) ? null : onIssue,
                icon: issuing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(issuing ? l.saving : 'Issue invoice'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: (!canSave || saving) ? null : onSaveDraft,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? l.saving : 'Save draft'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: canPreview ? onPreviewPdf : null,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('PDF preview'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
