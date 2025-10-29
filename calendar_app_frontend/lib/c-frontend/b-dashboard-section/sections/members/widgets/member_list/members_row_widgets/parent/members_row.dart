import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/user/repository/i_user_repository.dart'; // interface
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/models/members_ref.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/widgets/member_list/members_row_widgets/children/badge_icon.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/widgets/member_list/members_row_widgets/children/role_chip.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/widgets/member_list/members_row_widgets/children/status_dot.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/widgets/member_list/members_row_widgets/parent/member_detail_sheet.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class MemberRow extends StatelessWidget {
  final MemberRef ref;
  final String ownerId;
  final bool showRoleChip;

  const MemberRow({
    super.key,
    required this.ref,
    required this.ownerId,
    this.showRoleChip = true,
  });

  bool _isOwnerRole(String? raw) {
    final s = raw?.trim().toLowerCase() ?? '';
    return s == 'owner' ||
        s == 'group_owner' ||
        s == 'creator' ||
        s == 'founder';
  }

  bool _isAdminRole(String? raw) {
    final s = raw?.trim().toLowerCase() ?? '';
    return s == 'admin' ||
        s == 'administrator' ||
        s == 'manager' ||
        s == 'moderator';
  }

  bool _isMemberRole(String? raw) {
    final s = raw?.trim().toLowerCase() ?? '';
    return s == 'member' || s.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final userRepo = context.read<IUserRepository>(); // interface
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final typo = AppTypography.of(context); // ✅ Typo font

    return FutureBuilder<User>(
      future: userRepo.getUserBySelector(ref.username),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const ListTile(
            leading: CircleAvatar(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            title: SizedBox(height: 14, child: LinearProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text(
              ref.username,
              style: typo.bodyMedium,
            ),
            subtitle: Text(
              l.errorLoadingUser('${snap.error ?? 'Unknown error'}'),
              style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          );
        }

        final user = snap.data!;
        final isOwner = (user.id == ownerId) || _isOwnerRole(ref.role);
        final isAdmin = !isOwner && _isAdminRole(ref.role);
        final titleText = (user.name.isNotEmpty ? user.name : user.userName);

        return ListTile(
          onTap: () => showMemberDetailSheet(
            context: context,
            user: user,
            ref: ref,
            isOwnerRowUser: isOwner,
            isAdminRowUser: isAdmin,
          ),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                backgroundImage:
                    (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                        ? NetworkImage(user.photoUrl!)
                        : null,
                child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                    ? Text(_initials(titleText), style: typo.bodySmall)
                    : null,
              ),
              if (isOwner || isAdmin)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: BadgeIcon(
                    icon: isOwner
                        ? Icons.workspace_premium_rounded
                        : Icons.admin_panel_settings_rounded,
                    color: isOwner ? cs.primary : cs.secondary,
                    label: isOwner ? l.roleOwner : l.roleAdmin,
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (isOwner
                      ? typo.bodySmall.copyWith(fontWeight: FontWeight.w800)
                      : typo.bodySmall),
                ),
              ),
              const SizedBox(width: 8),
              if (showRoleChip && !isOwner && !isAdmin)
                RoleChip(
                  label: _isMemberRole(ref.role) ? l.roleMember : ref.role,
                  color:
                      _isMemberRole(ref.role) ? Colors.grey[800]! : cs.tertiary,
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                if (!isOwner) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: StatusDot(token: ref.statusToken),
                  ),
                  Expanded(
                    child: Text(
                      _getStatusText(ref.statusToken, l),
                      style:
                          typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }

  String _getStatusText(String token, AppLocalizations l) {
    switch (token) {
      case 'Accepted':
        return l.statusAccepted;
      case 'Pending':
        return l.statusPending;
      default:
        return l.statusNotAccepted;
    }
  }

  String _initials(String text) {
    final t = text.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
