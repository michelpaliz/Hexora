import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_card_widget/widgets/build_group_card.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupCardTile extends StatefulWidget {
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
  State<GroupCardTile> createState() => _GroupCardTileState();
}

class _GroupCardTileState extends State<GroupCardTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    final createdLabel = MaterialLocalizations.of(context).formatMediumDate(
      widget.group.createdTime,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          scale: _hovering ? 1.005 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: _hovering ? 0.16 : 0.1),
                  blurRadius: _hovering ? 14 : 10,
                  offset: Offset(0, _hovering ? 5 : 3),
                ),
              ],
            ),
            child: Material(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  showProfileAlertDialog(
                    context,
                    widget.group,
                    widget.currentUser,
                    widget.currentUser,
                    widget.userDomain,
                    widget.groupDomain,
                    widget.updateRole,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.surface,
                        cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      ],
                    ),
                    border: Border.all(
                      color: _hovering
                          ? cs.primary.withValues(alpha: 0.32)
                          : cs.outlineVariant.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withValues(alpha: 0.15),
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
                              widget.group.photoUrl,
                              radius: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.group.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                color: cs.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (widget.group.description.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.group.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.82),
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${loc.createdOn} $createdLabel',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.72),
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hovering
                              ? cs.primary.withValues(alpha: 0.14)
                              : cs.onSurface.withValues(alpha: 0.05),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: _hovering
                              ? cs.primary
                              : cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
