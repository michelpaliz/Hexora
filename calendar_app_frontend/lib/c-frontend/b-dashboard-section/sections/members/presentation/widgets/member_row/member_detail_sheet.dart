import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/domain/models/members_ref.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/member_row/components/role_chip.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

Future<void> showMemberDetailSheet({
  required BuildContext context,
  required User user,
  required MemberRef ref,
  required bool isOwnerRowUser,
  required bool isAdminRowUser,
}) async {
  final l = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final typo = AppTypography.of(context); // ✅ Typo font

  final bodyText = (user.name.isNotEmpty ? user.name : user.userName);

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                          ? NetworkImage(user.photoUrl!)
                          : null,
                  child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                      ? Text(_initials(bodyText), style: typo.bodySmall)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bodyText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: isOwnerRowUser
                        ? typo.bodySmall.copyWith(fontWeight: FontWeight.w800)
                        : typo.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                if (isOwnerRowUser)
                  RoleChip(label: l.roleOwner, color: cs.primary)
                else if (isAdminRowUser)
                  RoleChip(label: l.roleAdmin, color: cs.secondary)
                else
                  RoleChip(
                    label: _isMemberRole(ref.role) ? l.roleMember : ref.role,
                    color: _isMemberRole(ref.role)
                        ? Colors.grey[800]!
                        : cs.tertiary,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Meta
            Row(
              children: [
                Icon(Icons.alternate_email_rounded,
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.email,
                    style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.phone_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.phoneNumber!,
                      style:
                          typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Actions (placeholder—wire up later if needed)
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(l.close, style: typo.bodySmall),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        () {}, // TODO: define action (e.g., message, promote)
                    icon: const Icon(Icons.message_rounded),
                    label: Text(l.contact,
                        style: typo.bodySmall.copyWith(color: cs.onPrimary)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

bool _isMemberRole(String? raw) {
  final s = raw?.trim().toLowerCase() ?? '';
  return s == 'member' || s.isEmpty;
}

String _initials(String text) {
  final t = text.trim();
  if (t.isEmpty) return '?';
  final parts = t.split(RegExp(r'\\s+'));
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
