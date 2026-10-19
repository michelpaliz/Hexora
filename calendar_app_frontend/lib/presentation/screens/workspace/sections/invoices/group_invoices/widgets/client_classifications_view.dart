import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/l10n/build_context_locale.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/client_classification_store.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/client_classification_manager_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:intl/intl.dart';

class ClientClassificationsView extends StatefulWidget {
  const ClientClassificationsView(
      {super.key,
      required this.groupId,
      required this.clients,
      this.invoices = const [],
      this.onEditClient,
      this.onUpdateClient,
      this.onDeleteClient,
      this.onManageClassifications,
      this.showCreateAction = true,
      this.loadOptions});
  final bool showCreateAction;
  final String groupId;
  final List<GroupClient> clients;
  final List<Invoice> invoices;
  final ValueChanged<GroupClient>? onEditClient;
  final Future<GroupClient> Function(GroupClient, Map<String, dynamic>)?
      onUpdateClient;
  final Future<void> Function(GroupClient)? onDeleteClient;
  final Future<void> Function()? onManageClassifications;
  final Future<ClientClassificationOptions> Function(String)? loadOptions;
  @override
  State<ClientClassificationsView> createState() =>
      _ClientClassificationsViewState();
}

class _ClientClassificationsViewState extends State<ClientClassificationsView> {
  List<String> _entities = [], _properties = [];
  late List<GroupClient> _clients;
  bool _loading = true, _busy = false, _entity = true, _ascending = true;
  String? _error, _category, _location, _property;
  bool? _active;
  String _categoryQuery = '', _query = '';
  final Set<String> _selected = {};
  int _page = 0, _pageSize = 8;
  bool get _es => context.isSpanishLocale;
  String tr(String es, String en) => _es ? es : en;
  String norm(String? value) => (value ?? '').trim().toLowerCase();
  String label(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty
        ? tr('Sin clasificar', 'Unclassified')
        : '${text[0].toUpperCase()}${text.substring(1)}';
  }

  String location(GroupClient client) =>
      [client.billing?.addressCity, client.billing?.addressProvince]
          .whereType<String>()
          .where((v) => v.trim().isNotEmpty)
          .toSet()
          .join(' · ');
  String? value(GroupClient c, bool entity) =>
      entity ? c.entityType : c.propertyKind;
  List<String> options(bool entity) {
    final values = <String, String>{};
    for (final v in [
      ...(entity ? _entities : _properties),
      ..._clients.map((c) => value(c, entity) ?? '')
    ]) {
      if (norm(v).isNotEmpty) values.putIfAbsent(norm(v), () => v.trim());
    }
    return values.values.toList()..sort((a, b) => norm(a).compareTo(norm(b)));
  }

  List<GroupClient> get assigned => _category == null
      ? []
      : _clients
          .where((c) => norm(value(c, _entity)) == norm(_category))
          .toList();
  int count(String category, bool entity) =>
      _clients.where((c) => norm(value(c, entity)) == norm(category)).length;
  List<GroupClient> get filtered {
    final rows = assigned
        .where((c) =>
            '${c.name} ${c.email ?? ''} ${c.billing?.taxId ?? ''}'
                .toLowerCase()
                .contains(_query) &&
            (_location == null || location(c) == _location) &&
            (_active == null || c.isActive == _active) &&
            (_property == null || norm(c.propertyKind) == norm(_property)))
        .toList();
    rows.sort((a, b) => _ascending
        ? norm(a.name).compareTo(norm(b.name))
        : norm(b.name).compareTo(norm(a.name)));
    return rows;
  }

  void choose(String category, bool entity) => setState(() {
        _category = category;
        _entity = entity;
        _page = 0;
        _selected.clear();
        _location = null;
        _property = null;
      });
  void filter(VoidCallback change) => setState(() {
        change();
        _page = 0;
        _selected.clear();
      });
  @override
  void initState() {
    super.initState();
    _clients = List.of(widget.clients);
    _load();
  }

  @override
  void didUpdateWidget(covariant ClientClassificationsView old) {
    super.didUpdateWidget(old);
    _clients = List.of(widget.clients);
    _selected.removeWhere((id) => !_clients.any((c) => c.id == id));
    if (old.groupId != widget.groupId) {
      _category = null;
      _selected.clear();
      _page = 0;
      _load();
    }
  }

  Future<void> _load() async {
    final groupId = widget.groupId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await (widget.loadOptions ??
          ClientClassificationStore.getOptions)(groupId);
      if (!mounted || widget.groupId != groupId) return;
      setState(() {
        _entities = result.entityTypes;
        _properties = result.propertyKinds;
        if (_category == null) {
          final entities = options(true);
          _category = entities.isEmpty ? '' : entities.first;
          _entity = true;
        }
      });
    } catch (error) {
      if (mounted && widget.groupId == groupId) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && widget.groupId == groupId) {
        setState(() => _loading = false);
      }
    }
  }

  void notify(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _manage() async {
    if (widget.onManageClassifications != null) {
      await widget.onManageClassifications!();
      if (mounted) await _load();
      return;
    }
    await showDialog<void>(
        context: context,
        builder: (_) =>
            ClientClassificationManagerDialog(groupId: widget.groupId));
    if (mounted) await _load();
  }

  Future<bool> confirm(String title, String message) async =>
      await showDialog<bool>(
          context: context,
          builder: (context) =>
              AlertDialog(title: Text(title), content: Text(message), actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(tr('Cancelar', 'Cancel'))),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(tr('Confirmar', 'Confirm'))),
              ])) ??
      false;
  Future<String?> _askCategory(
      {required bool entity, String? initial, required String title}) async {
    return showDialog<String>(
        context: context,
        builder: (_) => _ClassificationNameDialog(
              title: title,
              entity: entity,
              initial: initial,
              options: options(entity),
              isSpanish: _es,
            ));
  }

  Future<void> _reclassify({bool rename = false, bool? targetEntity}) async {
    final entity = targetEntity ?? _entity;
    final old = _category;
    final targets = rename
        ? assigned
        : _clients.where((c) => _selected.contains(c.id)).toList();
    final name = await _askCategory(
        entity: entity,
        initial: rename ? old : null,
        title: rename
            ? tr('Editar clasificación', 'Edit classification')
            : tr('Cambiar clasificación', 'Change classification'));
    if (!mounted || name == null || (rename && norm(old) == norm(name))) return;
    if (!await confirm(
        tr('Actualizar clasificación', 'Update classification'),
        tr('Se asignará «${label(name)}» a ${targets.length} clientes. Las demás clasificaciones se conservarán.',
            'Assign “${label(name)}” to ${targets.length} clients. Other classifications will be preserved.'))) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    var completed = 0;
    try {
      await ClientClassificationStore.merge(
          groupId: widget.groupId,
          entityType: entity ? name : null,
          propertyKind: entity ? null : name);
      for (final client in targets) {
        if (!mounted) return;
        final updated = await widget.onUpdateClient!(
            client, {entity ? 'entityType' : 'propertyKind': name});
        if (!mounted) return;
        setState(() {
          _clients = [
            for (final c in _clients)
              if (c.id == updated.id) updated else c
          ];
          _selected.remove(client.id);
        });
        completed++;
      }
      if (rename && (old ?? '').isNotEmpty) {
        await ClientClassificationStore.remove(
            groupId: widget.groupId,
            entityType: entity ? old : null,
            propertyKind: entity ? null : old);
      }
      if (!mounted) return;
      choose(name, entity);
      await _load();
      notify(tr('Clasificación actualizada.', 'Classification updated.'));
    } catch (error) {
      notify(tr('$completed de ${targets.length} clientes actualizados. $error',
          '$completed of ${targets.length} clients updated. $error'));
      if (mounted) await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final targets = _clients.where((c) => _selected.contains(c.id)).toList();
    if (!await confirm(
        tr('Eliminar clientes', 'Delete clients'),
        tr('¿Eliminar ${targets.length} clientes seleccionados? Esta acción no se puede deshacer.',
            'Delete ${targets.length} selected clients? This cannot be undone.'))) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    var completed = 0;
    try {
      for (final client in targets) {
        if (!mounted) return;
        await widget.onDeleteClient!(client);
        if (!mounted) return;
        setState(() {
          _clients.removeWhere((c) => c.id == client.id);
          _selected.remove(client.id);
        });
        completed++;
      }
      notify(
          tr('$completed clientes eliminados.', '$completed clients deleted.'));
    } catch (error) {
      notify(tr('$completed eliminados. $error', '$completed deleted. $error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    final rows = filtered.where((c) => _selected.contains(c.id)).toList();
    String csv(String text) {
      if (RegExp(r'^\s*[=+@\-\t\r]').hasMatch(text)) text = "'$text";
      return '"${text.replaceAll('"', '""')}"';
    }

    final lines = <List<String>>[
      [
        tr('Nombre', 'Name'),
        tr('Tipo de entidad', 'Entity type'),
        tr('Tipo de propiedad', 'Property type'),
        tr('Ubicación', 'Location'),
        tr('Estado', 'Status')
      ],
      for (final c in rows)
        [
          c.name,
          c.entityType ?? '',
          c.propertyKind ?? '',
          location(c),
          c.isActive ? tr('Activo', 'Active') : tr('Inactivo', 'Inactive')
        ],
    ];
    try {
      await launchFileDownload(
          Uint8List.fromList(utf8.encode(
              '\uFEFF${lines.map((row) => row.map(csv).join(';')).join('\r\n')}')),
          fileName: 'clientes-clasificacion.csv',
          mimeType: 'text/csv;charset=utf-8');
    } catch (error) {
      notify(error.toString());
    }
  }

  List<({bool entity, List<String> names})> get duplicates {
    String key(String v) {
      var text = norm(v);
      const accented = 'áéíóúüñ';
      const plain = 'aeiouun';
      for (var i = 0; i < accented.length; i++) {
        text = text.replaceAll(accented[i], plain[i]);
      }
      return text.replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    final result = <({bool entity, List<String> names})>[];
    for (final entity in [true, false]) {
      final groups = <String, List<String>>{};
      for (final name in options(entity)) {
        final k = key(name);
        if (k.isNotEmpty) (groups[k] ??= []).add(name);
      }
      for (final names in groups.values.where((v) => v.length > 1)) {
        result.add((entity: entity, names: names));
      }
    }
    return result;
  }

  Future<void> _reviewDuplicates() async {
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(tr('Posibles duplicados', 'Possible duplicates')),
                content: SizedBox(
                    width: 440,
                    child: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(tr(
                          'Revisa los nombres. Edita una clasificación y elige la existente para combinarlas.',
                          'Review the names. Edit a classification and choose the existing one to combine them.')),
                      for (final group in duplicates)
                        ListTile(
                            title: Text(group.names.map(label).join(' / ')),
                            subtitle: Text(group.entity
                                ? tr('Tipo de entidad', 'Entity type')
                                : tr('Tipo de propiedad', 'Property type')),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              choose(group.names.first, group.entity);
                              Navigator.pop(context);
                            }),
                    ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(tr('Cerrar', 'Close')))
                ]));
  }

  BoxDecoration get panel => BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: .45)));
  InputDecoration fieldDecoration(String hint,
      {Widget? prefix, Widget? suffix}) {
    final cs = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(color: color, width: width));
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: cs.surfaceContainerLow.withValues(alpha: .7),
      hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
      prefixIcon: prefix,
      suffixIcon: suffix,
      prefixIconColor: cs.onSurfaceVariant,
      enabledBorder: border(cs.outlineVariant.withValues(alpha: .5)),
      disabledBorder: border(cs.outlineVariant.withValues(alpha: .25)),
      focusedBorder: border(cs.primary, 1.5),
      border: border(cs.outlineVariant.withValues(alpha: .5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget search(String hint, ValueChanged<String> onChanged) =>
      _ClassificationSearchField(
        hint: hint,
        decoration: fieldDecoration(hint,
            prefix: const Icon(Icons.search_rounded, size: 19)),
        clearLabel: tr('Limpiar búsqueda', 'Clear search'),
        onChanged: onChanged,
      );
  Widget stat(IconData icon, String number, String title,
      {VoidCallback? onTap, Color? color}) {
    final cs = Theme.of(context).colorScheme;
    final tone = color ?? cs.primary;
    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
              padding: const EdgeInsets.all(14),
              decoration: panel,
              child: Row(children: [
                CircleAvatar(
                    backgroundColor: tone.withValues(alpha: .1),
                    child: Icon(icon, color: tone, size: 21)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(number,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: tone)),
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                    ])),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 18, color: tone),
              ])),
        ));
  }

  Widget sidebar() => Container(
      decoration: panel,
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(tr('Clasificaciones', 'Classifications'),
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        search(tr('Buscar clasificación…', 'Search classifications…'),
            (v) => setState(() => _categoryQuery = norm(v))),
        const SizedBox(height: 12),
        Expanded(
            child: ListView(children: [
          for (final entity in [true, false]) ...[
            if (!entity) const Divider(height: 24),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                    entity
                        ? tr('TIPO DE ENTIDAD', 'ENTITY TYPE')
                        : tr('TIPO DE PROPIEDAD', 'PROPERTY TYPE'),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
            for (final category in [...options(entity), '']
                .where((v) => norm(label(v)).contains(_categoryQuery)))
              Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                      selected: _entity == entity &&
                          norm(_category) == norm(category),
                      selectedTileColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: .45),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Icon(
                          category.isEmpty
                              ? Icons.warning_amber_rounded
                              : entity
                                  ? Icons.business_outlined
                                  : Icons.home_work_outlined,
                          size: 19),
                      title: Text(label(category),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontSize: 13)),
                      trailing: Text('${count(category, entity)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                      onTap: _busy ? null : () => choose(category, entity))),
          ],
        ])),
      ]));
  Widget dropdown<T>(T? selected, String hint, List<DropdownMenuItem<T>> items,
          ValueChanged<T?> changed) =>
      DropdownButtonFormField<T>(
          key: ValueKey('$hint-$selected'),
          initialValue: selected,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded, size: 20),
          borderRadius: BorderRadius.circular(12),
          decoration: fieldDecoration(hint),
          hint: Text(hint,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 12)),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
          items: items,
          onChanged: _busy ? null : changed);
  Widget tablePanel() {
    final cs = Theme.of(context).colorScheme;
    final rows = filtered;
    final pages = (rows.length / _pageSize).ceil().clamp(1, 1000000);
    final page = _page.clamp(0, pages - 1);
    final current = rows.skip(page * _pageSize).take(_pageSize).toList();
    final locations = assigned
        .map(location)
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final latest = <String, DateTime>{};
    for (final invoice in widget.invoices) {
      final date = invoice.issuedAtResolved;
      if (date != null &&
          (!latest.containsKey(invoice.clientId) ||
              date.isAfter(latest[invoice.clientId]!))) {
        latest[invoice.clientId] = date;
      }
    }
    final enabled = !_busy && _selected.isNotEmpty;
    return Container(
        decoration: panel,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              _category == null
                                  ? tr('Selecciona una clasificación',
                                      'Select a classification')
                                  : label(_category),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              '${assigned.length} ${tr('clientes', 'clients')} · ${_entity ? tr('Tipo de entidad', 'Entity type') : tr('Tipo de propiedad', 'Property type')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant)),
                        ]),
                    OutlinedButton.icon(
                        onPressed: !_busy &&
                                (_category ?? '').isNotEmpty &&
                                widget.onUpdateClient != null
                            ? () => _reclassify(rename: true)
                            : null,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(
                            tr('Editar clasificación', 'Edit classification'))),
                  ])),
          const Divider(height: 1),
          Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Wrap(spacing: 8, runSpacing: 8, children: [
                  SizedBox(
                      width: width < 700 ? width : (width - 24) * .36,
                      child: search(tr('Buscar clientes…', 'Search clients…'),
                          (v) => filter(() => _query = norm(v)))),
                  SizedBox(
                      width: width < 700 ? (width - 8) / 2 : (width - 24) * .24,
                      child: dropdown<String>(
                          _location,
                          tr('Todas las ubicaciones', 'All locations'),
                          [
                            DropdownMenuItem(
                                value: null,
                                child: Text(tr(
                                    'Todas las ubicaciones', 'All locations'))),
                            for (final loc in locations)
                              DropdownMenuItem(
                                  value: loc,
                                  child: Text(loc,
                                      overflow: TextOverflow.ellipsis)),
                          ],
                          (v) => filter(() => _location = v))),
                  SizedBox(
                      width: width < 700 ? (width - 8) / 2 : (width - 24) * .20,
                      child: dropdown<bool>(
                          _active,
                          tr('Todos los estados', 'All statuses'),
                          [
                            DropdownMenuItem(
                                value: null,
                                child: Text(
                                    tr('Todos los estados', 'All statuses'))),
                            DropdownMenuItem(
                                value: true,
                                child: Text(tr('Activo', 'Active'))),
                            DropdownMenuItem(
                                value: false,
                                child: Text(tr('Inactivo', 'Inactive'))),
                          ],
                          (v) => filter(() => _active = v))),
                  SizedBox(
                      width: width < 700 ? width : (width - 24) * .20,
                      child: dropdown<String>(
                          _property,
                          tr('Tipo de propiedad', 'Property type'),
                          [
                            DropdownMenuItem(
                                value: null,
                                child: Text(tr('Todas las propiedades',
                                    'All properties'))),
                            for (final prop in options(false))
                              DropdownMenuItem(
                                  value: prop,
                                  child: Text(label(prop),
                                      overflow: TextOverflow.ellipsis)),
                          ],
                          (v) => filter(() => _property = v))),
                ]);
              })),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                        '${_selected.length} ${tr('seleccionados', 'selected')}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    PopupMenuButton<bool>(
                      enabled: enabled && widget.onUpdateClient != null,
                      tooltip:
                          tr('Cambiar clasificación', 'Change classification'),
                      onSelected: (entity) => _reclassify(targetEntity: entity),
                      itemBuilder: (_) => [
                        NavigationPopupMenuItem(
                            value: true,
                            child: Text(tr('Tipo de entidad', 'Entity type'))),
                        NavigationPopupMenuItem(
                            value: false,
                            child:
                                Text(tr('Tipo de propiedad', 'Property type')))
                      ],
                      child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                              tr('Cambiar clasificación',
                                  'Change classification'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontSize: 12,
                                      color: enabled
                                          ? cs.primary
                                          : cs.onSurface
                                              .withValues(alpha: .38)))),
                    ),
                    TextButton.icon(
                        onPressed: enabled ? _export : null,
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: Text(tr('Exportar', 'Export'))),
                    TextButton.icon(
                        onPressed: enabled && widget.onDeleteClient != null
                            ? _delete
                            : null,
                        style: TextButton.styleFrom(foregroundColor: cs.error),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(tr('Eliminar', 'Delete'))),
                  ])),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
              child: SingleChildScrollView(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 38,
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 54,
                        horizontalMargin: 12,
                        columnSpacing: 20,
                        showCheckboxColumn: true,
                        sortColumnIndex: 0,
                        sortAscending: _ascending,
                        headingRowColor: WidgetStatePropertyAll(
                            cs.primaryContainer.withValues(alpha: .18)),
                        onSelectAll: _busy || current.isEmpty
                            ? null
                            : (checked) => setState(() {
                                  for (final c in current) {
                                    if (checked == true) {
                                      _selected.add(c.id);
                                    } else {
                                      _selected.remove(c.id);
                                    }
                                  }
                                }),
                        columns: [
                          DataColumn(
                              label: Text(tr('Nombre', 'Name')),
                              onSort: (_, asc) => setState(() {
                                    _ascending = asc;
                                    _page = 0;
                                  })),
                          DataColumn(
                              label: Text(
                                  tr('Tipo de propiedad', 'Property type'))),
                          DataColumn(label: Text(tr('Ubicación', 'Location'))),
                          DataColumn(label: Text(tr('Estado', 'Status'))),
                          DataColumn(
                              label:
                                  Text(tr('Última factura', 'Latest invoice'))),
                          DataColumn(label: Text(tr('Acciones', 'Actions'))),
                        ],
                        rows: [
                          for (final c in current)
                            DataRow(
                                key: ValueKey(c.id),
                                selected: _selected.contains(c.id),
                                onSelectChanged: _busy
                                    ? null
                                    : (v) => setState(() {
                                          if (v == true) {
                                            _selected.add(c.id);
                                          } else {
                                            _selected.remove(c.id);
                                          }
                                        }),
                                cells: [
                                  DataCell(
                                      SizedBox(
                                          width: 210,
                                          child: Row(children: [
                                            CircleAvatar(
                                                radius: 15,
                                                backgroundColor: cs
                                                    .primaryContainer
                                                    .withValues(alpha: .6),
                                                child: Text(
                                                    c.name.isEmpty
                                                        ? '?'
                                                        : c.name[0]
                                                            .toUpperCase(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(
                                                            fontSize: 12))),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                  Text(c.name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium!
                                                          .copyWith(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                  Text(label(c.entityType),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium!
                                                          .copyWith(
                                                              fontSize: 10,
                                                              color: cs
                                                                  .onSurfaceVariant)),
                                                ]))
                                          ])),
                                      onTap:
                                          widget.onEditClient == null || _busy
                                              ? null
                                              : () => widget.onEditClient!(c)),
                                  DataCell(Text(label(c.propertyKind),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(fontSize: 12))),
                                  DataCell(SizedBox(
                                      width: 140,
                                      child: Text(
                                          location(c).isEmpty
                                              ? '—'
                                              : location(c),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(fontSize: 12)))),
                                  DataCell(Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: (c.isActive ? Colors.green : cs.error)
                                              .withValues(alpha: .1),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text(
                                          c.isActive
                                              ? tr('Activo', 'Active')
                                              : tr('Inactivo', 'Inactive'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                  fontSize: 11,
                                                  color: c.isActive
                                                      ? (cs.brightness == Brightness.dark
                                                          ? Colors.green.shade200
                                                          : Colors.green.shade800)
                                                      : cs.error)))),
                                  DataCell(Text(
                                      latest[c.id] == null
                                          ? '—'
                                          : DateFormat.yMMMd(
                                                  Localizations.localeOf(
                                                          context)
                                                      .toString())
                                              .format(latest[c.id]!),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(fontSize: 12))),
                                  DataCell(PopupMenuButton<String>(
                                      tooltip: tr('Acciones del cliente',
                                          'Client actions'),
                                      enabled: !_busy,
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          widget.onEditClient?.call(c);
                                        } else {
                                          setState(() {
                                            _selected.clear();
                                            _selected.add(c.id);
                                          });
                                          _reclassify();
                                        }
                                      },
                                      itemBuilder: (_) => [
                                            if (widget.onEditClient != null)
                                              NavigationPopupMenuItem(
                                                  value: 'edit',
                                                  child: Text(tr(
                                                      'Editar cliente',
                                                      'Edit client'))),
                                            if (widget.onUpdateClient != null)
                                              NavigationPopupMenuItem(
                                                  value: 'classify',
                                                  child: Text(tr(
                                                      'Cambiar clasificación',
                                                      'Change classification'))),
                                          ],
                                      icon: const Icon(Icons.more_horiz,
                                          size: 19))),
                                ]),
                        ],
                      )))),
          if (rows.isEmpty)
            Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                    tr('No hay clientes que coincidan.',
                        'No matching clients.'),
                    textAlign: TextAlign.center)),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 8,
                  children: [
                    Text(
                        rows.isEmpty
                            ? tr('0 clientes', '0 clients')
                            : tr(
                                'Mostrando ${page * _pageSize + 1}–${page * _pageSize + current.length} de ${rows.length} clientes',
                                'Showing ${page * _pageSize + 1}–${page * _pageSize + current.length} of ${rows.length} clients'),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontSize: 12)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      DropdownButton<int>(
                          value: _pageSize,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final size in [8, 16, 32])
                              DropdownMenuItem(
                                  value: size,
                                  child: Text(
                                      '$size ${tr('por página', 'per page')}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(fontSize: 12)))
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _pageSize = v;
                                _page = 0;
                              });
                            }
                          }),
                      IconButton(
                          tooltip: tr('Página anterior', 'Previous page'),
                          onPressed: page == 0
                              ? null
                              : () => setState(() => _page = page - 1),
                          icon: const Icon(Icons.chevron_left)),
                      Text('${page + 1} / $pages',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontSize: 12)),
                      IconButton(
                          tooltip: tr('Página siguiente', 'Next page'),
                          onPressed: page == pages - 1
                              ? null
                              : () => setState(() => _page = page + 1),
                          icon: const Icon(Icons.chevron_right)),
                    ]),
                  ])),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, textAlign: TextAlign.center),
        TextButton(onPressed: _load, child: Text(tr('Reintentar', 'Retry'))),
      ]));
    }
    final unclassified =
        _clients.where((c) => norm(c.entityType).isEmpty).length;
    final duplicateCount = duplicates.length;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1000;
      final cards = [
        stat(Icons.person_outline, '${_clients.length}',
            tr('Clientes totales', 'Total clients')),
        stat(Icons.business_outlined, '${options(true).length}',
            tr('Tipos de entidad', 'Entity types')),
        stat(Icons.home_outlined, '${options(false).length}',
            tr('Tipos de propiedad', 'Property types')),
        stat(Icons.warning_amber, '$unclassified',
            tr('Sin clasificar', 'Unclassified'),
            color: Colors.orange.shade800,
            onTap: _busy ? null : () => choose('', true)),
        stat(Icons.auto_awesome_outlined, '$duplicateCount',
            tr('Posibles duplicados', 'Possible duplicates'),
            onTap: duplicateCount == 0 || _busy ? null : _reviewDuplicates),
      ];
      final body =
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (widget.showCreateAction)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _busy ? null : _manage,
              icon: const Icon(Icons.add, size: 18),
              label: Text(tr('Nueva clasificación', 'New classification')),
            ),
          ),
        if (widget.showCreateAction) const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final card in cards)
            SizedBox(
                width: wide
                    ? (constraints.maxWidth - 60) / 5
                    : (constraints.maxWidth - 30) / 2,
                child: card)
        ]),
        const SizedBox(height: 14),
        if (wide)
          Expanded(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                SizedBox(width: 260, child: sidebar()),
                const SizedBox(width: 12),
                Expanded(child: tablePanel())
              ]))
        else ...[
          SizedBox(height: 300, child: sidebar()),
          const SizedBox(height: 12),
          SizedBox(height: 660, child: tablePanel())
        ],
      ]);
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      final shape =
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
      return Theme(
        data: theme.copyWith(
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  shape: shape,
                  backgroundColor: cs.surfaceContainerLow,
                  side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: .5)),
                  textStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 13, fontWeight: FontWeight.w600))),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  shape: shape,
                  backgroundColor: cs.primary.withValues(alpha: .05),
                  textStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 12, fontWeight: FontWeight.w600))),
          iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                  shape: shape, foregroundColor: cs.primary)),
        ),
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: wide ? body : SingleChildScrollView(child: body)),
      );
    });
  }
}

class _ClassificationNameDialog extends StatefulWidget {
  const _ClassificationNameDialog(
      {required this.title,
      required this.entity,
      required this.initial,
      required this.options,
      required this.isSpanish});
  final String title;
  final bool entity, isSpanish;
  final String? initial;
  final List<String> options;
  @override
  State<_ClassificationNameDialog> createState() =>
      _ClassificationNameDialogState();
}

class _ClassificationNameDialogState extends State<_ClassificationNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  String? _error;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final es = widget.isSpanish;
    return AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: 50,
                  decoration: InputDecoration(
                      errorText: _error,
                      labelText: widget.entity
                          ? (es ? 'Tipo de entidad' : 'Entity type')
                          : (es ? 'Tipo de propiedad' : 'Property type'))),
              if (widget.options.isNotEmpty)
                DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                        labelText: es
                            ? 'O elige una existente'
                            : 'Or choose an existing one'),
                    items: widget.options
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) _controller.text = value;
                    }),
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(es ? 'Cancelar' : 'Cancel')),
          FilledButton(
              onPressed: () {
                final value =
                    ClientClassificationStore.normalize(_controller.text);
                if (value == null) {
                  setState(() =>
                      _error = es ? 'Introduce un nombre' : 'Enter a name');
                  return;
                }
                Navigator.pop(context, value);
              },
              child: Text(es ? 'Continuar' : 'Continue')),
        ]);
  }
}

class _ClassificationSearchField extends StatefulWidget {
  const _ClassificationSearchField(
      {required this.hint,
      required this.decoration,
      required this.clearLabel,
      required this.onChanged});
  final String hint, clearLabel;
  final InputDecoration decoration;
  final ValueChanged<String> onChanged;
  @override
  State<_ClassificationSearchField> createState() =>
      _ClassificationSearchFieldState();
}

class _ClassificationSearchFieldState
    extends State<_ClassificationSearchField> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 13),
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        decoration: widget.decoration.copyWith(
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: widget.clearLabel,
                  icon: const Icon(Icons.close_rounded, size: 17),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  },
                ),
        ),
      );
}
