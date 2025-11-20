import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_card_widget/widgets/build_group_card.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';

class GroupCardTile extends StatelessWidget {
  const GroupCardTile({
    super.key,
    required this.group,
    required this.currentUser,
    required this.userDomain,
    required this.groupDomain,
    required this.updateRole,
  });

  final Group group;
  final User currentUser;
  final UserDomain userDomain;
  final GroupDomain groupDomain;
  final void Function(String?) updateRole;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Compact formatted created date
    final createdLabel =
        MaterialLocalizations.of(context).formatMediumDate(group.createdTime);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: cs.shadow.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showProfileAlertDialog(
              context,
              group,
              /* owner */ currentUser,
              currentUser,
              userDomain,
              groupDomain,
              updateRole,
            );
          },
          onHover: (hovering) {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surface,
                  cs.surfaceVariant.withOpacity(0.3),
                ],
              ),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Group avatar with subtle shadow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: AvatarUtils.groupAvatar(
                        context,
                        group.photoUrl,
                        radius: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name with subtle gradient text
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: cs.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),

                      // Optional description
                      if (group.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          group.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant.withOpacity(0.8),
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),

                      // Created date with icon
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: cs.onSurfaceVariant.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Created $createdLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant.withOpacity(0.7),
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Modern chevron icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.onSurface.withOpacity(0.05),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
