import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class SaveButton extends StatelessWidget {
  final bool saving;
  final bool isEdit;
  final VoidCallback? onPressed;

  const SaveButton({
    super.key,
    required this.saving,
    required this.isEdit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(
          saving ? l.saving : (isEdit ? l.saveChanges : l.saveClient),
          style: typo.bodySmall.copyWith(
            color: cs.onPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
