// lib/c-frontend/dialog_content/profile/widgets/group_hero_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_profile/dialog_choosement/alert_dialog/widgets/group_identity_row.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

enum GroupHeroSize { compact, wide }

class GroupHeroCard extends StatelessWidget {
  const GroupHeroCard({
    super.key,
    required this.group,
    required this.onTap,
    this.isPrimary = false,
    @Deprecated('Arrow removed; this flag is ignored.') this.showChevron = true,
    this.size = GroupHeroSize.compact,
  });

  final Group group;
  final VoidCallback onTap;
  final bool isPrimary;

  // Deprecated/ignored, kept only for call-site compatibility.
  final bool showChevron;

  final GroupHeroSize size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final createdAt = DateFormat.yMMMd(l.localeName).format(group.createdTime);

    // Neutral surface background always; primary only affects border emphasis.
    final Color background = cs.surface;
    final Color borderColor = isPrimary
        ? cs.primary.withOpacity(0.35)
        : cs.outlineVariant.withOpacity(0.35);
    final double borderWidth = isPrimary ? 1.5 : 1.0;

    // Size tokens
    final bool wide = size == GroupHeroSize.wide;
    final double radius = 14;
    final EdgeInsets pad = EdgeInsets.all(wide ? 16 : 12);
    final double avatar = wide ? 28 : 24;
    final int descMaxLines = wide ? 3 : 2;

    return Semantics(
      button: true,
      label: '${group.name}, ${l.createdOnDay(createdAt)}',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: cs.primary.withOpacity(0.08),
          highlightColor: cs.primary.withOpacity(0.04),
          child: Container(
            padding: pad,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identity row (no trailing arrow anymore)
                GroupIdentityRow(
                  title: group.name,
                  photoUrl: group.photoUrl,
                  avatarRadius: avatar,
                  metaTexts: const [], // not used since metaEntries provided
                  metaEntries: [
                    MetaEntry.text(l.createdOnDay(createdAt)),
                    MetaEntry.icon(
                        Icons.group_outlined), // 👈 icon instead of "X members"
                  ],
                  titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  dense: !wide,
                ),

                if (group.description.trim().isNotEmpty) ...[
                  SizedBox(height: wide ? 10 : 8),
                  Text(
                    group.description,
                    maxLines: descMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
