import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class MemberStatusRow extends StatelessWidget {
  final String statusToken;

  const MemberStatusRow({super.key, required this.statusToken});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final onCardSecondary = cs.onSurfaceVariant;
    final typo = AppTypography.of(context);

    Color statusColor() => switch (statusToken) {
          'Accepted' => const Color(0xFF10B981),
          'Pending' => const Color(0xFFF59E0B),
          _ => const Color(0xFFEF4444),
        };

    String statusText() => switch (statusToken) {
          'Accepted' => l.statusAccepted,
          'Pending' => l.statusPending,
          _ => l.statusNotAccepted,
        };

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration:
              BoxDecoration(color: statusColor(), shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            statusText(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typo.bodySmall.copyWith(
              color: onCardSecondary,
              fontSize: 11,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
