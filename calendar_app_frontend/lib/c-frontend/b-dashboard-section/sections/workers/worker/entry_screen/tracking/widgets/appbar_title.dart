import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:intl/intl.dart';

class WorkerAppBarTitle extends StatelessWidget {
  const WorkerAppBarTitle({
    super.key,
    required this.group,
    required this.worker,
    required this.year,
    required this.month,
  });

  final Group group;
  final Worker worker;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.yMMMM(locale).format(DateTime(year, month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          worker.displayName ?? 'Worker',
          style: t.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          '${group.name} • $monthLabel',
          style: t.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
