import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'section_card_builder.dart';

class DateTimeSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const DateTimeSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.startDate,
    required this.endDate,
    required this.onStartTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final startLocal = startDate.toLocal();
    final endLocal = endDate.toLocal();

    return cardBuilder(
      title: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isHorizontal = constraints.maxWidth >= 560;

            final brightness = Theme.of(context).brightness;
            final startBase = brightness == Brightness.dark
                ? const Color(0xFF1E7A4A)
                : const Color(0xFF2E8B57);
            final endBase = brightness == Brightness.dark
                ? const Color(0xFF9B2C2C)
                : const Color(0xFFCC3A3A);

            final startField = _DateFieldTile(
              label: loc.startDate,
              date: startLocal,
              onTap: onStartTap,
              icon: Icons.event_available_rounded,
              baseColor: startBase,
            );

            final endField = _DateFieldTile(
              label: loc.endDate,
              date: endLocal,
              onTap: onEndTap,
              icon: Icons.event_busy_rounded,
              baseColor: endBase,
            );

            if (isHorizontal) {
              return Row(
                children: [
                  Expanded(child: startField),
                  const SizedBox(width: 10),
                  Expanded(child: endField),
                ],
              );
            } else {
              return Column(
                children: [
                  _DateFieldTile(
                    label: loc.startDate,
                    date: startLocal,
                    onTap: onStartTap,
                    icon: Icons.event_available_rounded,
                    baseColor: startBase,
                  ),
                  const SizedBox(height: 10),
                  _DateFieldTile(
                    label: loc.endDate,
                    date: endLocal,
                    onTap: onEndTap,
                    icon: Icons.event_busy_rounded,
                    baseColor: endBase,
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class _DateFieldTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final IconData icon;
  final Color baseColor;

  const _DateFieldTile({
    required this.label,
    required this.date,
    required this.onTap,
    required this.icon,
    required this.baseColor,
  });

  String _todayWord(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code == 'es' ? 'Hoy' : 'Today';
  }

  String _tomorrowWord(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code == 'es' ? 'Mañana' : 'Tomorrow';
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final timeFmt = DateFormat('h:mm a', locale);
    if (dateOnly == today) {
      return '${_todayWord(context)}, ${timeFmt.format(date)}';
    } else if (dateOnly == tomorrow) {
      return '${_tomorrowWord(context)}, ${timeFmt.format(date)}';
    } else {
      return DateFormat('EEE, MMM d, h:mm a', locale).format(date);
    }
  }

  String _formatDay(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return _todayWord(context);
    if (dateOnly == tomorrow) return _tomorrowWord(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('EEEE', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final locale = Localizations.localeOf(context).toLanguageTag();
    final formattedDate = _formatDate(context, date);
    final day = DateFormat('d', locale).format(date);
    final month = DateFormat('MMM', locale).format(date);
    final time = DateFormat('h:mm a', locale).format(date);
    final dayOfWeek = _formatDay(context, date);

    final container = Color.lerp(baseColor, cs.surface, 0.70)!;
    final chipBg = Color.lerp(baseColor, cs.surface, 0.20)!;
    final border = Color.lerp(baseColor, cs.outlineVariant, 0.50)!;

    Color onColor(Color bg) =>
        ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    final onContainer = onColor(container);
    final onChip = onColor(chipBg);
    final onMuted = onContainer.withValues(alpha:0.75);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(container, Colors.white, 0.02)!,
                Color.lerp(container, Colors.black, 0.04)!,
              ],
            ),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha:0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            // ↓ reduced from (16, 18) → (12, 10) for ~30% height reduction
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Icon chip — smaller padding + icon
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: baseColor.withValues(alpha:0.35), width: 1),
                  ),
                  child: Icon(icon, color: onChip, size: 18),
                ),
                const SizedBox(width: 10),

                // Date text block
                Expanded(
                  child: Tooltip(
                    message: formattedDate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: typo.bodySmall.copyWith(
                            color: onMuted,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dayOfWeek,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typo.bodySmall.copyWith(
                            color: onContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 12, color: onMuted),
                            const SizedBox(width: 3),
                            Text(
                              time,
                              style: typo.bodySmall.copyWith(
                                color: onMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Mini calendar chip — smaller (44×44 from 56×56)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        month.toUpperCase(),
                        style: typo.bodySmall.copyWith(
                          color: onColor(baseColor).withValues(alpha:0.9),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        day,
                        style: typo.bodyMedium.copyWith(
                          color: onColor(baseColor),
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
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
