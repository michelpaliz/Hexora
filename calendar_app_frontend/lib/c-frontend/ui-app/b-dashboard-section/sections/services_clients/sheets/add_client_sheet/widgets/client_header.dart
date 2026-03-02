import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientHeader extends StatelessWidget {
  final bool isEdit;

  const ClientHeader({super.key, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
            size: 18,
            color: cs.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isEdit ? l.editClient : l.createClient,
            style: typo.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
