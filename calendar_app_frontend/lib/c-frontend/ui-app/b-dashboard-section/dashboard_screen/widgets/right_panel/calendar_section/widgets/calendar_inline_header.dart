import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class CalendarInlineHeader extends StatelessWidget {
  const CalendarInlineHeader({
    super.key,
    required this.groupName,
    required this.isLoading,
    required this.onRefresh,
    required this.onJumpToToday,
  });

  final String groupName;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onJumpToToday;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.goToCalendar,
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                groupName,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l.refresh,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: isLoading ? null : onRefresh,
        ),
        IconButton(
          tooltip: l.tabDay,
          icon: const Icon(Icons.today_outlined),
          onPressed: onJumpToToday,
        ),
      ],
    );
  }
}
