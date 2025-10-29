import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.groupName,
    required this.totalMembers,
    required this.totalPending,
    required this.totalUnion,
  });

  final String groupName;
  final int totalMembers;
  final int totalPending;
  final int totalUnion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    Widget chip(IconData icon, String text, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: typo.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.12),
            cs.tertiary.withOpacity(0.10),
          ],
        ),
        border: Border.all(color: cs.primary.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupName,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            groupName,
            style: typo.bodyMedium.copyWith(
              color: cs.onSurface.withOpacity(0.70),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(Icons.verified_user, '${l.membersTitle}: $totalMembers',
                  cs.primary),
              chip(Icons.hourglass_bottom, '${l.statusPending}: $totalPending',
                  cs.tertiary),
              chip(Icons.summarize, 'Total: $totalUnion', cs.secondary),
            ],
          ),
        ],
      ),
    );
  }
}
