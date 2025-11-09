import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/c-frontend/utils/image/avatar_utils.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A dedicated screen that shows the Group "header" (avatar, dates, quick pills)
/// so the main dashboard can stay lean.
class GroupHeaderScreen extends StatefulWidget {
  final Group group;
  const GroupHeaderScreen({super.key, required this.group});

  @override
  State<GroupHeaderScreen> createState() => _GroupHeaderScreenState();
}

class _GroupHeaderScreenState extends State<GroupHeaderScreen> {
  late GroupDomain _gm;
  MembersCount? _counts;
  bool _loadingCounts = false;

  @override
  void initState() {
    super.initState();
    _gm = context.read<GroupDomain>();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _loadingCounts = true);
    try {
      final c = await _gm.groupRepository.getMembersCount(
        widget.group.id,
        mode: 'union',
      );
      if (!mounted) return;
      setState(() => _counts = c);
    } finally {
      if (mounted) setState(() => _loadingCounts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final createdStr = DateFormat.yMMMd(l.localeName).format(group.createdTime);

    // Fallbacks
    final fallbackMembers = group.userIds.length;
    const fallbackPending = 0;
    final fallbackTotal = fallbackMembers + fallbackPending;

    // Server-first
    final showMembers = _counts?.accepted ?? fallbackMembers;
    final showPending = _counts?.pending ?? fallbackPending;
    final showTotal = _counts?.union ?? fallbackTotal;

    final tileBg = ThemeColors.listTileBg(context);
    final onTile = ThemeColors.textPrimary(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.sectionOverview, style: t.titleLarge),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AvatarUtils.groupAvatar(context, group.photoUrl, radius: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style:
                            t.titleLarge.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.createdOnDay(createdStr),
                        style: t.bodySmall
                            .copyWith(color: onTile.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingCounts) ...[
                        const _ShimmerPills(),
                      ] else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoPill(
                              icon: Icons.group_outlined,
                              label:
                                  '${NumberFormat.decimalPattern(l.localeName).format(showMembers)} ${l.membersTitle.toLowerCase()}',
                            ),
                            _InfoPill(
                              icon: Icons.hourglass_top_outlined,
                              label:
                                  '${NumberFormat.decimalPattern(l.localeName).format(showPending)} ${l.statusPending.toLowerCase()}',
                            ),
                            _InfoPill(
                              icon: Icons.all_inbox_outlined,
                              label:
                                  '${NumberFormat.decimalPattern(l.localeName).format(showTotal)} ${l.totalEarnings}',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              color: tileBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant.withOpacity(0.25)),
              ),
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(
                  l.insightsTitle,
                  style: t.accentText
                      .copyWith(fontWeight: FontWeight.w600, color: onTile),
                ),
                subtitle: Text(l.insightsSubtitle,
                    style:
                        t.bodySmall.copyWith(color: onTile.withOpacity(0.8))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight pill for figures in the header
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // Use secondaryContainer for a friendly, readable chip-like pill.
    final bg = cs.secondaryContainer;
    final fg = cs.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Simple shimmer placeholder while counts load
class _ShimmerPills extends StatelessWidget {
  const _ShimmerPills();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget box(double w) => Container(
          width: w,
          height: 28,
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(999),
          ),
        );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [box(96), box(120), box(80)],
    );
  }
}
