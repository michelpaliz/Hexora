import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RecurringScheduleForm extends StatelessWidget {
  final String freq;
  final TextEditingController intervalCtrl;
  final DateTime startDate;
  final String endType;
  final DateTime? endDate;
  final TextEditingController countCtrl;
  final TextEditingController billDayCtrl;
  final TextEditingController weekDayCtrl;
  final TextEditingController timezoneCtrl;
  final String timezoneLabel;
  final List<DateTime> exceptions;
  final ValueChanged<String> onFreqChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<String> onEndTypeChanged;
  final ValueChanged<String> onTimezoneChanged;
  final VoidCallback onPickTimezone;
  final VoidCallback onAddException;
  final ValueChanged<DateTime> onRemoveException;
  final VoidCallback onPickStartTime;

  const RecurringScheduleForm({
    super.key,
    required this.freq,
    required this.intervalCtrl,
    required this.startDate,
    required this.endType,
    required this.endDate,
    required this.countCtrl,
    required this.billDayCtrl,
    required this.weekDayCtrl,
    required this.timezoneCtrl,
    required this.timezoneLabel,
    required this.exceptions,
    required this.onFreqChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onEndTypeChanged,
    required this.onTimezoneChanged,
    required this.onPickTimezone,
    required this.onAddException,
    required this.onRemoveException,
    required this.onPickStartTime,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.65)),
    );
    final fieldFill = cs.surface;
    final inputTextStyle = t.bodyLarge.copyWith(color: cs.onSurface);
    final labelStyle = t.bodySmall.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurfaceVariant,
    );
    final hintStyle = t.bodySmall.copyWith(color: cs.onSurfaceVariant);
    final buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      foregroundColor: cs.onSurface,
      backgroundColor: fieldFill,
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: t.bodyLarge,
    );
    final dropdownTheme = Theme.of(context).copyWith(
      canvasColor: cs.surface,
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surface,
        textStyle: t.bodyMedium.copyWith(color: cs.onSurface),
      ),
    );
    const fieldSpacing = 10.0;
    const tightSpacing = 6.0;

    InputDecoration fieldDecoration({
      required String label,
      IconData? icon,
      String? hint,
    }) {
      return InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        hintText: hint,
        hintStyle: hintStyle,
        prefixIcon: icon == null ? null : Icon(icon),
        prefixIconColor: cs.primary,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 46, minHeight: 46),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: fieldFill,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final endDateTime = endDate == null
            ? null
            : DateTime(
                endDate!.year,
                endDate!.month,
                endDate!.day,
                startDate.hour,
                startDate.minute,
              );
        final endDateLabel = endDateTime == null
            ? l.recurringInvoicesEndDateSelect
            : '${l.recurringInvoicesEndDateLabel(DateFormat.yMMMd(l.localeName).format(endDate!))} · ${DateFormat.Hm(l.localeName).format(endDateTime)}';
        Widget twoCol(Widget left, Widget right) {
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                left,
                const SizedBox(height: tightSpacing),
                right,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 12),
              Expanded(child: right),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            twoCol(
              Theme(
                data: dropdownTheme,
                child: DropdownButtonFormField<String>(
                  value: freq,
                  style: inputTextStyle,
                  dropdownColor: cs.surface,
                  decoration: fieldDecoration(
                    label: l.recurringInvoicesFrequencyLabel,
                    icon: Icons.repeat_outlined,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text(
                        l.recurringFrequencyDaily,
                        style: t.bodyMedium.copyWith(color: cs.onSurface),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text(
                        l.recurringFrequencyWeekly,
                        style: t.bodyMedium.copyWith(color: cs.onSurface),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text(
                        l.recurringFrequencyMonthly,
                        style: t.bodyMedium.copyWith(color: cs.onSurface),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'yearly',
                      child: Text(
                        l.recurringFrequencyYearly,
                        style: t.bodyMedium.copyWith(color: cs.onSurface),
                      ),
                    ),
                  ],
                  onChanged: (v) => onFreqChanged(v ?? 'monthly'),
                ),
              ),
              TextFormField(
                controller: intervalCtrl,
                keyboardType: TextInputType.number,
                style: inputTextStyle,
                decoration: fieldDecoration(
                  label: l.recurringInvoicesIntervalLabel,
                  icon: Icons.exposure_plus_1_outlined,
                ),
              ),
            ),
            const SizedBox(height: fieldSpacing),
            twoCol(
              OutlinedButton.icon(
                onPressed: onPickStart,
                style: buttonStyle,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  '${l.recurringInvoicesStartLabel}: ${DateFormat.yMMMd(l.localeName).add_Hm().format(startDate)}',
                  style: inputTextStyle,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onPickStartTime,
                style: buttonStyle,
                icon: const Icon(Icons.access_time_outlined),
                label: Text(
                  '${l.recurringInvoicesTimeLabel}: ${TimeOfDay.fromDateTime(startDate).format(context)}',
                  style: inputTextStyle,
                ),
              ),
            ),
            const SizedBox(height: fieldSpacing),
            if (endType == 'date')
              twoCol(
                Theme(
                  data: dropdownTheme,
                  child: DropdownButtonFormField<String>(
                    value: endType,
                    style: inputTextStyle,
                    dropdownColor: cs.surface,
                    decoration: fieldDecoration(
                      label: l.recurringInvoicesEndLabel,
                      icon: Icons.flag_outlined,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'never',
                        child: Text(
                          l.recurringInvoicesEndNever,
                          style: t.bodyMedium.copyWith(color: cs.onSurface),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'date',
                        child: Text(
                          l.recurringInvoicesEndDate,
                          style: t.bodyMedium.copyWith(color: cs.onSurface),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'count',
                        child: Text(
                          l.recurringInvoicesEndCount,
                          style: t.bodyMedium.copyWith(color: cs.onSurface),
                        ),
                      ),
                    ],
                    onChanged: (v) => onEndTypeChanged(v ?? 'never'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onPickEnd,
                  style: buttonStyle,
                  icon: const Icon(Icons.event_busy_outlined),
                  label: Text(endDateLabel, style: inputTextStyle),
                ),
              )
            else if (endType == 'count')
              twoCol(
                Theme(
                  data: dropdownTheme,
                  child: DropdownButtonFormField<String>(
                    value: endType,
                    style: inputTextStyle,
                    dropdownColor: cs.surface,
                    decoration: fieldDecoration(
                      label: l.recurringInvoicesEndLabel,
                      icon: Icons.flag_outlined,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'never',
                        child: Text(
                          l.recurringInvoicesEndNever,
                          style: t.bodyMedium.copyWith(color: cs.onSurface),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'date',
                        child: Text(
                          l.recurringInvoicesEndDate,
                          style: t.bodyMedium.copyWith(color: cs.onSurface),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'count',
                        child: Text(
                          l.recurringInvoicesEndCount,
                          style: t.bodyMedium.copyWith(color: cs.onSurface),
                        ),
                      ),
                    ],
                    onChanged: (v) => onEndTypeChanged(v ?? 'never'),
                  ),
                ),
                TextFormField(
                  controller: countCtrl,
                  keyboardType: TextInputType.number,
                  style: inputTextStyle,
                  decoration: fieldDecoration(
                    label: l.recurringInvoicesCountLabel,
                    icon: Icons.numbers_outlined,
                  ),
                ),
              )
            else
              Theme(
                data: dropdownTheme,
                child: DropdownButtonFormField<String>(
                  value: endType,
                  style: inputTextStyle,
                  dropdownColor: cs.surface,
                  decoration: fieldDecoration(
                    label: l.recurringInvoicesEndLabel,
                    icon: Icons.flag_outlined,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'never',
                      child: Text(
                        l.recurringInvoicesEndNever,
                        style: t.bodyMedium.copyWith(color: cs.onSurface),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'date',
                      child: Text(
                        l.recurringInvoicesEndDate,
                        style: t.bodyMedium.copyWith(color: cs.onSurface),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'count',
                      child: Text(
                        l.recurringInvoicesEndCount,
                        style: t.bodyMedium.copyWith(color: cs.onSurface),
                      ),
                    ),
                  ],
                  onChanged: (v) => onEndTypeChanged(v ?? 'never'),
                ),
              ),
            if (freq == 'monthly') ...[
              const SizedBox(height: fieldSpacing),
              TextFormField(
                controller: billDayCtrl,
                keyboardType: TextInputType.number,
                style: inputTextStyle,
                decoration: fieldDecoration(
                  label: l.recurringInvoicesBillDayLabel,
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(height: tightSpacing),
              Text(
                l.recurringInvoicesBillDayHelper,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if (freq == 'weekly') ...[
              const SizedBox(height: fieldSpacing),
              TextFormField(
                controller: weekDayCtrl,
                keyboardType: TextInputType.number,
                style: inputTextStyle,
                decoration: fieldDecoration(
                  label: l.recurringInvoicesWeekDayLabel,
                  icon: Icons.event_note_outlined,
                ),
              ),
              const SizedBox(height: tightSpacing),
              Text(
                l.recurringInvoicesWeekDayHelper,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: fieldSpacing),
            TextFormField(
              controller: timezoneCtrl,
              style: inputTextStyle,
              decoration: fieldDecoration(
                label: l.recurringInvoicesTimezoneLabel,
                icon: Icons.public,
                hint: timezoneLabel,
              ).copyWith(suffixIcon: const Icon(Icons.expand_more_rounded)),
              onChanged: onTimezoneChanged,
              readOnly: true,
              onTap: onPickTimezone,
            ),
            const SizedBox(height: fieldSpacing),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.recurringInvoicesExceptionsLabel,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddException,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l.recurringInvoicesAddExceptionCta),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    textStyle:
                        t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (exceptions.isEmpty)
              Text(
                l.recurringInvoicesNoExceptions,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: exceptions
                    .map(
                      (d) => Chip(
                        label: Text(
                          DateFormat.yMMMd(l.localeName).format(d),
                          style: t.bodySmall.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor:
                            cs.secondaryContainer.withValues(alpha: 0.6),
                        deleteIconColor: cs.onSecondaryContainer,
                        side: BorderSide(
                          color: cs.secondaryContainer.withValues(alpha: 0.8),
                        ),
                        onDeleted: () => onRemoveException(d),
                      ),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }
}
