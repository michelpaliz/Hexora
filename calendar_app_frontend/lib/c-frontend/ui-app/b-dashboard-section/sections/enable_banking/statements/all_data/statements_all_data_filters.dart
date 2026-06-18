import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../statements_controller.dart';

class StatementsAllDataFilters extends StatelessWidget {
  const StatementsAllDataFilters({
    super.key,
    required this.controller,
    required this.yearController,
    required this.fromController,
    required this.toController,
    required this.clientProviderController,
    required this.onApply,
    required this.onClear,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onPickRange,
    this.onClientProviderClear,
    this.onPresetSelect,
    this.includePresetsInline = false,
    this.showTitle = true,
    this.compact,
  });

  final StatementsController controller;
  final TextEditingController yearController;
  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController clientProviderController;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final VoidCallback? onClientProviderClear;
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
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(l.statementsFiltersTitle, style: typography.bodyMedium),
          const SizedBox(height: 6),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final tight = constraints.maxWidth < 1180;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: isCompact ? 8 : 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: tight ? 118 : 136,
                      child: _YearInputField(controller: yearController),
                    ),
                    SizedBox(
                      width: tight ? 150 : 172,
                      child: _DatePickerField(
                        value: fromController.text,
                        startIcon: Icons.arrow_forward_rounded,
                        onTap: controller.loadingAllEntries ? null : onPickFrom,
                      ),
                    ),
                    SizedBox(
                      width: tight ? 150 : 172,
                      child: _DatePickerField(
                        value: toController.text,
                        startIcon: Icons.arrow_back_rounded,
                        onTap: controller.loadingAllEntries ? null : onPickTo,
                      ),
                    ),
                    SizedBox(
                      width: tight ? 210 : 240,
                      child: _ClientProviderFilterField(
                        controller: clientProviderController,
                        enabled: !controller.loadingAllEntries,
                        onSubmitted: (_) => onApply(),
                        onClear: onClientProviderClear,
                      ),
                    ),
                    _FilterIconCluster(
                      children: [
                        _FilterIconButton(
                          tooltip: l.statementsApplyFilters,
                          icon: Icons.search,
                          selected: true,
                          onPressed:
                              controller.loadingAllEntries ? null : onApply,
                        ),
                        _FilterIconButton(
                          tooltip: l.statementsClearFilters,
                          icon: Icons.replay,
                          onPressed:
                              controller.loadingAllEntries ? null : onClear,
                        ),
                        _FilterIconButton(
                          tooltip: l.statementsPickRange,
                          icon: Icons.date_range_outlined,
                          onPressed:
                              controller.loadingAllEntries ? null : onPickRange,
                        ),
                      ],
                    ),
                  ],
                ),
                if (includePresetsInline && onPresetSelect != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PresetPill(
                        label: l.statementsPresetThisMonth,
                        onPressed: controller.loadingAllEntries
                            ? null
                            : () {
                                final now = DateTime.now();
                                final from = DateTime(now.year, now.month, 1);
                                final to = DateTime(now.year, now.month + 1, 0);
                                onPresetSelect!(from, to, now.year);
                              },
                      ),
                      _PresetPill(
                        label: l.statementsPresetLast30Days,
                        onPressed: controller.loadingAllEntries
                            ? null
                            : () {
                                final now = DateTime.now();
                                final from =
                                    now.subtract(const Duration(days: 30));
                                onPresetSelect!(from, now, null);
                              },
                      ),
                      _PresetPill(
                        label: isEs ? 'Ultimos 3 meses' : 'Last 3 months',
                        onPressed: controller.loadingAllEntries
                            ? null
                            : () {
                                final now = DateTime.now();
                                final from =
                                    DateTime(now.year, now.month - 3, now.day);
                                onPresetSelect!(from, now, null);
                              },
                      ),
                      _PresetPill(
                        label: l.statementsPresetThisYear,
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
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FilterIconCluster extends StatelessWidget {
  const _FilterIconCluster({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.42)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          minimumSize: const Size(34, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: selected ? cs.onPrimary : cs.onSurfaceVariant,
          backgroundColor: selected ? cs.primary : Colors.transparent,
          disabledForegroundColor: cs.onSurfaceVariant.withValues(alpha: 0.34),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    return ActionChip(
      label: Text(label),
      labelStyle: typography.bodySmall.copyWith(fontWeight: FontWeight.w700),
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.62)),
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? cs.outlineVariant.withValues(alpha: 0.9)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(startIcon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                _formattedDate(value),
                style: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: value.trim().isEmpty ? cs.onSurfaceVariant : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
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
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined,
              size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
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

class _ClientProviderFilterField extends StatelessWidget {
  const _ClientProviderFilterField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
    this.onClear,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final hasText = controller.text.isNotEmpty;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled
              ? cs.outlineVariant.withValues(alpha: 0.9)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.person_search_outlined,
              size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: isEs ? 'Cliente / proveedor' : 'Client / provider',
              ),
            ),
          ),
          if (hasText) ...[
            const SizedBox(width: 2),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                controller.clear();
                onClear?.call();
              },
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.close_rounded,
                    size: 14, color: cs.onSurfaceVariant),
              ),
            ),
          ],
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
