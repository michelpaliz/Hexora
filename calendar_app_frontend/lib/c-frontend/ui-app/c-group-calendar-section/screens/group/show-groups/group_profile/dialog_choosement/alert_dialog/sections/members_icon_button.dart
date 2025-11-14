// lib/.../dialog_content/widgets/members_icon_button.dart
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class MembersIconButton extends StatelessWidget {
  const MembersIconButton(
      {super.key, required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bodyS = Theme.of(context).textTheme.bodySmall!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          onPressed: onPressed,
          tooltip: AppLocalizations.of(context)!.viewMembers,
          icon: const Icon(Icons.people_alt_rounded, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: cs.surfaceContainerHighest,
            foregroundColor: cs.onSurface,
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(36, 36),
            padding: const EdgeInsets.all(8),
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$count',
              style: bodyS.copyWith(
                  color: cs.onPrimary, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
