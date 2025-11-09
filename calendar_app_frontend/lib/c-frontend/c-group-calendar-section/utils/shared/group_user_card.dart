import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/c-frontend/utils/app_utils.dart';
import 'package:hexora/c-frontend/utils/image/avatar_utils.dart';

class GroupUserCard extends StatelessWidget {
  final String userName;
  final String role;
  final String? photoUrl;
  final VoidCallback? onRemove;
  final bool isAdmin;
  final String? status; // Accepted | Pending | NotAccepted | Expired | null
  final DateTime? sendingDate;

  const GroupUserCard({
    Key? key,
    required this.userName,
    required this.role,
    this.photoUrl,
    this.onRemove,
    this.isAdmin = false,
    this.status,
    this.sendingDate,
  }) : super(key: key);

  IconData _getStatusIcon() {
    switch (status) {
      case 'Accepted':
        return Icons.check_circle_outline;
      case 'Pending':
        return Icons.hourglass_empty;
      case 'NotAccepted':
      case 'Not Accepted':
        return Icons.cancel_outlined;
      case 'Expired':
        return Icons.schedule_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Color _statusColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case 'Accepted':
        return cs.primary;
      case 'Pending':
        return cs.tertiary;
      case 'NotAccepted':
      case 'Not Accepted':
        return cs.error;
      case 'Expired':
        return cs.onSurfaceVariant;
      default:
        return cs.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final bg = ThemeColors.listTileBg(context);
    final onBg = ThemeColors.textPrimary(context);
    final border = cs.outlineVariant.withOpacity(0.25);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: AvatarUtils.groupAvatar(context, photoUrl, radius: 30),
        title: Row(
          children: [
            Expanded(
              child: Text(
                userName,
                style: t.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onBg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (status != null)
              Icon(
                _getStatusIcon(),
                color: _statusColor(context),
                size: 18,
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(
                role,
                style: t.bodySmall.copyWith(
                  color: onBg.withOpacity(0.75),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sendingDate != null) ...[
              const SizedBox(width: 10),
              Text(
                '• ${AppUtils.formatDate(sendingDate!)}',
                style: t.caption.copyWith(
                  color: onBg.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
        trailing: isAdmin
            ? Icon(Icons.verified_user, color: cs.primary, size: 18)
            : (onRemove != null
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: cs.error,
                    onPressed: onRemove,
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                  )
                : null),
      ),
    );
  }
}
