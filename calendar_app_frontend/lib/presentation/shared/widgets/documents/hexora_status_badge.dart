import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

/// Lifecycle states shared by invoices, receipts, quotes and contracts, so
/// every document list colours the same state the same way: issued is green,
/// warnings amber, drafts muted. Blue stays reserved for selection and
/// primary actions.
enum HexoraDocumentStatus {
  draft,
  issued,
  rectified,
  cancelled,
  warning;

  Color color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    return switch (this) {
      draft => cs.onSurfaceVariant,
      issued => light ? const Color(0xFF2E7D32) : const Color(0xFF81C784),
      rectified => cs.tertiary,
      cancelled => cs.error,
      warning => light ? const Color(0xFF9A5B00) : const Color(0xFFFFC247),
    };
  }

  IconData get icon => switch (this) {
        draft => Icons.edit_note_outlined,
        issued => Icons.task_alt_outlined,
        rectified => Icons.replay_outlined,
        cancelled => Icons.cancel_outlined,
        warning => Icons.warning_amber_rounded,
      };
}

/// Shared non-interactive status styling for document and directory rows.
class HexoraStatusBadge extends StatelessWidget {
  const HexoraStatusBadge(
      {super.key, required this.label, required this.color, this.leading});

  /// Badge for a document lifecycle state, with its standard colour and icon.
  factory HexoraStatusBadge.document(
    BuildContext context, {
    Key? key,
    required HexoraDocumentStatus status,
    required String label,
  }) {
    final color = status.color(context);
    return HexoraStatusBadge(
      key: key,
      label: label,
      color: color,
      leading: Icon(status.icon, size: 14, color: color),
    );
  }

  final String label;
  final Color color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HexoraTableTokens.badgeHorizontalPadding,
          vertical: HexoraTableTokens.badgeVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(HexoraDimensions.radius),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: HexoraDimensions.space)
          ],
          Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: HexoraTypography.fontFamily,
                        fontSize: HexoraTypography.caption,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ))),
        ]),
      );
}
