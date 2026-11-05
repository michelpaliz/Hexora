import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TimeSummarySection extends StatelessWidget {
  const TimeSummarySection({
    super.key,
    required this.start,
    required this.end,
    required this.dateFormat,
    required this.timeFormat,
    required this.selectedCount,
  });

  final DateTime start;
  final DateTime end;
  final DateFormat dateFormat;
  final DateFormat timeFormat;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final duration = end.difference(start);
    final valid = !duration.isNegative;
    final hours = duration.inMinutes ~/ 60;
    final minutes = duration.inMinutes.remainder(60);
    final durationLabel = !valid
        ? (l.localeName.startsWith('es') ? 'Horario no válido' : 'Invalid time')
        : [
            if (hours > 0) '$hours h',
            if (minutes > 0 || hours == 0) '$minutes min',
          ].join(' ');
    final workerLabel = selectedCount == 1
        ? (l.localeName.startsWith('es') ? '1 trabajador' : '1 worker')
        : (l.localeName.startsWith('es')
            ? '$selectedCount trabajadores'
            : '$selectedCount workers');
    final endLabel = DateUtils.isSameDay(start, end)
        ? timeFormat.format(end)
        : '${dateFormat.format(end)} ${timeFormat.format(end)}';

    return Row(
      children: [
        Icon(Icons.schedule_rounded,
            size: 16, color: valid ? cs.primary : cs.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${dateFormat.format(start)} · ${timeFormat.format(start)}–$endLabel · $durationLabel · $workerLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: valid ? cs.onSurfaceVariant : cs.error,
            ),
          ),
        ),
      ],
    );
  }
}
