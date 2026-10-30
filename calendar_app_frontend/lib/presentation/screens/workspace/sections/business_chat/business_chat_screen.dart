import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/services/business_chat/business_chat_api.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/shared/backend_api_exception.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:url_launcher/url_launcher.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:hexora/theme/colors/app_colors.dart';

class BusinessChatScreen extends StatefulWidget {
  const BusinessChatScreen(
      {super.key, required this.groupId, required this.currentUserId});
  final String groupId;
  final String? currentUserId;

  @override
  State<BusinessChatScreen> createState() => _BusinessChatScreenState();
}

class _BusinessChatScreenState extends State<BusinessChatScreen> {
  final _api = BusinessChatApi();
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  List<BusinessChatConversation> _conversations = const [];
  List<BusinessChatMessage> _messages = const [];
  BusinessChatConversation? _selected;
  Timer? _timer;
  Timer? _socketDebounce;
  io.Socket? _socket;
  bool _loading = false;
  bool _refreshQueued = false;
  bool _sending = false;
  bool _liveConnected = false;
  bool _canCreateTeam = false;
  bool _canCreateIssues = true;
  bool _canManageIssues = false;
  bool _canAssignIssues = false;
  bool _canModerateMessages = false;
  bool _showChatOnNarrow = false;
  String? _error;
  bool get _es => Localizations.localeOf(context).languageCode == 'es';

  @override
  void initState() {
    super.initState();
    _refresh();
    _connectSocket();
    _timer = Timer.periodic(
        const Duration(seconds: 60), (_) => _refresh(silent: true));
  }

  Future<void> _connectSocket() async {
    final token = await TokenService.loadToken();
    if (!mounted || token == null || token.isEmpty) return;
    final socket = io.io(ApiConstants.socketBaseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
      'auth': {'token': token},
    });
    _socket = socket;
    socket.onConnect((_) {
      if (mounted) setState(() => _liveConnected = true);
    });
    socket.onDisconnect((_) {
      if (mounted) setState(() => _liveConnected = false);
    });
    socket.onConnectError((_) {
      if (mounted) setState(() => _liveConnected = false);
    });
    socket.on('business-chat:changed', (data) {
      if (!mounted ||
          data is! Map ||
          data['groupId']?.toString() != widget.groupId) return;
      _socketDebounce?.cancel();
      _socketDebounce = Timer(
          const Duration(milliseconds: 250), () => _refresh(silent: true));
    });
    socket.on('business-chat:revoked', (data) {
      if (!mounted ||
          data is! Map ||
          data['groupId']?.toString() != widget.groupId) return;
      _revokeVisibleAccess();
    });
    socket.connect();
  }

  @override
  void didUpdateWidget(covariant BusinessChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _conversations = const [];
      _selected = null;
      _messages = const [];
      _composer.clear();
      _showChatOnNarrow = false;
      _error = null;
      _canCreateTeam = false;
      _canCreateIssues = false;
      _canManageIssues = false;
      _canAssignIssues = false;
      _canModerateMessages = false;
      _refresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socketDebounce?.cancel();
    _socket?.dispose();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _revokeVisibleAccess() {
    if (!mounted) return;
    setState(() {
      _conversations = const [];
      _messages = const [];
      _selected = null;
      _showChatOnNarrow = false;
      _canCreateTeam = false;
      _canCreateIssues = false;
      _canManageIssues = false;
      _canAssignIssues = false;
      _canModerateMessages = false;
      _error = _es
          ? 'Ya no tienes acceso al chat de este negocio.'
          : 'You no longer have access to this business chat.';
    });
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_loading) {
      _refreshQueued = true;
      return;
    }
    final requestedGroupId = widget.groupId;
    setState(() {
      _loading = true;
      if (!silent) _error = null;
    });
    try {
      final data = await _api.conversations(requestedGroupId);
      if (!mounted || requestedGroupId != widget.groupId) return;
      final next =
          List<BusinessChatConversation>.from(data['conversations'] as List);
      final oldId = _selected?.id;
      setState(() {
        _error = null;
        _conversations = next;
        _selected = next.where((item) => item.id == oldId).firstOrNull ??
            next.where((item) => item.type == 'general').firstOrNull ??
            (next.isEmpty ? null : next.first);
        if (_selected?.id != oldId) _messages = const [];
        if (_selected == null) _showChatOnNarrow = false;
        _canCreateTeam =
            (data['capabilities'] as Map?)?['canCreateTeam'] == true;
        _canCreateIssues =
            (data['capabilities'] as Map?)?['canCreateIssues'] == true;
        _canManageIssues =
            (data['capabilities'] as Map?)?['canManageIssues'] == true;
        _canAssignIssues =
            (data['capabilities'] as Map?)?['canAssignIssues'] == true;
        _canModerateMessages =
            (data['capabilities'] as Map?)?['canModerateMessages'] == true;
      });
      if (_selected != null) {
        await _loadMessages(_selected!, forceScroll: oldId != _selected!.id);
      }
    } catch (error) {
      if (requestedGroupId != widget.groupId) {
        return;
      } else if (error is BackendApiException && error.statusCode == 403) {
        _revokeVisibleAccess();
      } else if (mounted && !silent) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (requestedGroupId != widget.groupId || _refreshQueued) {
          final groupChanged = requestedGroupId != widget.groupId;
          _refreshQueued = false;
          Future<void>.microtask(() => _refresh(silent: !groupChanged));
        }
      }
    }
  }

  Future<void> _loadMessages(BusinessChatConversation conversation,
      {bool forceScroll = false}) async {
    try {
      final nearLatest =
          !_scroll.hasClients || _scroll.position.extentAfter < 120;
      final messages = await _api.messages(widget.groupId, conversation.id);
      if (!mounted || _selected?.id != conversation.id) return;
      setState(() => _messages = messages);
      if (forceScroll || nearLatest) _scrollToEnd();
      await _api.markRead(widget.groupId, conversation.id);
      if (mounted && _selected?.id == conversation.id) {
        final readConversation = conversation.copyWith(unreadCount: 0);
        setState(() {
          _selected = readConversation;
          _conversations = _conversations
              .map((item) =>
                  item.id == conversation.id ? readConversation : item)
              .toList();
        });
      }
    } catch (error) {
      if (error is BackendApiException &&
          (error.statusCode == 403 || error.statusCode == 404)) {
        if (mounted) {
          setState(() => _messages = const []);
          Future<void>.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _refresh(silent: true);
          });
        }
      } else if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _send() async {
    final conversation = _selected;
    final body = _composer.text.trim();
    if (_sending || body.isEmpty || conversation == null) return;
    setState(() => _sending = true);
    try {
      await _api.send(widget.groupId, conversation.id, body);
      if (!mounted) return;
      _composer.clear();
      await _loadMessages(conversation);
      _scrollToEnd();
      _refresh(silent: true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _attach() async {
    final conversation = _selected;
    if (_sending || conversation == null) return;
    final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: true);
    if (picked == null || picked.files.isEmpty || !mounted) return;
    final file = picked.files.single;
    if (file.size > 10 * 1024 * 1024) {
      _showError(_es
          ? 'El archivo debe ser menor de 10 MB.'
          : 'File must be under 10 MB.');
      return;
    }
    setState(() => _sending = true);
    try {
      await _api.sendAttachment(
          widget.groupId, conversation.id, file, _composer.text.trim());
      if (!mounted) return;
      _composer.clear();
      await _loadMessages(conversation);
      _scrollToEnd();
      _refresh(silent: true);
    } catch (error) {
      if (mounted) {
        _showError(error is BackendApiException && error.statusCode == 400
            ? (_es
                ? 'No se pudo adjuntar. Usa una imagen JPG, PNG, WebP o un PDF válido de hasta 10 MB.'
                : 'Could not attach this file. Use a valid JPG, PNG, WebP, or PDF up to 10 MB.')
            : error);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openAttachment(BusinessChatMessage message) async {
    try {
      final url = await _api.attachmentUrl(widget.groupId, message);
      if (!await launchUrl(url, mode: LaunchMode.platformDefault))
        throw StateError('Could not open attachment');
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients)
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut);
      });

  Future<void> _createIssue() async {
    try {
      final values = await _issueDialog();
      if (values == null) return;
      final created = await _api.createIssue(
          widget.groupId, values.$1, values.$2,
          workerId: values.$3, clientId: values.$4, eventId: values.$5);
      await _refresh();
      final id = (created['conversation'] as Map)['id'].toString();
      if (mounted)
        setState(() =>
            _selected = _conversations.where((c) => c.id == id).firstOrNull);
      if (_selected != null) await _loadMessages(_selected!);
    } catch (error) {
      _showError(error);
    }
  }

  Future<(String, String, String?, String?, String?)?> _issueDialog() async {
    final workers = _canAssignIssues
        ? await _api.workers(widget.groupId)
        : const <Map<String, dynamic>>[];
    final links = await _api.issueLinks(widget.groupId);
    final clients = (links['clients'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((c) => Map<String, dynamic>.from(c))
        .toList();
    final events = (links['events'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (!mounted) return null;
    final title = TextEditingController();
    final description = TextEditingController();
    var workerId = '';
    var clientId = '';
    var eventId = '';
    return showDialog<(String, String, String?, String?, String?)>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, refreshDialog) => AlertDialog(
                  title: Text(_es ? 'Nueva incidencia' : 'New incident'),
                  content: SizedBox(
                      width: 440,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(
                            controller: title,
                            maxLength: 160,
                            decoration: InputDecoration(
                                labelText: _es ? 'Título' : 'Title',
                                border: const OutlineInputBorder())),
                        const SizedBox(height: 12),
                        TextField(
                            controller: description,
                            maxLength: 4000,
                            maxLines: 4,
                            decoration: InputDecoration(
                                labelText: _es ? 'Descripción' : 'Description',
                                border: const OutlineInputBorder())),
                        if (clients.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                              initialValue: clientId,
                              decoration: InputDecoration(
                                  labelText: _es
                                      ? 'Cliente (opcional)'
                                      : 'Client (optional)',
                                  border: const OutlineInputBorder()),
                              items: [
                                DropdownMenuItem(
                                    value: '',
                                    child: Text(
                                        _es ? 'Sin cliente' : 'No client')),
                                ...clients.map((client) => DropdownMenuItem(
                                    value: client['id'].toString(),
                                    child: Text(client['name'].toString(),
                                        overflow: TextOverflow.ellipsis)))
                              ],
                              onChanged: (value) => refreshDialog(() {
                                    clientId = value ?? '';
                                    eventId = '';
                                  })),
                        ],
                        if (events.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                              key: ValueKey(clientId),
                              initialValue: eventId,
                              decoration: InputDecoration(
                                  labelText: _es
                                      ? 'Evento (opcional)'
                                      : 'Event (optional)',
                                  border: const OutlineInputBorder()),
                              items: [
                                DropdownMenuItem(
                                    value: '',
                                    child:
                                        Text(_es ? 'Sin evento' : 'No event')),
                                ...events
                                    .where((event) =>
                                        clientId.isEmpty ||
                                        event['clientId']?.toString() ==
                                            clientId)
                                    .map((event) => DropdownMenuItem(
                                        value: event['id'].toString(),
                                        child: Text(event['title'].toString(),
                                            overflow: TextOverflow.ellipsis)))
                              ],
                              onChanged: (value) =>
                                  refreshDialog(() => eventId = value ?? '')),
                        ],
                        if (_canAssignIssues && workers.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                              initialValue: workerId,
                              decoration: InputDecoration(
                                  labelText: _es
                                      ? 'Asignar a (opcional)'
                                      : 'Assign to (optional)',
                                  border: const OutlineInputBorder()),
                              items: [
                                DropdownMenuItem<String>(
                                    value: '',
                                    child: Text(
                                        _es ? 'Sin asignar' : 'Unassigned')),
                                ...workers.map((worker) => DropdownMenuItem<
                                        String>(
                                    value: worker['id'].toString(),
                                    child: Text(
                                        '${worker['name']} · ${worker['role']}')))
                              ],
                              onChanged: (value) {
                                if (value != null)
                                  refreshDialog(() => workerId = value);
                              }),
                        ],
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(_es ? 'Cancelar' : 'Cancel')),
                    FilledButton(
                        onPressed: () {
                          final value = title.text.trim();
                          if (value.isNotEmpty)
                            Navigator.pop(context, (
                              value,
                              description.text.trim(),
                              workerId.isEmpty ? null : workerId,
                              clientId.isEmpty ? null : clientId,
                              eventId.isEmpty ? null : eventId
                            ));
                        },
                        child: Text(_es ? 'Crear' : 'Create'))
                  ],
                ))).then((value) {
      title.dispose();
      description.dispose();
      return value;
    });
  }

  Future<void> _assignIssue(BusinessChatConversation conversation) async {
    final issueId = conversation.issue?['id']?.toString();
    if (issueId == null) return;
    try {
      final workers = await _api.workers(widget.groupId);
      if (!mounted) return;
      if (workers.isEmpty) {
        _showError(_es
            ? 'No hay trabajadores activos con una cuenta Hexora.'
            : 'No active workers with a Hexora account are available.');
        return;
      }
      final workerId = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
                title: Text(_es ? 'Asignar incidencia' : 'Assign incident'),
                children: workers
                    .map((worker) => SimpleDialogOption(
                        onPressed: () =>
                            Navigator.pop(context, worker['id'].toString()),
                        child: Text('${worker['name']} · ${worker['role']}')))
                    .toList(),
              ));
      if (workerId == null) return;
      await _api.assignIssue(widget.groupId, issueId, workerId);
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createTeam() async {
    try {
      final members = await _api.members(widget.groupId);
      if (!mounted) return;
      final seen = <String>{};
      final unique = members.where((m) {
        final id = (m['id'] ?? '').toString();
        if (id.isEmpty || id == widget.currentUserId || !seen.add(id))
          return false;
        return true;
      }).toList();

      final titleCtrl = TextEditingController();
      final searchCtrl = TextEditingController();
      final selected = <String>{};
      final formKey = GlobalKey<FormState>();

      final result = await showDialog<(String, List<String>)>(
          context: context,
          builder: (dialogContext) {
            final viewportH = MediaQuery.of(dialogContext).size.height;
            return StatefulBuilder(
                builder: (dialogContext, refreshDialog) {
              final query = searchCtrl.text.toLowerCase();
              final filtered = unique.where((m) {
                final name =
                    (m['name'] ?? m['userName'] ?? '').toString().toLowerCase();
                return query.isEmpty || name.contains(query);
              }).toList();
              final canCreate = titleCtrl.text.trim().isNotEmpty &&
                  selected.isNotEmpty;

              return AlertDialog(
                title: Text(_es ? 'Nuevo chat de equipo' : 'New team chat'),
                content: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: 480,
                        maxHeight: viewportH * 0.7),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Form(
                              key: formKey,
                              child: TextFormField(
                                  controller: titleCtrl,
                                  maxLength: 120,
                                  onChanged: (_) => refreshDialog(() {}),
                                  validator: (v) =>
                                      (v ?? '').trim().isEmpty
                                          ? (_es
                                              ? 'Escribe un nombre'
                                              : 'Enter a name')
                                          : null,
                                  decoration: InputDecoration(
                                      labelText: _es
                                          ? 'Nombre del chat'
                                          : 'Chat name',
                                      counterText: '',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))))),
                          const SizedBox(height: 12),
                          TextField(
                              controller: searchCtrl,
                              onChanged: (_) => refreshDialog(() {}),
                              decoration: InputDecoration(
                                  prefixIcon:
                                      const Icon(Icons.search, size: 20),
                                  hintText: _es
                                      ? 'Buscar participantes…'
                                      : 'Search participants…',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)))),
                          const SizedBox(height: 8),
                          Text(
                              _es
                                  ? '${selected.length + 1}/50 participantes (incluyéndote)'
                                  : '${selected.length + 1}/50 participants (including you)',
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .bodySmall),
                          const SizedBox(height: 8),
                          Flexible(
                              child: filtered.isEmpty
                                  ? Center(
                                      child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Text(
                                              _es
                                                  ? 'Sin resultados'
                                                  : 'No results',
                                              style: Theme.of(dialogContext)
                                                  .textTheme
                                                  .bodySmall)))
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final member = filtered[index];
                                        final id = (member['id'] ?? '')
                                            .toString();
                                        final name = (member['name'] ??
                                                member['userName'] ??
                                                id)
                                            .toString();
                                        final role = (member['role'] ?? '')
                                            .toString();
                                        return CheckboxListTile(
                                            value: selected.contains(id),
                                            title: Text(name,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            subtitle: role.isNotEmpty
                                                ? Text(role,
                                                    style: const TextStyle(
                                                        fontSize: 12))
                                                : null,
                                            dense: true,
                                            onChanged:
                                                !selected.contains(id) &&
                                                        selected.length >= 49
                                                    ? null
                                                    : (value) =>
                                                        refreshDialog(() {
                                                          value == true
                                                              ? selected
                                                                  .add(id)
                                                              : selected
                                                                  .remove(id);
                                                        }));
                                      })),
                        ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(_es ? 'Cancelar' : 'Cancel')),
                  HexoraButton(
                      label: _es ? 'Crear' : 'Create',
                      size: HexoraButtonSize.compact,
                      onPressed: !canCreate
                          ? null
                          : () {
                              if (formKey.currentState?.validate() ?? false) {
                                Navigator.pop(dialogContext,
                                    (titleCtrl.text.trim(), selected.toList()));
                              }
                            }),
                ],
              );
            });
          });

      titleCtrl.dispose();
      searchCtrl.dispose();
      if (result == null) return;
      await _api.createTeam(widget.groupId, result.$1, result.$2);
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _manageTeam(BusinessChatConversation conversation) async {
    try {
      final members = await _api.members(widget.groupId);
      if (!mounted) return;
      final byId = {
        for (final member in members) (member['id'] ?? '').toString(): member
      };
      await showDialog<void>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
              builder: (dialogContext, refreshDialog) => AlertDialog(
                    title: Text(_es
                        ? 'Participantes de ${conversation.title}'
                        : '${conversation.title} participants'),
                    content: SizedBox(
                        width: 440,
                        height: 360,
                        child: Column(children: [
                          Text(_es
                              ? '${conversation.participantIds.length}/50 participantes'
                              : '${conversation.participantIds.length}/50 participants'),
                          const SizedBox(height: 8),
                          Expanded(
                              child: ListView(children: [
                            for (final id in conversation.participantIds)
                              ListTile(
                                title: Text((byId[id]?['name'] ??
                                        byId[id]?['userName'] ??
                                        id)
                                    .toString()),
                                trailing: IconButton(
                                    icon: const Icon(
                                        Icons.person_remove_outlined),
                                    tooltip: _es ? 'Quitar' : 'Remove',
                                    onPressed: () async {
                                      try {
                                        await _api.removeParticipant(
                                            widget.groupId,
                                            conversation.id,
                                            id);
                                        conversation.participantIds.remove(id);
                                        refreshDialog(() {});
                                        await _refresh(silent: true);
                                      } catch (error) {
                                        if (mounted) _showError(error);
                                      }
                                    }),
                              ),
                          ])),
                        ])),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            final value = await _textDialog(
                                _es ? 'Renombrar equipo' : 'Rename team',
                                initialValue: conversation.title,
                                maxLength: 120,
                                actionLabel: _es ? 'Guardar' : 'Save');
                            if (value == null) return;
                            try {
                              await _api.renameTeam(
                                  widget.groupId, conversation.id, value.$1);
                              if (dialogContext.mounted)
                                Navigator.pop(dialogContext);
                              await _refresh();
                            } catch (error) {
                              if (mounted) _showError(error);
                            }
                          },
                          child: Text(_es ? 'Renombrar' : 'Rename')),
                      if (_canCreateTeam)
                        TextButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                  context: dialogContext,
                                  builder: (context) => AlertDialog(
                                          title: Text(_es
                                              ? '¿Eliminar chat de equipo?'
                                              : 'Delete team chat?'),
                                          content: Text(_es
                                              ? 'Se archivará para todos los participantes.'
                                              : 'It will be archived for all participants.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: Text(_es
                                                    ? 'Cancelar'
                                                    : 'Cancel')),
                                            TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: Text(_es
                                                    ? 'Eliminar'
                                                    : 'Delete'))
                                          ]));
                              if (confirmed != true) return;
                              try {
                                await _api.archiveTeam(
                                    widget.groupId, conversation.id);
                                if (dialogContext.mounted)
                                  Navigator.pop(dialogContext);
                                await _refresh();
                              } catch (error) {
                                if (mounted) _showError(error);
                              }
                            },
                            child: Text(_es ? 'Eliminar chat' : 'Delete chat')),
                      TextButton(
                          onPressed: conversation.participantIds.length >= 50
                              ? null
                              : () async {
                                  final available = members
                                      .where((member) =>
                                          !conversation.participantIds.contains(
                                              (member['id'] ?? '').toString()))
                                      .toList();
                                  final selected = <String>{};
                                  final remaining =
                                      50 - conversation.participantIds.length;
                                  final chosen = await showDialog<List<String>>(
                                      context: dialogContext,
                                      builder: (context) => StatefulBuilder(
                                          builder: (context, update) =>
                                              AlertDialog(
                                                title: Text(_es
                                                    ? 'Añadir participantes'
                                                    : 'Add participants'),
                                                content: SizedBox(
                                                    width: 400,
                                                    height: 320,
                                                    child: Column(children: [
                                                      Text(_es
                                                          ? '${selected.length}/$remaining plazas seleccionadas'
                                                          : '${selected.length}/$remaining places selected'),
                                                      const SizedBox(height: 8),
                                                      Expanded(
                                                          child: ListView(
                                                              children:
                                                                  available.map(
                                                                      (member) {
                                                        final id =
                                                            (member['id'] ?? '')
                                                                .toString();
                                                        return CheckboxListTile(
                                                            value: selected
                                                                .contains(id),
                                                            title: Text((member[
                                                                        'name'] ??
                                                                    member[
                                                                        'userName'] ??
                                                                    id)
                                                                .toString()),
                                                            onChanged: !selected
                                                                        .contains(
                                                                            id) &&
                                                                    selected.length >=
                                                                        remaining
                                                                ? null
                                                                : (value) =>
                                                                    update(() {
                                                                      if (value ==
                                                                          true) {
                                                                        selected
                                                                            .add(id);
                                                                      } else {
                                                                        selected
                                                                            .remove(id);
                                                                      }
                                                                    }));
                                                      }).toList())),
                                                    ])),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: Text(_es
                                                          ? 'Cancelar'
                                                          : 'Cancel')),
                                                  FilledButton(
                                                      onPressed: selected
                                                              .isEmpty
                                                          ? null
                                                          : () => Navigator.pop(
                                                              context,
                                                              selected
                                                                  .toList()),
                                                      child: Text(_es
                                                          ? 'Añadir'
                                                          : 'Add'))
                                                ],
                                              )));
                                  if (chosen == null || chosen.isEmpty) return;
                                  try {
                                    await _api.addParticipants(widget.groupId,
                                        conversation.id, chosen);
                                    conversation.participantIds.addAll(chosen);
                                    refreshDialog(() {});
                                    await _refresh(silent: true);
                                  } catch (error) {
                                    if (mounted) _showError(error);
                                  }
                                },
                          child: Text(_es ? 'Añadir' : 'Add')),
                      FilledButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(_es ? 'Cerrar' : 'Close')),
                    ],
                  )));
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<(String, String)?> _textDialog(String title,
      {bool withDescription = false,
      String initialValue = '',
      int maxLength = 160,
      int maxLines = 1,
      String? fieldLabel,
      String? actionLabel}) async {
    final name = TextEditingController(text: initialValue);
    final description = TextEditingController();
    return showDialog<(String, String)>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: name,
                    maxLength: maxLength,
                    maxLines: maxLines,
                    decoration: InputDecoration(
                        labelText: fieldLabel ??
                            (maxLines > 1
                                ? (_es ? 'Nota' : 'Note')
                                : (_es ? 'Título' : 'Title')),
                        border: const OutlineInputBorder())),
                if (withDescription) ...[
                  const SizedBox(height: 12),
                  TextField(
                      controller: description,
                      maxLength: 4000,
                      maxLines: 4,
                      decoration: InputDecoration(
                          labelText: _es ? 'Descripción' : 'Description',
                          border: const OutlineInputBorder()))
                ],
              ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_es ? 'Cancelar' : 'Cancel')),
                FilledButton(
                    onPressed: () {
                      final value = name.text.trim();
                      if (value.isNotEmpty)
                        Navigator.pop(
                            context, (value, description.text.trim()));
                    },
                    child: Text(actionLabel ?? (_es ? 'Crear' : 'Create')))
              ],
            )).then((value) {
      name.dispose();
      description.dispose();
      return value;
    });
  }

  Future<void> _messageAction(
      BusinessChatMessage message, String action) async {
    try {
      if (action == 'delete') {
        await _api.delete(widget.groupId, message);
      } else {
        final value = await _textDialog(_es ? 'Editar mensaje' : 'Edit message',
            initialValue: message.body,
            maxLength: 2000,
            maxLines: 4,
            fieldLabel: _es ? 'Mensaje' : 'Message',
            actionLabel: _es ? 'Guardar' : 'Save');
        if (value == null) return;
        await _api.edit(widget.groupId, message, value.$1);
      }
      if (_selected != null) await _loadMessages(_selected!);
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(error.toString())));

  Future<void> _setIssueStatus(String status) async {
    final issueId = _selected?.issue?['id']?.toString();
    if (issueId == null || issueId.isEmpty) return;
    try {
      String? note;
      if (status == 'resolved' || status == 'closed') {
        final existing = (_selected?.issue?['resolutionNote'] ?? '').toString();
        final result = await _textDialog(
            _es ? 'Nota de resolución' : 'Resolution note',
            initialValue: existing,
            maxLength: 4000,
            maxLines: 4,
            actionLabel: _es ? 'Guardar' : 'Save');
        if (result == null) return;
        note = result.$1;
        if (note.isEmpty) {
          _showError(_es
              ? 'Escribe cómo se resolvió la incidencia.'
              : 'Enter how the incident was resolved.');
          return;
        }
      }
      await _api.updateIssueStatus(widget.groupId, issueId, status, note: note);
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  void _showIssueDetails(BusinessChatConversation conversation) {
    final issue = conversation.issue;
    if (issue == null) return;
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(issue['title']?.toString() ?? conversation.title),
              content: SizedBox(
                  width: 440,
                  child: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        if ((issue['description'] ?? '').toString().isNotEmpty)
                          Text(issue['description'].toString()),
                        if (issue['clientId'] != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                  '${_es ? 'Cliente' : 'Client'}: ${issue['clientName'] ?? issue['clientId']}')),
                        if (issue['eventId'] != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                  '${_es ? 'Evento' : 'Event'}: ${issue['eventTitle'] ?? issue['eventId']}')),
                        if ((issue['resolutionNote'] ?? '')
                            .toString()
                            .isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                  '${_es ? 'Resolución' : 'Resolution'}: ${issue['resolutionNote']}')),
                      ]))),
              actions: [
                FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_es ? 'Cerrar' : 'Close'))
              ],
            ));
  }

  String _typeLabel(String type) => switch (type) {
        'general' => _es ? 'General' : 'General',
        'team' => _es ? 'Equipo' : 'Team',
        'issue' => _es ? 'Incidencia' : 'Incident',
        _ => type,
      };

  String _statusLabel(String status) => switch (status) {
        'open' => _es ? 'Abierta' : 'Open',
        'in_progress' => _es ? 'En curso' : 'In progress',
        'review' => _es ? 'En revisión' : 'In review',
        'resolved' => _es ? 'Resuelta' : 'Resolved',
        'closed' => _es ? 'Cerrada' : 'Closed',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Badge(
                isLabelVisible: _conversations.fold<int>(
                        0, (sum, item) => sum + item.unreadCount) >
                    0,
                label: Text(
                    '${_conversations.fold<int>(0, (sum, item) => sum + item.unreadCount)}'),
                child: Icon(Icons.forum_outlined, color: colors.primary)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(_es ? 'Hexora Chat' : 'Hexora Chat',
                    style: Theme.of(context).textTheme.titleMedium)),
            Tooltip(
                message: _liveConnected
                    ? (_es ? 'Actualizaciones en directo' : 'Live updates')
                    : (_es
                        ? 'Sin conexión en directo; se actualiza cada minuto'
                        : 'Live connection unavailable; checks every minute'),
                child: Icon(_liveConnected ? Icons.wifi : Icons.wifi_off,
                    size: 18,
                    color: _liveConnected ? colors.primary : colors.outline)),
            const SizedBox(width: 8),
            HexoraButton.iconOnly(
                icon: Icons.refresh,
                onPressed: _loading ? null : _refresh,
                tooltip: _es ? 'Actualizar' : 'Refresh',
                size: HexoraButtonSize.compact),
            if (_canCreateIssues)
              HexoraButton.iconOnly(
                  icon: Icons.report_gmailerrorred_outlined,
                  onPressed: _createIssue,
                  tooltip: _es ? 'Nueva incidencia' : 'New incident',
                  size: HexoraButtonSize.compact),
            if (_canCreateTeam)
              HexoraButton.iconOnly(
                  icon: Icons.group_add_outlined,
                  onPressed: _createTeam,
                  tooltip: _es ? 'Nuevo chat de equipo' : 'New team chat',
                  size: HexoraButtonSize.compact),
          ])),
      const Divider(height: 1),
      Expanded(child: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 700;
        const sidebarW = 280.0;
        final chatWidth = narrow
            ? constraints.maxWidth
            : constraints.maxWidth - sidebarW - 1;
        return Row(children: [
          if (!narrow || !_showChatOnNarrow)
            SizedBox(
                width: narrow ? constraints.maxWidth : sidebarW,
                child: NavigationSurface(
                    builder: (sidebarCtx) {
                  final sc = Theme.of(sidebarCtx).colorScheme;
                  if (_conversations.isEmpty) {
                    return Center(
                        child: _loading
                            ? const CircularProgressIndicator()
                            : Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                    _error ??
                                        (_es
                                            ? 'No hay conversaciones'
                                            : 'No conversations'),
                                    textAlign: TextAlign.center)));
                  }
                  return ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = _conversations[index];
                        final selected = _selected?.id == conversation.id;
                        final status = conversation.issue?['status'];
                        final lastMessage = conversation.lastMessage;
                        final preview = lastMessage == null
                            ? (status == null
                                ? _typeLabel(conversation.type)
                                : _statusLabel(status.toString()))
                            : lastMessage.isDeleted
                                ? (_es
                                    ? 'Mensaje eliminado'
                                    : 'Message deleted')
                                : lastMessage.body.trim().isNotEmpty
                                    ? lastMessage.body
                                    : (lastMessage.attachment?['fileName'] ??
                                            (_es
                                                ? 'Archivo adjunto'
                                                : 'Attachment'))
                                        .toString();
                        final timeStamp = lastMessage != null
                            ? DateFormat('HH:mm')
                                .format(lastMessage.createdAt.toLocal())
                            : null;
                        return ListTile(
                            selected: selected,
                            selectedTileColor: AppDarkColors.surfaceHover,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: Icon(
                                conversation.type == 'issue'
                                    ? Icons.report_outlined
                                    : conversation.type == 'team'
                                        ? Icons.groups_outlined
                                        : Icons.campaign_outlined,
                                size: 20,
                                color: selected
                                    ? sc.primary
                                    : sc.onSurfaceVariant),
                            title: Text(
                                conversation.issue?['title']?.toString() ??
                                    conversation.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: sc.onSurface,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500)),
                            subtitle: Text(preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: sc.onSurfaceVariant)),
                            trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (timeStamp != null)
                                    Text(timeStamp,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: sc.onSurfaceVariant)),
                                  if (conversation.unreadCount > 0)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2),
                                        child: Badge(
                                            label: Text(
                                                '${conversation.unreadCount}'))),
                                ]),
                            onTap: () {
                              setState(() {
                                _selected = conversation;
                                _messages = const [];
                                _showChatOnNarrow = true;
                              });
                              _loadMessages(conversation, forceScroll: true);
                            });
                      });
                })),
          if (!narrow) const VerticalDivider(width: 1),
          if (!narrow || _showChatOnNarrow)
            Expanded(
                child: Column(children: [
              if (_selected != null)
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    color: colors.surfaceContainerLow,
                    child: Row(children: [
                      if (narrow)
                        HexoraButton.iconOnly(
                            icon: Icons.arrow_back,
                            tooltip: _es ? 'Conversaciones' : 'Conversations',
                            onPressed: () =>
                                setState(() => _showChatOnNarrow = false),
                            size: HexoraButtonSize.compact),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                _selected!.issue?['title']?.toString() ??
                                    _selected!.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            if (_selected!.type == 'issue')
                              Text(
                                  _selected!.issue?['assigneeName'] == null
                                      ? (_es ? 'Sin asignar' : 'Unassigned')
                                      : '${_es ? 'Asignada a' : 'Assigned to'} ${_selected!.issue!['assigneeName']}',
                                  style: Theme.of(context).textTheme.bodySmall),
                            if (_selected!.type == 'team')
                              Text(
                                  _es
                                      ? '${_selected!.participantIds.length} participantes'
                                      : '${_selected!.participantIds.length} participants',
                                  style: Theme.of(context).textTheme.bodySmall),
                            if (_selected!.issue?['clientName'] != null ||
                                _selected!.issue?['eventTitle'] != null)
                              Text(
                                  [
                                    _selected!.issue?['clientName'],
                                    _selected!.issue?['eventTitle']
                                  ].whereType<String>().join(' · '),
                                  style: Theme.of(context).textTheme.bodySmall)
                          ])),
                      if (_selected!.type == 'team' &&
                          (_canCreateTeam ||
                              (_canModerateMessages &&
                                  _selected!.participantIds
                                      .contains(widget.currentUserId))))
                        HexoraButton.iconOnly(
                            icon: Icons.manage_accounts_outlined,
                            tooltip: _es
                                ? 'Gestionar participantes'
                                : 'Manage participants',
                            onPressed: () => _manageTeam(_selected!),
                            size: HexoraButtonSize.compact),
                      if (_selected!.type == 'issue')
                        HexoraButton.iconOnly(
                            icon: Icons.info_outline,
                            tooltip: _es ? 'Ver incidencia' : 'View incident',
                            onPressed: () => _showIssueDetails(_selected!),
                            size: HexoraButtonSize.compact),
                      if (_selected!.issue?['status'] != null &&
                          _canAssignIssues)
                        HexoraButton.iconOnly(
                            icon: Icons.assignment_ind_outlined,
                            tooltip:
                                _es ? 'Cambiar responsable' : 'Change assignee',
                            onPressed: () => _assignIssue(_selected!),
                            size: HexoraButtonSize.compact),
                      if (_selected!.issue?['status'] != null)
                        Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _canManageIssues
                                ? DropdownButton<String>(
                                    value:
                                        _selected!.issue!['status'].toString(),
                                    items: [
                                      DropdownMenuItem(
                                          value: 'open',
                                          child: Text(_statusLabel('open'))),
                                      DropdownMenuItem(
                                          value: 'in_progress',
                                          child: Text(
                                              _statusLabel('in_progress'))),
                                      DropdownMenuItem(
                                          value: 'review',
                                          child: Text(_statusLabel('review'))),
                                      DropdownMenuItem(
                                          value: 'resolved',
                                          child:
                                              Text(_statusLabel('resolved'))),
                                      DropdownMenuItem(
                                          value: 'closed',
                                          child: Text(_statusLabel('closed')))
                                    ],
                                    onChanged: (value) {
                                      if (value != null) _setIssueStatus(value);
                                    })
                                : Chip(
                                    label: Text(_statusLabel(_selected!
                                        .issue!['status']
                                        .toString()))))
                    ])),
              Expanded(
                  child: _error != null && _messages.isEmpty
                      ? Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                          Padding(
                              padding: const EdgeInsets.all(16),
                              child:
                                  Text(_error!, textAlign: TextAlign.center)),
                          TextButton(
                              onPressed: _refresh,
                              child: Text(_es ? 'Reintentar' : 'Retry'))
                        ]))
                      : _selected == null
                          ? Center(
                              child: _loading
                                  ? const CircularProgressIndicator()
                                  : Text(_es
                                      ? 'Selecciona una conversación.'
                                      : 'Select a conversation.'))
                          : _messages.isEmpty
                              ? Center(
                                  child: Text(_es
                                      ? 'Todavía no hay mensajes.'
                                      : 'No messages yet.'))
                              : ListView.builder(
                                  controller: _scroll,
                                  padding: const EdgeInsets.all(14),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, index) {
                                    final message = _messages[index];
                                    final mine = message.senderId ==
                                        widget.currentUserId;
                                    final prev =
                                        index > 0 ? _messages[index - 1] : null;
                                    final showSender = prev == null ||
                                        prev.senderId != message.senderId;
                                    final canEdit = mine &&
                                        !message.isDeleted &&
                                        DateTime.now()
                                                .difference(
                                                    message.createdAt.toLocal())
                                                .inMinutes <
                                            15;
                                    final canDelete = !message.isDeleted &&
                                        (mine ||
                                            (_canModerateMessages &&
                                                (_canCreateTeam ||
                                                    _selected?.type ==
                                                        'team')));
                                    return _MessageBubble(
                                      message: message,
                                      mine: mine,
                                      showSender: showSender,
                                      canEdit: canEdit,
                                      canDelete: canDelete,
                                      maxWidth: chatWidth *
                                          (narrow ? 0.85 : 0.65),
                                      narrow: narrow,
                                      es: _es,
                                      onAction: _messageAction,
                                      onAttachment: _openAttachment,
                                    );
                                  })),
              const Divider(height: 1),
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: SafeArea(
                      top: false,
                      child: Row(children: [
                        HexoraButton.iconOnly(
                            icon: Icons.attach_file,
                            onPressed: _sending || _selected == null
                                ? null
                                : _attach,
                            tooltip: _es
                                ? 'Adjuntar foto o PDF'
                                : 'Attach photo or PDF',
                            size: HexoraButtonSize.compact),
                        const SizedBox(width: 8),
                        Expanded(
                            child: TextField(
                                controller: _composer,
                                enabled: _selected != null && !_sending,
                                maxLength: 2000,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.newline,
                                decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    hintText: _es
                                        ? 'Escribe un mensaje…'
                                        : 'Write a message…',
                                    counterText: '',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8))))),
                        const SizedBox(width: 8),
                        HexoraButton.iconOnly(
                            icon: Icons.send,
                            onPressed:
                                _sending || _selected == null ? null : _send,
                            tooltip: _es ? 'Enviar' : 'Send',
                            variant: HexoraButtonVariant.primary,
                            size: HexoraButtonSize.compact,
                            loading: _sending),
                      ]))),
            ])),
        ]);
      })),
    ]);
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.showSender,
    required this.canEdit,
    required this.canDelete,
    required this.maxWidth,
    required this.narrow,
    required this.es,
    required this.onAction,
    required this.onAttachment,
  });

  final BusinessChatMessage message;
  final bool mine;
  final bool showSender;
  final bool canEdit;
  final bool canDelete;
  final double maxWidth;
  final bool narrow;
  final bool es;
  final void Function(BusinessChatMessage, String) onAction;
  final void Function(BusinessChatMessage) onAttachment;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _hovered = false;

  void _showMobileActions() {
    showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.canEdit)
                ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(widget.es ? 'Editar' : 'Edit'),
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onAction(widget.message, 'edit');
                    }),
              if (widget.canDelete)
                ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(widget.es ? 'Eliminar' : 'Delete'),
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onAction(widget.message, 'delete');
                    }),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasActions = widget.canEdit || widget.canDelete;
    final showMenuIcon = hasActions && !widget.narrow && _hovered;
    final name = widget.message.senderName;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Padding(
      padding: EdgeInsets.only(top: widget.showSender ? 10 : 2),
      child: Row(
        mainAxisAlignment:
            widget.mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.mine) ...[
            if (widget.showSender)
              CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      colors.onSurfaceVariant.withValues(alpha: .10),
                  child: Text(initial,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant)))
            else
              const SizedBox(width: 28),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: GestureDetector(
                onLongPress:
                    hasActions && widget.narrow ? _showMobileActions : null,
                child: Card(
                  elevation: 0,
                  color: widget.mine
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!widget.mine && widget.showSender)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                        child: Text(name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                                color: colors.primary))),
                                    if (hasActions)
                                      _buildMenuIcon(showMenuIcon),
                                  ])),
                        if (widget.message.isDeleted ||
                            widget.message.body.isNotEmpty)
                          Text(
                            widget.message.isDeleted
                                ? (widget.es
                                    ? 'Mensaje eliminado'
                                    : 'Message deleted')
                                : widget.message.body,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: widget.message.isDeleted
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color: widget.message.isDeleted
                                  ? colors.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        if (!widget.message.isDeleted &&
                            widget.message.attachment != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TextButton.icon(
                              onPressed: () =>
                                  widget.onAttachment(widget.message),
                              icon: Icon(
                                  (widget.message.attachment!['mimeType'] ??
                                              '')
                                          .toString()
                                          .startsWith('image/')
                                      ? Icons.image_outlined
                                      : Icons.attach_file,
                                  size: 16),
                              label: Text(
                                (widget.message.attachment!['fileName'] ??
                                        (widget.es
                                            ? 'Adjunto'
                                            : 'Attachment'))
                                    .toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${DateFormat('HH:mm').format(widget.message.createdAt.toLocal())}${widget.message.editedAt != null ? (widget.es ? ' · Editado' : ' · Edited') : ''}',
                                style:
                                    Theme.of(context).textTheme.labelSmall,
                              ),
                              if (hasActions &&
                                  (widget.mine || !widget.showSender)) ...[
                                const SizedBox(width: 4),
                                _buildMenuIcon(showMenuIcon),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(bool visible) => AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: 24,
          height: 24,
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            iconSize: 14,
            onSelected: (value) =>
                widget.onAction(widget.message, value),
            itemBuilder: (_) => [
              if (widget.canEdit)
                PopupMenuItem(
                    value: 'edit',
                    child: Text(widget.es ? 'Editar' : 'Edit')),
              if (widget.canDelete)
                PopupMenuItem(
                    value: 'delete',
                    child: Text(widget.es ? 'Eliminar' : 'Delete')),
            ],
          ),
        ),
      );
}
