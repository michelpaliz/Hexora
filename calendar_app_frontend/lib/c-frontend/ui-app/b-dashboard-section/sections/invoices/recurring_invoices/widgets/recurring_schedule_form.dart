import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
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
  final String invoiceDateMode;
  final TextEditingController invoiceDateDayCtrl;
  final TextEditingController invoiceDateOffsetDaysCtrl;
  final String invoiceDateClampPolicy;
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
  final ValueChanged<String> onInvoiceDateModeChanged;
  final ValueChanged<String> onInvoiceDateClampPolicyChanged;
  final String? errorText;
  final bool startReadOnly;
  final bool allowExecutionTimeEditWhenStartReadOnly;

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
    required this.invoiceDateMode,
    required this.invoiceDateDayCtrl,
    required this.invoiceDateOffsetDaysCtrl,
    required this.invoiceDateClampPolicy,
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
    required this.onInvoiceDateModeChanged,
    required this.onInvoiceDateClampPolicyChanged,
    this.errorText,
    this.startReadOnly = false,
    this.allowExecutionTimeEditWhenStartReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
    );
    final fieldFill = cs.surface;
    final inputTextStyle = t.bodySmall.copyWith(color: cs.onSurface, fontSize: 13);
    final labelStyle = t.bodySmall.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurfaceVariant,
      fontSize: 11,
    );
    final hintStyle = t.bodySmall.copyWith(color: cs.onSurfaceVariant, fontSize: 11);
    final buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      foregroundColor: cs.onSurface,
      backgroundColor: fieldFill,
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: t.bodySmall.copyWith(fontSize: 13),
    );
    final dropdownTheme = Theme.of(context).copyWith(
      canvasColor: cs.surface,
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surface,
        textStyle: t.bodyMedium.copyWith(color: cs.onSurface),
      ),
    );
    const fieldSpacing = 8.0;
    const tightSpacing = 4.0;

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
            const BoxConstraints(minWidth: 36, minHeight: 36),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
        final wide = constraints.maxWidth >= 460;
        final normalizedFreq = normalizeFrequencyFromApi(freq);
        final isMonthly = normalizedFreq == recurringFreqMonthly ||
            normalizedFreq == recurringFreqBimensual ||
            normalizedFreq == recurringFreqTrimestral;
        final isWeekly = normalizedFreq == recurringFreqWeekly;
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

        final endTypeField = Theme(
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
        );

        Widget endCompanionField() {
          if (endType == 'date') {
            return OutlinedButton.icon(
              onPressed: onPickEnd,
              style: buttonStyle,
              icon: const Icon(Icons.event_busy_outlined),
              label: Text(endDateLabel, style: inputTextStyle),
            );
          }
          if (endType == 'count') {
            return TextFormField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              style: inputTextStyle,
              decoration: fieldDecoration(
                label: l.recurringInvoicesCountLabel,
                icon: Icons.numbers_outlined,
              ),
            );
          }
          return const SizedBox.shrink();
        }

        Widget executionTimeField() {
          return OutlinedButton.icon(
            onPressed: startReadOnly && !allowExecutionTimeEditWhenStartReadOnly
                ? null
                : onPickStartTime,
            style: buttonStyle,
            icon: const Icon(Icons.access_time_outlined),
            label: Text(
              '${isEs ? 'Hora de ejecucion' : 'Execution time'}: ${TimeOfDay.fromDateTime(startDate).format(context)}',
              style: inputTextStyle,
            ),
          );
        }

        Widget executionDayField() {
          if (isMonthly) {
            return TextFormField(
              controller: billDayCtrl,
              keyboardType: TextInputType.number,
              style: inputTextStyle,
              decoration: fieldDecoration(
                label:
                    isEs ? 'Dia de ejecucion (1-31)' : 'Execution day (1-31)',
                icon: Icons.calendar_today_outlined,
              ),
            );
          }
          return TextFormField(
            controller: weekDayCtrl,
            keyboardType: TextInputType.number,
            style: inputTextStyle,
            decoration: fieldDecoration(
              label: l.recurringInvoicesWeekDayLabel,
              icon: Icons.event_note_outlined,
            ),
          );
        }

        final timezoneField = TextFormField(
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
        );
        final Widget invoiceModeCompanion = invoiceDateMode == 'offset_days'
            ? TextFormField(
                controller: invoiceDateOffsetDaysCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                style: inputTextStyle,
                decoration: fieldDecoration(
                  label: isEs
                      ? 'Desfase de dias (-365..365)'
                      : 'Day offset (-365..365)',
                  icon: Icons.exposure_plus_1_outlined,
                ),
              )
            : const SizedBox.shrink();
        final String? scheduleInfoTooltip = isMonthly
            ? '${l.recurringInvoicesBillDayHelper}\n${isEs ? 'Este dia controla cuando se ejecuta la recurrencia.' : 'This day controls when recurring execution happens.'}'
            : isWeekly
                ? l.recurringInvoicesWeekDayHelper
                : null;
        Widget invoiceModeSelector() {
          final executionDayTooltip = isEs
              ? 'Misma fecha de ejecucion.\nLa factura usa el mismo dia en que se ejecuta la recurrencia.\nEjemplo: ejecuta 24 -> factura 24.'
              : 'Same as execution date.\nInvoice date matches recurrence execution day.\nExample: runs on 24 -> invoice dated 24.';
          final fixedDayTooltip = isEs
              ? 'Dia fijo del mes.\nLa factura siempre usa un dia concreto (1-31).\nEjemplo: ejecuta 24 -> factura 28.'
              : 'Fixed day of month.\nInvoice always uses a specific day (1-31).\nExample: runs on 24 -> invoice dated 28.';
          final offsetDaysTooltip = isEs
              ? 'Dias respecto a ejecucion.\nLa fecha factura se calcula con desfase (+/- dias).\nEjemplo: +4 y ejecuta 24 -> factura 28.'
              : 'Offset from execution date.\nInvoice date is calculated with +/- day offset.\nExample: +4 and run on 24 -> invoice dated 28.';
          final String selectedModeText;
          if (invoiceDateMode == 'fixed_day') {
            selectedModeText =
                isEs ? 'Dia fijo del mes' : 'Fixed day of month';
          } else if (invoiceDateMode == 'offset_days') {
            selectedModeText = isEs
                ? 'Dias respecto a ejecucion'
                : 'Offset from execution date';
          } else {
            selectedModeText = isEs
                ? 'Misma fecha de ejecucion'
                : 'Same as execution date';
          }
          ({String executionDay, String issueDay}) previewValues() {
            final executionDay = billDayCtrl.text.trim().isEmpty
                ? '--'
                : billDayCtrl.text.trim();
            final issueDay = invoiceDateMode == 'fixed_day'
                ? (invoiceDateDayCtrl.text.trim().isEmpty
                    ? '--'
                    : invoiceDateDayCtrl.text.trim())
                : invoiceDateMode == 'offset_days'
                    ? '${invoiceDateOffsetDaysCtrl.text.trim().isEmpty ? '0' : invoiceDateOffsetDaysCtrl.text.trim()}d'
                    : executionDay;
            return (executionDay: executionDay, issueDay: issueDay);
          }

          Widget modeItem({
            required String value,
            required IconData icon,
            required String tooltip,
          }) {
            final selected = invoiceDateMode == value;
            return Tooltip(
              message: tooltip,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onInvoiceDateModeChanged(value),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? cs.primary : cs.outlineVariant,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 18,
                    color: selected ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  modeItem(
                    value: 'execution_day',
                    icon: Icons.calendar_today_outlined,
                    tooltip: executionDayTooltip,
                  ),
                  const SizedBox(width: 8),
                  modeItem(
                    value: 'fixed_day',
                    icon: Icons.event_available_outlined,
                    tooltip: fixedDayTooltip,
                  ),
                  const SizedBox(width: 8),
                  modeItem(
                    value: 'offset_days',
                    icon: Icons.timeline_outlined,
                    tooltip: offsetDaysTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: Listenable.merge([
                  billDayCtrl,
                  invoiceDateDayCtrl,
                  invoiceDateOffsetDaysCtrl,
                ]),
                builder: (_, __) {
                  final p = previewValues();
                  return RichText(
                    text: TextSpan(
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                      children: [
                        TextSpan(
                          text: '$selectedModeText · ',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: isEs ? 'Ejecucion ' : 'Execution '),
                        TextSpan(
                          text: p.executionDay,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: isEs ? 'Fecha factura ' : 'Invoice date ',
                        ),
                        TextSpan(
                          text: p.issueDay,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
                  value: normalizedFreq,
                  style: inputTextStyle,
                  dropdownColor: cs.surface,
                  decoration: fieldDecoration(
                    label: l.recurringInvoicesFrequencyLabel,
                    icon: Icons.repeat_outlined,
                  ),
                  items: recurringFrequencyDropdownOrder
                      .map(
                        (f) => DropdownMenuItem(
                          value: f,
                          child: Text(
                            recurringFrequencyLabel(l, f),
                            style: t.bodyMedium.copyWith(color: cs.onSurface),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (v) => onFreqChanged(
                    canonicalFrequencyForApi(v ?? recurringFreqMonthly),
                  ),
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
            if (isMonthly || isWeekly) ...[
              twoCol(executionDayField(), executionTimeField()),
              const SizedBox(height: fieldSpacing),
            ],
            if (!startReadOnly)
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
                (isMonthly || isWeekly)
                    ? const SizedBox.shrink()
                    : executionTimeField(),
              ),
            const SizedBox(height: fieldSpacing),
            twoCol(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  endTypeField,
                  if (endType != 'never') ...[
                    const SizedBox(height: tightSpacing),
                    endCompanionField(),
                  ],
                ],
              ),
              timezoneField,
            ),
            if (scheduleInfoTooltip != null) const SizedBox(height: tightSpacing),
            const SizedBox(height: fieldSpacing),
            twoCol(
              invoiceModeSelector(),
              invoiceModeCompanion,
            ),
            if (invoiceDateMode == 'fixed_day') ...[
              const SizedBox(height: fieldSpacing),
              twoCol(
                TextFormField(
                  controller: invoiceDateDayCtrl,
                  keyboardType: TextInputType.number,
                  style: inputTextStyle,
                  decoration: fieldDecoration(
                    label: isEs ? 'Dia de emision (1-31)' : 'Issue day (1-31)',
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
                Theme(
                  data: dropdownTheme,
                  child: DropdownButtonFormField<String>(
                    value: invoiceDateClampPolicy,
                    style: inputTextStyle,
                    dropdownColor: cs.surface,
                    decoration: fieldDecoration(
                      label:
                          isEs ? 'Si el dia no existe' : 'If day does not exist',
                      icon: Icons.rule_outlined,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'end_of_month',
                        child: Text(
                          isEs
                              ? 'Usar ultimo dia del mes'
                              : 'Use last day of month',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'error',
                        child: Text(isEs ? 'Mostrar error' : 'Return error'),
                      ),
                    ],
                    onChanged: (v) => onInvoiceDateClampPolicyChanged(
                      v ?? 'end_of_month',
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: fieldSpacing),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.recurringInvoicesExceptionsLabel,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
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
            if ((errorText ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: fieldSpacing),
              Text(
                errorText!,
                style: t.bodySmall.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

