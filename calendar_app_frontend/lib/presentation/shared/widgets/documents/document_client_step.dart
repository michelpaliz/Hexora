import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/shared/widgets/client_search_select.dart';

enum DocumentClientMode { existing, manual }

class DocumentManualClientConfig {
  const DocumentManualClientConfig({
    required this.nameController,
    required this.onChanged,
    this.addressController,
    this.cityController,
    this.postalCodeController,
    this.nameLabel = 'Nombre del cliente',
    this.addressLabel = 'Dirección',
    this.cityLabel = 'Ciudad',
    this.postalCodeLabel = 'CP',
    this.helperText,
    this.nameErrorText,
  });

  final TextEditingController nameController;
  final TextEditingController? addressController;
  final TextEditingController? cityController;
  final TextEditingController? postalCodeController;
  final VoidCallback onChanged;
  final String nameLabel;
  final String addressLabel;
  final String cityLabel;
  final String postalCodeLabel;
  final String? helperText;
  final String? nameErrorText;
}

/// Shared presentation for the client step used by document editors.
///
/// Selection state, validation, history loading, and persistence remain owned
/// by the document-specific editor.
class DocumentClientStep extends StatelessWidget {
  const DocumentClientStep({
    super.key,
    required this.clients,
    required this.selectedClientId,
    required this.onClientChanged,
    required this.mode,
    required this.onModeChanged,
    required this.selectedDetails,
    this.manual,
    this.enabled = true,
    this.allowManual = true,
    this.existingLabel = 'Cliente existente',
    this.manualLabel = 'Cliente manual',
    this.selectClientLabel = 'Selecciona cliente',
    this.emptySelectionLabel = 'Selecciona un cliente para continuar',
    this.twoColumnBreakpoint = 980,
  });

  final List<GroupClient> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onClientChanged;
  final DocumentClientMode mode;
  final ValueChanged<DocumentClientMode> onModeChanged;
  final Widget? selectedDetails;
  final DocumentManualClientConfig? manual;
  final bool enabled;
  final bool allowManual;
  final String existingLabel;
  final String manualLabel;
  final String selectClientLabel;
  final String emptySelectionLabel;
  final double twoColumnBreakpoint;

  @override
  Widget build(BuildContext context) {
    if (mode == DocumentClientMode.manual && allowManual && manual != null) {
      return _ManualClientPanel(
        mode: mode,
        onModeChanged: onModeChanged,
        config: manual!,
        enabled: enabled,
        existingLabel: existingLabel,
        manualLabel: manualLabel,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= twoColumnBreakpoint;
        final listHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 520.0;
        final list = _ExistingClientPanel(
          clients: clients,
          selectedClientId: selectedClientId,
          onClientChanged: onClientChanged,
          mode: mode,
          onModeChanged: onModeChanged,
          enabled: enabled,
          allowManual: allowManual && manual != null,
          existingLabel: existingLabel,
          manualLabel: manualLabel,
          title: selectClientLabel,
          maxListHeight: listHeight,
        );
        final details = _ClientDetailsPanel(
          hasSelection: selectedClientId != null,
          emptyLabel: emptySelectionLabel,
          child: selectedDetails,
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: list),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: details),
            ],
          );
        }

        if (selectedClientId == null) return list;
        final availableHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 700.0;
        final listSlot = (availableHeight * .62).clamp(280.0, 460.0);
        final detailsSlot = (availableHeight * .45).clamp(240.0, 360.0);
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: listSlot, child: list),
              const SizedBox(height: 10),
              SizedBox(height: detailsSlot, child: details),
            ],
          ),
        );
      },
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.mode,
    required this.onChanged,
    required this.enabled,
    required this.existingLabel,
    required this.manualLabel,
  });

  final DocumentClientMode mode;
  final ValueChanged<DocumentClientMode> onChanged;
  final bool enabled;
  final String existingLabel;
  final String manualLabel;

  @override
  Widget build(BuildContext context) => SegmentedButton<DocumentClientMode>(
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10),
          ),
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        segments: [
          ButtonSegment(
            value: DocumentClientMode.existing,
            icon: const Icon(Icons.group_outlined, size: 16),
            label: Text(existingLabel),
          ),
          ButtonSegment(
            value: DocumentClientMode.manual,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(manualLabel),
          ),
        ],
        selected: {mode},
        onSelectionChanged:
            enabled ? (selection) => onChanged(selection.first) : null,
      );
}

class _ExistingClientPanel extends StatelessWidget {
  const _ExistingClientPanel({
    required this.clients,
    required this.selectedClientId,
    required this.onClientChanged,
    required this.mode,
    required this.onModeChanged,
    required this.enabled,
    required this.allowManual,
    required this.existingLabel,
    required this.manualLabel,
    required this.title,
    required this.maxListHeight,
  });

  final List<GroupClient> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onClientChanged;
  final DocumentClientMode mode;
  final ValueChanged<DocumentClientMode> onModeChanged;
  final bool enabled;
  final bool allowManual;
  final String existingLabel;
  final String manualLabel;
  final String title;
  final double maxListHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final heading = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${clients.length}',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
                if (!allowManual) return heading;
                if (constraints.maxWidth < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading,
                      const SizedBox(height: 7),
                      _ModeSelector(
                        mode: mode,
                        onChanged: onModeChanged,
                        enabled: enabled,
                        existingLabel: existingLabel,
                        manualLabel: manualLabel,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 10),
                    _ModeSelector(
                      mode: mode,
                      onChanged: onModeChanged,
                      enabled: enabled,
                      existingLabel: existingLabel,
                      manualLabel: manualLabel,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: IgnorePointer(
              ignoring: !enabled,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: ClientSearchSelect(
                  clients: clients,
                  selectedClientId: selectedClientId,
                  onClientChanged: onClientChanged,
                  useDefaultPropertyKind: false,
                  showAdvancedFilters: false,
                  maxListHeight: maxListHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientDetailsPanel extends StatelessWidget {
  const _ClientDetailsPanel({
    required this.hasSelection,
    required this.emptyLabel,
    required this.child,
  });

  final bool hasSelection;
  final String emptyLabel;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: hasSelection ? cs.primary.withValues(alpha: .035) : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasSelection
              ? cs.primary.withValues(alpha: .25)
              : cs.outlineVariant.withValues(alpha: .38),
        ),
      ),
      child: hasSelection && child != null
          ? child
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      size: 24,
                      color: cs.onSurfaceVariant.withValues(alpha: .5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ManualClientPanel extends StatelessWidget {
  const _ManualClientPanel({
    required this.mode,
    required this.onModeChanged,
    required this.config,
    required this.enabled,
    required this.existingLabel,
    required this.manualLabel,
  });

  final DocumentClientMode mode;
  final ValueChanged<DocumentClientMode> onModeChanged;
  final DocumentManualClientConfig config;
  final bool enabled;
  final String existingLabel;
  final String manualLabel;

  InputDecoration _decoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      prefixIcon: Icon(icon, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      filled: true,
      fillColor: cs.surfaceContainer,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: .45),
        ),
      ),
    );
  }

  Widget _field(BuildContext context, TextEditingController controller,
          String label, IconData icon,
          {String? errorText}) =>
      TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(fontSize: 13),
        onChanged: (_) => config.onChanged(),
        decoration: _decoration(context, label, icon).copyWith(
          errorText: errorText,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final optional = <Widget>[
      if (config.addressController != null)
        _field(
          context,
          config.addressController!,
          config.addressLabel,
          Icons.location_on_outlined,
        ),
      if (config.cityController != null)
        _field(
          context,
          config.cityController!,
          config.cityLabel,
          Icons.location_city_outlined,
        ),
      if (config.postalCodeController != null)
        _field(
          context,
          config.postalCodeController!,
          config.postalCodeLabel,
          Icons.markunread_mailbox_outlined,
        ),
    ];
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: .38),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  final selector = _ModeSelector(
                    mode: mode,
                    onChanged: onModeChanged,
                    enabled: enabled,
                    existingLabel: existingLabel,
                    manualLabel: manualLabel,
                  );
                  final title = Text(
                    manualLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  );
                  if (constraints.maxWidth < 600) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 7), selector],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 10),
                      selector,
                    ],
                  );
                }),
                const SizedBox(height: 12),
                _field(
                  context,
                  config.nameController,
                  config.nameLabel,
                  Icons.person_outline_rounded,
                  errorText: config.nameErrorText,
                ),
                if (optional.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return Column(
                        children: [
                          for (var i = 0; i < optional.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            optional[i],
                          ],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < optional.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(child: optional[i]),
                        ],
                      ],
                    );
                  }),
                ],
                if ((config.helperText ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    config.helperText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
