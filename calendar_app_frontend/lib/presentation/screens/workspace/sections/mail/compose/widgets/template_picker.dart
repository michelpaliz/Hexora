part of '../../mail_compose_screen.dart';

class _ComposeTemplatePicker extends StatefulWidget {
  const _ComposeTemplatePicker({
    required this.templates,
    required this.selectedId,
    required this.onSelect,
    this.onClear,
  });

  final List<Map<String, dynamic>> templates;
  final String? selectedId;
  final void Function(Map<String, dynamic>) onSelect;
  final VoidCallback? onClear;

  @override
  State<_ComposeTemplatePicker> createState() => _ComposeTemplatePickerState();
}

class _ComposeTemplatePickerState extends State<_ComposeTemplatePicker> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTemplates {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.templates;
    return widget.templates.where((template) {
      return ['name', 'subject', 'text'].any(
        (key) => (template[key] ?? '').toString().toLowerCase().contains(query),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final templates = _filteredTemplates;
    final totalLabel = widget.templates.length == 1
        ? '1 plantilla disponible'
        : '${widget.templates.length} plantillas disponibles';

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 10, 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description_outlined,
                      size: 20, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar plantilla',
                        style: t.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalLabel,
                        style: t.bodySmall.copyWith(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              controller: _searchController,
              autofocus: widget.templates.length > 5,
              onChanged: (value) => setState(() => _query = value),
              style: t.bodySmall.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, asunto o contenido',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                border: fieldBorder,
                enabledBorder: fieldBorder,
                focusedBorder: fieldBorder.copyWith(
                  borderSide: BorderSide(color: cs.primary, width: 1.4),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              ),
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.45)),
          Flexible(
            child: templates.isEmpty
                ? _TemplateSearchEmptyState(query: _query)
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: templates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, index) => _TemplatePickerItem(
                      template: templates[index],
                      selectedId: widget.selectedId,
                      onTap: widget.onSelect,
                    ),
                  ),
          ),
          if (widget.onClear != null) ...[
            Divider(
                height: 1, color: cs.outlineVariant.withValues(alpha: 0.45)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextButton.icon(
                onPressed: widget.onClear,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 17),
                label: const Text('Continuar sin plantilla'),
                style: TextButton.styleFrom(
                  foregroundColor: cs.onSurfaceVariant,
                  alignment: Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TemplatePickerItem extends StatelessWidget {
  const _TemplatePickerItem({
    required this.template,
    required this.selectedId,
    required this.onTap,
  });

  final Map<String, dynamic> template;
  final String? selectedId;
  final void Function(Map<String, dynamic>) onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final id = (template['id'] ?? template['_id'])?.toString().trim() ?? '';
    final name = (template['name'] ?? '').toString().trim();
    final subject = (template['subject'] ?? '').toString().trim();
    final preview = (template['text'] ?? '').toString().trim();
    final isSelected = id == selectedId;
    final isDefault = template['isDefault'] == true;

    return Material(
      color: isSelected
          ? cs.primaryContainer.withValues(alpha: 0.5)
          : cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: BorderSide(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.75)
              : cs.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(template),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.description_outlined,
                size: 19,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isEmpty ? 'Sin nombre' : name,
                            style: t.bodySmall.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? cs.primary : cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDefault)
                          _TemplateBadge(
                            label: 'Predeterminada',
                            color: cs.primary,
                          ),
                        if (isSelected)
                          _TemplateBadge(label: 'En uso', color: cs.primary),
                      ],
                    ),
                    if (subject.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: t.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        preview.replaceAll(RegExp(r'\s+'), ' '),
                        style: t.bodySmall.copyWith(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateBadge extends StatelessWidget {
  const _TemplateBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _TemplateSearchEmptyState extends StatelessWidget {
  const _TemplateSearchEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 32, color: cs.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              'No hay resultados para “${query.trim()}”',
              textAlign: TextAlign.center,
              style: t.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Prueba con otro nombre o asunto.',
              textAlign: TextAlign.center,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
