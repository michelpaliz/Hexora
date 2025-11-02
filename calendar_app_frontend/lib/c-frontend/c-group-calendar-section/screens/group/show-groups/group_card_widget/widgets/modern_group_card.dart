// lib/c-frontend/c-group-calendar-section/screens/group/show-groups/group_card_widget/modern_group_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/show-groups/group_card_widget/widgets/meta_pills.dart';
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
    final theme = Theme.of(context);
    final bodyMedium = theme.textTheme.bodyMedium!;
    final bodySmall = theme.textTheme.bodySmall!;
    final scheme = theme.colorScheme;

    final baseCardColor =
        ThemeColors.getCardBackgroundColor(context).withOpacity(0.95);
    final hoverOverlay = scheme.primary.withOpacity(0.06);
    final blended = Color.alphaBlend(hoverOverlay, baseCardColor);
    final cardColor = isHovered ? blended : baseCardColor;

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
              color: scheme.outlineVariant.withOpacity(isHovered ? 0.5 : 0.3)),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                      color: scheme.shadow.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8))
                ]
              : [
                  BoxShadow(
                      color: scheme.shadow.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 6))
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
                    colors: [scheme.primary, scheme.primary.withOpacity(0.5)],
                  ),
                ),
              ),
            ),

            // Responsive content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 420;

                  if (isCompact) {
                    // Pills wrap under title – more room for name
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
                                bodyMedium: bodyMedium,
                                bodySmall: bodySmall,
                                onSurface: scheme.onSurface,
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
                                  color: scheme.onSurfaceVariant),
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
                          bodyMedium: bodyMedium,
                          bodySmall: bodySmall,
                          onSurface: scheme.onSurface,
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
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
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
