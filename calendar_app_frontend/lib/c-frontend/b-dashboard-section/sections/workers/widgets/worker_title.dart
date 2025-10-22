import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class WorkerTile extends StatelessWidget {
  final Worker worker;
  const WorkerTile({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final int? totalMinutes = _extractTotalMinutes(worker);
    final String tracked =
        totalMinutes == null ? '—' : _formatMinutes(totalMinutes, l.localeName);

    return Card(
      color: ThemeColors.getListTileBackgroundColor(context),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.surfaceVariant,
          child: const Icon(Icons.person_outline),
        ),
        title: Text(
          worker.displayName ?? l.unknownWorker,
          style: t.accentText.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          totalMinutes == null ? l.noTrackedYet : l.trackedTotal(tracked),
          style: t.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          // Hook to a worker detail screen if you add one later.
        },
      ),
    );
  }

  static int? _extractTotalMinutes(Worker w) {
    // Adjust to your model (examples):
    // return w.totalTrackedMinutes;
    // return w.summary?.totalMinutes;
    return null;
  }

  static String _formatMinutes(int minutes, String locale) {
    final d = Duration(minutes: minutes);
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    final nf = NumberFormat.decimalPattern(locale);
    return '${nf.format(hours)}h ${nf.format(mins)}m';
    // If you prefer HH:mm zero-padded, use:
    // final hh = hours.toString().padLeft(2, '0');
    // final mm = mins.toString().padLeft(2, '0');
    // return '$hh:$mm';
  }
}
