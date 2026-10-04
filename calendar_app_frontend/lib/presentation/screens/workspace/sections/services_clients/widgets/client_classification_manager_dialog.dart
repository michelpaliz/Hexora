import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/client_classification_store.dart';

class ClientClassificationManagerDialog extends StatefulWidget {
  const ClientClassificationManagerDialog(
      {super.key, required this.groupId, this.clients});
  final String groupId;
  final List<GroupClient>? clients;

  @override
  State<ClientClassificationManagerDialog> createState() =>
      _ClientClassificationManagerDialogState();
}

class _OptionDraft {
  _OptionDraft(String value) : controller = TextEditingController(text: value);
  final TextEditingController controller;
  final focus = FocusNode();
  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class _ClientClassificationManagerDialogState
    extends State<ClientClassificationManagerDialog> {
  final _form = GlobalKey<FormState>();
  final _entities = <_OptionDraft>[];
  final _properties = <_OptionDraft>[];
  // Removed rows retain their controllers until their widgets are unmounted.
  final _retired = <_OptionDraft>[];
  List<String> _savedEntities = [], _savedProperties = [];
  List<GroupClient> _clients = [];
  bool _loading = true, _saving = false, _closing = false;
  String? _error;
  String t(String es, String en) =>
      Localizations.localeOf(context).languageCode == 'es' ? es : en;
  String norm(String value) => value.trim().toLowerCase();
  List<String> values(List<_OptionDraft> rows) =>
      rows.map((r) => norm(r.controller.text)).toList();
  bool get _dirty =>
      !listEquals(values(_entities), _savedEntities) ||
      !listEquals(values(_properties), _savedProperties);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final row in [..._entities, ..._properties, ..._retired]) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ClientClassificationStore.getOptions(widget.groupId),
        widget.clients != null
            ? Future.value(widget.clients!)
            : ClientsApi().list(groupId: widget.groupId, active: null),
      ]);
      if (!mounted) return;
      final options = results[0] as ClientClassificationOptions;
      setState(() {
        _savedEntities = options.entityTypes.map(norm).toList();
        _savedProperties = options.propertyKinds.map(norm).toList();
        _clients = results[1] as List<GroupClient>;
        _resetDraft();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = t(
            'No se pudieron cargar las opciones. Reintenta antes de editar.',
            'Could not load options. Retry before editing.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetDraft() {
    _retired.addAll([..._entities, ..._properties]);
    _entities
      ..clear()
      ..addAll(_savedEntities.map(_OptionDraft.new));
    _properties
      ..clear()
      ..addAll(_savedProperties.map(_OptionDraft.new));
    _form.currentState?.reset();
    _error = null;
  }

  Future<void> _close() async {
    if (_saving || _closing) return;
    _closing = true;
    if (_dirty) {
      final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(t('¿Descartar los cambios?', 'Discard changes?')),
                content: Text(t('Las opciones guardadas no se modificarán.',
                    'Saved options will remain unchanged.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(t('Seguir editando', 'Keep editing'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(t('Descartar', 'Discard'))),
                ],
              ));
      if (!mounted) return;
      if (discard != true) {
        _closing = false;
        return;
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_saving || _loading || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ClientClassificationStore.replaceOptions(
          groupId: widget.groupId,
          entityTypes: values(_entities),
          propertyKinds: values(_properties));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error = t(
            'No se pudieron guardar los cambios. Tus ediciones se conservan; vuelve a intentarlo.',
            'Could not save changes. Your edits are preserved; please retry.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _add(List<_OptionDraft> rows) {
    final row = _OptionDraft('');
    setState(() => rows.add(row));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && rows.contains(row)) row.focus.requestFocus();
    });
  }

  int _count(_OptionDraft row, bool entity) => _clients
      .where((client) =>
          norm((entity ? client.entityType : client.propertyKind) ?? '') ==
              norm(row.controller.text) &&
          row.controller.text.trim().isNotEmpty)
      .length;

  Widget _section(bool entity) {
    final cs = Theme.of(context).colorScheme;
    final rows = entity ? _entities : _properties;
    final color = entity ? cs.primary : const Color(0xFF168351);
    final icon = entity ? Icons.business_outlined : Icons.home_outlined;
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
          borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
            color: cs.surfaceContainerLow.withValues(alpha: .5),
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(builder: (context, constraints) {
              final heading = Row(children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 23)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          entity
                              ? t('Tipo de entidad', 'Entity type')
                              : t('Tipo de propiedad', 'Property type'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                          t('Añade, edita o elimina opciones · máx. 50 caracteres',
                              'Add, edit or remove options · max. 50 characters'),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                    ])),
              ]);
              final add = OutlinedButton.icon(
                  onPressed: _saving ? null : () => _add(rows),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t('Añadir opción', 'Add option')));
              return constraints.maxWidth < 520
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          heading,
                          const SizedBox(height: 10),
                          Align(alignment: Alignment.centerRight, child: add)
                        ])
                  : Row(children: [
                      Expanded(child: heading),
                      const SizedBox(width: 12),
                      add
                    ]);
            })),
        if (rows.isEmpty)
          Padding(
              padding: const EdgeInsets.all(20),
              child: Text(t('No hay opciones guardadas.', 'No saved options.'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: cs.onSurfaceVariant))),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: rows.length,
          onReorder: (oldIndex, newIndex) {
            if (_saving) return;
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              rows.insert(newIndex, rows.removeAt(oldIndex));
            });
          },
          itemBuilder: (context, index) {
            final row = rows[index];
            final count = _count(row, entity);
            return Material(
                key: ObjectKey(row),
                color: cs.surface,
                child: Container(
                  decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: .3)))),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final compact = constraints.maxWidth < 540;
                    final usage = Text(
                        '$count ${t(count == 1 ? 'cliente' : 'clientes', count == 1 ? 'client' : 'clients')}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 12, color: cs.onSurfaceVariant));
                    final field = TextFormField(
                      key: ObjectKey(row.controller),
                      controller: row.controller,
                      focusNode: row.focus,
                      enabled: !_saving,
                      maxLength: 50,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 13),
                      onChanged: (_) => setState(() {}),
                      validator: (text) {
                        final value = norm(text ?? '');
                        if (value.isEmpty) {
                          return t('Escribe un nombre', 'Enter a name');
                        }
                        if (values(rows).where((v) => v == value).length > 1) {
                          return t('Esta opción ya existe',
                              'This option already exists');
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                          hintText: t('Nombre de la opción', 'Option name'),
                          counterText: '',
                          isDense: true,
                          filled: true,
                          fillColor:
                              cs.surfaceContainerLow.withValues(alpha: .55),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(
                                  color:
                                      cs.outlineVariant.withValues(alpha: .5))),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide:
                                  BorderSide(color: cs.primary, width: 1.5))),
                    );
                    return Row(children: [
                      Tooltip(
                          message:
                              t('Arrastrar para ordenar', 'Drag to reorder'),
                          child: ReorderableDragStartListener(
                              index: index,
                              enabled: !_saving,
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 12),
                                  child: Icon(Icons.drag_indicator,
                                      size: 18, color: cs.onSurfaceVariant)))),
                      if (!compact) ...[
                        Icon(icon, size: 19, color: color),
                        const SizedBox(width: 12)
                      ],
                      Expanded(
                          child: compact
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      field,
                                      const SizedBox(height: 4),
                                      usage
                                    ])
                              : field),
                      if (!compact) ...[
                        const SizedBox(width: 18),
                        Icon(Icons.circle, size: 9, color: color),
                        const SizedBox(width: 8),
                        SizedBox(width: 110, child: usage)
                      ],
                      const SizedBox(width: 6),
                      if (!compact)
                        IconButton(
                            tooltip: t('Editar opción', 'Edit option'),
                            onPressed: _saving
                                ? null
                                : () {
                                    row.focus.requestFocus();
                                    row.controller.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset:
                                            row.controller.text.length);
                                  },
                            icon: const Icon(Icons.edit_outlined, size: 18)),
                      IconButton(
                          tooltip: t('Eliminar opción', 'Remove option'),
                          style: IconButton.styleFrom(
                              foregroundColor: cs.error,
                              backgroundColor: cs.error.withValues(alpha: .06)),
                          onPressed: _saving
                              ? null
                              : () => setState(() {
                                    rows.remove(row);
                                    _retired.add(row);
                                  }),
                          icon: const Icon(Icons.delete_outline, size: 18)),
                    ]);
                  }),
                ));
          },
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    return PopScope(
        canPop: !_saving && !_dirty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
              width: 900,
              height: (MediaQuery.sizeOf(context).height * .88).clamp(0, 850),
              child: Theme(
                data: theme.copyWith(
                  outlinedButtonTheme: OutlinedButtonThemeData(
                      style: OutlinedButton.styleFrom(
                          shape: shape,
                          side: BorderSide(color: cs.outlineVariant),
                          minimumSize: const Size(0, 40))),
                  filledButtonTheme: FilledButtonThemeData(
                      style: FilledButton.styleFrom(
                          shape: shape, minimumSize: const Size(0, 42))),
                  iconButtonTheme: IconButtonThemeData(
                      style: IconButton.styleFrom(shape: shape)),
                ),
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (MediaQuery.sizeOf(context).width > 600) ...[
                              Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: cs.primaryContainer
                                          .withValues(alpha: .6),
                                      borderRadius: BorderRadius.circular(14)),
                                  child: Icon(Icons.settings_outlined,
                                      color: cs.primary, size: 27)),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      t('Administrar opciones guardadas',
                                          'Manage saved options'),
                                      style:
                                          Theme.of(
                                                  context)
                                              .textTheme
                                              .titleLarge!
                                              .copyWith(
                                                  fontSize:
                                                      MediaQuery.sizeOf(context)
                                                                  .width <
                                                              600
                                                          ? 16
                                                          : 18,
                                                  fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 5),
                                  Text(
                                      t('Gestiona las opciones que se usan para clasificar a los clientes.',
                                          'Manage the options used to classify clients.'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                              fontSize: 13,
                                              color: cs.onSurfaceVariant)),
                                ])),
                            IconButton(
                                tooltip: t('Cerrar', 'Close'),
                                onPressed: _saving ? null : _close,
                                icon: const Icon(Icons.close)),
                          ])),
                  Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : Form(
                              key: _form,
                              child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Column(children: [
                                    if (_error != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Material(
                                              color: cs.errorContainer,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  child: Column(children: [
                                                    Text(_error!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium!
                                                            .copyWith(
                                                                color: cs
                                                                    .onErrorContainer)),
                                                    if (_entities.isEmpty &&
                                                        _properties.isEmpty &&
                                                        !_dirty)
                                                      TextButton(
                                                          onPressed: _load,
                                                          child: Text(t(
                                                              'Reintentar',
                                                              'Retry'))),
                                                  ])))),
                                    if (_error == null ||
                                        _entities.isNotEmpty ||
                                        _properties.isNotEmpty ||
                                        _dirty) ...[
                                      _section(true),
                                      const SizedBox(height: 20),
                                      _section(false),
                                      const SizedBox(height: 16),
                                      Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                              color: cs.primaryContainer
                                                  .withValues(alpha: .35),
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(Icons.info_outline,
                                                    color: cs.primary,
                                                    size: 20),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                    child: Text(
                                                        t('Estas opciones se guardan para el grupo. Los clientes conservan su clasificación actual; para cambiarla, usa «Editar clasificación» en la lista de clientes.',
                                                            'These options are saved for the group. Existing clients keep their classification; use “Edit classification” in the client list to change it.'),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium!
                                                            .copyWith(
                                                                fontSize: 12,
                                                                color: cs
                                                                    .onSurfaceVariant))),
                                              ])),
                                      const SizedBox(height: 12),
                                    ],
                                  ])))),
                  const Divider(height: 1),
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                    onPressed: !_loading && !_saving && _dirty
                                        ? () => setState(_resetDraft)
                                        : null,
                                    icon:
                                        const Icon(Icons.restart_alt, size: 18),
                                    label: Text(t('Restablecer', 'Reset'))),
                                TextButton(
                                    onPressed: _saving ? null : _close,
                                    child: Text(t('Cancelar', 'Cancel'))),
                                FilledButton(
                                    onPressed: !_loading && !_saving && _dirty
                                        ? _save
                                        : null,
                                    child: _saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : Text(t('Guardar cambios',
                                            'Save changes'))),
                              ]))),
                ]),
              )),
        ));
  }
}
