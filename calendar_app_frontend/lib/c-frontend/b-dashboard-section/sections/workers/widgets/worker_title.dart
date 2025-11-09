import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
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

    final bg = ThemeColors.listTileBg(context);
    final onBg = ThemeColors.textPrimary(context);

    return Card(
      margin: EdgeInsets.zero,
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.25), width: 1),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: cs.secondary.withOpacity(0.12),
          child: Icon(Icons.person_outline, color: cs.secondary),
        ),
        title: Text(
          worker.displayName ?? l.unknownWorker,
          style: t.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: onBg,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          totalMinutes == null ? l.noTrackedYet : l.trackedTotal(tracked),
          style: t.bodySmall.copyWith(
            color: onBg.withOpacity(0.75),
            height: 1.25,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing:
            Icon(Icons.chevron_right_rounded, color: onBg.withOpacity(0.6)),
        onTap: () {
          // TODO: navigate to worker detail when available.
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
  }
}
