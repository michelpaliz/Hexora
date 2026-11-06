import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/time_tracking/time_entry.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/functions/edit_time_entry_sheet.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:intl/intl.dart';

class TimeEntryCard extends StatelessWidget {
  const TimeEntryCard(
      {super.key,
      required this.entry,
      required this.groupId,
      required this.repo,
      required this.getToken,
      this.onUpdated});

  final TimeEntry entry;
  final String groupId;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;
  final VoidCallback? onUpdated;

  String _durationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) return '$hours h $minutes m';
    if (hours > 0) return '$hours h';
    return '$minutes m';
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  Future<void> _edit(BuildContext context) async {
    final updated = await showModalBottomSheet<bool>(
      sheetAnimationStyle: HexoraMotion.sheetStyle(context),
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: EditTimeEntrySheet(
            entry: entry, groupId: groupId, repo: repo, getToken: getToken),
      ),
    );
    if (updated == true) onUpdated?.call();
  }

  Future<bool> _delete(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showHexoraDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.delete),
        content: Text(l.areYouSureDelete),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l.delete)),
        ],
      ),
    );
    if (confirmed != true) return false;
    try {
      await repo.deleteTimeEntry(groupId, entry.id, await getToken());
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.deletedSuccessfully)));
      }
      onUpdated?.call();
      return true;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${l.error}: $error')));
      }
      return false;
    }
  }

  Widget _swipeBackground(BuildContext context, AlignmentGeometry alignment) {
    final colors = Theme.of(context).colorScheme;
    return Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: colors.error.withValues(alpha: .12),
        child: Icon(Icons.delete, size: 18, color: colors.error));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = entry.start.toLocal();
    final end = entry.end?.toLocal();
    final duration = entry.end?.difference(entry.start);
    final month = DateFormat.MMM(locale);
    final day = DateFormat.d(locale);
    final date = DateFormat('EEEE, d MMM y', locale);
    final time = DateFormat.Hm(locale);

    final dateBlock = SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colors.surfaceContainerHighest.withValues(alpha: .52),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              month.format(start).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                height: 1,
                letterSpacing: .35,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              day.format(start),
              style: TextStyle(
                fontSize: 14,
                height: 1,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
    final dateLabel = Text(
      _capitalize(date.format(start)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
    );
    final statusChip = _EntryChip(
      label: end != null ? l.completed : l.inProgress,
      icon: end != null
          ? Icons.check_circle_outline_rounded
          : Icons.timelapse_rounded,
      color: end != null ? colors.primary : colors.secondary,
      fontSize: 11,
    );
    final durationChip = end != null && duration != null
        ? _EntryChip(
            label: _durationLabel(duration),
            icon: Icons.schedule_rounded,
            color: colors.onSurfaceVariant,
            fontSize: 12,
          )
        : null;
    final timeRange = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 15, color: colors.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          end != null ? '${time.format(start)}–${time.format(end)}' : l.ongoing,
          style: TextStyle(
            fontSize: 12.5,
            height: 1,
            fontWeight: FontWeight.w500,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
    final actions = PopupMenuButton<_EntryAction>(
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      icon: const Icon(Icons.more_vert_rounded),
      iconSize: 18,
      style: IconButton.styleFrom(
        minimumSize: const Size(32, 32),
        fixedSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        foregroundColor: colors.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onSelected: (action) {
        if (action == _EntryAction.edit) {
          _edit(context);
        } else {
          _delete(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _EntryAction.edit,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined, size: 19),
            title: Text(l.edit),
          ),
        ),
        PopupMenuItem(
          value: _EntryAction.delete,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded,
                size: 19, color: colors.error),
            title: Text(l.delete),
          ),
        ),
      ],
    );

    return Dismissible(
      key: ValueKey('time-entry-${entry.id}'),
      direction: DismissDirection.horizontal,
      background: _swipeBackground(context, Alignment.centerLeft),
      secondaryBackground: _swipeBackground(context, Alignment.centerRight),
      confirmDismiss: (_) => _delete(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            bottom: BorderSide(
              color: colors.outlineVariant.withValues(alpha: .38),
            ),
          ),
        ),
        child: InkWell(
          onTap: () => _edit(context),
          hoverColor: colors.surfaceContainerHighest.withValues(alpha: .34),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                if (compact) {
                  return Row(
                    children: [
                      dateBlock,
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            dateLabel,
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(child: statusChip),
                                if (durationChip != null) ...[
                                  const SizedBox(width: 5),
                                  Flexible(child: durationChip),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      timeRange,
                      const SizedBox(width: 4),
                      actions,
                    ],
                  );
                }
                return Row(
                  children: [
                    dateBlock,
                    const SizedBox(width: 10),
                    SizedBox(width: 180, child: dateLabel),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 98,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: statusChip,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 82,
                      child: durationChip == null
                          ? const SizedBox.shrink()
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: durationChip,
                            ),
                    ),
                    const Spacer(),
                    timeRange,
                    const SizedBox(width: 8),
                    actions,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryChip extends StatelessWidget {
  const _EntryChip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.fontSize});
  final String label;
  final IconData icon;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: color.withValues(alpha: .07)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                height: 1,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ]),
      );
}

enum _EntryAction { edit, delete }
