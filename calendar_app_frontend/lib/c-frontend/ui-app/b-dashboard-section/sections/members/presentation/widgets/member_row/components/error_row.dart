import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_ref.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class MemberErrorRow extends StatelessWidget {
  final MemberRef ref;
  final Object? error;

  const MemberErrorRow({super.key, required this.ref, this.error});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final onCard = cs.onSurface;
    final onCardSecondary = cs.onSurfaceVariant;
    final typo = AppTypography.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: onCardSecondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded,
                size: 24, color: onCardSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.bodyMedium
                      .copyWith(color: onCard, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  l.errorLoadingUser('${error ?? 'Unknown error'}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.bodySmall
                      .copyWith(color: onCardSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
