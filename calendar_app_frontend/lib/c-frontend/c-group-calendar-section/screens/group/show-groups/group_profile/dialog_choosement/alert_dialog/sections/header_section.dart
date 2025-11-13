// lib/.../dialog_content/widgets/header_section.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/j-routes/appRoutes.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'members_icon_button.dart';
import 'spacing.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    final createdAt = DateFormat.yMMMd(l.localeName).format(group.createdTime);

    const radius = 14.0;
    final cardBg = ThemeColors.cardBg(context);
    final onCard = ThemeColors.textPrimary(context);
    final shadow = ThemeColors.cardShadow(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cs.outlineVariant.withOpacity(.25)),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          // slim accent bar
          Positioned.fill(
            top: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(radius)),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [cs.primary, cs.primary.withOpacity(.5)],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // top row: created-on + members
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      l.createdOnDay(createdAt),
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const Spacer(),
                    MembersIconButton(
                      count: group.userIds.length,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.groupMembers,
                        arguments: group,
                      ),
                    ),
                  ],
                ),

                // avatar + title/description
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // soft avatar ring
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: cs.outlineVariant.withOpacity(.35)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: AvatarUtils.groupAvatar(
                          context,
                          group.photoUrl,
                          radius: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: onCard,
                              height: 1.15,
                            ),
                          ),
                          if (group.description.isNotEmpty) ...[
                            kGap6,
                            Text(
                              group.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                color: onCard.withOpacity(.7),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                kGap14,

                // primary action
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.dashboard_rounded, size: 16),
                    label: Text(l.dashboard, style: t.buttonText),
                    onPressed: () {
                      final gd =
                          Provider.of<GroupDomain>(context, listen: false);
                      gd.currentGroup = group;
                      Navigator.pushNamed(context, AppRoutes.groupDashboard,
                          arguments: group);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
