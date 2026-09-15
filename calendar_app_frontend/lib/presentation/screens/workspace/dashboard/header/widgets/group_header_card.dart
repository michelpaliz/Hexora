// lib/presentation/screens/workspace/dashboard/header/widgets/group_header_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/header/widgets/group_header_primitives.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/header/widgets/group_stats_pill_compact.dart';
import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupHeaderCard extends StatelessWidget {
  const GroupHeaderCard({
    super.key,
    required this.photoUrl,
    required this.title,
    required this.description,
    required this.createdLabel,
    required this.members,
    required this.pending,
    required this.total,
    required this.localeName,
    required this.onTap,
    this.isLoading = false,
    this.presenceStrip,
    this.clientCount,
    this.workerCount,
    this.editTooltip,
    this.pendingEventsCount,
    this.onMembersTap,
    this.onPendingEventsTap,
    this.onClientsTap,
    this.onWorkersTap,
  });

  final Widget? presenceStrip;
  final String? photoUrl;
  final String title;
  final String description;
  final String createdLabel;
  final int members;
  final int pending;
  final int total;
  final String localeName;
  final bool isLoading;
  final VoidCallback? onTap;
  final int? clientCount;
  final int? workerCount;
  final String? editTooltip;
  final int? pendingEventsCount;
  final VoidCallback? onMembersTap;
  final VoidCallback? onPendingEventsTap;
  final VoidCallback? onClientsTap;
  final VoidCallback? onWorkersTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppTypography.of(context);
    final hasDescription = description.trim().isNotEmpty;
    final l = AppLocalizations.of(context)!;

    final isInteractive = onTap != null;
    final cardColor = Color.alphaBlend(
      cs.primaryContainer.withOpacity(
        theme.brightness == Brightness.dark ? 0.22 : 0.14,
      ),
      ThemeColors.cardBg(context),
    );

    if (MediaQuery.sizeOf(context).width < 700) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                AvatarUtils.groupAvatar(context, photoUrl, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (onTap != null)
                  IconButton(
                    tooltip: editTooltip ?? l.edit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onTap,
                  ),
              ]),
              if (hasDescription) ...[
                const SizedBox(height: 12),
                Text(description,
                    style: t.bodySmall
                        .copyWith(color: cs.onSurfaceVariant, height: 1.5)),
              ],
              if (presenceStrip != null) presenceStrip!,
              const SizedBox(height: 12),
              if (isLoading)
                const LinearProgressIndicator()
              else
                Wrap(spacing: 8, runSpacing: 4, children: [
                  TextButton.icon(
                      onPressed: onMembersTap,
                      icon: const Icon(Icons.group_outlined, size: 18),
                      label: Text('$members ${l.membersTitle.toLowerCase()}')),
                  if (pendingEventsCount != null)
                    TextButton.icon(
                        onPressed: onPendingEventsTap,
                        icon: const Icon(Icons.pending_actions_outlined,
                            size: 18),
                        label: Text(
                            '$pendingEventsCount ${l.statusPending.toLowerCase()}')),
                  if (clientCount != null)
                    TextButton(
                        onPressed: onClientsTap,
                        child:
                            Text('$clientCount ${l.tabClients.toLowerCase()}')),
                  if (workerCount != null)
                    TextButton(
                        onPressed: onWorkersTap,
                        child: Text(
                            '$workerCount ${l.localeName.startsWith('es') ? 'trabajadores' : 'workers'}')),
                ]),
            ],
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: '$title, $createdLabel',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: cardColor,
                border: Border.all(
                  color: cs.primaryContainer.withOpacity(0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.cardShadow(context),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  // 1) bigger centered avatar
                  Center(
                    child: ClipOval(
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: AvatarUtils.groupAvatar(context, photoUrl,
                            radius: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2) icon meta row (calendar text + members icon [+ pending icon if any])
                  _IconMetaRow(
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      MetaText(text: createdLabel),
                      const MetaSeparatorDot(),
                      Icon(Icons.group_outlined,
                          size: 16, color: cs.onSurfaceVariant),
                      if (pendingEventsCount != null &&
                          pendingEventsCount! > 0) ...[
                        const MetaSeparatorDot(),
                        Icon(Icons.pending_actions_outlined,
                            size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        MetaText(
                          text:
                              '${pendingEventsCount!.toString()} ${l.statusPending.toLowerCase()}',
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 3) title + description responsive
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 560;
                      if (!isWide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            if (hasDescription) ...[
                              const SizedBox(height: 8),
                              Text(
                                description,
                                style: t.bodyLarge.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.displayMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          if (hasDescription)
                            Expanded(
                              flex: 7,
                              child: Text(
                                description,
                                style: t.bodyLarge.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.55,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  if (presenceStrip != null) presenceStrip!,
                  const SizedBox(height: 16),
                  Divider(
                      height: 1,
                      thickness: 0.8,
                      color: cs.outlineVariant.withOpacity(0.4)),
                  const SizedBox(height: 10),

                  GroupStatsPillsCompact(
                    loading: isLoading,
                    members: members,
                    localeName: localeName,
                    clientCount: clientCount,
                    workerCount: workerCount,
                    pendingEventsCount: pendingEventsCount,
                    onMembersTap: onMembersTap,
                    onPendingEventsTap: onPendingEventsTap,
                    onClientsTap: onClientsTap,
                    onWorkersTap: onWorkersTap,
                  ),
                ],
              ),
            ),
            if (isInteractive)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: editTooltip ?? 'Edit',
                  onPressed: onTap,
                  style: IconButton.styleFrom(
                    foregroundColor: cs.primary,
                    backgroundColor: cs.surface.withOpacity(0.8),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconMetaRow extends StatelessWidget {
  const _IconMetaRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 6,
      children: children,
    );
  }
}
