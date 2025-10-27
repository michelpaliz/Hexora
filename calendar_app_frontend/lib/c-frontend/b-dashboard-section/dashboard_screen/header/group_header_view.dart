import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/b-dashboard-section/dashboard_screen/infopill/info_pill.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/members/models/Members_count.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_utilities/image/avatar_utils.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GroupHeaderView extends StatefulWidget {
  final Group group;
  const GroupHeaderView({super.key, required this.group});

  @override
  State<GroupHeaderView> createState() => _GroupHeaderViewState();
}

class _GroupHeaderViewState extends State<GroupHeaderView> {
  late GroupDomain _gm;
  MembersCount? _counts;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _gm = context.read<GroupDomain>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await _gm.groupRepository.getMembersCount(
        widget.group.id,
        mode: 'union',
      );
      if (!mounted) return;
      setState(() => _counts = c);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final createdStr = DateFormat.yMMMd(l.localeName).format(group.createdTime);

    // Fallbacks + server-first
    final fallbackMembers = group.userIds.length;
    const fallbackPending = 0;
    final members = _counts?.accepted ?? fallbackMembers;
    final pending = _counts?.pending ?? fallbackPending;
    final total = _counts?.union ?? (fallbackMembers + fallbackPending);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AvatarUtils.groupAvatar(context, group.photoUrl, radius: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style:
                          t.titleLarge.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    l.createdOnDay(createdStr),
                    style: t.bodySmall
                        .copyWith(color: cs.onSurface.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const _ShimmerPills()
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        InfoPill(
                          icon: Icons.group_outlined,
                          label:
                              '${NumberFormat.decimalPattern(l.localeName).format(members)} ${l.membersTitle.toLowerCase()}',
                        ),
                        InfoPill(
                          icon: Icons.hourglass_top_outlined,
                          label:
                              '${NumberFormat.decimalPattern(l.localeName).format(pending)} ${l.statusPending.toLowerCase()}',
                        ),
                        InfoPill(
                          icon: Icons.all_inbox_outlined,
                          label:
                              '${NumberFormat.decimalPattern(l.localeName).format(total)} total',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
        spacing: 8, runSpacing: 8, children: [box(96), box(120), box(80)]);
  }
}
