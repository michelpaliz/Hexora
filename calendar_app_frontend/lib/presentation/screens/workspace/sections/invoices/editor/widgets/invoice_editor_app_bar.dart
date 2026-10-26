import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';

class InvoiceEditorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final TextStyle? titleStyle;
  final bool saving;
  final String? saveLabel;
  final VoidCallback onSaveDraft;
  final bool showClose;
  final VoidCallback? onClose;

  const InvoiceEditorAppBar({
    super.key,
    this.titleStyle,
    required this.saving,
    this.saveLabel,
    required this.onSaveDraft,
    this.showClose = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
        HexoraButton(
          onPressed: onSaveDraft,
          label: saveLabel ?? l.invoiceSaveDraftCta,
          variant: HexoraButtonVariant.ghost,
          loading: saving,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
