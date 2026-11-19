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
    required this.onCustomName,
    required this.customName,
    required this.onSearchMode,
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
  final ValueChanged<String> onCustomName;
  final bool customName;
  final VoidCallback onSearchMode;
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
  bool get _customName => widget.customName;
  bool _searchFailed = false;
  int _requestRevision = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    _requestRevision++;
    if (_customName) return;
    if (_menuController.isOpen) _menuController.close();
    setState(() {
      _results = const [];
      _loading = false;
      _searched = false;
    });
    final query = value.trim();
    if (query.length < 2) {
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
      _searchFailed = false;
      _results = const [];
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
        _searchFailed = true;
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
      if (!mounted ||
          _customName ||
          !_focusNode.hasFocus ||
          _menuController.isOpen) {
        return;
      }
      _menuController.open();
    });
  }

  void _select(GroupClient client) {
    _debounce?.cancel();
    _requestRevision++;
    setState(() => _loading = false);
    widget.controller.value = TextEditingValue(
      text: client.name.trim(),
      selection: TextSelection.collapsed(offset: client.name.trim().length),
    );
    widget.onSelected(client);
    _menuController.close();
    _focusNode.unfocus();
  }

  void _useCustomName() {
    _debounce?.cancel();
    _requestRevision++;
    _menuController.close();
    setState(() {
      _loading = false;
      _results = const [];
      _searched = false;
    });
    widget.onCustomName(widget.controller.text.trim());
    _focusNode.requestFocus();
  }

  void _useSavedClient() {
    widget.onSearchMode();
    _searchFromButton();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) =>
            _buildField(context, constraints.maxWidth),
      );

  Widget _buildField(BuildContext context, double width) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final query = widget.controller.text.trim();
    final menuChildren = <Widget>[
      if (query.isNotEmpty) ...[
        MenuItemButton(
          key: const ValueKey('use_custom_client_name'),
          onPressed: _useCustomName,
          leadingIcon: Icon(Icons.edit_outlined, size: 20, color: cs.primary),
          child: SizedBox(
            width: (width - 80).clamp(0, double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Usar «$query»',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Nombre personalizado para este presupuesto',
                    maxLines: 2, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Text('Clientes guardados',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: cs.onSurfaceVariant)),
      ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            width: (width - 32).clamp(0, double.infinity),
            child: Text(_searchFailed
                ? 'No se pudieron cargar los clientes. Puedes escribir un nombre personalizado o volver a buscar.'
                : 'Sin coincidencias. Usa el nombre escrito o prueba otra búsqueda.'),
          ),
        )
      else
        for (final client in _results)
          MenuItemButton(
            onPressed: () => _select(client),
            style: const ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(0, 52)),
              padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
            ),
            leadingIcon: const Icon(Icons.business_outlined, size: 18),
            child: SizedBox(
              width: (width - 80).clamp(0, double.infinity),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 5),
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
            childFocusNode: _focusNode,
            crossAxisUnconstrained: false,
            style: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerLow),
              surfaceTintColor:
                  const WidgetStatePropertyAll(Colors.transparent),
              minimumSize: WidgetStatePropertyAll(Size(width, 0)),
              maximumSize: WidgetStatePropertyAll(Size(width, 320)),
              padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(vertical: 6)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: cs.outlineVariant),
              )),
            ),
            menuChildren: menuChildren,
            builder: (context, controller, child) => TextField(
              key: widget.fieldKey,
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: true,
              style: theme.textTheme.bodySmall,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                widget.onChanged(value);
                _scheduleSearch(value);
              },
              onTap: () => _scheduleSearch(widget.controller.text),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 38, minHeight: 38),
                suffixIconConstraints: const BoxConstraints(minHeight: 38),
                hintText:
                    _customName ? 'Escribe el nombre del cliente' : widget.hint,
                prefixIcon: _customName
                    ? Icon(Icons.person_outline_rounded,
                        size: 20, color: cs.primary)
                    : widget.selectedClientId == null
                        ? Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(9),
                            child: CircleAvatar(
                              radius: 11,
                              backgroundColor:
                                  cs.primary.withValues(alpha: 0.16),
                              child: Icon(
                                Icons.apartment_rounded,
                                size: 14,
                                color: cs.primary,
                              ),
                            ),
                          ),
                suffixIcon: _customName
                    ? null
                    : _loading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : widget.selectedClientId == null
                            ? IconButton(
                                tooltip: 'Buscar clientes',
                                onPressed: _searchFromButton,
                                icon:
                                    const Icon(Icons.search_rounded, size: 19),
                              )
                            : TextButton(
                                onPressed: () {
                                  widget.onClear?.call();
                                  _searchFromButton();
                                },
                                child: const Text('Cambiar'),
                              ),
                filled: true,
                fillColor: widget.selectedClientId == null
                    ? cs.surfaceContainer
                    : cs.primaryContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.selectedClientId == null
                        ? cs.outlineVariant.withValues(alpha: 0.78)
                        : cs.primary.withValues(alpha: 0.35),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.primary, width: 1.4),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!_customName && widget.selectedClientId != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text('Cliente seleccionado',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ])
                else
                  Text(
                      _customName
                          ? 'Solo para este presupuesto.'
                          : '¿No está registrado?',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                TextButton(
                  key: ValueKey(
                      _customName ? 'client_mode_saved' : 'client_mode_custom'),
                  onPressed: _customName ? _useSavedClient : _useCustomName,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: theme.textTheme.bodySmall,
                  ),
                  child: Text(
                      _customName ? 'Volver a clientes' : 'Usar nombre manual'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
