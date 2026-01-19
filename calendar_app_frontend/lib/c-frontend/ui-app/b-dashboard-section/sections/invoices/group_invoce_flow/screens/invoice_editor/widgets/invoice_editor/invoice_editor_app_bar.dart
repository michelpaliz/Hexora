import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InvoiceEditorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final TextStyle? titleStyle;
  final bool saving;
  final bool issuing;
  final VoidCallback onSaveDraft;
  final VoidCallback onIssue;
  final bool showClose;
  final VoidCallback? onClose;

  const InvoiceEditorAppBar({
    super.key,
    this.titleStyle,
    required this.saving,
    required this.issuing,
    required this.onSaveDraft,
    required this.onIssue,
    this.showClose = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      title: Text(l.invoiceEditorTitle, style: titleStyle),
      backgroundColor: cs.surface,
      iconTheme: IconThemeData(color: cs.onSurface),
      automaticallyImplyLeading: !showClose,
      leading: showClose
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            )
          : null,
      actions: [
        TextButton(
          onPressed: saving ? null : onSaveDraft,
          child: Text(saving ? l.saving : l.invoiceSaveDraftCta),
        ),
        TextButton(
          onPressed: issuing ? null : onIssue,
          child: Text(issuing ? l.saving : l.invoiceIssueCta),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
