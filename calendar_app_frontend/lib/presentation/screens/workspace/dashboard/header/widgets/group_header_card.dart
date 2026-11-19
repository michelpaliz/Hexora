// lib/presentation/screens/workspace/dashboard/header/widgets/group_header_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/header/widgets/group_header_primitives.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/header/widgets/group_stats_pill_compact.dart';
import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/theme/components/themed_buttons.dart';

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
    this.onEdit,
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
  final VoidCallback? onEdit;
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
    final editButtonStyle = ThemedButtons.iconAction(
      context,
      color: cs.primary,
    );
    final hasDescription = description.trim().isNotEmpty;
    final l = AppLocalizations.of(context)!;

    final isInteractive = onTap != null;
    final cardColor = Color.alphaBlend(
      cs.primaryContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.22 : 0.14,
      ),
      ThemeColors.cardBg(context),
    );

    if (MediaQuery.sizeOf(context).width < 700) {
      final primary = cs.primary;
      final secondary = Color.lerp(primary, const Color(0xFF5146E5), .62)!;
      final pendingCount = pendingEventsCount ?? pending;

      return Semantics(
        container: true,
        button: isInteractive,
        label: '$title, $createdLabel',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: .22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 58,
                              height: 58,
                              child: AvatarUtils.groupAvatar(
                                context,
                                photoUrl,
                                radius: 29,
                              ),
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: const Color(0xFF20C875),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            if (hasDescription) ...[
                              const SizedBox(height: 3),
                              Text(
                                description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: .82),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onEdit != null)
                        IconButton.filledTonal(
                          tooltip: editTooltip ?? l.edit,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: .18),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: onEdit,
                        ),
                    ],
                  ),
                  if (presenceStrip != null) ...[
                    const SizedBox(height: 10),
                    presenceStrip!,
                  ],
                  const SizedBox(height: 12),
                  Divider(
                      height: 1, color: Colors.white.withValues(alpha: .18)),
                  const SizedBox(height: 10),
                  if (isLoading)
                    LinearProgressIndicator(
                      minHeight: 2,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: .18),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _MobileStat(
                            value: members,
                            label: l.membersTitle,
                            onTap: onMembersTap,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _MobileStat(
                            value: pendingCount,
                            label: l.statusPending,
                            onTap: onPendingEventsTap,
                            emphasized: pendingCount > 0,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _MobileStat(
                            value: clientCount ?? 0,
                            label: l.tabClients,
                            onTap: onClientsTap,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _MobileStat(
                            value: workerCount ?? 0,
                            label: l.localeName.startsWith('es')
                                ? 'Equipo'
                                : 'Team',
                            onTap: onWorkersTap,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: cardColor,
                  border: Border.all(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
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
                        color: cs.outlineVariant.withValues(alpha: 0.4)),
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
              if (onEdit != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    style: editButtonStyle,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: editTooltip ?? 'Edit',
                    onPressed: onEdit,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileStat extends StatelessWidget {
  const _MobileStat({
    required this.value,
    required this.label,
    this.onTap,
    this.emphasized = false,
  });

  final int value;
  final String label;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: emphasized
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD166).withValues(alpha: .85),
                  ),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .82),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .15,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
