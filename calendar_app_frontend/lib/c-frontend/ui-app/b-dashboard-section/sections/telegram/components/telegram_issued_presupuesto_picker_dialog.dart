import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hexora/a-models/presupuesto/presupuesto_kind.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';

class TelegramIssuedPresupuestoSelection {
  const TelegramIssuedPresupuestoSelection({
    required this.id,
    required this.title,
    required this.isDraft,
    required this.kind,
  });

  final String id;
  final String title;
  final bool isDraft;
  final PresupuestoKind kind;
}

enum _PresupuestoKindFilter { all, structured, document }

Future<TelegramIssuedPresupuestoSelection?>
    showTelegramIssuedPresupuestoPickerDialog(
  BuildContext context, {
  required String groupId,
  PresupuestosApi? api,
}) {
  return showDialog<TelegramIssuedPresupuestoSelection>(
    context: context,
    builder: (dialogContext) => Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: TelegramIssuedPresupuestoPickerDialog(
          groupId: groupId,
          api: api,
        ),
      ),
    ),
  );
}

class TelegramIssuedPresupuestoPickerDialog extends StatefulWidget {
  const TelegramIssuedPresupuestoPickerDialog({
    super.key,
    required this.groupId,
    this.api,
  });

  final String groupId;
  final PresupuestosApi? api;

  @override
  State<TelegramIssuedPresupuestoPickerDialog> createState() =>
      _TelegramIssuedPresupuestoPickerDialogState();
}

class _TelegramIssuedPresupuestoPickerDialogState
    extends State<TelegramIssuedPresupuestoPickerDialog> {
  late final PresupuestosApi _api;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _documents = const <Map<String, dynamic>>[];
  PresupuestoStatusFilter _statusFilter = PresupuestoStatusFilter.all;
  _PresupuestoKindFilter _kindFilter = _PresupuestoKindFilter.all;
  bool _loading = true;
  String? _error;

  bool get _isSpanish =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  List<Map<String, dynamic>> get _visibleDocuments {
    final query = _searchController.text.trim().toLowerCase();
    return _documents.where((document) {
      if (_statusFilter == PresupuestoStatusFilter.draft &&
          !_isDraft(document)) {
        return false;
      }
      if (_statusFilter == PresupuestoStatusFilter.issued &&
          !_isIssued(document)) {
        return false;
      }
      final kind = PresupuestoKind.fromJson(document);
      if (_kindFilter == _PresupuestoKindFilter.structured &&
          kind != PresupuestoKind.structured) {
        return false;
      }
      if (_kindFilter == _PresupuestoKindFilter.document &&
          kind != PresupuestoKind.document) {
        return false;
      }
      if (query.isEmpty) return true;
      return <String>[
        _title(document),
        _number(document),
        _clientName(document),
      ].any((value) => value.toLowerCase().contains(query));
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? PresupuestosApi();
    _searchController.addListener(_handleSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loaded = await _api.listByGroup(groupId: widget.groupId);
      final documents = loaded.where((document) {
        return _id(document).isNotEmpty &&
            (_isDraft(document) || _isIssued(document));
      }).toList(growable: false)
        ..sort((a, b) => _sortDate(b).compareTo(_sortDate(a)));
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _select(Map<String, dynamic> document) async {
    final isDraft = _isDraft(document);
    if (isDraft) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (confirmationContext) => AlertDialog(
          title: Text(
            _isSpanish ? '¿Enviar borrador?' : 'Send draft?',
          ),
          content: Text(
            _isSpanish
                ? 'Este presupuesto todavía es un borrador. ¿Quieres enviarlo igualmente?'
                : 'This budget is still a draft and may change. Do you want to send it anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(confirmationContext).pop(false),
              child: Text(_isSpanish ? 'Cancelar' : 'Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(confirmationContext).pop(true),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isSpanish ? 'Enviar borrador' : 'Send draft',
              ),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }
    Navigator.of(context).pop(
      TelegramIssuedPresupuestoSelection(
        id: _id(document),
        title: _title(document),
        isDraft: isDraft,
        kind: PresupuestoKind.fromJson(document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final documents = _visibleDocuments;

    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.request_quote_rounded,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSpanish ? 'Presupuestos' : 'Budgets',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isSpanish
                            ? 'Selecciona el PDF que quieres enviar a este chat.'
                            : 'Select the PDF to send to this chat.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _isSpanish
                    ? 'Buscar por título, número o cliente'
                    : 'Search by title, number, or client',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close_rounded, size: 19),
                      ),
                filled: true,
                fillColor: cs.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<PresupuestoStatusFilter>(
                segments: [
                  ButtonSegment(
                    value: PresupuestoStatusFilter.all,
                    label: Text(_isSpanish ? 'Todos' : 'All'),
                  ),
                  ButtonSegment(
                    value: PresupuestoStatusFilter.draft,
                    label: Text(_isSpanish ? 'Borradores' : 'Drafts'),
                  ),
                  ButtonSegment(
                    value: PresupuestoStatusFilter.issued,
                    label: Text(_isSpanish ? 'Emitidos' : 'Issued'),
                  ),
                ],
                selected: {_statusFilter},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  setState(() => _statusFilter = selection.first);
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_PresupuestoKindFilter>(
                segments: [
                  ButtonSegment(
                    value: _PresupuestoKindFilter.all,
                    label: Text(_isSpanish ? 'Todos los tipos' : 'All types'),
                  ),
                  ButtonSegment(
                    value: _PresupuestoKindFilter.structured,
                    label: Text(_isSpanish ? 'Partidas' : 'Itemized'),
                  ),
                  ButtonSegment(
                    value: _PresupuestoKindFilter.document,
                    label: Text(_isSpanish ? 'Documentos' : 'Documents'),
                  ),
                ],
                selected: {_kindFilter},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  setState(() => _kindFilter = selection.first);
                },
              ),
            ),
            const SizedBox(height: 14),
            Flexible(child: _buildBody(documents, cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    List<Map<String, dynamic>> documents,
    ColorScheme cs,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: cs.error, size: 36),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_isSpanish ? 'Reintentar' : 'Retry'),
            ),
          ],
        ),
      );
    }
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.request_quote_outlined,
              color: cs.onSurfaceVariant.withValues(alpha: 0.55),
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              _searchController.text.trim().isEmpty
                  ? _emptyFilterMessage()
                  : (_isSpanish
                      ? 'No hay resultados para esta búsqueda.'
                      : 'No budgets match this search.'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final document = documents[index];
        final isDraft = _isDraft(document);
        final kind = PresupuestoKind.fromJson(document);
        final number = _displayNumber(document, isSpanish: _isSpanish);
        final client = _clientName(document);
        final meta = <String>[
          if (number.isNotEmpty) number,
          if (client.isNotEmpty) client,
          if (_formattedDate(document).isNotEmpty) _formattedDate(document),
        ].join(' · ');
        return Material(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _select(document),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: cs.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _title(document),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _PresupuestoBadge(
                              label: kind == PresupuestoKind.document
                                  ? (_isSpanish ? 'Documento' : 'Document')
                                  : (_isSpanish ? 'Partidas' : 'Itemized'),
                              foreground: cs.primary,
                              background: cs.primaryContainer,
                            ),
                            const SizedBox(width: 5),
                            _PresupuestoBadge(
                              label: isDraft
                                  ? (_isSpanish ? 'Borrador' : 'Draft')
                                  : (_isSpanish ? 'Emitido' : 'Issued'),
                              foreground: isDraft
                                  ? cs.onTertiaryContainer
                                  : Colors.green.shade800,
                              background: isDraft
                                  ? cs.tertiaryContainer
                                  : Colors.green.shade100,
                            ),
                          ],
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.send_rounded,
                    color: isDraft ? cs.tertiary : cs.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _emptyFilterMessage() {
    if (_statusFilter == PresupuestoStatusFilter.draft) {
      return _isSpanish ? 'No hay borradores.' : 'There are no drafts.';
    }
    if (_statusFilter == PresupuestoStatusFilter.issued) {
      return _isSpanish
          ? 'No hay presupuestos emitidos.'
          : 'There are no issued budgets.';
    }
    if (_kindFilter == _PresupuestoKindFilter.structured) {
      return _isSpanish
          ? 'No hay presupuestos por partidas.'
          : 'There are no itemized budgets.';
    }
    if (_kindFilter == _PresupuestoKindFilter.document) {
      return _isSpanish ? 'No hay propuestas.' : 'There are no proposals.';
    }
    return _isSpanish ? 'No hay presupuestos.' : 'There are no budgets.';
  }
}

class _PresupuestoBadge extends StatelessWidget {
  const _PresupuestoBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

String _id(Map<String, dynamic> document) =>
    (document['presupuestoId'] ?? document['_id'] ?? document['id'] ?? '')
        .toString()
        .trim();

String _title(Map<String, dynamic> document) {
  final proposalTemplate = document['proposalTemplate'];
  for (final value in <Object?>[
    document['documentTitle'],
    document['title'],
    document['name'],
    if (proposalTemplate is Map) proposalTemplate['title'],
  ]) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return 'Presupuesto';
}

String _number(Map<String, dynamic> document) =>
    (document['presupuestoNumber'] ??
            document['budgetNumber'] ??
            document['number'] ??
            '')
        .toString()
        .trim();

String _status(Map<String, dynamic> document) =>
    (document['status'] ?? '').toString().trim().toLowerCase();

bool _isDraft(Map<String, dynamic> document) => _status(document) == 'draft';

bool _isIssued(Map<String, dynamic> document) => _status(document) == 'issued';

String _displayNumber(
  Map<String, dynamic> document, {
  required bool isSpanish,
}) {
  final number = _number(document);
  if (number.isNotEmpty) return number;
  if (_isDraft(document)) return isSpanish ? 'BORRADOR' : 'DRAFT';
  return '';
}

String _clientName(Map<String, dynamic> document) {
  final snapshot = document['clientSnapshot'];
  for (final value in <Object?>[
    document['clientName'],
    document['customerName'],
    if (snapshot is Map) snapshot['billingName'],
    if (snapshot is Map) snapshot['legalName'],
    if (snapshot is Map) snapshot['name'],
  ]) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '';
}

DateTime _sortDate(Map<String, dynamic> document) {
  final values = <Object?>[
    document['issueDate'],
    if (_isDraft(document)) document['createdAt'],
    document['issuedAt'],
    if (!_isDraft(document)) document['createdAt'],
    document['updatedAt'],
  ];
  for (final value in values) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _formattedDate(Map<String, dynamic> document) {
  final date = _sortDate(document);
  if (date.millisecondsSinceEpoch == 0) return '';
  return DateFormat('dd/MM/yyyy').format(date.toLocal());
}
