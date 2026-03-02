import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../widgets/folder_header_action_button.dart';
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
    this.onPresetSelect,
    this.includePresetsInline = false,
    this.showTitle = true,
    this.compact,
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
  final void Function(DateTime from, DateTime to, int? year)? onPresetSelect;
  final bool includePresetsInline;
  final bool showTitle;
  final bool? compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);
    final isCompact = compact ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(l.statementsFiltersTitle, style: typography.bodyMedium),
          const SizedBox(height: 6),
        ],
        Wrap(
          spacing: isCompact ? 10 : 12,
          runSpacing: isCompact ? 10 : 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: isCompact ? 150 : 140,
              child: _YearInputField(
                controller: yearController,
              ),
            ),
            SizedBox(
              width: isCompact ? 190 : 150,
              child: _DatePickerField(
                value: fromController.text,
                startIcon: Icons.arrow_forward_rounded,
                onTap: controller.loadingAllEntries ? null : onPickFrom,
              ),
            ),
            SizedBox(
              width: isCompact ? 190 : 150,
              child: _DatePickerField(
                value: toController.text,
                startIcon: Icons.arrow_back_rounded,
                onTap: controller.loadingAllEntries ? null : onPickTo,
              ),
            ),
            Tooltip(
              message: l.statementsApplyFilters,
              child: FolderHeaderActionButton(
                selected: true,
                onPressed: controller.loadingAllEntries ? null : onApply,
                icon: const Icon(Icons.search, size: 18),
              ),
            ),
            Tooltip(
              message: l.statementsClearFilters,
              child: FolderHeaderActionButton(
                onPressed: controller.loadingAllEntries ? null : onClear,
                icon: const Icon(Icons.replay, size: 18),
              ),
            ),
            Tooltip(
              message: l.statementsPickRange,
              child: FolderHeaderActionButton(
                onPressed: controller.loadingAllEntries ? null : onPickRange,
                icon: const Icon(Icons.date_range_outlined, size: 18),
              ),
            ),
            if (includePresetsInline && onPresetSelect != null) ...[
              SizedBox(width: isCompact ? 6 : 10),
              ActionChip(
                label: Text(l.statementsPresetThisMonth),
                onPressed: controller.loadingAllEntries
                    ? null
                    : () {
                        final now = DateTime.now();
                        final from = DateTime(now.year, now.month, 1);
                        final to = DateTime(now.year, now.month + 1, 0);
                        onPresetSelect!(from, to, now.year);
                      },
              ),
              ActionChip(
                label: Text(l.statementsPresetLast30Days),
                onPressed: controller.loadingAllEntries
                    ? null
                    : () {
                        final now = DateTime.now();
                        final from = now.subtract(const Duration(days: 30));
                        onPresetSelect!(from, now, null);
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
                        onPresetSelect!(from, to, now.year);
                      },
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.value,
    required this.onTap,
    required this.startIcon,
  });

  final String value;
  final VoidCallback? onTap;
  final IconData startIcon;

  String _formattedDate(String raw) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return 'dd/mm/aaaa';
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? cs.outlineVariant.withValues(alpha: 0.9)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(startIcon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formattedDate(value),
                style: t.bodyMedium.copyWith(
                  color: value.trim().isEmpty ? cs.onSurfaceVariant : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _YearInputField extends StatelessWidget {
  const _YearInputField({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined,
              size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: t.bodyMedium,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '2026',
              ),
            ),
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
    this.compact,
  });

  final StatementsController controller;
  final void Function(DateTime from, DateTime to, int? year) onSelect;
  final bool? compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);
    final isCompact = compact ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isCompact ? 8 : 12),
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
    this.compact,
  });

  final StatementsController controller;
  final List<int> sizeOptions;
  final int totalPages;
  final void Function(int value) onSizeChanged;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool? compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isCompact = compact ?? false;

    if (!isCompact) {
      return SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.statementsPaginationTitle, style: typography.bodySmall),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: controller.allEntriesSize,
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
                  onPressed:
                      controller.allEntriesPage < totalPages ? onNext : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.statementsPageSize.toUpperCase(),
            style: typography.bodySmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 86,
            child: DropdownButtonFormField<int>(
              initialValue: controller.allEntriesSize,
              isDense: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
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
          ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          Text(
            '${controller.allEntriesPage} / $totalPages',
            style: typography.bodySmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l.statementsPrevPage,
            visualDensity: VisualDensity.compact,
            onPressed: controller.allEntriesPage > 1 ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: l.statementsNextPage,
            visualDensity: VisualDensity.compact,
            onPressed: controller.allEntriesPage < totalPages ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
