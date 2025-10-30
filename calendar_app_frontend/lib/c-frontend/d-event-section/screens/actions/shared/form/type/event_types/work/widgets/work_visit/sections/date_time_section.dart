import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
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

    return cardBuilder(
      title: title,
      child: Padding(
        // more air around the whole block
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isHorizontal = constraints.maxWidth >= 560;

            // Warm, accessible greens/reds (tuned per theme brightness)
            final brightness = Theme.of(context).brightness;
            final startBase = brightness == Brightness.dark
                ? const Color(0xFF1E7A4A) // deep warm green
                : const Color(0xFF2E8B57); // sea green
            final endBase = brightness == Brightness.dark
                ? const Color(0xFF9B2C2C) // deep warm red
                : const Color(0xFFCC3A3A); // warm red

            final startField = _DateFieldTile(
              label: loc.startDate,
              date: startDate,
              onTap: onStartTap,
              icon: Icons.event_available_rounded,
              baseColor: startBase,
            );

            final endField = _DateFieldTile(
              label: loc.endDate,
              date: endDate,
              onTap: onEndTap,
              icon: Icons.event_busy_rounded,
              baseColor: endBase,
            );

            if (isHorizontal) {
              return Row(
                children: [
                  Expanded(child: startField),
                  const SizedBox(width: 16),
                  Expanded(child: endField),
                ],
              );
            } else {
              return Column(
                children: [
                  startField,
                  const SizedBox(height: 16),
                  endField,
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
  final Color baseColor; // warm green or warm red per tile

  const _DateFieldTile({
    required this.label,
    required this.date,
    required this.onTap,
    required this.icon,
    required this.baseColor,
  });

  // Simple EN/ES helper (fallbacks if your l10n doesn’t expose today/tomorrow)
  String _todayWord(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    switch (code) {
      case 'es':
        return 'Hoy';
      default:
        return 'Today';
    }
  }

  String _tomorrowWord(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    switch (code) {
      case 'es':
        return 'Mañana';
      default:
        return 'Tomorrow';
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    final locale =
        Localizations.localeOf(context).toLanguageTag(); // e.g. en, es
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

    // Derived colors for container/text/accents from the base warm color
    final container = Color.lerp(baseColor, cs.surface, 0.70)!;
    final chipBg = Color.lerp(baseColor, cs.surface, 0.20)!;
    final border = Color.lerp(baseColor, cs.outlineVariant, 0.50)!;

    // Choose on-color with decent contrast (simple heuristic)
    Color _on(Color bg) =>
        ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    final onContainer = _on(container);
    final onChip = _on(chipBg);
    final onMuted = onContainer.withOpacity(0.75);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
                color: baseColor.withOpacity(0.16),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                // Icon chip tinted by base color
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: baseColor.withOpacity(0.35), width: 1),
                  ),
                  child: Icon(icon, color: onChip, size: 20),
                ),
                const SizedBox(width: 14),

                // Date text block
                Expanded(
                  child: Tooltip(
                    message: formattedDate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label (Start/End)
                        Text(
                          label,
                          style: typo.bodySmall.copyWith(
                            color: onMuted,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Day of week
                        Text(
                          dayOfWeek,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typo.bodySmall.copyWith(
                            color: onContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Time row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 14, color: onMuted),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: typo.bodyMedium.copyWith(
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
                const SizedBox(width: 12),

                // Mini calendar chip (month + day) using the base tone
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        month.toUpperCase(),
                        style: typo.bodySmall.copyWith(
                          color: _on(baseColor).withOpacity(0.9),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        day,
                        style: typo.bodyMedium.copyWith(
                          color: _on(baseColor),
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
