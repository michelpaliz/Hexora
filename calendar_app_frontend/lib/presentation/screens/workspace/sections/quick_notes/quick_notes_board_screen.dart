import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/widgets/hexora_popup_menu.dart';
import 'package:hexora/services/quick_notes/quick_notes_api.dart';
import 'package:hexora/services/shared/backend_api_exception.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:provider/provider.dart';

class QuickNotesBoardScreen extends StatefulWidget {
  const QuickNotesBoardScreen({
    super.key,
    required this.group,
    this.embedded = false,
  });

  final Group group;
  final bool embedded;

  @override
  State<QuickNotesBoardScreen> createState() => _QuickNotesBoardScreenState();
}

class _QuickNotesBoardScreenState extends State<QuickNotesBoardScreen> {
  static const _statuses = ['todo', 'in_progress', 'done'];
  final _api = QuickNotesApi();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _notes = const [];
  Map<String, String> _auditNames = const {};
  Map<String, int?> _limits = const {
    'todo': null,
    'in_progress': null,
    'done': null,
  };
  bool _loading = true;
  String? _error;

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  String _statusLabel(String status) => switch (status) {
        'todo' => _isEs ? 'Por hacer' : 'To Do',
        'in_progress' => _isEs ? 'En progreso' : 'In Progress',
        'done' => _isEs ? 'Hecho' : 'Done',
        _ => status,
      };

  String _emptyLabel(String status) => switch (status) {
        'todo' => _isEs ? 'No hay notas pendientes.' : 'No pending notes.',
        'in_progress' =>
          _isEs ? 'No hay notas en progreso.' : 'No notes in progress.',
        'done' => _isEs ? 'No hay notas completadas.' : 'No completed notes.',
        _ => '',
      };

  Color _statusColor(String status, ColorScheme cs) => switch (status) {
        'todo' => cs.primary,
        'in_progress' => Colors.amber.shade700,
        'done' => Colors.green.shade600,
        _ => cs.outline,
      };

  String _noteId(Map<String, dynamic> note) =>
      (note['id'] ?? note['_id'] ?? '').toString();

  String _auditUser(Map<String, dynamic> note, String userKey) {
    final prefix = userKey.startsWith('created') ? 'created' : 'updated';
    final user = note[userKey];
    final legacyUser = note['${prefix}By'];
    final candidates = <Object?>[
      if (user is Map) ...[
        user['name'],
        user['displayName'],
        user['fullName'],
      ],
      if (legacyUser is Map) ...[
        legacyUser['name'],
        legacyUser['displayName'],
        legacyUser['fullName'],
      ],
      if (legacyUser is String) legacyUser,
      note['${prefix}ByName'],
      note['${prefix}ByUserName'],
      note['${prefix}ByUsername'],
    ];
    for (final candidate in candidates) {
      final name = _validAuditName(candidate);
      if (name != null) return name;
    }
    final actorId = note['${prefix}By'] ?? note['${prefix}ById'];
    final resolved = _resolveAuditName(actorId);
    if (resolved != null) return resolved;
    if (prefix == 'updated') {
      final history = _historyEntries(note);
      if (history.isNotEmpty) {
        final historyName = _historyUserNameOrNull(
          history.first,
          history.first['user'] as Map?,
        );
        if (historyName != null) return historyName;
      }
    }
    return _auditFallback;
  }

  String get _auditFallback => _isEs ? 'Usuario' : 'User';

  String? _validAuditName(Object? value) {
    final name = value?.toString().trim() ?? '';
    final normalized = name.toLowerCase();
    if (name.isEmpty ||
        RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(name) ||
        normalized == 'usuario' ||
        normalized == 'user') {
      return null;
    }
    return name;
  }

  String? _resolveAuditName(Object? actorId) {
    final id = actorId is Map
        ? (actorId['id'] ?? actorId['_id'])?.toString().trim() ?? ''
        : actorId?.toString().trim() ?? '';
    if (id.isEmpty) return null;
    final cached = _validAuditName(_auditNames[id]);
    if (cached != null) return cached;
    try {
      final current = context.read<UserDomain>().user;
      if (current != null && current.id == id) {
        return _validAuditName(current.displayName) ??
            _validAuditName(current.name);
      }
    } catch (_) {}
    try {
      final members = context.read<GroupDomain>().usersInGroup.value;
      for (final member in members) {
        if (member.id == id) {
          return _validAuditName(member.displayName) ??
              _validAuditName(member.name);
        }
      }
    } catch (_) {}
    return null;
  }

  String _auditTimestamp(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '${MaterialLocalizations.of(context).formatMediumDate(date)} · $time';
  }

  String _historyFieldLabel(String field) => switch (field) {
        'status' => _isEs ? 'Estado' : 'Status',
        'title' => _isEs ? 'Título' : 'Title',
        'details' => _isEs ? 'Detalles' : 'Details',
        'dueDate' => _isEs ? 'Fecha límite' : 'Due date',
        'clientId' => _isEs ? 'Cliente' : 'Client',
        'assigneeIds' => _isEs ? 'Asignados' : 'Assignees',
        _ => field,
      };

  String _historyValue(String field, Object? value) {
    final raw = value?.toString() ?? '—';
    if (field == 'status' && _statuses.contains(raw)) return _statusLabel(raw);
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      UserDomain? userDomain;
      try {
        userDomain = context.read<UserDomain>();
      } catch (_) {}
      final data = await _api.board(widget.group.id);
      try {
        if (userDomain != null) {
          final users = await userDomain.getUsersForGroup(widget.group);
          _auditNames = {
            for (final user in users)
              user.id: _validAuditName(user.displayName) ??
                  _validAuditName(user.name) ??
                  _auditFallback,
          };
        }
      } catch (_) {}
      final rawNotes = data['notes'] as List? ?? const [];
      final rawLimits = data['columnLimits'] as Map? ?? const {};
      if (!mounted) return;
      setState(() {
        _notes = rawNotes
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _limits = {
          for (final key in _statuses)
            key: int.tryParse(rawLimits[key]?.toString() ?? ''),
        };
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _errorMessage(error);
      });
    }
  }

  Future<void> _move(Map<String, dynamic> note, String status) async {
    if (note['status'] == status) return;
    String? reason;
    if (_requiresStatusReason(note, status)) {
      reason = await _askReason(
        title: status == 'done'
            ? (_isEs
                ? '¿Por qué se completa esta nota?'
                : 'Why is this note being completed?')
            : (_isEs
                ? '¿Por qué se vuelve a abrir esta nota?'
                : 'Why is this note being reopened?'),
        message: _isEs
            ? 'Añade un motivo para registrar este cambio.'
            : 'Add a reason to record this change.',
      );
      if (reason == null || reason.trim().isEmpty) return;
    }
    final oldStatus = note['status'];
    setState(() => note['status'] = status);
    try {
      // Send the same core fields used by the edit flow. Some API versions
      // validate the complete note document when changing its status rather
      // than accepting a status-only patch.
      final payload = <String, dynamic>{
        'title': note['title']?.toString().trim() ?? '',
        'details': note['details']?.toString().trim() ?? '',
        'status': status,
        if (reason != null) 'reason': reason,
      };
      final response = await _api.update(
        widget.group.id,
        _noteId(note),
        payload,
      );
      final updated = response['note'];
      if (updated is Map) {
        setState(() {
          note
            ..clear()
            ..addAll(Map<String, dynamic>.from(updated));
        });
      }
      _showLimitWarning(response['warning'] as Map?);
    } catch (error) {
      if (!mounted) return;
      setState(() => note['status'] = oldStatus);
      _showError(error);
    }
  }

  void _showLimitWarning(Map? warning, {bool created = false}) {
    if (warning == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEs
              ? created
                  ? 'Nota creada. La columna supera el límite configurado.'
                  : 'La columna ha superado su límite de ${warning['limit']} tarjetas.'
              : created
                  ? 'Note created. The column is over its configured limit.'
                  : 'This column is over its ${warning['limit']} card limit.',
        ),
      ),
    );
  }

  void _showError(Object error) {
    final message = _errorMessage(error);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error) {
    if (error is BackendApiException &&
        const {502, 503, 504}.contains(error.statusCode)) {
      return _isEs
          ? 'Las notas no están disponibles temporalmente. Inténtalo de nuevo.'
          : 'Notes are temporarily unavailable. Please try again.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  bool _requiresStatusReason(Map<String, dynamic> note, String nextStatus) =>
      nextStatus == 'done' || note['status'] == 'done';

  bool _requiresPayloadReason(
    Map<String, dynamic> note,
    Map<String, dynamic> payload,
  ) {
    if (payload.containsKey('clientId') || payload.containsKey('assigneeIds')) {
      return true;
    }
    return false;
  }

  Future<String?> _askReason({
    required String title,
    required String message,
  }) async {
    var reason = '';
    String? error;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message),
              const SizedBox(height: 12),
              TextFormField(
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                onChanged: (value) {
                  reason = value;
                  if (error != null && value.trim().isNotEmpty) {
                    setDialogState(() => error = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: _isEs ? 'Motivo *' : 'Reason *',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_isEs ? 'Cancelar' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (reason.trim().isEmpty) {
                  setDialogState(() {
                    error = _isEs
                        ? 'Escribe un motivo para continuar.'
                        : 'Enter a reason to continue.';
                  });
                  return;
                }
                Navigator.pop(dialogContext, reason.trim());
              },
              child: Text(_isEs ? 'Continuar' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create({String initialStatus = 'todo'}) async {
    final payload = await _showNoteDialog(initialStatus: initialStatus);
    if (payload == null) return;
    try {
      final response = await _api.create(widget.group.id, payload);
      final note = response['note'];
      if (note is Map && mounted) {
        setState(() => _notes = [Map<String, dynamic>.from(note), ..._notes]);
      }
      _showLimitWarning(response['warning'] as Map?, created: true);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _edit(Map<String, dynamic> note) async {
    final payload = await _showNoteDialog(note: note);
    if (payload == null) return;
    final statusReason = payload['status'] != note['status'] &&
        _requiresStatusReason(note, payload['status'].toString());
    if (statusReason || _requiresPayloadReason(note, payload)) {
      final reason = await _askReason(
        title: statusReason && payload['status'] == 'done'
            ? (_isEs
                ? '¿Por qué se completa esta nota?'
                : 'Why is this note being completed?')
            : statusReason
                ? (_isEs
                    ? '¿Por qué se vuelve a abrir esta nota?'
                    : 'Why is this note being reopened?')
                : (_isEs
                    ? '¿Por qué se modifica esta nota?'
                    : 'Why is this note being changed?'),
        message: _isEs
            ? 'Añade un motivo para registrar este cambio.'
            : 'Add a reason to record this change.',
      );
      if (reason == null || reason.trim().isEmpty) return;
      payload['reason'] = reason.trim();
    }
    try {
      final response =
          await _api.update(widget.group.id, _noteId(note), payload);
      if (!mounted) return;
      final updated = response['note'];
      setState(() {
        if (updated is Map) {
          note
            ..clear()
            ..addAll(Map<String, dynamic>.from(updated));
        } else {
          note.addAll(payload);
        }
      });
      _showLimitWarning(response['warning'] as Map?);
      await _preview(note);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _preview(Map<String, dynamic> note) async {
    await _showNoteDialog(note: note, startInEdit: false);
  }

  Future<Map<String, dynamic>?> _showNoteDialog({
    Map<String, dynamic>? note,
    String initialStatus = 'todo',
    bool startInEdit = true,
  }) async {
    var title = note?['title']?.toString() ?? '';
    var details = note?['details']?.toString() ?? '';
    var status = note?['status']?.toString() ?? initialStatus;
    var editing = note == null || startInEdit;
    String? titleError;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final cs = Theme.of(context).colorScheme;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.note_alt_outlined,
                              size: 19, color: cs.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              !editing
                                  ? (_isEs
                                      ? 'Detalle de la nota'
                                      : 'Note details')
                                  : note == null
                                      ? (_isEs
                                          ? 'Nueva nota rápida'
                                          : 'New quick note')
                                      : (_isEs ? 'Editar nota' : 'Edit note'),
                              style: const TextStyle(
                                fontFamily: HexoraTypography.fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: _isEs ? 'Cerrar' : 'Close',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded, size: 19),
                          ),
                        ],
                      ),
                      if (editing)
                        ..._editNoteFields(
                          dialogContext: dialogContext,
                          note: note,
                          title: title,
                          details: details,
                          status: status,
                          titleError: titleError,
                          setDialogState: setDialogState,
                          onTitleChanged: (value) {
                            title = value;
                            if (titleError != null && value.trim().isNotEmpty) {
                              setDialogState(() => titleError = null);
                            }
                          },
                          onDetailsChanged: (value) => details = value,
                          onStatusChanged: (value) =>
                              setDialogState(() => status = value),
                          onValidateAndSave: () {
                            if (title.trim().isEmpty) {
                              setDialogState(() {
                                titleError = _isEs
                                    ? 'Escribe un título para continuar.'
                                    : 'Enter a title to continue.';
                              });
                              return;
                            }
                            Navigator.pop(dialogContext, <String, dynamic>{
                              'title': title.trim(),
                              'details': details.trim(),
                              'status': status,
                            });
                          },
                        )
                      else
                        ..._previewNoteFields(
                          dialogContext: dialogContext,
                          note: note!,
                          status: status,
                          setDialogState: setDialogState,
                          onStatusChanged: (value) => status = value,
                          onEdit: () => setDialogState(() => editing = true),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    return result;
  }

  List<Widget> _editNoteFields({
    required BuildContext dialogContext,
    required Map<String, dynamic>? note,
    required String title,
    required String details,
    required String status,
    required String? titleError,
    required StateSetter setDialogState,
    required ValueChanged<String> onTitleChanged,
    required ValueChanged<String> onDetailsChanged,
    required ValueChanged<String> onStatusChanged,
    required VoidCallback onValidateAndSave,
  }) {
    return [
      const SizedBox(height: 16),
      TextFormField(
        initialValue: title,
        autofocus: true,
        textInputAction: TextInputAction.next,
        onChanged: onTitleChanged,
        decoration: InputDecoration(
          labelText: _isEs ? 'Título *' : 'Title *',
          hintText: _isEs ? '¿Qué necesitas hacer?' : 'What do you need to do?',
          errorText: titleError,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
      ),
      const SizedBox(height: 14),
      TextFormField(
        initialValue: details,
        onChanged: onDetailsChanged,
        minLines: 3,
        maxLines: 7,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          labelText: _isEs ? 'Detalles' : 'Details',
          hintText: _isEs
              ? 'Añade información adicional (opcional)…'
              : 'Add optional details…',
          alignLabelWithHint: true,
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        ),
      ),
      const SizedBox(height: 16),
      _statusLabelWidget(),
      const SizedBox(height: 6),
      _statusSelector(status, onStatusChanged),
      const SizedBox(height: 18),
      Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          HexoraButton(
            onPressed: () => Navigator.pop(dialogContext),
            label: _isEs ? 'Cancelar' : 'Cancel',
            variant: HexoraButtonVariant.secondary,
          ),
          const SizedBox(width: 8),
          HexoraButton(
            onPressed: onValidateAndSave,
            icon: note == null ? Icons.add_rounded : Icons.check_rounded,
            label: note == null
                ? (_isEs ? 'Crear nota' : 'Create note')
                : (_isEs ? 'Guardar' : 'Save'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _previewNoteFields({
    required BuildContext dialogContext,
    required Map<String, dynamic> note,
    required String status,
    required StateSetter setDialogState,
    required ValueChanged<String> onStatusChanged,
    required VoidCallback onEdit,
  }) {
    final cs = Theme.of(context).colorScheme;
    final details = note['details']?.toString().trim() ?? '';
    final client = note['client'] as Map?;
    final assignees = note['assignees'] as List? ?? const [];
    final due = DateTime.tryParse(note['dueDate']?.toString() ?? '')?.toLocal();
    final createdAt = _auditTimestamp(note['createdAt']);
    final updatedAt = _auditTimestamp(note['updatedAt']);
    final createdBy = _auditUser(note, 'createdByUser');
    final updatedBy = _auditUser(note, 'updatedByUser');
    final history = _historyEntries(note);
    return [
      const SizedBox(height: 12),
      Text(
        note['title']?.toString() ?? '',
        style: const TextStyle(
          fontFamily: HexoraTypography.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
      if (details.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          details,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: HexoraTypography.body,
            height: 1.5,
          ),
        ),
      ],
      if (client != null)
        _previewMeta(Icons.business_outlined, client['name']?.toString() ?? ''),
      if (assignees.isNotEmpty)
        _previewMeta(
          Icons.group_outlined,
          assignees
              .map((item) => item is Map ? item['name']?.toString() : null)
              .whereType<String>()
              .join(', '),
        ),
      if (due != null)
        _previewMeta(
          Icons.event_outlined,
          MaterialLocalizations.of(context).formatMediumDate(due),
        ),
      if (createdAt.isNotEmpty)
        _previewMeta(
          Icons.person_outline_rounded,
          '${_isEs ? 'Creada' : 'Created'} · $createdAt${createdBy.isEmpty ? '' : ' · $createdBy'}',
        ),
      if (updatedAt.isNotEmpty)
        _previewMeta(
          Icons.update_rounded,
          '${_isEs ? 'Modificada' : 'Updated'} · $updatedAt${updatedBy.isEmpty ? '' : ' · $updatedBy'}',
        ),
      if (history.isNotEmpty) ...[
        const SizedBox(height: 18),
        Text(
          _isEs ? 'Historial de cambios' : 'Change history',
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: HexoraTypography.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in history) _historyEntry(entry),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          Text(
            _isEs ? 'Estado' : 'Status',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: HexoraTypography.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          _statusChip(status),
        ],
      ),
      const SizedBox(height: 18),
      Divider(height: 1, color: cs.outlineVariant),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (status != 'done')
            HexoraButton(
              onPressed: () async {
                await _move(note, 'done');
                if (mounted && note['status'] == 'done') {
                  onStatusChanged('done');
                  setDialogState(() {});
                }
              },
              icon: Icons.check_rounded,
              label: _isEs ? 'Marcar como hecho' : 'Mark as done',
              variant: HexoraButtonVariant.secondary,
              size: HexoraButtonSize.compact,
            ),
          if (status != 'done') const SizedBox(width: 8),
          HexoraButton(
            onPressed: onEdit,
            icon: Icons.edit_outlined,
            label: _isEs ? 'Editar' : 'Edit',
            size: HexoraButtonSize.compact,
          ),
        ],
      ),
    ];
  }

  List<Map<String, dynamic>> _historyEntries(Map<String, dynamic> note) {
    final entries = (note['changeHistory'] as List? ?? const [])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    entries.sort((a, b) {
      final aDate = DateTime.tryParse(a['changedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['changedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return entries;
  }

  Widget _historyEntry(Map<String, dynamic> entry) {
    final cs = Theme.of(context).colorScheme;
    final user = entry['user'] as Map?;
    final userName = _historyUserName(entry, user);
    final changes = (entry['changes'] as List? ?? const [])
        .whereType<Map>()
        .map((change) => Map<String, dynamic>.from(change))
        .toList();
    final reason = entry['reason']?.toString().trim() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 15, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(
                    fontSize: HexoraTypography.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _auditTimestamp(entry['changedAt']),
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: HexoraTypography.caption,
                ),
              ),
            ],
          ),
          for (final change in changes)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '${_historyFieldLabel(change['field']?.toString() ?? '')}: ${_historyValue(change['field']?.toString() ?? '', change['fromValue'])} → ${_historyValue(change['field']?.toString() ?? '', change['toValue'])}',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: HexoraTypography.caption,
                ),
              ),
            ),
          if (reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${_isEs ? 'Motivo' : 'Reason'}: $reason',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: HexoraTypography.caption,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _historyUserName(Map<String, dynamic> entry, Map? user) {
    return _historyUserNameOrNull(entry, user) ?? _auditFallback;
  }

  String? _historyUserNameOrNull(Map<String, dynamic> entry, Map? user) {
    final candidates = <Object?>[
      user?['name'],
      user?['displayName'],
      user?['fullName'],
      entry['userName'],
      entry['username'],
      entry['actorName'],
    ];
    for (final candidate in candidates) {
      final name = _validAuditName(candidate);
      if (name != null) return name;
    }
    for (final actor in <Object?>[
      entry['userId'],
      entry['actorId'],
      entry['changedBy'],
      entry['changedByUser'],
    ]) {
      final resolved = _resolveAuditName(actor);
      if (resolved != null) return resolved;
    }
    return null;
  }

  Widget _statusLabelWidget() {
    final cs = Theme.of(context).colorScheme;
    return Text(
      _isEs ? 'Estado' : 'Status',
      style: TextStyle(
        color: cs.onSurfaceVariant,
        fontSize: HexoraTypography.label,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _statusChip(String status) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontSize: HexoraTypography.label,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _previewMeta(IconData icon, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: HexoraTypography.label,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusSelector(String selected, ValueChanged<String> onChanged) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final value in _statuses)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == value
                        ? cs.primaryContainer
                        : Colors.transparent,
                  ),
                  child: Text(
                    _statusLabel(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected == value
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                      fontSize: HexoraTypography.label,
                      fontWeight:
                          selected == value ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> note) async {
    final reason = await _askReason(
      title: _isEs ? 'Eliminar nota' : 'Delete note',
      message: _isEs
          ? 'Indica por qué eliminas “${note['title'] ?? ''}”.'
          : 'Tell us why you are deleting “${note['title'] ?? ''}”.',
    );
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await _api.delete(
        widget.group.id,
        _noteId(note),
        reason: reason.trim(),
      );
      if (mounted) setState(() => _notes.remove(note));
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _editLimits() async {
    final values = {
      for (final key in _statuses) key: _limits[key]?.toString() ?? '',
    };
    final result = await showDialog<Map<String, int?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEs ? 'Límites de columnas' : 'Column limits'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isEs
                  ? 'Déjalo vacío para no usar límite. Los límites avisan, pero no bloquean tarjetas.'
                  : 'Leave blank for no limit. Limits warn but never block cards.'),
              const SizedBox(height: 12),
              for (final key in values.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    initialValue: values[key],
                    onChanged: (value) => values[key] = value,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: _statusLabel(key)),
                  ),
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
            onPressed: () => Navigator.pop(context, {
              for (final entry in values.entries)
                entry.key: int.tryParse(entry.value.trim()),
            }),
            child: Text(_isEs ? 'Guardar' : 'Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await _api.updateLimits(widget.group.id, result);
      if (mounted) setState(() => _limits = result);
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  List<Map<String, dynamic>> _notesFor(String status) {
    final query = _searchController.text.trim().toLowerCase();
    return _notes.where((note) {
      if (note['status'] != status) return false;
      if (query.isEmpty) return true;
      final client = note['client'] as Map?;
      final assignees = note['assignees'] as List? ?? const [];
      final searchable = [
        note['title'],
        note['details'],
        client?['name'],
        ...assignees.map((item) => item is Map ? item['name'] : null),
      ].whereType<Object>().join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: isMobile
          ? FloatingActionButton.small(
              onPressed: _create,
              tooltip: _isEs ? 'Nueva nota' : 'New note',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: SafeArea(
        top: !widget.embedded,
        child: Column(
          children: [
            _toolbar(isMobile),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _toolbar(bool isMobile) {
    final cs = Theme.of(context).colorScheme;
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.embedded) ...[
          HexoraButton.iconOnly(
            onPressed: () => Navigator.maybePop(context),
            icon: Icons.arrow_back_rounded,
            tooltip: _isEs ? 'Volver' : 'Back',
          ),
          const SizedBox(width: 6),
        ],
        Icon(Icons.view_kanban_outlined, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          _isEs ? 'Notas rápidas' : 'Quick notes',
          style: const TextStyle(
            fontFamily: HexoraTypography.fontFamily,
            fontSize: HexoraTypography.pageTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HexoraButton.iconOnly(
          onPressed: _editLimits,
          icon: Icons.tune_rounded,
          tooltip: _isEs ? 'Límites de columnas' : 'Column limits',
        ),
        const SizedBox(width: 4),
        HexoraButton.iconOnly(
          onPressed: _load,
          icon: Icons.refresh_rounded,
          tooltip: _isEs ? 'Actualizar' : 'Refresh',
        ),
        if (!isMobile) ...[
          const SizedBox(width: 8),
          HexoraButton(
            onPressed: _create,
            icon: Icons.add_rounded,
            label: _isEs ? 'Nueva nota' : 'New note',
          ),
        ],
      ],
    );
    final search = SizedBox(
      height: 34,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: HexoraTypography.body),
        decoration: InputDecoration(
          hintText: _isEs ? 'Buscar notas…' : 'Search notes…',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: _isEs ? 'Limpiar búsqueda' : 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          filled: true,
          fillColor: cs.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(HexoraDimensions.radius),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(HexoraDimensions.radius),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, isMobile ? 10 : 8),
      child: isMobile
          ? Column(
              children: [
                Row(children: [Expanded(child: title), actions]),
                const SizedBox(height: 8),
                search,
              ],
            )
          : Row(
              children: [
                title,
                const SizedBox(width: 24),
                Expanded(
                  child: Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: search,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                actions,
              ],
            ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 32),
              const SizedBox(height: 10),
              Text(_error!.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              HexoraButton(
                onPressed: _load,
                icon: Icons.refresh_rounded,
                label: _isEs ? 'Reintentar' : 'Try again',
              ),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        if (constraints.maxWidth >= 900) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < _statuses.length; index++) ...[
                  if (index > 0) const SizedBox(width: gap),
                  Expanded(child: _column(_statuses[index])),
                ],
              ],
            ),
          );
        }
        final columnWidth = constraints.maxWidth < 600
            ? (constraints.maxWidth * .86).clamp(280.0, 340.0)
            : 320.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: constraints.maxHeight - 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < _statuses.length; index++) ...[
                  if (index > 0) const SizedBox(width: 12),
                  SizedBox(
                    width: columnWidth,
                    child: _column(_statuses[index]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _column(String status) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(status, cs);
    final notes = _notesFor(status);
    final totalCount = _notes.where((note) => note['status'] == status).length;
    final limit = _limits[status];
    final over = limit != null && totalCount >= limit;
    final searching = _searchController.text.trim().isNotEmpty;
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => details.data['status'] != status,
      onAcceptWithDetails: (details) => _move(details.data, status),
      builder: (context, candidates, rejected) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? color.withValues(alpha: .10)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: candidates.isNotEmpty
              ? Border.all(color: color.withValues(alpha: .55), width: 1.5)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _statusLabel(status),
                        style: const TextStyle(
                          fontFamily: HexoraTypography.fontFamily,
                          fontSize: HexoraTypography.sectionTitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: over
                            ? cs.errorContainer
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        limit == null ? '$totalCount' : '$totalCount/$limit',
                        style: TextStyle(
                          fontSize: HexoraTypography.caption,
                          fontWeight: FontWeight.w700,
                          color:
                              over ? cs.onErrorContainer : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: HexoraPopupMenuButton<String>(
                        tooltip:
                            _isEs ? 'Acciones de columna' : 'Column actions',
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        onSelected: (value) {
                          if (value == 'add') _create(initialStatus: status);
                          if (value == 'limits') _editLimits();
                        },
                        itemBuilder: (_) => [
                          HexoraPopupMenuActionItem(
                            value: 'add',
                            icon: Icons.add_rounded,
                            label: _isEs ? 'Añadir nota' : 'Add note',
                            tone: HexoraPopupMenuTone.primary,
                          ),
                          HexoraPopupMenuActionItem(
                            value: 'limits',
                            icon: Icons.tune_rounded,
                            label: _isEs ? 'Editar límites' : 'Edit limits',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (over)
              Container(
                width: double.infinity,
                color: cs.errorContainer.withValues(alpha: .55),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Text(
                  _isEs ? 'Límite alcanzado' : 'Column limit reached',
                  style: TextStyle(
                    color: cs.onErrorContainer,
                    fontSize: HexoraTypography.caption,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Expanded(
              child: notes.isEmpty
                  ? _emptyState(status, searching)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                      itemCount: notes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return _draggableCard(note);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _draggableCard(Map<String, dynamic> note) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    return LayoutBuilder(
      builder: (context, constraints) {
        final feedback = Material(
          color: Colors.transparent,
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: constraints.maxWidth,
            child: _card(note, dragging: true),
          ),
        );
        final placeholder = Opacity(
          opacity: .28,
          child: _card(note),
        );
        final card = MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: _card(note),
        );

        if (desktop) {
          return Draggable<Map<String, dynamic>>(
            data: note,
            rootOverlay: true,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: feedback,
            childWhenDragging: placeholder,
            child: card,
          );
        }

        return LongPressDraggable<Map<String, dynamic>>(
          data: note,
          delay: const Duration(milliseconds: 260),
          rootOverlay: true,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: feedback,
          childWhenDragging: placeholder,
          child: card,
        );
      },
    );
  }

  Widget _emptyState(String status, bool searching) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off_rounded : Icons.note_alt_outlined,
              size: 24,
              color: cs.onSurfaceVariant.withValues(alpha: .65),
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? (_isEs ? 'No hay resultados.' : 'No matching notes.')
                  : _emptyLabel(status),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: HexoraTypography.body,
              ),
            ),
            if (!searching) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _create(initialStatus: status),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(_isEs ? 'Añadir nota' : 'Add note'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> note, {bool dragging = false}) {
    final cs = Theme.of(context).colorScheme;
    final client = note['client'] as Map?;
    final assignees = note['assignees'] as List? ?? const [];
    final due = DateTime.tryParse(note['dueDate']?.toString() ?? '')?.toLocal();
    final details = note['details']?.toString().trim() ?? '';
    final createdAt = _auditTimestamp(note['createdAt']);
    final updatedAt = _auditTimestamp(note['updatedAt']);
    final createdBy = _auditUser(note, 'createdByUser');
    final updatedBy = _auditUser(note, 'updatedByUser');
    final history = _historyEntries(note);
    final latestReason = history
        .map((entry) => entry['reason']?.toString().trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: .55)),
      ),
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: dragging ? null : () => _preview(note),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10, dragging ? 12 : 40, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note['title']?.toString() ?? '',
                    style: const TextStyle(
                      fontFamily: HexoraTypography.fontFamily,
                      fontSize: HexoraTypography.body,
                      fontWeight: FontWeight.w600,
                      height: 1.28,
                    ),
                  ),
                  if (details.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        details,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: HexoraTypography.label,
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (client != null)
                    _meta(Icons.business_outlined,
                        client['name']?.toString() ?? ''),
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
                  if (createdAt.isNotEmpty)
                    _meta(
                      Icons.person_outline_rounded,
                      '${_isEs ? 'Creada' : 'Created'} · $createdAt${createdBy.isEmpty ? '' : ' · $createdBy'}',
                    ),
                  if (updatedAt.isNotEmpty)
                    _meta(
                      Icons.update_rounded,
                      '${_isEs ? 'Modificada' : 'Updated'} · $updatedAt${updatedBy.isEmpty ? '' : ' · $updatedBy'}',
                    ),
                  if (latestReason.isNotEmpty)
                    _meta(
                      Icons.info_outline_rounded,
                      '${_isEs ? 'Motivo' : 'Reason'} · $latestReason',
                    ),
                ],
              ),
            ),
          ),
          if (!dragging)
            Positioned(
              top: 2,
              right: 2,
              child: SizedBox(
                width: 32,
                height: 32,
                child: _cardMenu(note),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardMenu(Map<String, dynamic> note) {
    final cs = Theme.of(context).colorScheme;
    return HexoraPopupMenuButton<String>(
      tooltip: _isEs ? 'Acciones de nota' : 'Note actions',
      icon: Icon(
        Icons.more_vert_rounded,
        size: 16,
        color: cs.onSurfaceVariant.withValues(alpha: .7),
      ),
      onSelected: (value) {
        if (_statuses.contains(value)) _move(note, value);
        if (value == 'edit') _edit(note);
        if (value == 'delete') _delete(note);
      },
      itemBuilder: (_) => [
        HexoraPopupMenuActionItem(
          value: 'edit',
          icon: Icons.edit_outlined,
          label: _isEs ? 'Editar' : 'Edit',
        ),
        for (final status in _statuses)
          if (note['status'] != status)
            HexoraPopupMenuActionItem(
              value: status,
              icon: status == 'done'
                  ? Icons.check_circle_outline_rounded
                  : Icons.arrow_forward_rounded,
              label: '${_isEs ? 'Mover a' : 'Move to'} ${_statusLabel(status)}',
            ),
        const HexoraPopupMenuDivider(),
        HexoraPopupMenuActionItem(
          value: 'delete',
          icon: Icons.delete_outline_rounded,
          label: _isEs ? 'Eliminar' : 'Delete',
          tone: HexoraPopupMenuTone.destructive,
        ),
      ],
    );
  }

  Widget _meta(IconData icon, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: HexoraTypography.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
