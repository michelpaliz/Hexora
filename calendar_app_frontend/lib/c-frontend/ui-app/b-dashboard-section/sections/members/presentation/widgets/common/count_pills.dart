// widgets/counts_pills.dart
import 'package:flutter/material.dart';

class CountsPills extends StatelessWidget {
  final bool loading;
  final int? members; // server “accepted”
  final int? pending; // server “pending”
  final int? total; // server “union”
  final int fallbackMembers; // local derivation
  final int fallbackPending; // local derivation
  final String membersLabel; // localized
  final String pendingLabel; // localized
  final String totalLabel; // localized (or plain 'Total')

  const CountsPills({
    super.key,
    required this.loading,
    required this.members,
    required this.pending,
    required this.total,
    required this.fallbackMembers,
    required this.fallbackPending,
    required this.membersLabel,
    required this.pendingLabel,
    this.totalLabel = 'Total',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;

    final showMembers = members ?? fallbackMembers;
    final showPending = pending ?? fallbackPending;
    final showTotal = total ?? (showMembers + showPending);

    Widget pill(IconData icon, String label, String value, Color bg) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colors.onSurface.withOpacity(0.8)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: text.labelSmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 2),
                Text(loading ? '…' : value,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    )),
              ],
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        pill(Icons.group_outlined, membersLabel, '$showMembers',
            colors.primaryContainer),
        pill(Icons.hourglass_top_outlined, pendingLabel, '$showPending',
            colors.secondaryContainer),
        pill(Icons.all_inbox_outlined, totalLabel, '$showTotal',
            colors.tertiaryContainer),
      ],
    );
  }
}
