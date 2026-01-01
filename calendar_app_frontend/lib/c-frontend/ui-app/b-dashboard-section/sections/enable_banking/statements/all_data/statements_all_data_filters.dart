import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../statements_controller.dart';

class StatementsAllDataFilters extends StatelessWidget {
  const StatementsAllDataFilters({
    super.key,
    required this.controller,
    required this.yearController,
    required this.fromController,
    required this.toController,
    required this.onApply,
    required this.onClear,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onPickRange,
    this.showTitle = true,
  });

  final StatementsController controller;
  final TextEditingController yearController;
  final TextEditingController fromController;
  final TextEditingController toController;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onPickRange;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(l.statementsFiltersTitle, style: typography.bodyMedium),
            const SizedBox(height: 6),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: yearController,
                  decoration: InputDecoration(
                    labelText: l.statementsFilterYear,
                    hintText: '2025',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: fromController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l.statementsFilterFrom,
                    hintText: 'YYYY-MM-DD',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  onTap: controller.loadingAllEntries ? null : onPickFrom,
                ),
              ),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: toController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l.statementsFilterTo,
                    hintText: 'YYYY-MM-DD',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  ),
                  onTap: controller.loadingAllEntries ? null : onPickTo,
                ),
              ),
              TextButton.icon(
                onPressed: controller.loadingAllEntries ? null : onPickRange,
                icon: const Icon(Icons.date_range_outlined, size: 18),
                label: Text(l.statementsPickRange),
              ),
              FilledButton(
                onPressed: controller.loadingAllEntries ? null : onApply,
                child: Text(l.statementsApplyFilters),
              ),
              TextButton(
                onPressed: controller.loadingAllEntries ? null : onClear,
                child: Text(l.statementsClearFilters),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatementsAllDataPresets extends StatelessWidget {
  const StatementsAllDataPresets({
    super.key,
    required this.controller,
    required this.onSelect,
  });

  final StatementsController controller;
  final void Function(DateTime from, DateTime to, int? year) onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(l.statementsPresetsTitle, style: typography.bodySmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: Text(l.statementsPresetThisMonth),
              onPressed: controller.loadingAllEntries
                  ? null
                  : () {
                      final now = DateTime.now();
                      final from = DateTime(now.year, now.month, 1);
                      final to = DateTime(now.year, now.month + 1, 0);
                      onSelect(from, to, now.year);
                    },
            ),
            ActionChip(
              label: Text(l.statementsPresetLast30Days),
              onPressed: controller.loadingAllEntries
                  ? null
                  : () {
                      final now = DateTime.now();
                      final from = now.subtract(const Duration(days: 30));
                      onSelect(from, now, null);
                    },
            ),
            ActionChip(
              label: Text(l.statementsPresetThisYear),
              onPressed: controller.loadingAllEntries
                  ? null
                  : () {
                      final now = DateTime.now();
                      final from = DateTime(now.year, 1, 1);
                      final to = DateTime(now.year, 12, 31);
                      onSelect(from, to, now.year);
                    },
            ),
          ],
        ),
      ],
    );
  }
}

class StatementsAllDataPagination extends StatelessWidget {
  const StatementsAllDataPagination({
    super.key,
    required this.controller,
    required this.sizeOptions,
    required this.totalPages,
    required this.onSizeChanged,
    required this.onPrev,
    required this.onNext,
  });

  final StatementsController controller;
  final List<int> sizeOptions;
  final int totalPages;
  final void Function(int value) onSizeChanged;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.statementsPaginationTitle, style: typography.bodySmall),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: controller.allEntriesSize,
            decoration: InputDecoration(
              labelText: l.statementsPageSize,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            items: sizeOptions
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v.toString()),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              onSizeChanged(v);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                l.statementsPageInfo(controller.allEntriesPage, totalPages),
                style:
                    typography.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              IconButton(
                tooltip: l.statementsPrevPage,
                onPressed: controller.allEntriesPage > 1 ? onPrev : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: l.statementsNextPage,
                onPressed: controller.allEntriesPage < totalPages ? onNext : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
