import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_section_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_schedule_form.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final beforeLabel = isEs ? 'Antes' : 'Before';
    final nowLabel = isEs ? 'Ahora' : 'Now';

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

    String currentEndValue() {
      if (endType == 'never') return l.recurringInvoicesEndNever;
      if (endType == 'date' && endDate != null) {
        return DateFormat.yMMMd(l.localeName).format(endDate!);
      }
      if (endType == 'count' && countCtrl.text.trim().isNotEmpty) {
        return countCtrl.text.trim();
      }
      return l.recurringInvoicesEndNever;
    }

    String originalEndValue() {
      final originalEndDate = parseMaybeDate(originalField('endDate'));
      final originalCount = originalField('count');
      if (originalEndDate != null) {
        return DateFormat.yMMMd(l.localeName).format(originalEndDate);
      }
      if (originalCount != null && originalCount.toString().trim().isNotEmpty) {
        return originalCount.toString().trim();
      }
      return l.recurringInvoicesEndNever;
    }

    Widget compareRow({
      required String label,
      required String before,
      required String now,
    }) {
      final changed = before.trim() != now.trim();
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: changed ? cs.primary.withValues(alpha: 0.06) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: changed
                ? cs.primary.withValues(alpha: 0.34)
                : cs.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                before,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.82),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: Text(
                now,
                style: t.bodySmall.copyWith(
                  color: changed ? cs.primary : cs.onSurface,
                  fontWeight: changed ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget pill({
      required String label,
      required IconData icon,
      bool accent = false,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              accent ? cs.primary.withValues(alpha: 0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent
                ? cs.primary.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.36),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent ? cs.primary : cs.onSurface),
            const SizedBox(width: 6),
            Text(
              label,
              style: t.bodySmall.copyWith(
                color: accent ? cs.primary : cs.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    Widget sectionHeader({
      required IconData icon,
      required String title,
      required String subtitle,
    }) {
      return Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, color: cs.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.bodyLarge.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget detailsCard() {
      final originalFreq = normalizeFrequencyFromApi((originalField('freq') ??
                  originalField('frequency') ??
                  recurringFreqMonthly)
              .toString())
          .toString();
      final originalInterval = (originalField('interval') ?? 1).toString();
      final originalStartDate = parseMaybeDate(originalField('startDate'));
      final originalStartLabel = originalStartDate == null
          ? '-'
          : DateFormat.yMMMd(l.localeName).add_Hm().format(originalStartDate);
      final nowStartLabel =
          DateFormat.yMMMd(l.localeName).add_Hm().format(startDate);
      final originalBillDay =
          (originalField('billDay') ?? '').toString().trim();
      final originalTimezone =
          (originalField('timezone') ?? timezoneLabel).toString().trim();
      final originalExceptions = originalField('exceptions');
      final originalExceptionsLabel =
          (originalExceptions is List && originalExceptions.isNotEmpty)
              ? '${originalExceptions.length}'
              : l.recurringInvoicesNoExceptions;
      final nowExceptionsLabel = exceptions.isEmpty
          ? l.recurringInvoicesNoExceptions
          : '${exceptions.length}';

      return RecurringDetailSectionCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionHeader(
              icon: Icons.compare_arrows_rounded,
              title: isEs ? 'Resumen de cambios' : 'Change summary',
              subtitle: isEs
                  ? 'Comprueba la regla antes de guardarla.'
                  : 'Review the rule before saving it.',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                pill(
                  label: clientName.trim().isEmpty ? '-' : clientName.trim(),
                  icon: Icons.person_outline_rounded,
                  accent: true,
                ),
                pill(
                  label: timezoneLabel,
                  icon: Icons.public_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(flex: 4),
                Expanded(
                  flex: 5,
                  child: Text(
                    beforeLabel,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: Text(
                    nowLabel,
                    style: t.bodySmall.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            compareRow(
              label: l.recurringInvoicesFrequencyLabel,
              before: freqLabel(originalFreq),
              now: freqLabel(freq),
            ),
            compareRow(
              label: l.recurringInvoicesIntervalLabel,
              before: originalInterval,
              now: intervalCtrl.text.trim().isEmpty
                  ? '1'
                  : intervalCtrl.text.trim(),
            ),
            compareRow(
              label: l.recurringInvoicesStartLabel,
              before: originalStartLabel,
              now: nowStartLabel,
            ),
            compareRow(
              label: l.recurringInvoicesEndLabel,
              before: originalEndValue(),
              now: currentEndValue(),
            ),
            if (normalizeFrequencyFromApi(freq) == recurringFreqMonthly ||
                normalizeFrequencyFromApi(freq) == recurringFreqBimensual ||
                normalizeFrequencyFromApi(freq) == recurringFreqTrimestral)
              compareRow(
                label:
                    isEs ? 'Dia de ejecucion (1-31)' : 'Execution day (1-31)',
                before: originalBillDay.isEmpty ? '-' : originalBillDay,
                now: billDayCtrl.text.trim().isEmpty
                    ? '-'
                    : billDayCtrl.text.trim(),
              ),
            if (normalizeFrequencyFromApi(freq) == recurringFreqWeekly)
              compareRow(
                label: l.recurringInvoicesWeekDayLabel,
                before: originalBillDay.isEmpty ? '-' : originalBillDay,
                now: weekDayCtrl.text.trim().isEmpty
                    ? '-'
                    : weekDayCtrl.text.trim(),
              ),
            compareRow(
              label: l.recurringInvoicesTimezoneLabel,
              before: originalTimezone,
              now: timezoneLabel,
            ),
            compareRow(
              label: isEs
                  ? 'Fecha de emision de factura'
                  : 'Invoice issue date policy',
              before: originalIssueDatePolicySummary,
              now: issueDatePolicySummary,
            ),
            compareRow(
              label: l.recurringInvoicesExceptionsLabel,
              before: originalExceptionsLabel,
              now: nowExceptionsLabel,
            ),
          ],
        ),
      );
    }

    final saveButton = canManage
        ? FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: saving ? null : onSave,
            child: Text(
              saving
                  ? l.recurringInvoicesSavingRule
                  : l.recurringInvoicesSaveRuleCta,
            ),
          )
        : const SizedBox.shrink();

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
      return RecurringDetailSectionCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionHeader(
              icon: Icons.event_repeat_rounded,
              title: isEs ? 'Programacion de la regla' : 'Rule schedule',
              subtitle: isEs
                  ? 'Define cuando se crean las proximas facturas.'
                  : 'Control when upcoming invoices are created.',
            ),
            const SizedBox(height: 20),
            form,
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    formCard(),
                    const SizedBox(height: 18),
                    detailsCard(),
                    if (canManage) ...[
                      const SizedBox(height: 16),
                      saveButton,
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: formCard()),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        detailsCard(),
                        if (canManage) ...[
                          const SizedBox(height: 16),
                          saveButton,
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
