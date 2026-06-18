import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ExpenseProviderPicker extends StatelessWidget {
  final List<Map<String, dynamic>> providers;
  final String? selectedProviderId;
  final String? providersError;
  final bool loading;
  final ValueChanged<String?> onSelectProvider;

  const ExpenseProviderPicker({
    super.key,
    required this.providers,
    required this.selectedProviderId,
    required this.providersError,
    required this.loading,
    required this.onSelectProvider,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    final selected = providers.firstWhere(
      (p) =>
          (p['id'] ?? p['_id'] ?? p['providerId'])?.toString() ==
          selectedProviderId,
      orElse: () => const <String, dynamic>{},
    );
    final selectedName = selected.isEmpty
        ? l.expenseUploadProviderManualOption
        : (selected['name']?.toString() ?? l.expenseUploadProviderManualOption);
    final hasRealProvider = selectedProviderId != null && selected.isNotEmpty;

    Future<void> openPicker() async {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _ProviderPickerSheet(
          providers: providers,
          selectedProviderId: selectedProviderId,
          onSelect: (id) {
            onSelectProvider(id);
            Navigator.of(ctx).pop();
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Trigger button ──
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: loading ? null : openPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasRealProvider
                        ? Icons.business_outlined
                        : Icons.edit_outlined,
                    size: 16,
                    color: hasRealProvider ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.expenseUploadProviderSavedLabel.toUpperCase(),
                          style: ts.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          selectedName,
                          style: ts.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: hasRealProvider
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (providersError != null) ...[
          const SizedBox(height: 6),
          Text(
            providersError!,
            style: TextStyle(color: cs.error, fontSize: 12),
          ),
        ],
        if (loading)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: cs.primary.withValues(alpha: 0.5),
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class _ProviderPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> providers;
  final String? selectedProviderId;
  final ValueChanged<String?> onSelect;

  const _ProviderPickerSheet({
    required this.providers,
    required this.selectedProviderId,
    required this.onSelect,
  });

  @override
  State<_ProviderPickerSheet> createState() => _ProviderPickerSheetState();
}

class _ProviderPickerSheetState extends State<_ProviderPickerSheet> {
  String _query = '';
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.toLowerCase().trim();
    if (q.isEmpty) return widget.providers;
    return widget.providers.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final filtered = _filtered;
    final totalCount = widget.providers.length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.expenseUploadProviderSearchPlaceholder,
                          style: ts.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$totalCount proveedores',
                          style: ts.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),

            // ── Search field ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre…',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        )
                      : null,
                  filled: true,
                  fillColor:
                      cs.surfaceContainerHighest.withValues(alpha: 0.25),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: cs.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),

            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.2),
            ),

            // ── List ──
            Expanded(
              child: filtered.isEmpty && _query.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 36,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sin resultados para "$_query"',
                            style: ts.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      // +1 for "manual" option at top
                      itemCount: filtered.length + 1,
                      itemBuilder: (_, index) {
                        if (index == 0) {
                          return _ProviderRow(
                            initial: null,
                            name: l.expenseUploadProviderManualOption,
                            isManual: true,
                            isSelected: widget.selectedProviderId == null,
                            onTap: () => widget.onSelect(null),
                            cs: cs,
                            ts: ts,
                          );
                        }
                        final p = filtered[index - 1];
                        final id = (p['id'] ?? p['_id'] ?? p['providerId'])
                            ?.toString();
                        final name = p['name']?.toString() ?? '-';
                        return _ProviderRow(
                          initial: name.trim().isEmpty
                              ? '?'
                              : name.trim()[0].toUpperCase(),
                          name: name,
                          isManual: false,
                          isSelected:
                              id != null && id == widget.selectedProviderId,
                          onTap: id == null ? null : () => widget.onSelect(id),
                          cs: cs,
                          ts: ts,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ── Row ───────────────────────────────────────────────────────────────────────

class _ProviderRow extends StatelessWidget {
  final String? initial;
  final String name;
  final bool isManual;
  final bool isSelected;
  final VoidCallback? onTap;
  final ColorScheme cs;
  final TextTheme ts;

  const _ProviderRow({
    required this.initial,
    required this.name,
    required this.isManual,
    required this.isSelected,
    required this.onTap,
    required this.cs,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    final avatarBg = isSelected
        ? cs.primary.withValues(alpha: 0.15)
        : cs.surfaceContainerHighest.withValues(alpha: 0.5);
    final avatarFg = isSelected ? cs.primary : cs.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: isSelected
            ? cs.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: avatarBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isManual
                  ? Icon(Icons.edit_outlined, size: 15, color: avatarFg)
                  : Text(
                      initial ?? '?',
                      style: ts.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: avatarFg,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                name,
                style: ts.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? cs.primary : cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Checkmark
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
            ],
          ],
        ),
      ),
    );
  }
}
