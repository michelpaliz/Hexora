import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/functions/edit_time_entry_sheet.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TimeEntryCard extends StatelessWidget {
  final TimeEntry entry;
  final String groupId;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;
  final VoidCallback? onUpdated;

  const TimeEntryCard({
    super.key,
    required this.entry,
    required this.groupId,
    required this.repo,
    required this.getToken,
    this.onUpdated,
  });

  Duration? get _duration =>
      entry.end != null ? entry.end!.difference(entry.start) : null;

  String _fmtDurShort(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Future<bool> _confirmAndDelete(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.delete),
        content: Text(l.areYouSureDelete),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return false;

    try {
      final token = await getToken();
      await repo.deleteTimeEntry(groupId, entry.id, token);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.deletedSuccessfully)));
      }
      onUpdated?.call();
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${l.error}: $e')));
      }
      return false;
    }
  }

  Widget _swipeBg(BuildContext context, AlignmentGeometry align) {
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Theme.of(context).colorScheme.error.withOpacity(0.12),
      child: Icon(Icons.delete,
          size: 18, color: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    // Compact formats
    final monthFmt = DateFormat.MMM(locale); // e.g., Oct
    final dayFmt = DateFormat.d(locale); // e.g., 27
    final dateRowFmt = DateFormat.yMMMd(locale); // e.g., Oct 27, 2025
    final timeFmt = DateFormat.Hm(locale); // 14:05

    final hasEnd = entry.end != null;
    final dur = _duration;

    return Dismissible(
      key: ValueKey('time-entry-${entry.id}'),
      direction: DismissDirection.horizontal,
      background: _swipeBg(context, Alignment.centerLeft),
      secondaryBackground: _swipeBg(context, Alignment.centerRight),
      confirmDismiss: (d) => _confirmAndDelete(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final updated = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            builder: (_) => Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: EditTimeEntrySheet(
                entry: entry,
                groupId: groupId,
                repo: repo,
                getToken: getToken,
              ),
            ),
          );
          if (updated == true) onUpdated?.call();
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Compact date pill (Month on top, Day below)
                Container(
                  width: 42,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthFmt.format(entry.start.toLocal()).toUpperCase(),
                        style: t.caption.copyWith(
                          letterSpacing: .6,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayFmt.format(entry.start.toLocal()),
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Middle: compact details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // top row: status chip + duration chip (if any)
                      Row(
                        children: [
                          _Chip(
                            label: hasEnd ? l.completed : l.inProgress,
                            fg: hasEnd
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                          ),
                          if (hasEnd && dur != null) ...[
                            const SizedBox(width: 6),
                            _Chip(
                              label: _fmtDurShort(dur),
                              fg: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.75),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // bottom line: date + time range (tiny, muted)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateRowFmt.format(entry.start.toLocal()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.caption.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ),
                          if (hasEnd) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.schedule,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text(
                              '${timeFmt.format(entry.start.toLocal())}–${timeFmt.format(entry.end!.toLocal())}',
                              style: t.caption.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(width: 6),
                            Text(
                              l.ongoing,
                              style: t.caption.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color fg;
  const _Chip({required this.label, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: fg.withOpacity(0.10),
        border: Border.all(color: fg.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: AppTypography.of(context).caption.copyWith(
              height: 1.0,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
      ),
    );
  }
}
