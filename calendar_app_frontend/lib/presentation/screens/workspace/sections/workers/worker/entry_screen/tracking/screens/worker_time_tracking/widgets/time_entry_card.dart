import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/time_tracking/time_entry.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/functions/edit_time_entry_sheet.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
    final text = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = entry.start.toLocal();
    final end = entry.end?.toLocal();
    final duration = entry.end?.difference(entry.start);
    final month = DateFormat.MMM(locale);
    final day = DateFormat.d(locale);
    final date = DateFormat('EEEE, d MMM y', locale);
    final time = DateFormat.Hm(locale);

    return Dismissible(
      key: ValueKey('time-entry-${entry.id}'),
      direction: DismissDirection.horizontal,
      background: _swipeBackground(context, Alignment.centerLeft),
      secondaryBackground: _swipeBackground(context, Alignment.centerRight),
      confirmDismiss: (_) => _delete(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _edit(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: .34))),
          child: Row(children: [
            Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: colors.primary.withValues(alpha: .08)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(month.format(start).toUpperCase(),
                      style: text.caption.copyWith(
                          letterSpacing: .6,
                          fontWeight: FontWeight.w700,
                          color: colors.primary)),
                  const SizedBox(height: 2),
                  Text(day.format(start),
                      style: text.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                ])),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_capitalize(date.format(start)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _EntryChip(
                        label: end != null ? l.completed : l.inProgress,
                        icon: end != null
                            ? Icons.check_circle_outline_rounded
                            : Icons.timelapse_rounded,
                        color: end != null ? colors.primary : colors.secondary),
                    if (end != null && duration != null)
                      _EntryChip(
                          label: _durationLabel(duration),
                          icon: Icons.schedule_rounded,
                          color: colors.onSurfaceVariant),
                  ]),
                ])),
            const SizedBox(width: 12),
            if (end != null) ...[
              Icon(Icons.schedule_rounded,
                  size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('${time.format(start)}–${time.format(end)}',
                  style:
                      text.bodySmall.copyWith(color: colors.onSurfaceVariant)),
            ] else
              Text(l.ongoing,
                  style:
                      text.bodySmall.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(width: 12),
            PopupMenuButton<_EntryAction>(
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              icon: const Icon(Icons.more_vert_rounded),
              iconSize: 20,
              style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  fixedSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                  backgroundColor:
                      colors.surfaceContainerHighest.withValues(alpha: .55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
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
                        title: Text(l.edit))),
                PopupMenuItem(
                    value: _EntryAction.delete,
                    child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline_rounded,
                            size: 19, color: colors.error),
                        title: Text(l.delete))),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

class _EntryChip extends StatelessWidget {
  const _EntryChip(
      {required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: color.withValues(alpha: .08),
            border: Border.all(color: color.withValues(alpha: .2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTypography.of(context).caption.copyWith(
                  height: 1, fontWeight: FontWeight.w600, color: color)),
        ]),
      );
}

enum _EntryAction { edit, delete }
