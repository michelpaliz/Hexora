import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_ref.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/member_row/components/error_row.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/member_row/components/loadin_avatar_badge.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/member_row/components/member_loadiing_row.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/member_row/components/members_role_chip.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/member_row/components/status_row.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/member_row/member_detail_sheet.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/username/username_tag.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/card_surface.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:provider/provider.dart';

class MemberRow extends StatelessWidget {
  final MemberRef ref;
  final String ownerId;
  final bool showRoleChip;
  final Group group;
  final String? currentUserId;

  const MemberRow({
    super.key,
    required this.ref,
    required this.ownerId,
    required this.group,
    this.currentUserId,
    this.showRoleChip = true,
  });

  @override
  Widget build(BuildContext context) {
    final userRepo = context.read<IUserRepository>();
    final typo = AppTypography.of(context);

    final onCard = CardSurface.onBg(context);
    final onCardSecondary = CardSurface.onBgSecondary(context);

    return FutureBuilder<User>(
      future: userRepo.getUserBySelector(ref.username),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const MemberLoadingRow();
        }
        if (snap.hasError || !snap.hasData) {
          return MemberErrorRow(ref: ref, error: snap.error);
        }

        final user = snap.data!;
        final gd = context.read<GroupDomain>();

        return ValueListenableBuilder<Map<String, String>>(
          valueListenable: gd.userRoles,
          builder: (_, rolesMap, __) {
            final roleWire = rolesMap[user.id] ?? ref.role;
            final parsedRole = GroupRole.fromWire(roleWire);
            final displayRole =
                (user.id == ownerId) ? GroupRole.owner : parsedRole;

            final isOwner = displayRole.wire == 'owner';
            final isAdmin = displayRole.wire == 'admin' ||
                displayRole.wire.toLowerCase().replaceAll('-', '') == 'coadmin';

            final titleText =
                (user.name.isNotEmpty ? user.name : user.userName);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => showMemberDetailSheet(
                  context: context,
                  user: user,
                  ref: ref,
                  isOwnerRowUser: isOwner,
                  isAdminRowUser: isAdmin,
                  group: group,
                  currentUserId: currentUserId,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      LeadingAvatarBadge(
                        user: user,
                        isOwner: isOwner,
                        isAdmin: isAdmin,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(titleText,
                                style: typo.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: onCard)),
                            if (user.userName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              UsernameTag(username: user.userName),
                            ],
                            const SizedBox(height: 8),
                            Wrap(spacing: 10, runSpacing: 6, children: [
                              if (showRoleChip)
                                MemberRoleChip(
                                    role: displayRole, hideForAdminLike: false),
                              if (!isOwner)
                                MemberStatusRow(statusToken: ref.statusToken),
                            ]),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: onCardSecondary.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
