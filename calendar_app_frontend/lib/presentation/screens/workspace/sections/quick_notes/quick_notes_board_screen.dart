import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/quick_notes/quick_notes_api.dart';

class QuickNotesBoardScreen extends StatefulWidget {
  const QuickNotesBoardScreen({super.key, required this.group});

  final Group group;

  @override
  State<QuickNotesBoardScreen> createState() => _QuickNotesBoardScreenState();
}

class _QuickNotesBoardScreenState extends State<QuickNotesBoardScreen> {
  final _api = QuickNotesApi();
  List<Map<String, dynamic>> _notes = const [];
  Map<String, int?> _limits = const {
    'todo': null,
    'in_progress': null,
    'done': null,
  };
  bool _loading = true;
  String? _error;

  bool get _isEs =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('es');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.board(widget.group.id);
      final rawNotes = data['notes'] as List? ?? const [];
      final rawLimits = data['columnLimits'] as Map? ?? const {};
      if (!mounted) return;
      setState(() {
        _notes = rawNotes
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _limits = {
          for (final key in const ['todo', 'in_progress', 'done'])
            key: int.tryParse(rawLimits[key]?.toString() ?? ''),
        };
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _loading = false; _error = error.toString(); });
    }
  }

  Future<void> _move(Map<String, dynamic> note, String status) async {
    if (note['status'] == status) return;
    final oldStatus = note['status'];
    String? reason;
    if (status == 'done' || oldStatus == 'done') {
      reason = await _requestReason(
        status == 'done'
            ? (_isEs
                ? '¿Por qué se completa esta nota?'
                : 'Why is this note being completed?')
            : (_isEs
                ? '¿Por qué se vuelve a abrir esta nota?'
                : 'Why is this note being reopened?'),
      );
      if (reason == null) return;
    }
    setState(() => note['status'] = status);
    try {
      final response = await _api.update(
        widget.group.id,
        note['id'].toString(),
        {
          'status': status,
          if (reason != null) 'reason': reason,
        },
      );
      final saved = response['note'];
      if (saved is Map && mounted) {
        final index = _notes.indexWhere((item) => item['id'] == note['id']);
        if (index >= 0) {
          setState(() => _notes[index] = Map<String, dynamic>.from(saved));
        }
      }
      final warning = response['warning'] as Map?;
      if (warning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEs
              ? 'La columna ha superado su límite de ${warning['limit']} tarjetas.'
              : 'This column is over its ${warning['limit']} card limit.'),
        ));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => note['status'] = oldStatus);
      _showError(error);
    }
  }

  Future<String?> _requestReason(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: _isEs ? 'Motivo' : 'Reason',
            hintText: _isEs
                ? 'Explica brevemente el cambio'
                : 'Briefly explain the change',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isEs ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: Text(_isEs ? 'Continuar' : 'Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _create() async {
    final title = TextEditingController();
    final details = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEs ? 'Nueva nota rápida' : 'New quick note'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: InputDecoration(labelText: _isEs ? 'Título' : 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: details,
                minLines: 2,
                maxLines: 5,
                decoration:
                    InputDecoration(labelText: _isEs ? 'Detalles' : 'Details'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isEs ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty) return;
              Navigator.pop(context, {
                'title': title.text.trim(),
                'details': details.text.trim(),
              });
            },
            child: Text(_isEs ? 'Crear' : 'Create'),
          ),
        ],
      ),
    );
    title.dispose();
    details.dispose();
    if (result == null) return;
    try {
      final response = await _api.create(widget.group.id, result);
      final note = response['note'];
      if (note is Map && mounted) {
        setState(() => _notes = [
              Map<String, dynamic>.from(note),
              ..._notes,
            ]);
      }
      final warning = response['warning'] as Map?;
      if (warning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEs
              ? 'Nota creada. La columna supera el límite configurado.'
              : 'Note created. The column is over its configured limit.'),
        ));
      }
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _editLimits() async {
    final controllers = {
      for (final key in const ['todo', 'in_progress', 'done'])
        key: TextEditingController(text: _limits[key]?.toString() ?? ''),
    };
    final labels = {
      'todo': _isEs ? 'Por hacer' : 'To Do',
      'in_progress': _isEs ? 'En progreso' : 'In Progress',
      'done': _isEs ? 'Hecho' : 'Done',
    };
    final result = await showDialog<Map<String, int?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEs ? 'Límites de columnas' : 'Column limits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isEs
                ? 'Déjalo vacío para no usar límite. El límite muestra un aviso, pero no bloquea tarjetas.'
                : 'Leave blank for no limit. Limits show a warning and never block cards.'),
            const SizedBox(height: 12),
            for (final key in controllers.keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: controllers[key],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: labels[key]),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isEs ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              for (final entry in controllers.entries)
                entry.key: int.tryParse(entry.value.text.trim()),
            }),
            child: Text(_isEs ? 'Guardar' : 'Save'),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (result == null) return;
    try {
      await _api.updateLimits(widget.group.id, result);
      if (mounted) setState(() => _limits = result);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEs ? 'Notas rápidas' : 'Quick notes'),
        actions: [
          IconButton(
            tooltip: _isEs ? 'Límites de columnas' : 'Column limits',
            onPressed: _editLimits,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: Text(_isEs ? 'Nueva nota' : 'New note'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(_error!),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 1050
                        ? (constraints.maxWidth - 64) / 3
                        : 330.0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _column('todo', _isEs ? 'Por hacer' : 'To Do',
                              Colors.blue, width, cs),
                          const SizedBox(width: 16),
                          _column('in_progress',
                              _isEs ? 'En progreso' : 'In Progress',
                              Colors.amber.shade700, width, cs),
                          const SizedBox(width: 16),
                          _column('done', _isEs ? 'Hecho' : 'Done',
                              Colors.green, width, cs),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _column(
    String status,
    String label,
    Color color,
    double width,
    ColorScheme cs,
  ) {
    final notes = _notes.where((note) => note['status'] == status).toList();
    final limit = _limits[status];
    final over = limit != null && notes.length >= limit;
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => _move(details.data, status),
      builder: (context, candidates, rejected) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        constraints: const BoxConstraints(minHeight: 260),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? color.withValues(alpha: .14)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: over ? cs.error : color.withValues(alpha: .3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w800))),
                Text(limit == null ? '${notes.length}' : '${notes.length}/$limit',
                    style: TextStyle(
                      color: over ? cs.error : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
            if (over)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _isEs ? 'Límite alcanzado' : 'Column limit reached',
                  style: TextStyle(color: cs.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 10),
            for (final note in notes) ...[
              LongPressDraggable<Map<String, dynamic>>(
                data: note,
                feedback: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(width: width - 24, child: _card(note, color)),
                ),
                childWhenDragging: Opacity(opacity: .35, child: _card(note, color)),
                child: _card(note, color),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> note, Color color) {
    final client = note['client'] as Map?;
    final assignees = note['assignees'] as List? ?? const [];
    final due = DateTime.tryParse(note['dueDate']?.toString() ?? '')?.toLocal();
    final createdAt =
        DateTime.tryParse(note['createdAt']?.toString() ?? '')?.toLocal();
    final updatedAt =
        DateTime.tryParse(note['updatedAt']?.toString() ?? '')?.toLocal();
    final createdBy = note['createdByUser'] as Map?;
    final updatedBy = note['updatedByUser'] as Map?;
    final createdByName = _safeUserName(createdBy?['name']);
    final updatedByName = _safeUserName(updatedBy?['name']);
    final history = note['changeHistory'] as List? ?? const [];
    final latestHistory =
        history.isNotEmpty && history.last is Map ? history.last as Map : null;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showHistory(note),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note['title']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (status) => _move(note, status),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'todo',
                        child: Text(_isEs ? 'Por hacer' : 'To Do'),
                      ),
                      PopupMenuItem(
                        value: 'in_progress',
                        child: Text(_isEs ? 'En progreso' : 'In Progress'),
                      ),
                      PopupMenuItem(
                        value: 'done',
                        child: Text(_isEs ? 'Hecho' : 'Done'),
                      ),
                    ],
                  ),
                ],
              ),
              if ((note['details']?.toString().trim() ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    note['details'].toString(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (client != null)
                _meta(Icons.business_outlined, client['name']?.toString() ?? ''),
              if (assignees.isNotEmpty)
                _meta(
                  Icons.group_outlined,
                  assignees
                      .map((item) =>
                          item is Map ? item['name']?.toString() : null)
                      .whereType<String>()
                      .join(', '),
                ),
              if (due != null)
                _meta(
                  Icons.event_outlined,
                  MaterialLocalizations.of(context).formatMediumDate(due),
                ),
              if (createdAt != null)
                _meta(
                  Icons.person_add_alt_1_outlined,
                  '${_isEs ? 'Creada' : 'Created'} ${_formatDateTime(createdAt)}'
                  '${createdByName.isEmpty ? '' : ' · $createdByName'}',
                ),
              if (updatedAt != null &&
                  createdAt != null &&
                  updatedAt.difference(createdAt).inSeconds.abs() > 1)
                _meta(
                  Icons.edit_outlined,
                  '${_isEs ? 'Modificada' : 'Modified'} ${_formatDateTime(updatedAt)}'
                  '${updatedByName.isEmpty ? '' : ' · $updatedByName'}',
                ),
              if ((latestHistory?['reason']?.toString().trim() ?? '').isNotEmpty)
                _meta(
                  Icons.comment_outlined,
                  latestHistory!['reason'].toString(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(value)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
  }

  String _safeUserName(dynamic value) {
    final name = value?.toString().trim() ?? '';
    if (RegExp(r'^[0-9a-f]{24}$', caseSensitive: false).hasMatch(name)) {
      return '';
    }
    return name;
  }

  Future<void> _showHistory(Map<String, dynamic> note) async {
    final history = note['changeHistory'] as List? ?? const [];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEs ? 'Historial de la nota' : 'Note history'),
        content: SizedBox(
          width: 520,
          child: history.isEmpty
              ? Text(_isEs
                  ? 'Esta nota todavía no tiene modificaciones.'
                  : 'This note has not been modified yet.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final entry = history[history.length - 1 - index] as Map;
                    final user = entry['user'] as Map?;
                    final userName = _safeUserName(user?['name']);
                    final changedAt = DateTime.tryParse(
                      entry['changedAt']?.toString() ?? '',
                    )?.toLocal();
                    final changes = entry['changes'] as List? ?? const [];
                    final fields = changes
                        .whereType<Map>()
                        .map((change) => change['field']?.toString() ?? '')
                        .where((field) => field.isNotEmpty)
                        .join(', ');
                    final reason = entry['reason']?.toString().trim() ?? '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history_rounded),
                      title: Text(
                        userName.isEmpty
                            ? (_isEs ? 'Usuario' : 'User')
                            : userName,
                      ),
                      subtitle: Text([
                        if (changedAt != null) _formatDateTime(changedAt),
                        if (fields.isNotEmpty)
                          '${_isEs ? 'Cambios' : 'Changes'}: $fields',
                        if (reason.isNotEmpty)
                          '${_isEs ? 'Motivo' : 'Reason'}: $reason',
                      ].join('\n')),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_isEs ? 'Cerrar' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(children: [
      Icon(icon, size: 15),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
    ]),
  );
}
