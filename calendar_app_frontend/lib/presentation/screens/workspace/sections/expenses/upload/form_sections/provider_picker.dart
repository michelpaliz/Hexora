import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ExpenseProviderPicker extends StatefulWidget {
  final List<Map<String, dynamic>> providers;
  final String? selectedProviderId;
  final String? providersError;
  final bool loading;
  final ValueChanged<String?> onSelectProvider;
  final bool manualMode;
  final VoidCallback? onManualMode;

  const ExpenseProviderPicker({
    super.key,
    required this.providers,
    required this.selectedProviderId,
    required this.providersError,
    required this.loading,
    required this.onSelectProvider,
    this.manualMode = false,
    this.onManualMode,
  });

  @override
  State<ExpenseProviderPicker> createState() => _ExpenseProviderPickerState();
}

class _ExpenseProviderPickerState extends State<ExpenseProviderPicker> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _selectedLabel());
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant ExpenseProviderPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        (oldWidget.selectedProviderId != widget.selectedProviderId ||
            oldWidget.manualMode != widget.manualMode ||
            oldWidget.providers.length != widget.providers.length)) {
      _searchController.text = _selectedLabel();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _providerId(Map<String, dynamic> provider) =>
      (provider['id'] ?? provider['_id'] ?? provider['providerId'] ?? '')
          .toString();

  String _providerName(Map<String, dynamic> provider) => (provider['name'] ??
          provider['providerName'] ??
          provider['vendorName'] ??
          '-')
      .toString();

  String _providerTaxId(Map<String, dynamic> provider) => (provider['taxId'] ??
          provider['taxIdentifier'] ??
          provider['nif'] ??
          provider['cif'] ??
          provider['vatNumber'] ??
          '')
      .toString()
      .trim();

  String _selectedLabel() {
    if (widget.manualMode) return 'Proveedor manual';
    final id = (widget.selectedProviderId ?? '').trim();
    if (id.isEmpty) return '';
    final provider = widget.providers.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item != null && _providerId(item) == id,
          orElse: () => null,
        );
    return provider == null
        ? 'Proveedor no vinculado'
        : _providerName(provider);
  }

  String _fold(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }

  bool _matches(Map<String, dynamic> provider, String query) {
    final folded = _fold(query.trim());
    if (folded.isEmpty) return true;
    final searchable = [
      _providerName(provider),
      _providerTaxId(provider),
      provider['reference'],
      provider['code'],
      provider['providerCode'],
    ].whereType<Object>().map((value) => value.toString()).join(' ');
    return _fold(searchable).contains(folded);
  }

  Iterable<Map<String, dynamic>> _options(String query) =>
      widget.providers.where((provider) => _matches(provider, query));

  void _select(Map<String, dynamic> provider) {
    final id = _providerId(provider);
    if (id.isEmpty) return;
    _searchController.text = _providerName(provider);
    _query = '';
    _focusNode.unfocus();
    widget.onSelectProvider(id);
  }

  void _enterManual() {
    _searchController.text = 'Proveedor manual';
    _query = '';
    _focusNode.unfocus();
    if (widget.onManualMode != null) {
      widget.onManualMode!();
    } else {
      widget.onSelectProvider(null);
    }
  }

  Future<void> _openMobilePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetContext) => _ProviderPickerSheet(
        providers: widget.providers,
        selectedProviderId: widget.selectedProviderId,
        onSelect: (provider) {
          _select(provider);
          Navigator.of(sheetContext).pop();
        },
        onManual: () {
          _enterManual();
          Navigator.of(sheetContext).pop();
        },
        matches: _matches,
        providerId: _providerId,
        providerName: _providerName,
        providerTaxId: _providerTaxId,
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, {required String hint}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: 'Proveedor',
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.18),
      prefixIcon:
          Icon(Icons.search_rounded, size: 17, color: cs.onSurfaceVariant),
      prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      suffixIcon: widget.loading
          ? const Padding(
              padding: EdgeInsets.all(11),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: cs.outlineVariant.withValues(alpha: 0.38)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.7)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      constraints: const BoxConstraints(minHeight: 40),
    );
  }

  Widget _providerRow(
    BuildContext context,
    Map<String, dynamic> provider, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final name = _providerName(provider);
    final taxId = _providerTaxId(provider);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color:
            selected ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
        child: Row(
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: selected
                  ? cs.primary.withValues(alpha: 0.16)
                  : cs.surfaceContainerHighest,
              child: Text(
                name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                style: ts.labelMedium?.copyWith(
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: name,
                  children: taxId.isEmpty
                      ? null
                      : [
                          TextSpan(
                            text: '  ·  $taxId',
                            style: ts.bodySmall?.copyWith(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                  style: ts.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 18, color: cs.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final hint = l.localeName.toLowerCase().startsWith('es')
        ? 'Buscar por nombre, NIF/CIF o referencia'
        : 'Search by name, tax ID or reference';
    final hasNoResults = _query.trim().isNotEmpty && _options(_query).isEmpty;

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: widget.loading ? null : _openMobilePicker,
            borderRadius: BorderRadius.circular(8),
            child: IgnorePointer(
              child: TextField(
                controller: _searchController,
                readOnly: true,
                decoration: _decoration(context, hint: hint),
              ),
            ),
          ),
          if (widget.providersError != null) ...[
            const SizedBox(height: 5),
            Text(widget.providersError!,
                style: TextStyle(color: cs.error, fontSize: 12)),
          ],
        ],
      );
    }

    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: _searchController,
      focusNode: _focusNode,
      displayStringForOption: _providerName,
      optionsBuilder: (value) => _options(value.text),
      onSelected: _select,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !widget.loading,
              style: const TextStyle(fontSize: 13),
              decoration: _decoration(context, hint: hint),
              onTap: () {
                if (!_focusNode.hasFocus) _focusNode.requestFocus();
                if (_query.isEmpty) controller.clear();
              },
              onChanged: (value) => setState(() => _query = value),
              onSubmitted: (_) => onSubmit(),
            ),
            if (hasNoResults)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'No se encontraron proveedores',
                        style:
                            TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                      ),
                    ),
                    TextButton(
                      onPressed: _enterManual,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Introducir manualmente'),
                    ),
                  ],
                ),
              ),
            if (widget.providersError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 2),
                child: Text(widget.providersError!,
                    style: TextStyle(color: cs.error, fontSize: 12)),
              ),
          ],
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final rows = options.toList(growable: false);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SizedBox(
                width: 420,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final provider = rows[index];
                          return Builder(
                            builder: (context) => _providerRow(
                              context,
                              provider,
                              selected: _providerId(provider) ==
                                      widget.selectedProviderId ||
                                  AutocompleteHighlightedOption.of(context) ==
                                      index,
                              onTap: () => onSelected(provider),
                            ),
                          );
                        },
                      ),
                    ),
                    Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.4)),
                    TextButton.icon(
                      onPressed: _enterManual,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Introducir proveedor manualmente'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProviderPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> providers;
  final String? selectedProviderId;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback onManual;
  final bool Function(Map<String, dynamic>, String) matches;
  final String Function(Map<String, dynamic>) providerId;
  final String Function(Map<String, dynamic>) providerName;
  final String Function(Map<String, dynamic>) providerTaxId;

  const _ProviderPickerSheet({
    required this.providers,
    required this.selectedProviderId,
    required this.onSelect,
    required this.onManual,
    required this.matches,
    required this.providerId,
    required this.providerName,
    required this.providerTaxId,
  });

  @override
  State<_ProviderPickerSheet> createState() => _ProviderPickerSheetState();
}

class _ProviderPickerSheetState extends State<_ProviderPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final filtered = widget.providers
        .where((provider) => widget.matches(provider, _query))
        .toList(growable: false);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Seleccionar proveedor',
                      style: ts.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, NIF/CIF o referencia',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                constraints: const BoxConstraints(minHeight: 40),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No se encontraron proveedores',
                        style: ts.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        )),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final provider = filtered[index];
                      final selected = widget.providerId(provider) ==
                          widget.selectedProviderId;
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 15,
                          child: Text(widget.providerName(provider).isEmpty
                              ? '?'
                              : widget.providerName(provider)[0].toUpperCase()),
                        ),
                        title: Text(widget.providerName(provider),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: widget.providerTaxId(provider).isEmpty
                            ? null
                            : Text(widget.providerTaxId(provider),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: selected
                            ? Icon(Icons.check_rounded, color: cs.primary)
                            : null,
                        onTap: () => widget.onSelect(provider),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onManual,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Introducir proveedor manualmente'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
