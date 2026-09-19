part of '../../mail_compose_screen.dart';

class _ClientSearchField extends StatelessWidget {
  const _ClientSearchField({
    required this.clients,
    required this.selectedClientId,
    required this.loading,
    required this.enabled,
    required this.onChanged,
  });

  final List<GroupClient> clients;
  final String? selectedClientId;
  final bool loading;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  GroupClient? get _selected => selectedClientId == null
      ? null
      : clients.cast<GroupClient?>().firstWhere(
            (c) => c?.id == selectedClientId,
            orElse: () => null,
          );

  Future<void> _openPicker(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _ClientPickerDialog(
        clients: clients,
        selectedClientId: selectedClientId,
      ),
    );
    // result == '' means "clear selection"
    if (result != null) onChanged(result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final selected = _selected;
    final hasSelection = selected != null;

    if (loading) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          const SizedBox(width: 8),
          Text(
            l.expenseBatchStatLoading,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? () => _openPicker(context) : null,
      child: Container(
        padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 6),
        decoration: BoxDecoration(
          color: hasSelection
              ? cs.primaryContainer.withValues(alpha: 0.55)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: hasSelection
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 13,
              color: hasSelection ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasSelection ? selected.name : l.selectClientFirst,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  color: hasSelection
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                  fontWeight: hasSelection ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (hasSelection)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled ? () => onChanged(null) : null,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClientPickerDialog extends StatefulWidget {
  const _ClientPickerDialog({
    required this.clients,
    required this.selectedClientId,
  });

  final List<GroupClient> clients;
  final String? selectedClientId;

  @override
  State<_ClientPickerDialog> createState() => _ClientPickerDialogState();
}

class _ClientPickerDialogState extends State<_ClientPickerDialog> {
  final TextEditingController _search = TextEditingController();
  late List<GroupClient> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.clients;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final lower = q.trim().toLowerCase();
    setState(() {
      _filtered = lower.isEmpty
          ? widget.clients
          : widget.clients.where((c) {
              final name = c.name.toLowerCase();
              final email = (c.email ?? '').toLowerCase();
              return name.contains(lower) || email.contains(lower);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 17, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.recurringInvoicesClientFilterLabel,
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: l.clientSearchHint,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                  focusedBorder: fieldBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.4),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            _onSearch('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                style: t.bodySmall.copyWith(fontSize: 13),
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

            // Client list
            Flexible(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 32,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.noClientsYet,
                            style: t.bodySmall
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final client = _filtered[i];
                        final isSel = client.id == widget.selectedClientId;
                        final email = (client.email ?? '').trim();
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: isSel
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            child: isSel
                                ? Icon(Icons.check_rounded,
                                    size: 14, color: cs.primary)
                                : Text(
                                    client.name.isNotEmpty
                                        ? client.name[0].toUpperCase()
                                        : '?',
                                    style: t.bodySmall.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                          ),
                          title: Text(
                            client.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall.copyWith(
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w600,
                              color: isSel ? cs.primary : cs.onSurface,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: email.isNotEmpty
                              ? Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                )
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () => Navigator.pop(context, client.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
