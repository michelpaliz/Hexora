import 'package:flutter/material.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/avatars/hexora_user_avatar.dart';
import 'package:intl/intl.dart';

class WorkerTile extends StatelessWidget {
  final Worker worker;
  const WorkerTile({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: HexoraUserAvatar(
          userId: worker.userId ?? worker.id,
          displayName: worker.displayName ?? l.unknownWorker,
          username: worker.externalId,
          size: 40,
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
            color: onBg.withValues(alpha: 0.75),
            height: 1.25,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: onBg.withValues(alpha: 0.6)),
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
