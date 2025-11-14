import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/utils/form/reminder_options.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'section_card_builder.dart';

class ReminderSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final bool notifyMe;
  final int? reminderMinutes;
  final ValueChanged<bool> onNotifyChanged;
  final ValueChanged<int?> onReminderChanged;

  const ReminderSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.notifyMe,
    required this.reminderMinutes,
    required this.onNotifyChanged,
    required this.onReminderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;

    // Explicit, high-contrast colors for the switch in both states
    final activeThumb = cs.onPrimary;
    final activeTrack = cs.primary;
    final inactiveThumb = cs.onSurface; // visible on light & dark
    final inactiveTrack =
        cs.outlineVariant.withOpacity(0.55); // distinct from surface

    return cardBuilder(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtle container so the switch always has contrast with the background
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
            ),
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              secondary: Icon(
                notifyMe
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: notifyMe ? cs.primary : cs.onSurfaceVariant,
              ),
              title: Text(
                title,
                style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                notifyMe ? loc.notifyMeOnSubtitle : loc.notifyMeOffSubtitle,
                style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),

              value: notifyMe,
              onChanged: onNotifyChanged,

              // 👇 Force visible colors for both states (works on stable Flutter)
              activeColor: activeThumb, // thumb when ON
              activeTrackColor: activeTrack, // track when ON
              inactiveThumbColor: inactiveThumb, // thumb when OFF
              inactiveTrackColor: inactiveTrack, // track when OFF
            ),
          ),

          // Time picker stays only when enabled
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: notifyMe
                ? Padding(
                    key: const ValueKey('reminder-on'),
                    padding: const EdgeInsets.only(top: 8),
                    child: ReminderTimeDropdownField(
                      initialValue: reminderMinutes,
                      onChanged: onReminderChanged,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('reminder-off')),
          ),
        ],
      ),
    );
  }
}
