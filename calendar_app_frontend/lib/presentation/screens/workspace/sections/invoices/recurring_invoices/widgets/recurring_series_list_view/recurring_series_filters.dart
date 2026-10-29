import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/presentation/shared/widgets/buttons/buttons.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

class RecurringSeriesFilters extends StatelessWidget {
  const RecurringSeriesFilters({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.activeFilterCount,
    required this.statusOptions,
    required this.selectedStatus,
    required this.onStatusSelected,
    required this.onStatusClear,
    required this.clientOptions,
    required this.selectedClient,
    required this.onClientSelected,
    required this.onClientClear,
    required this.frequencyOptions,
    required this.selectedFrequency,
    required this.onFrequencySelected,
    required this.onFrequencyClear,
    required this.dueSoonOnly,
    required this.onDueSoonChanged,
    required this.showInactiveClients,
    required this.onShowInactiveChanged,
    required this.sortByClientName,
    required this.onSortByClientNameChanged,
    required this.onClearFilters,
    this.allStatusLabel,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final int activeFilterCount;
  final List<String> statusOptions;
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;
  final VoidCallback onStatusClear;
  final List<String> clientOptions;
  final String? selectedClient;
  final ValueChanged<String> onClientSelected;
  final VoidCallback onClientClear;
  final List<String> frequencyOptions;
  final String? selectedFrequency;
  final ValueChanged<String> onFrequencySelected;
  final VoidCallback onFrequencyClear;
  final bool dueSoonOnly;
  final ValueChanged<bool> onDueSoonChanged;
  final bool showInactiveClients;
  final ValueChanged<bool> onShowInactiveChanged;
  final bool sortByClientName;
  final ValueChanged<bool> onSortByClientNameChanged;
  final VoidCallback onClearFilters;
  final String? allStatusLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = l.localeName.startsWith('es');
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: .6)),
    );
    final search = SizedBox(
      key: const ValueKey('recurring-series-search'),
      height: 38,
      child: TextField(
        controller: searchController,
        onChanged: (_) => onSearchChanged(),
        style: t.bodySmall.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: l.clientSearchHint,
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: .55),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: cs.primary, width: 1.3),
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          suffixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: searchController.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip:
                      MaterialLocalizations.of(context).deleteButtonTooltip,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged();
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
        ),
      ),
    );

    final filtersMenu = MenuAnchor(
      style: MenuStyle(
        elevation: const WidgetStatePropertyAll(6),
        backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        _RecurringFilterPanel(
          statusOptions: statusOptions,
          selectedStatus: selectedStatus,
          onStatusSelected: onStatusSelected,
          clientOptions: clientOptions,
          selectedClient: selectedClient,
          onClientSelected: onClientSelected,
          onClientClear: onClientClear,
          frequencyOptions: frequencyOptions,
          selectedFrequency: selectedFrequency,
          onFrequencySelected: onFrequencySelected,
          onFrequencyClear: onFrequencyClear,
          dueSoonOnly: dueSoonOnly,
          onDueSoonChanged: onDueSoonChanged,
          showInactiveClients: showInactiveClients,
          onShowInactiveChanged: onShowInactiveChanged,
        ),
      ],
      builder: (context, controller, _) => HexoraButton(
        key: const ValueKey('recurring-series-filters-button'),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: Icons.tune_rounded,
        label: activeFilterCount == 0
            ? (isEs ? 'Filtros' : 'Filters')
            : '${isEs ? 'Filtros' : 'Filters'} ($activeFilterCount)',
        variant: HexoraButtonVariant.secondary,
        size: HexoraButtonSize.large,
      ),
    );

    final sortLabel = sortByClientName
        ? (isEs ? 'Cliente A-Z' : 'Client A-Z')
        : (isEs ? 'Próxima creación' : 'Next creation');
    final sortMenu = MenuAnchor(
      menuChildren: [
        _SortMenuItem(
          selected: sortByClientName,
          label: isEs ? 'Cliente A-Z' : 'Client A-Z',
          onPressed: () => onSortByClientNameChanged(true),
        ),
        _SortMenuItem(
          selected: !sortByClientName,
          label: isEs ? 'Próxima creación' : 'Next creation',
          onPressed: () => onSortByClientNameChanged(false),
        ),
      ],
      builder: (context, controller, _) => HexoraButton(
        key: const ValueKey('recurring-series-sort-button'),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: Icons.sort_rounded,
        label: sortLabel,
        trailingIcon: Icons.keyboard_arrow_down_rounded,
        variant: HexoraButtonVariant.secondary,
        size: HexoraButtonSize.large,
      ),
    );
    final clear = activeFilterCount == 0
        ? null
        : HexoraButton(
            key: const ValueKey('recurring-series-clear-filters'),
            onPressed: onClearFilters,
            icon: Icons.close_rounded,
            label: l.clientFiltersClear,
            variant: HexoraButtonVariant.ghost,
            size: HexoraButtonSize.large,
          );
    final compactClear = activeFilterCount == 0
        ? null
        : HexoraButton.iconOnly(
            key: const ValueKey('recurring-series-clear-filters'),
            onPressed: onClearFilters,
            icon: Icons.close_rounded,
            tooltip: l.clientFiltersClear,
            variant: HexoraButtonVariant.ghost,
            size: HexoraButtonSize.large,
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 540) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  filtersMenu,
                  sortMenu,
                  if (compactClear != null) compactClear,
                ],
              ),
            ],
          );
        }
        final searchWidth = (constraints.maxWidth * .42).clamp(260.0, 320.0);
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(width: searchWidth, child: search),
            filtersMenu,
            sortMenu,
            if (clear != null)
              constraints.maxWidth < 650 ? compactClear! : clear,
          ],
        );
      },
    );
  }
}

class _RecurringFilterPanel extends StatelessWidget {
  const _RecurringFilterPanel({
    required this.statusOptions,
    required this.selectedStatus,
    required this.onStatusSelected,
    required this.clientOptions,
    required this.selectedClient,
    required this.onClientSelected,
    required this.onClientClear,
    required this.frequencyOptions,
    required this.selectedFrequency,
    required this.onFrequencySelected,
    required this.onFrequencyClear,
    required this.dueSoonOnly,
    required this.onDueSoonChanged,
    required this.showInactiveClients,
    required this.onShowInactiveChanged,
  });

  final List<String> statusOptions;
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;
  final List<String> clientOptions;
  final String? selectedClient;
  final ValueChanged<String> onClientSelected;
  final VoidCallback onClientClear;
  final List<String> frequencyOptions;
  final String? selectedFrequency;
  final ValueChanged<String> onFrequencySelected;
  final VoidCallback onFrequencyClear;
  final bool dueSoonOnly;
  final ValueChanged<bool> onDueSoonChanged;
  final bool showInactiveClients;
  final ValueChanged<bool> onShowInactiveChanged;

  Future<void> _pickClient(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _ClientPickerDialog(
        title: l.recurringInvoicesClientFilterLabel,
        options: clientOptions,
        selected: selectedClient,
      ),
    );
    if (result == null) return;
    if (result.isEmpty) {
      onClientClear();
    } else {
      onClientSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = l.localeName.startsWith('es');
    final frequencyLabels = {
      for (final value in frequencyOptions)
        value: recurringFrequencyLabel(l, value),
    };
    return SizedBox(
      width: 340,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEs ? 'Filtros' : 'Filters',
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(l.recurringInvoicesStatusFilterLabel,
                style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            SegmentedButton<String>(
              segments: [
                for (final option in statusOptions)
                  ButtonSegment(value: option, label: Text(option)),
              ],
              selected: {selectedStatus},
              onSelectionChanged: (values) => onStatusSelected(values.first),
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(height: 10),
            _PanelFieldButton(
              icon: Icons.person_outline_rounded,
              label: selectedClient ?? l.recurringInvoicesClientFilterLabel,
              active: selectedClient != null,
              onPressed: () => _pickClient(context),
              onClear: selectedClient == null ? null : onClientClear,
            ),
            if (frequencyOptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedFrequency,
                    hint: Text(l.recurringInvoicesFrequencyLabel),
                    items: [
                      for (final value in frequencyOptions)
                        DropdownMenuItem(
                            value: value,
                            child: Text(frequencyLabels[value] ?? value)),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        onFrequencyClear();
                      } else {
                        onFrequencySelected(value);
                      }
                    },
                    icon: selectedFrequency == null
                        ? const Icon(Icons.keyboard_arrow_down_rounded,
                            size: 18)
                        : IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .deleteButtonTooltip,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: onFrequencyClear,
                            icon: const Icon(Icons.close_rounded, size: 16),
                          ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _PanelToggle(
              icon: Icons.alarm_outlined,
              label: l.recurringInvoicesDueSoon,
              value: dueSoonOnly,
              onChanged: onDueSoonChanged,
            ),
            _PanelToggle(
              icon: Icons.visibility_outlined,
              label: l.showInactiveClients,
              value: showInactiveClients,
              onChanged: onShowInactiveChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortMenuItem extends StatelessWidget {
  const _SortMenuItem(
      {required this.selected, required this.label, required this.onPressed});
  final bool selected;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => MenuItemButton(
        onPressed: onPressed,
        leadingIcon: selected
            ? Icon(Icons.check_rounded,
                size: 16, color: Theme.of(context).colorScheme.primary)
            : const SizedBox(width: 16),
        child: Text(label),
      );
}

class _PanelFieldButton extends StatelessWidget {
  const _PanelFieldButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
    this.onClear,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: active ? cs.primary : cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 7),
            Expanded(
                child:
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 16),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PanelToggle extends StatelessWidget {
  const _PanelToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 36,
        child: SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          secondary: Icon(icon, size: 16),
          title: Text(label, style: Theme.of(context).textTheme.bodySmall),
          value: value,
          onChanged: onChanged,
        ),
      );
}

class _ClientPickerDialog extends StatefulWidget {
  const _ClientPickerDialog(
      {required this.title, required this.options, required this.selected});
  final String title;
  final List<String> options;
  final String? selected;

  @override
  State<_ClientPickerDialog> createState() => _ClientPickerDialogState();
}

class _ClientPickerDialogState extends State<_ClientPickerDialog> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? widget.options
        : widget.options
            .where((option) => option.toLowerCase().contains(query))
            .toList(growable: false);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 340,
        height: 380,
        child: Column(
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                hintText: widget.title,
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    dense: true,
                    leading: widget.selected == null
                        ? const Icon(Icons.check_rounded, size: 16)
                        : const SizedBox(width: 16),
                    title: Text(
                        MaterialLocalizations.of(context).selectAllButtonLabel),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  for (final option in visible)
                    ListTile(
                      dense: true,
                      leading: widget.selected == option
                          ? const Icon(Icons.check_rounded, size: 16)
                          : const SizedBox(width: 16),
                      title: Text(option),
                      onTap: () => Navigator.pop(context, option),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}
