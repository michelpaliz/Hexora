// lib/.../dialog_content/widgets/header_section.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/f-themes/app_utilities/image/avatar_utils.dart';
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bodyM = theme.textTheme.bodyMedium!;
    final bodyS = theme.textTheme.bodySmall!;
    final loc = AppLocalizations.of(context)!;

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final createdAt = DateFormat.yMMMd(localeTag).format(group.createdTime);

    const radius = 16.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: double.maxFinite,
        // outer visual (rounded + shadow)
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Base gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primaryContainer.withOpacity(0.55),
                    cs.secondaryContainer.withOpacity(0.45),
                  ],
                ),
              ),
            ),

            // Soft radial accents (very subtle)
            Positioned(
              top: -40,
              left: -20,
              child: _Blob(
                size: 140,
                color: cs.primary.withOpacity(0.08),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -10,
              child: _Blob(
                size: 170,
                color: cs.secondary.withOpacity(0.07),
              ),
            ),

            // Glass sheen
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.white.withOpacity(0.03), // ultra subtle film
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top row: created-on + members icon
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            loc.createdOnDay(createdAt),
                            style: bodyS.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 8),
                        child: MembersIconButton(
                          count: group.userIds.length,
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.groupMembers,
                            arguments: group,
                          ),
                        ),
                      ),
                    ],
                  ),

                  kGap10,

                  // Avatar + title/description
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: cs.primary.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
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
                            // Group name (2 lines)
                            Text(
                              group.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: bodyM.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            if (group.description.isNotEmpty) ...[
                              kGap6,
                              Text(
                                group.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: bodyS.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  kGap14,

                  // Primary action inside header
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () {
                        final groupDomain =
                            Provider.of<GroupDomain>(context, listen: false);
                        groupDomain.currentGroup = group;
                        Navigator.pushNamed(
                          context,
                          AppRoutes.groupDashboard,
                          arguments: group,
                        );
                      },
                      icon: const Icon(Icons.dashboard_rounded, size: 16),
                      label: Text(
                        loc.dashboard,
                        style: bodyM.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // subtle radial falloff
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
