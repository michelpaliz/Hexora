// widgets/client_service_pickers.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientServicePickers extends StatelessWidget {
  final List<dynamic> clients; // expects items with .id and .name
  final List<dynamic> services; // expects items with .id and .name
  final String? clientId;
  final String? serviceId;
  final ValueChanged<String?> onClientChanged;
  final ValueChanged<String?> onServiceChanged;

  const ClientServicePickers({
    super.key,
    required this.clients,
    required this.services,
    required this.clientId,
    required this.serviceId,
    required this.onClientChanged,
    required this.onServiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final clientField = _SearchablePickerField(
      items: clients,
      selectedId: clientId,
      labelText: loc.client,
      onChanged: onClientChanged,
    );
    final serviceField = _SearchablePickerField(
      items: services,
      selectedId: serviceId,
      labelText: loc.primaryService,
      onChanged: onServiceChanged,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 380) {
          return Row(
            children: [
              Expanded(child: clientField),
              const SizedBox(width: 12),
              Expanded(child: serviceField),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            clientField,
            const SizedBox(height: 12),
            serviceField,
          ],
        );
      },
    );
  }
}

// ── Searchable picker ─────────────────────────────────────────────────────────

class _SearchablePickerField extends StatelessWidget {
  const _SearchablePickerField({
    required this.items,
    required this.selectedId,
    required this.labelText,
    required this.onChanged,
  });

  final List<dynamic> items;
  final String? selectedId;
  final String labelText;
  final ValueChanged<String?> onChanged;

  String _nameOf(dynamic item) => (item.name ?? '') as String;
  String _idOf(dynamic item) => (item.id ?? '') as String;

  String? get _selectedName {
    if (selectedId == null || selectedId!.isEmpty) return null;
    try {
      final match = items.firstWhere((c) => _idOf(c) == selectedId);
      return _nameOf(match);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openSearch(BuildContext context) async {
    final result = await showDialog<String?>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _SearchDialog(
        items: items,
        selectedId: selectedId,
        labelText: labelText,
        nameOf: _nameOf,
        idOf: _idOf,
      ),
    );
    // result == null means dismissed (no change); result == '' means cleared
    if (result != null) {
      onChanged(result.isEmpty ? null : result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final hasValue = _selectedName != null;

    return GestureDetector(
      onTap: items.isEmpty ? null : () => _openSearch(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: typo.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outlineVariant, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outlineVariant, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: items.isEmpty
              ? Icon(Icons.lock_outline,
                  size: 18,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4))
              : Icon(Icons.arrow_drop_down_rounded,
                  size: 24, color: cs.onSurfaceVariant),
        ),
        isEmpty: !hasValue,
        child: Text(
          _selectedName ?? '',
          style: typo.bodyMedium.copyWith(color: cs.onSurface),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

// ── Search dialog ─────────────────────────────────────────────────────────────

class _SearchDialog extends StatefulWidget {
  const _SearchDialog({
    required this.items,
    required this.selectedId,
    required this.labelText,
    required this.nameOf,
    required this.idOf,
  });

  final List<dynamic> items;
  final String? selectedId;
  final String labelText;
  final String Function(dynamic) nameOf;
  final String Function(dynamic) idOf;

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _search = TextEditingController();
  late List<dynamic> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _search.addListener(_onQuery);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onQuery() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items
              .where((item) =>
                  widget.nameOf(item).toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: cs.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.labelText,
                    style: typo.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // ── Search field ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _search.text.isNotEmpty
                    ? IconButton(
                        onPressed: _search.clear,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
                hintText: isSpanish ? 'Buscar...' : 'Search...',
                isDense: true,
                filled: true,
                fillColor:
                    cs.surfaceContainerHighest.withValues(alpha: 0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── List ────────────────────────────────────────────────────────
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 32,
                            color:
                                cs.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          isSpanish
                              ? 'Sin resultados'
                              : 'No results',
                          style: typo.bodyMedium.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemBuilder: (ctx, i) {
                      final item = _filtered[i];
                      final id = widget.idOf(item);
                      final name = widget.nameOf(item);
                      final selected = id == widget.selectedId;

                      return InkWell(
                        onTap: () => Navigator.of(context).pop(id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 13),
                          color: selected
                              ? cs.primaryContainer.withValues(alpha: 0.28)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: typo.bodyMedium.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check_rounded,
                                    size: 16, color: cs.primary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
