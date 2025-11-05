// lib/c-frontend/c-group-calendar-section/screens/group/show-groups/group_card_widget/modern_group_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/show-groups/group_card_widget/widgets/meta_pills.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:intl/intl.dart';

import 'group_thumbnail.dart';
import 'title_meta.dart';

class ModernGroupCard extends StatelessWidget {
  const ModernGroupCard({
    super.key,
    required this.group,
    required this.role,
    required this.isHovered,
    required this.onTap,
  });

  final Group group;
  final String role;
  final bool isHovered;
  final VoidCallback onTap;

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // Base surface, then a subtle hover tint
    final baseCardColor = ThemeColors.cardBg(context).withOpacity(0.98);
    final hoverOverlay = cs.primary.withOpacity(0.06);
    final cardColor = isHovered
        ? Color.alphaBlend(hoverOverlay, baseCardColor)
        : baseCardColor;

    final onCard = ThemeColors.textPrimary(context);

    final formattedDate = DateFormat('yyyy-MM-dd').format(group.createdTime);
    final participantCount = group.userIds.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: cs.outlineVariant.withOpacity(isHovered ? 0.45 : 0.28),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.cardShadow(context),
              blurRadius: isHovered ? 18 : 10,
              offset: Offset(0, isHovered ? 8 : 6),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cardColor, cardColor.withOpacity(0.98)],
          ),
        ),
        child: Stack(
          children: [
            // Accent stripe
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(_radius),
                    topRight: Radius.circular(_radius),
                  ),
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withOpacity(0.5)],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 420;

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GroupThumbnail(photoUrl: group.photoUrl),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TitleMeta(
                                name: group.name,
                                formattedDate: formattedDate,
                                // use AppTypography styles
                                bodyMedium: t.bodyLarge.copyWith(
                                  color: onCard,
                                  fontWeight: FontWeight.w700,
                                ),
                                bodySmall: t.bodySmall.copyWith(
                                  color: onCard.withOpacity(0.75),
                                ),
                                onSurface: onCard,
                                maxLinesForTitle: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: MetaPills(
                                participants: participantCount,
                                role: role,
                              ),
                            ),
                            if (!isCompact)
                              Icon(Icons.chevron_right,
                                  color: onCard.withOpacity(0.6)),
                          ],
                        ),
                      ],
                    );
                  }

                  // Wide layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GroupThumbnail(photoUrl: group.photoUrl),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TitleMeta(
                          name: group.name,
                          formattedDate: formattedDate,
                          bodyMedium: t.bodyLarge.copyWith(
                            color: onCard,
                            fontWeight: FontWeight.w700,
                          ),
                          bodySmall: t.bodySmall.copyWith(
                            color: onCard.withOpacity(0.75),
                          ),
                          onSurface: onCard,
                          maxLinesForTitle: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        fit: FlexFit.loose,
                        child: MetaPills(
                          participants: participantCount,
                          role: role,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right, color: onCard.withOpacity(0.6)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
