import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/domain/models/members_ref.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/member_row/components/badge_icon.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/member_row/components/role_chip.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/member_row/components/status_dot.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/widgets/member_row/member_detail_sheet.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/card_surface.dart';
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
    final userRepo = context.read<IUserRepository>();
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final onCard = CardSurface.onBg(context);
    final onCardSecondary = CardSurface.onBgSecondary(context);

    return FutureBuilder<User>(
      future: userRepo.getUserBySelector(ref.username),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
            minLeadingWidth: 0,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            leading: const CircleAvatar(
              radius: 16,
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            title: SizedBox(
              height: 10,
              child: LinearProgressIndicator(
                color: onCardSecondary,
                backgroundColor: onCardSecondary.withOpacity(0.15),
              ),
            ),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
            minLeadingWidth: 0,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            leading:
                Icon(Icons.error_outline, size: 18, color: onCardSecondary),
            title: Text(
              ref.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typo.bodySmall
                  .copyWith(color: onCard, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l.errorLoadingUser('${snap.error ?? 'Unknown error'}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  typo.bodySmall.copyWith(color: onCardSecondary, fontSize: 11),
            ),
          );
        }

        final user = snap.data!;
        final isOwner = (user.id == ownerId) || _isOwnerRole(ref.role);
        final isAdmin = !isOwner && _isAdminRole(ref.role);
        final titleText = (user.name.isNotEmpty ? user.name : user.userName);

        return ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
          minLeadingWidth: 0,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                radius: 16, // smaller avatar
                backgroundImage:
                    (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                        ? NetworkImage(user.photoUrl!)
                        : null,
                child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                    ? Text(
                        _initials(titleText),
                        style: typo.bodySmall.copyWith(
                            color: onCard,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      )
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
                          : typo.bodySmall
                              .copyWith(fontWeight: FontWeight.w600))
                      .copyWith(color: onCard, height: 1.0),
                ),
              ),
              const SizedBox(width: 6),
              if (showRoleChip && !isOwner && !isAdmin)
                RoleChip(
                  label: _isMemberRole(ref.role) ? l.roleMember : ref.role,
                  color:
                      _isMemberRole(ref.role) ? Colors.grey[800]! : cs.tertiary,
                ),
            ],
          ),
          subtitle: (!isOwner)
              ? Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Row(
                    children: [
                      // keep the dot, make text very compact
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: StatusDot(token: ref.statusToken),
                      ),
                      Expanded(
                        child: Text(
                          _getStatusText(ref.statusToken, l),
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
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            size: 16,
            color: onCardSecondary,
          ),
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
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
