import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:provider/provider.dart';

import 'statements_controller.dart';
import 'statements_formatters.dart';
import 'history/statements_history_widgets.dart';

class StatementsFreshnessBanner extends StatelessWidget {
  const StatementsFreshnessBanner({
    super.key,
    required this.controller,
    required this.batchId,
    this.showThresholdSelector = false,
  });

  final StatementsController controller;
  final String? batchId;
  final bool showThresholdSelector;

  @override
  Widget build(BuildContext context) {
    final id = batchId;
    if (id == null || id.isEmpty) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final thresholdOptions = const [3, 5, 7];

    final status = controller.batchStatus[id];
    final statusLoading = controller.loadingStatus[id] == true;
    final statusErr = controller.statusError[id];
    final autoImportEnabled =
        context.watch<AuthProvider>().currentUser?.autoStatementImportEnabled ??
            false;
    final reminder = controller.reminderSettings[id];
    final reminderLoading = controller.loadingReminderSettings[id] == true;
    final reminderErr = controller.reminderSettingsError[id];
    final reminderSaving = controller.savingReminderSettings[id] == true;

    if (!statusLoading && status == null && statusErr == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchBatchStatus(id);
      });
    }

    final isStale = status?['stale'] == true;
    final isAdmin = status?['isAdmin'] == true;
    final lastDate = status?['lastDate'];
    final daysSince = status?['daysSince'];
    final hasLastDate = lastDate != null && lastDate.toString().isNotEmpty;
    final lastDateLabel = hasLastDate
        ? StatementsFormatters.formatDate(context, lastDate)
        : '';
    final daysLabel = daysSince == null
        ? ''
        : StatementsFormatters.formatCount(context, daysSince);
    if (!statusLoading &&
        status != null &&
        isAdmin &&
        !autoImportEnabled &&
        reminder == null &&
        reminderErr == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchReminderSettings(id);
      });
    }

    final freshnessLabel = !hasLastDate
        ? l.statementsFreshnessNoData
        : isStale
            ? l.statementsFreshnessStale(lastDateLabel, daysLabel)
            : l.statementsFreshnessUpToDate(lastDateLabel);
    final freshnessColor = isStale ? cs.error : cs.primary;
    final reminderEnabled = reminder?['enabled'] == true;
    final reminderThreshold =
        (reminder?['thresholdDays'] as num?)?.toInt() ??
            controller.statusThreshold;

    Widget buildBadge() {
      if (statusLoading) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(l.statementsFreshnessLoading),
          ],
        );
      }
      if (statusErr != null) {
        return Text(
          statusErr,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.error),
        );
      }
      if (status == null) {
        return const SizedBox.shrink();
      }
      return StatusBadge(
        label: freshnessLabel,
        color: freshnessColor,
        icon:
            isStale ? Icons.warning_amber_outlined : Icons.check_circle_outline,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          buildBadge(),
          if (!autoImportEnabled)
            Text(
              !isAdmin
                  ? l.statementsReminderStatusUnknown
                  : reminderEnabled
                      ? l.statementsReminderStatusOn(reminderThreshold)
                      : l.statementsReminderStatusOff,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          if (showThresholdSelector)
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<int>(
                initialValue: controller.statusThreshold,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.statementsFreshnessThreshold,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                items: thresholdOptions
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  controller.setStatusThreshold(v);
                },
              ),
            ),
          if (isAdmin && !autoImportEnabled) ...[
            if (reminderLoading)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.statementsReminderSettingsLoading,
                    style: t.bodySmall,
                  ),
                ],
              )
            else if (reminderErr != null)
              Text(
                reminderErr,
                style: t.bodySmall.copyWith(color: cs.error),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.statementsReminderSettingsAuto, style: t.bodySmall),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 38,
                    height: 22,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Switch(
                        value: reminderEnabled,
                        onChanged: reminderSaving
                            ? null
                            : (value) async {
                                final r = await controller.saveReminderSettings(
                                  id,
                                  enabled: value,
                                  thresholdDays: reminderThreshold,
                                );
                                if (!context.mounted) return;
                                final ok = r != null;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? l.statementsReminderSettingsSaved
                                        : l.statementsReminderSettingsFailed),
                                  ),
                                );
                              },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 96,
                    child: DropdownButtonFormField<int>(
                      initialValue: reminderThreshold,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l.statementsReminderSettingsThreshold,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      items: thresholdOptions
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(v.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: reminderSaving
                          ? null
                          : (v) async {
                              if (v == null) return;
                              final r = await controller.saveReminderSettings(
                                id,
                                enabled: reminderEnabled,
                                thresholdDays: v,
                              );
                              if (!context.mounted) return;
                              final ok = r != null;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? l.statementsReminderSettingsSaved
                                      : l.statementsReminderSettingsFailed),
                                ),
                              );
                            },
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
