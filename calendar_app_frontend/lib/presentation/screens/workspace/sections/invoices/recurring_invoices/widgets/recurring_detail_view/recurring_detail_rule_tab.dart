import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_schedule_form.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RecurringDetailRuleTab extends StatelessWidget {
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
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEnd;
  final ValueChanged<String> onEndTypeChanged;
  final ValueChanged<String> onTimezoneChanged;
  final VoidCallback onPickTimezone;
  final VoidCallback onAddException;
  final ValueChanged<DateTime> onRemoveException;
  final ValueChanged<String> onInvoiceDateModeChanged;
  final ValueChanged<String> onInvoiceDateClampPolicyChanged;
  final bool canManage;
  final bool saving;
  final VoidCallback onSave;
  final String? errorText;
  final String issueDatePolicySummary;
  final String originalIssueDatePolicySummary;
  final Map<String, dynamic> originalSeries;
  final String clientName;
  final bool startReadOnly;
  final bool showInvoiceDatePolicy;

  const RecurringDetailRuleTab({
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
    required this.onPickStartTime,
    required this.onPickEnd,
    required this.onEndTypeChanged,
    required this.onTimezoneChanged,
    required this.onPickTimezone,
    required this.onAddException,
    required this.onRemoveException,
    required this.onInvoiceDateModeChanged,
    required this.onInvoiceDateClampPolicyChanged,
    required this.canManage,
    required this.saving,
    required this.onSave,
    this.errorText,
    required this.issueDatePolicySummary,
    required this.originalIssueDatePolicySummary,
    required this.originalSeries,
    required this.clientName,
    this.startReadOnly = false,
    this.showInvoiceDatePolicy = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = l.localeName.toLowerCase().startsWith('es');

    DateTime? parseMaybeDate(dynamic raw) {
      if (raw is DateTime) return raw;
      if (raw is String && raw.trim().isNotEmpty) return DateTime.tryParse(raw);
      return null;
    }

    final originalRule = (originalSeries['rule'] as Map?) ?? const {};
    dynamic originalField(String key) =>
        originalRule[key] ?? originalSeries[key];

    String freqLabel(String value) {
      return recurringFrequencyLabel(l, value);
    }

    // ── Normalised before/after values ───────────────────────────────────────
    // Compare canonical values, never display labels, so equivalent values
    // ("Europe/Madrid" vs "Madrid", a stored start date + timeOfDay vs the
    // loaded start) are not reported as changes.
    final dateFmt = DateFormat('d MMM y', l.localeName);
    final dateTimeFmt = DateFormat('d MMM y · HH:mm', l.localeName);

    // Original start as wall-clock time, rebuilt the same way the editor
    // loads it: stored date + timeOfDay (when present).
    DateTime? originalStartWall() {
      final parsed = parseMaybeDate(originalField('startDate'));
      if (parsed == null) return null;
      final tod = parseTimeOfDay(originalField('timeOfDay'));
      return DateTime(parsed.year, parsed.month, parsed.day,
          tod?.hour ?? parsed.hour, tod?.minute ?? parsed.minute);
    }

    final nowStartWall = DateTime(startDate.year, startDate.month,
        startDate.day, startDate.hour, startDate.minute);
    final beforeStart = originalStartWall();

    String normalizedTimezone(String? raw) =>
        timezoneLabelFrom(raw).trim().toLowerCase();
    final originalTimezoneRaw = (originalField('timezone') ?? '').toString();

    int? asInt(dynamic raw) => int.tryParse((raw ?? '').toString().trim());

    String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
    final originalExceptionDays = <String>{
      if (originalField('exceptions') is List)
        for (final e in originalField('exceptions') as List)
          if (parseMaybeDate(e) != null) dayKey(parseMaybeDate(e)!),
    };
    final nowExceptionDays = {for (final e in exceptions) dayKey(e)};

    // End condition as (type, value) for comparison.
    final originalEndDate = parseMaybeDate(originalField('endDate'));
    final originalCount = asInt(originalField('count'));
    final originalEndKey = originalEndDate != null
        ? 'date:${dayKey(originalEndDate)}'
        : originalCount != null
            ? 'count:$originalCount'
            : 'never';
    final nowCount = asInt(countCtrl.text);
    final nowEndKey = endType == 'date' && endDate != null
        ? 'date:${dayKey(endDate!)}'
        : endType == 'count' && nowCount != null
            ? 'count:$nowCount'
            : 'never';

    final normFreq = normalizeFrequencyFromApi(freq);
    final originalFreq = normalizeFrequencyFromApi((originalField('freq') ??
            originalField('frequency') ??
            recurringFreqMonthly)
        .toString());
    final usesMonthDay = normFreq == recurringFreqMonthly ||
        normFreq == recurringFreqBimensual ||
        normFreq == recurringFreqTrimestral;
    final originalBillDay = asInt(originalField('billDay'));

    String exceptionsLabel(int count) =>
        count == 0 ? l.recurringInvoicesNoExceptions : '$count';

    final changes = <_RuleChange>[
      if (originalFreq != normFreq)
        _RuleChange(l.recurringInvoicesFrequencyLabel, freqLabel(originalFreq),
            freqLabel(normFreq)),
      if ((asInt(originalField('interval')) ?? 1) !=
          (asInt(intervalCtrl.text) ?? 1))
        _RuleChange(
          l.recurringInvoicesIntervalLabel,
          '${asInt(originalField('interval')) ?? 1}',
          '${asInt(intervalCtrl.text) ?? 1}',
        ),
      if (beforeStart == null || beforeStart != nowStartWall)
        if (beforeStart != null && dayKey(beforeStart) == dayKey(nowStartWall))
          _RuleChange(
            isEs ? 'Hora de inicio' : 'Start time',
            DateFormat.Hm(l.localeName).format(beforeStart),
            DateFormat.Hm(l.localeName).format(nowStartWall),
          )
        else
          _RuleChange(
            l.recurringInvoicesStartLabel,
            beforeStart == null ? '-' : dateTimeFmt.format(beforeStart),
            dateTimeFmt.format(nowStartWall),
          ),
      if (originalEndKey != nowEndKey)
        _RuleChange(
          l.recurringInvoicesEndLabel,
          originalEndDate != null
              ? dateFmt.format(originalEndDate)
              : originalCount?.toString() ?? l.recurringInvoicesEndNever,
          endType == 'date' && endDate != null
              ? dateFmt.format(endDate!)
              : endType == 'count' && nowCount != null
                  ? '$nowCount'
                  : l.recurringInvoicesEndNever,
        ),
      if (usesMonthDay && originalBillDay != asInt(billDayCtrl.text))
        _RuleChange(
          isEs ? 'Día de ejecución' : 'Execution day',
          originalBillDay?.toString() ?? '-',
          asInt(billDayCtrl.text)?.toString() ?? '-',
        ),
      if (normFreq == recurringFreqWeekly &&
          originalBillDay != asInt(weekDayCtrl.text))
        _RuleChange(
          l.recurringInvoicesWeekDayLabel,
          originalBillDay?.toString() ?? '-',
          asInt(weekDayCtrl.text)?.toString() ?? '-',
        ),
      if (normalizedTimezone(originalTimezoneRaw.isEmpty
              ? timezoneLabel
              : originalTimezoneRaw) !=
          normalizedTimezone(timezoneLabel))
        _RuleChange(
          l.recurringInvoicesTimezoneLabel,
          timezoneLabelFrom(originalTimezoneRaw),
          timezoneLabel,
        ),
      if (showInvoiceDatePolicy &&
          originalIssueDatePolicySummary.trim() !=
              issueDatePolicySummary.trim())
        _RuleChange(
          isEs ? 'Fecha de factura' : 'Invoice date',
          originalIssueDatePolicySummary,
          issueDatePolicySummary,
        ),
      if (originalExceptionDays.length != nowExceptionDays.length ||
          !originalExceptionDays.containsAll(nowExceptionDays))
        _RuleChange(
          l.recurringInvoicesExceptionsLabel,
          exceptionsLabel(originalExceptionDays.length),
          exceptionsLabel(nowExceptionDays.length),
        ),
    ];

    Widget changeRow(_RuleChange change) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: .35)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              change.label,
              style: t.bodySmall.copyWith(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 2,
              children: [
                Text(
                  change.before,
                  style: t.bodySmall.copyWith(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: cs.onSurfaceVariant.withValues(alpha: .6),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    size: 14, color: cs.onSurfaceVariant),
                Text(
                  change.now,
                  style: t.bodySmall.copyWith(
                    fontSize: 13,
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget whiteCard({required Key key, required Widget child}) => Container(
          key: key,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.primary.withValues(alpha: .10)),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: .035),
                blurRadius: 14,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: child,
        );

    Widget headingIcon(IconData icon) => Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cs.primary, size: 23),
        );

    Widget summaryCard() {
      final count = changes.length;
      return whiteCard(
        key: const ValueKey('rule-change-summary'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                headingIcon(Icons.description_outlined),
                Expanded(
                  child: Text(
                    isEs ? 'Resumen de cambios' : 'Change summary',
                    style: t.bodyMedium.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    key: const ValueKey('rule-change-count'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isEs
                          ? '$count ${count == 1 ? 'cambio' : 'cambios'}'
                          : '$count ${count == 1 ? 'change' : 'changes'}',
                      style: t.bodySmall.copyWith(
                        fontSize: 11.5,
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            if (clientName.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                clientName.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (count == 0)
              Row(
                key: const ValueKey('rule-no-changes'),
                children: [
                  Icon(Icons.check_circle_rounded, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEs ? 'No hay cambios pendientes' : 'No pending changes',
                      style: t.bodySmall.copyWith(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              )
            else
              for (final change in changes) changeRow(change),
          ],
        ),
      );
    }

    final form = RecurringScheduleForm(
      freq: freq,
      intervalCtrl: intervalCtrl,
      startDate: startDate,
      endType: endType,
      endDate: endDate,
      countCtrl: countCtrl,
      billDayCtrl: billDayCtrl,
      weekDayCtrl: weekDayCtrl,
      timezoneCtrl: timezoneCtrl,
      invoiceDateMode: invoiceDateMode,
      invoiceDateDayCtrl: invoiceDateDayCtrl,
      invoiceDateOffsetDaysCtrl: invoiceDateOffsetDaysCtrl,
      invoiceDateClampPolicy: invoiceDateClampPolicy,
      showInvoiceDatePolicy: showInvoiceDatePolicy,
      timezoneLabel: timezoneLabel,
      exceptions: exceptions,
      onFreqChanged: onFreqChanged,
      onPickStart: onPickStart,
      onPickStartTime: onPickStartTime,
      onPickEnd: onPickEnd,
      onEndTypeChanged: onEndTypeChanged,
      onTimezoneChanged: onTimezoneChanged,
      onPickTimezone: onPickTimezone,
      onAddException: onAddException,
      onRemoveException: onRemoveException,
      onInvoiceDateModeChanged: onInvoiceDateModeChanged,
      onInvoiceDateClampPolicyChanged: onInvoiceDateClampPolicyChanged,
      errorText: errorText,
      startReadOnly: startReadOnly,
      allowExecutionTimeEditWhenStartReadOnly: true,
    );

    Widget formCard() {
      return whiteCard(
        key: const ValueKey('rule-schedule-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              headingIcon(Icons.event_note_rounded),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEs ? 'Programación de la regla' : 'Rule schedule',
                    style: t.bodyMedium.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEs
                        ? 'Define cuándo se generan las facturas.'
                        : 'Control when invoices are generated.',
                    style: t.bodySmall.copyWith(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              )),
            ]),
            const SizedBox(height: 12),
            form,
          ],
        ),
      );
    }

    // Compact sticky action bar: stays reachable however long the form gets.
    final actionBar = !canManage
        ? null
        : Container(
            key: const ValueKey('rule-action-bar'),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: .10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    changes.isEmpty
                        ? (isEs ? 'Sin cambios' : 'No changes')
                        : isEs
                            ? '${changes.length} ${changes.length == 1 ? 'cambio pendiente' : 'cambios pendientes'}'
                            : '${changes.length} pending ${changes.length == 1 ? 'change' : 'changes'}',
                    style: t.bodySmall.copyWith(
                      fontSize: 12.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                FilledButton(
                  key: const ValueKey('rule-save'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(132, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: saving ? null : onSave,
                  child: Text(
                    saving
                        ? l.recurringInvoicesSavingRule
                        : l.recurringInvoicesSaveRuleCta,
                  ),
                ),
              ],
            ),
          );

    // Light-blue canvas; the two white cards end where their content ends.
    return ColoredBox(
      key: const ValueKey('rule-canvas'),
      color: cs.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        formCard(),
                        const SizedBox(height: 14),
                        summaryCard(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: formCard()),
                      const SizedBox(width: 14),
                      Expanded(flex: 3, child: summaryCard()),
                    ],
                  );
                },
              ),
            ),
          ),
          if (actionBar != null) actionBar,
        ],
      ),
    );
  }
}

class _RuleChange {
  const _RuleChange(this.label, this.before, this.now);
  final String label;
  final String before;
  final String now;
}
