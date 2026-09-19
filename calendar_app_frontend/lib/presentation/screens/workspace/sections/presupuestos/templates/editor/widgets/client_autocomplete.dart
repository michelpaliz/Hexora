part of '../../presupuesto_template_editor_screen.dart';

class _ClientAutocompleteField extends StatefulWidget {
  const _ClientAutocompleteField({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.hint,
    required this.selectedClientId,
    required this.search,
    required this.onSelected,
    required this.onChanged,
    this.onClear,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? selectedClientId;
  final Future<List<GroupClient>> Function(String search) search;
  final ValueChanged<GroupClient> onSelected;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  State<_ClientAutocompleteField> createState() =>
      _ClientAutocompleteFieldState();
}

class _ClientAutocompleteFieldState extends State<_ClientAutocompleteField> {
  final MenuController _menuController = MenuController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<GroupClient> _results = const [];
  bool _loading = false;
  bool _searched = false;
  int _requestRevision = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      _requestRevision++;
      setState(() {
        _results = const [];
        _loading = false;
        _searched = false;
      });
      if (_menuController.isOpen) _menuController.close();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final revision = ++_requestRevision;
    setState(() {
      _loading = true;
      _searched = false;
    });
    try {
      final clients = await widget.search(query);
      if (!mounted || revision != _requestRevision) return;
      setState(() {
        _results = clients.where((client) => client.isActive).toList();
        _loading = false;
        _searched = true;
      });
      _openMenuAfterBuild();
    } catch (_) {
      if (!mounted || revision != _requestRevision) return;
      setState(() {
        _results = const [];
        _loading = false;
        _searched = true;
      });
      _openMenuAfterBuild();
    }
  }

  void _searchFromButton() {
    _debounce?.cancel();
    _focusNode.requestFocus();
    _performSearch(widget.controller.text.trim());
  }

  void _openMenuAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus || _menuController.isOpen) return;
      _menuController.open();
    });
  }

  void _select(GroupClient client) {
    widget.controller.value = TextEditingValue(
      text: client.name.trim(),
      selection: TextSelection.collapsed(offset: client.name.trim().length),
    );
    widget.onSelected(client);
    _menuController.close();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final menuChildren = <Widget>[
      if (_loading)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Buscando clientes...'),
            ],
          ),
        )
      else if (_searched && _results.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text('Sin coincidencias · puedes usar el nombre escrito'),
        )
      else
        for (final client in _results)
          MenuItemButton(
            onPressed: () => _select(client),
            leadingIcon: const Icon(Icons.business_outlined, size: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 260),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((client.billing?.legalName ?? '').trim().isNotEmpty &&
                      client.billing!.legalName!.trim() != client.name.trim())
                    Text(
                      client.billing!.legalName!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: Text(
              widget.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15,
              ),
            ),
          ),
          MenuAnchor(
            controller: _menuController,
            crossAxisUnconstrained: false,
            menuChildren: menuChildren,
            builder: (context, controller, child) => TextField(
              key: widget.fieldKey,
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                widget.onChanged(value);
                _scheduleSearch(value);
              },
              onTap: () => _scheduleSearch(widget.controller.text),
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: widget.selectedClientId == null
                    ? Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      )
                    : Padding(
                        padding: const EdgeInsets.all(9),
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: cs.primary.withValues(alpha: 0.16),
                          child: Icon(
                            Icons.apartment_rounded,
                            size: 14,
                            color: cs.primary,
                          ),
                        ),
                      ),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : widget.selectedClientId == null
                        ? IconButton(
                            tooltip: 'Buscar clientes',
                            onPressed: _searchFromButton,
                            icon: const Icon(Icons.search_rounded, size: 19),
                          )
                        : TextButton(
                            onPressed: () {
                              widget.onClear?.call();
                              _focusNode.requestFocus();
                            },
                            child: const Text('Cambiar'),
                          ),
                filled: true,
                fillColor: widget.selectedClientId == null
                    ? cs.surfaceContainerLowest
                    : cs.primary.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: widget.selectedClientId == null
                        ? cs.outlineVariant.withValues(alpha: 0.78)
                        : cs.primary.withValues(alpha: 0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.primary, width: 1.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
