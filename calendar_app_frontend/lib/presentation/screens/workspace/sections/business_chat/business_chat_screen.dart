import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/services/business_chat/business_chat_api.dart';
import 'package:hexora/presentation/shared/widgets/avatars/hexora_user_avatar.dart';
import 'package:intl/intl.dart';

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
  final _conversationSearch = TextEditingController();
  final _scroll = ScrollController();
  List<BusinessChatConversation> _conversations = const [];
  List<BusinessChatMessage> _messages = const [];
  BusinessChatConversation? _selected;
  Timer? _timer;
  bool _loading = false;
  bool _sending = false;
  bool _canCreateTeam = false;
  bool _canCreateIssues = true;
  bool _canManageIssues = false;
  bool _canAssignIssues = false;
  bool _canModerateMessages = false;
  String? _error;
  bool _nearLatest = true;
  int _unseenMessages = 0;
  bool get _es => Localizations.localeOf(context).languageCode == 'es';

  @override
  void initState() {
    super.initState();
    _refresh();
    _composer.addListener(() => mounted ? setState(() {}) : null);
    _conversationSearch.addListener(() => mounted ? setState(() {}) : null);
    _scroll.addListener(_updateScrollPosition);
    _timer = Timer.periodic(
        const Duration(seconds: 8), (_) => _refresh(silent: true));
  }

  @override
  void didUpdateWidget(covariant BusinessChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _selected = null;
      _messages = const [];
      _refresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _composer.dispose();
    _conversationSearch.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _updateScrollPosition() {
    if (!_scroll.hasClients) return;
    final nearLatest = _scroll.position.maxScrollExtent - _scroll.offset < 96;
    if (nearLatest != _nearLatest || (nearLatest && _unseenMessages > 0)) {
      setState(() {
        _nearLatest = nearLatest;
        if (nearLatest) _unseenMessages = 0;
      });
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (!silent) _error = null;
    });
    try {
      final data = await _api.conversations(widget.groupId);
      if (!mounted) return;
      final next =
          List<BusinessChatConversation>.from(data['conversations'] as List);
      final oldId = _selected?.id;
      setState(() {
        _conversations = next;
        _selected = next.where((item) => item.id == oldId).firstOrNull ??
            next.where((item) => item.type == 'general').firstOrNull ??
            (next.isEmpty ? null : next.first);
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
      if (_selected != null) await _loadMessages(_selected!);
    } catch (error) {
      if (mounted && !silent) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMessages(BusinessChatConversation conversation) async {
    try {
      final messages = await _api.messages(widget.groupId, conversation.id);
      if (!mounted || _selected?.id != conversation.id) return;
      final previousIds = _messages.map((message) => message.id).toSet();
      final newCount =
          messages.where((message) => !previousIds.contains(message.id)).length;
      final shouldScroll = _messages.isEmpty || _nearLatest;
      setState(() {
        _messages = messages;
        if (newCount > 0 && !shouldScroll) _unseenMessages += newCount;
      });
      if (shouldScroll) _scrollToEnd();
      await _api.markRead(widget.groupId, conversation.id);
      if (mounted) {
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
      if (mounted) setState(() => _error = error.toString());
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut);
        }
      });

  Future<void> _createIssue() async {
    try {
      final values = await _issueDialog();
      if (values == null) return;
      final created = await _api.createIssue(
          widget.groupId, values.$1, values.$2,
          workerId: values.$3);
      await _refresh();
      final id = (created['conversation'] as Map)['id'].toString();
      if (mounted) {
        setState(() =>
            _selected = _conversations.where((c) => c.id == id).firstOrNull);
      }
      if (_selected != null) {
        await _loadMessages(_selected!);
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<(String, String, String?)?> _issueDialog() async {
    final workers = _canAssignIssues
        ? await _api.workers(widget.groupId)
        : const <Map<String, dynamic>>[];
    if (!mounted) return null;
    final title = TextEditingController();
    final description = TextEditingController();
    var workerId = '';
    return showDialog<(String, String, String?)>(
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
                                if (value != null) {
                                  refreshDialog(() => workerId = value);
                                }
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
                          if (value.isNotEmpty) {
                            Navigator.pop(context, (
                              value,
                              description.text.trim(),
                              workerId.isEmpty ? null : workerId
                            ));
                          }
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
    final title =
        await _textDialog(_es ? 'Nuevo chat de equipo' : 'New team chat');
    if (title == null) return;
    try {
      final members = await _api.members(widget.groupId);
      if (!mounted) return;
      final selected = <String>{};
      final chosen = await showDialog<List<String>>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, refreshDialog) => AlertDialog(
                  title:
                      Text(_es ? 'Añadir participantes' : 'Add participants'),
                  content: SizedBox(
                      width: 420,
                      height: 360,
                      child: ListView(
                          children: members.map((member) {
                        final id = (member['id'] ?? '').toString();
                        if (id.isEmpty || id == widget.currentUserId) {
                          return const SizedBox.shrink();
                        }
                        return CheckboxListTile(
                            value: selected.contains(id),
                            title: Text(
                                (member['name'] ?? member['userName'] ?? '')
                                    .toString()),
                            onChanged: (value) => refreshDialog(() {
                                  value == true
                                      ? selected.add(id)
                                      : selected.remove(id);
                                }));
                      }).toList())),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(_es ? 'Cancelar' : 'Cancel')),
                    FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, selected.toList()),
                        child: Text(_es ? 'Crear' : 'Create'))
                  ],
                )),
      );
      if (chosen == null) return;
      await _api.createTeam(widget.groupId, title.$1, chosen);
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  Future<(String, String)?> _textDialog(String title,
      {bool withDescription = false, String initialValue = ''}) async {
    final name = TextEditingController(text: initialValue);
    final description = TextEditingController();
    return showDialog<(String, String)>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: name,
                    maxLength: 160,
                    decoration: InputDecoration(
                        labelText: _es ? 'Título' : 'Title',
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
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_es ? 'Cancelar' : 'Cancel')),
                FilledButton(
                    onPressed: () {
                      final value = name.text.trim();
                      if (value.isNotEmpty) {
                        Navigator.pop(
                            context, (value, description.text.trim()));
                      }
                    },
                    child: Text(_es ? 'Crear' : 'Create'))
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
            initialValue: message.body);
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
      await _api.updateIssueStatus(widget.groupId, issueId, status);
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  String _typeLabel(String type) => switch (type) {
        'general' => _es ? 'General' : 'General',
        'team' => _es ? 'Equipo' : 'Team',
        'issue' => _es ? 'Incidencia' : 'Incident',
        _ => type,
      };

  // Kept temporarily as a reference while the compact chat layout is rolled
  // out below.
  // ignore: unused_element
  Widget _buildCurrentChat(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final query = _conversationSearch.text.trim().toLowerCase();
    final visible = _conversations
        .where((conversation) =>
            query.isEmpty ||
            conversation.title.toLowerCase().contains(query) ||
            (conversation.lastMessage?.body ?? '')
                .toLowerCase()
                .contains(query))
        .toList();
    final general = visible.where((item) => item.type == 'general').toList();
    final teams = visible.where((item) => item.type == 'team').toList();
    final issues = visible.where((item) => item.type == 'issue').toList();

    Widget conversationRow(BusinessChatConversation conversation) {
      final selected = _selected?.id == conversation.id;
      final preview =
          conversation.lastMessage?.body ?? _typeLabel(conversation.type);
      final icon = conversation.type == 'issue'
          ? Icons.report_outlined
          : conversation.type == 'team'
              ? Icons.groups_outlined
              : Icons.campaign_outlined;
      return ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: cs.primaryContainer.withValues(alpha: .4),
        leading: Icon(icon,
            size: 19, color: selected ? cs.primary : cs.onSurfaceVariant),
        title: Text(conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: conversation.unreadCount > 0
            ? Badge(label: Text('${conversation.unreadCount}'))
            : null,
        onTap: () {
          setState(() {
            _selected = conversation;
            _messages = const [];
          });
          _loadMessages(conversation);
        },
      );
    }

    Widget section(String title, List<BusinessChatConversation> items) =>
        items.isEmpty
            ? const SizedBox.shrink()
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
                    child: Text(title,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurfaceVariant))),
                ...items.map(conversationRow)
              ]);

    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(children: [
            Icon(Icons.forum_outlined, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Hexora Chat',
                    style: Theme.of(context).textTheme.titleMedium)),
            IconButton(
                onPressed: _loading ? null : _refresh,
                tooltip: _es ? 'Actualizar' : 'Refresh',
                icon: const Icon(Icons.refresh)),
            if (_canCreateIssues)
              IconButton(
                  onPressed: _createIssue,
                  tooltip: _es ? 'Nueva incidencia' : 'New incident',
                  icon: const Icon(Icons.report_gmailerrorred_outlined)),
            if (_canCreateTeam)
              IconButton(
                  onPressed: _createTeam,
                  tooltip: _es ? 'Nuevo chat de equipo' : 'New team chat',
                  icon: const Icon(Icons.group_add_outlined))
          ])),
      const Divider(height: 1),
      Expanded(
          child: Row(children: [
        SizedBox(
            width: 300,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                      controller: _conversationSearch,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar conversaciones',
                          isDense: true))),
              Expanded(
                  child: _conversations.isEmpty
                      ? Center(
                          child: Text(_error ??
                              (_es
                                  ? 'No hay conversaciones'
                                  : 'No conversations')))
                      : ListView(children: [
                          section('GENERAL', general),
                          section(_es ? 'EQUIPOS' : 'TEAMS', teams),
                          section(_es ? 'INCIDENCIAS' : 'ISSUES', issues)
                        ]))
            ])),
        VerticalDivider(
            width: 1, color: cs.outlineVariant.withValues(alpha: .5)),
        Expanded(
            child: Column(children: [
          if (_selected != null)
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: .4)))),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_selected!.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(_typeLabel(_selected!.type),
                            style: Theme.of(context).textTheme.bodySmall)
                      ])),
                  if (_selected!.type == 'issue' && _canAssignIssues)
                    IconButton(
                        tooltip:
                            _es ? 'Cambiar responsable' : 'Change assignee',
                        onPressed: () => _assignIssue(_selected!),
                        icon: const Icon(Icons.assignment_ind_outlined)),
                  PopupMenuButton<String>(
                      tooltip: _es ? 'Más opciones' : 'More options',
                      itemBuilder: (_) => const [])
                ])),
          Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 34, color: cs.onSurfaceVariant),
                      const SizedBox(height: 10),
                      Text(_es ? 'Todavía no hay mensajes' : 'No messages yet',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                          _es
                              ? 'Escribe el primer mensaje para comenzar.'
                              : 'Write the first message to get started.',
                          style: TextStyle(color: cs.onSurfaceVariant))
                    ]))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(14),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final mine = message.senderId == widget.currentUserId;
                        return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Card(
                                color: mine
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest,
                                child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(message.senderName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                          Text(message.isDeleted
                                              ? (_es
                                                  ? 'Mensaje eliminado'
                                                  : 'Message deleted')
                                              : message.body),
                                          Text(
                                              DateFormat('HH:mm').format(
                                                  message.createdAt.toLocal()),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall)
                                        ]))));
                      })),
          const Divider(height: 1),
          Padding(
              padding: const EdgeInsets.all(10),
              child: SafeArea(
                  top: false,
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _composer,
                            enabled: _selected != null && !_sending,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                                hintText: _es
                                    ? 'Escribe un mensaje…'
                                    : 'Write a message…',
                                border: const OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    IconButton.filled(
                        onPressed: _sending ||
                                _selected == null ||
                                _composer.text.trim().isEmpty
                            ? null
                            : _send,
                        tooltip: _es ? 'Enviar' : 'Send',
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send))
                  ]))),
        ])),
      ])),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final query = _conversationSearch.text.trim().toLowerCase();
    final visible = _conversations.where((conversation) {
      return query.isEmpty ||
          conversation.title.toLowerCase().contains(query) ||
          (conversation.lastMessage?.body ?? '').toLowerCase().contains(query);
    }).toList();

    Widget conversationRow(BusinessChatConversation conversation) {
      final selected = _selected?.id == conversation.id;
      final lastMessage = conversation.lastMessage;
      final icon = switch (conversation.type) {
        'issue' => Icons.report_outlined,
        'team' => Icons.groups_outlined,
        _ => Icons.forum_outlined,
      };
      return ListTile(
        dense: true,
        minVerticalPadding: 7,
        selected: selected,
        selectedTileColor: cs.primaryContainer.withValues(alpha: .48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon,
            size: 19, color: selected ? cs.primary : cs.onSurfaceVariant),
        title: Text(conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
        subtitle: Text(lastMessage?.body ?? _typeLabel(conversation.type),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: SizedBox(
          width: 42,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastMessage != null)
                Text(
                    DateFormat('HH:mm').format(lastMessage.createdAt.toLocal()),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              if (conversation.unreadCount > 0) ...[
                const SizedBox(height: 3),
                Badge(label: Text('${conversation.unreadCount}')),
              ],
            ],
          ),
        ),
        onTap: () {
          setState(() {
            _selected = conversation;
            _messages = const [];
            _nearLatest = true;
            _unseenMessages = 0;
          });
          _loadMessages(conversation);
        },
      );
    }

    Widget section(String title, String type) {
      final items = visible.where((item) => item.type == type).toList();
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
          child: Text(title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                    letterSpacing: .5,
                  )),
        ),
        ...items.map(conversationRow),
      ]);
    }

    Widget messageItem(int index, double maxWidth) {
      final message = _messages[index];
      final mine = message.senderId == widget.currentUserId;
      final previous = index == 0 ? null : _messages[index - 1];
      final showDay = previous == null ||
          previous.createdAt.toLocal().day != message.createdAt.toLocal().day ||
          previous.createdAt.toLocal().month !=
              message.createdAt.toLocal().month ||
          previous.createdAt.toLocal().year != message.createdAt.toLocal().year;
      final grouped = !mine &&
          previous != null &&
          previous.senderId == message.senderId &&
          !showDay &&
          message.createdAt.difference(previous.createdAt).inMinutes.abs() < 5;
      final canEdit = mine &&
          !message.isDeleted &&
          DateTime.now().difference(message.createdAt.toLocal()).inMinutes < 15;
      final canDelete = !message.isDeleted && (mine || _canModerateMessages);
      final bubble = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: mine ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!mine && !grouped)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(message.senderName,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              Text(
                  message.isDeleted
                      ? (_es ? 'Mensaje eliminado' : 'Message deleted')
                      : message.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14.5,
                      height: 1.3,
                      fontStyle: message.isDeleted ? FontStyle.italic : null)),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(DateFormat('HH:mm').format(message.createdAt.toLocal()),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                if (message.editedAt != null) ...[
                  const SizedBox(width: 4),
                  Text(_es ? 'Editado' : 'Edited',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
                if (canEdit || canDelete)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    tooltip: _es ? 'Acciones del mensaje' : 'Message actions',
                    onSelected: (action) => _messageAction(message, action),
                    itemBuilder: (_) => [
                      if (canEdit)
                        PopupMenuItem(
                            value: 'edit',
                            child: Text(_es ? 'Editar' : 'Edit')),
                      if (canDelete)
                        PopupMenuItem(
                            value: 'delete',
                            child: Text(_es ? 'Eliminar' : 'Delete')),
                    ],
                  ),
              ]),
            ]),
          ),
        ),
      );
      return Column(children: [
        if (showDay)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Chip(
                label: Text(DateFormat('d MMM yyyy')
                    .format(message.createdAt.toLocal()))),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment:
                mine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine) ...[
                grouped
                    ? const SizedBox(width: 32)
                    : HexoraUserAvatar(
                        userId: message.senderId,
                        displayName: message.senderName,
                        username: message.senderName,
                        size: 32),
                const SizedBox(width: 8),
              ],
              bubble,
            ],
          ),
        ),
      ]);
    }

    Widget sidebar() => Column(children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _conversationSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 19),
                hintText:
                    _es ? 'Buscar conversaciones' : 'Search conversations',
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: _conversations.isEmpty
                ? Center(
                    child: Text(_error ??
                        (_es ? 'No hay conversaciones' : 'No conversations')))
                : ListView(children: [
                    section('GENERAL', 'general'),
                    section(_es ? 'EQUIPOS' : 'TEAMS', 'team'),
                    section(_es ? 'INCIDENCIAS' : 'ISSUES', 'issue'),
                  ]),
          ),
        ]);

    Widget conversationPanel() => Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: .45)))),
            child: Row(children: [
              Expanded(
                  child: _selected == null
                      ? Text(_es
                          ? 'Selecciona una conversación'
                          : 'Select a conversation')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(_selected!.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              Text(_typeLabel(_selected!.type),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant)),
                            ])),
              if (_selected?.type == 'issue' && _canAssignIssues)
                IconButton(
                    tooltip:
                        _es ? 'Gestionar participantes' : 'Manage participants',
                    onPressed: () => _assignIssue(_selected!),
                    icon: const Icon(Icons.group_outlined)),
            ]),
          ),
          Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 34, color: cs.onSurfaceVariant),
                      const SizedBox(height: 10),
                      Text(_es ? 'Todavía no hay mensajes' : 'No messages yet',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                          _es
                              ? 'Escribe el primer mensaje para comenzar.'
                              : 'Write the first message to get started.',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ]))
                  : LayoutBuilder(
                      builder: (context, constraints) => Stack(children: [
                            ListView.builder(
                                controller: _scroll,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) => messageItem(
                                    index, constraints.maxWidth * .7)),
                            if (_unseenMessages > 0)
                              Positioned(
                                  bottom: 12,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                      child: FilledButton.tonal(
                                    onPressed: _scrollToEnd,
                                    child: Text(_es
                                        ? 'Nuevos mensajes'
                                        : 'New messages'),
                                  ))),
                          ]))),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SafeArea(
                top: false,
                child: Focus(
                  onKeyEvent: (_, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _send();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                      controller: _composer,
                      enabled: _selected != null && !_sending,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText:
                            _es ? 'Escribe un mensaje…' : 'Write a message…',
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    )),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: _es ? 'Enviar' : 'Send',
                      onPressed: _sending ||
                              _selected == null ||
                              _composer.text.trim().isEmpty
                          ? null
                          : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                    ),
                  ]),
                )),
          ),
        ]);

    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(children: [
            Icon(Icons.forum_outlined, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Hexora Chat',
                    style: Theme.of(context).textTheme.titleMedium)),
            IconButton(
                onPressed: _loading ? null : _refresh,
                tooltip: _es ? 'Actualizar' : 'Refresh',
                icon: const Icon(Icons.refresh)),
            if (_canCreateIssues)
              IconButton(
                  onPressed: _createIssue,
                  tooltip: _es ? 'Nueva incidencia' : 'New incident',
                  icon: const Icon(Icons.report_gmailerrorred_outlined)),
            if (_canCreateTeam)
              IconButton(
                  onPressed: _createTeam,
                  tooltip: _es ? 'Nuevo chat de equipo' : 'New team chat',
                  icon: const Icon(Icons.group_add_outlined)),
          ])),
      const Divider(height: 1),
      Expanded(child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(children: [
            SizedBox(height: 220, child: sidebar()),
            const Divider(height: 1),
            Expanded(child: conversationPanel())
          ]);
        }
        return Row(children: [
          SizedBox(width: 300, child: sidebar()),
          VerticalDivider(
              width: 1, color: cs.outlineVariant.withValues(alpha: .5)),
          Expanded(child: conversationPanel())
        ]);
      })),
    ]);
  }

  // ignore: unused_element
  Widget _buildLegacyChat(BuildContext context) {
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
            IconButton(
                onPressed: _loading ? null : _refresh,
                tooltip: _es ? 'Actualizar' : 'Refresh',
                icon: const Icon(Icons.refresh)),
            if (_canCreateIssues)
              IconButton(
                  onPressed: _createIssue,
                  tooltip: _es ? 'Nueva incidencia' : 'New incident',
                  icon: const Icon(Icons.report_gmailerrorred_outlined)),
            if (_canCreateTeam)
              IconButton(
                  onPressed: _createTeam,
                  tooltip: _es ? 'Nuevo chat de equipo' : 'New team chat',
                  icon: const Icon(Icons.group_add_outlined)),
          ])),
      const Divider(height: 1),
      Expanded(
          child: Row(children: [
        SizedBox(
            width: 250,
            child: _conversations.isEmpty
                ? Center(
                    child: Text(_error ??
                        (_es ? 'No hay conversaciones' : 'No conversations')))
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      final selected = _selected?.id == conversation.id;
                      final status = conversation.issue?['status'];
                      final preview = conversation.lastMessage?.body ??
                          (status?.toString() ?? _typeLabel(conversation.type));
                      return ListTile(
                          selected: selected,
                          leading: Icon(conversation.type == 'issue'
                              ? Icons.report_outlined
                              : conversation.type == 'team'
                                  ? Icons.groups_outlined
                                  : Icons.campaign_outlined),
                          title: Text(conversation.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(preview,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: conversation.unreadCount > 0
                              ? Badge(
                                  label: Text('${conversation.unreadCount}'))
                              : null,
                          onTap: () {
                            setState(() {
                              _selected = conversation;
                              _messages = const [];
                            });
                            _loadMessages(conversation);
                          });
                    })),
        const VerticalDivider(width: 1),
        Expanded(
            child: Column(children: [
          if (_selected != null)
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: colors.surfaceContainerLow,
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_selected!.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        if (_selected!.type == 'issue')
                          Text(
                              _selected!.issue?['assigneeName'] == null
                                  ? (_es ? 'Sin asignar' : 'Unassigned')
                                  : '${_es ? 'Asignada a' : 'Assigned to'} ${_selected!.issue!['assigneeName']}',
                              style: Theme.of(context).textTheme.bodySmall)
                      ])),
                  Text(_typeLabel(_selected!.type)),
                  if (_selected!.issue?['status'] != null && _canAssignIssues)
                    IconButton(
                        tooltip:
                            _es ? 'Cambiar responsable' : 'Change assignee',
                        onPressed: () => _assignIssue(_selected!),
                        icon: const Icon(Icons.assignment_ind_outlined)),
                  if (_selected!.issue?['status'] != null)
                    Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _canManageIssues
                            ? DropdownButton<String>(
                                value: _selected!.issue!['status'].toString(),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'open', child: Text('Open')),
                                  DropdownMenuItem(
                                      value: 'in_progress',
                                      child: Text('In progress')),
                                  DropdownMenuItem(
                                      value: 'review',
                                      child: Text('In review')),
                                  DropdownMenuItem(
                                      value: 'resolved',
                                      child: Text('Resolved')),
                                  DropdownMenuItem(
                                      value: 'closed', child: Text('Closed'))
                                ],
                                onChanged: (value) {
                                  if (value != null) _setIssueStatus(value);
                                })
                            : Chip(
                                label: Text(
                                    _selected!.issue!['status'].toString())))
                ])),
          Expanded(
              child: _error != null && _messages.isEmpty
                  ? Center(
                      child: TextButton(
                          onPressed: _refresh,
                          child: Text(_es ? 'Reintentar' : 'Retry')))
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
                            final mine =
                                message.senderId == widget.currentUserId;
                            final canEdit = mine &&
                                !message.isDeleted &&
                                DateTime.now()
                                        .difference(message.createdAt.toLocal())
                                        .inMinutes <
                                    15;
                            final canDelete = !message.isDeleted &&
                                (mine || _canModerateMessages);
                            return Align(
                                alignment: mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 520),
                                    child: Card(
                                        color: mine
                                            ? colors.primaryContainer
                                            : colors.surfaceContainerHighest,
                                        child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(children: [
                                                    HexoraUserAvatar(
                                                        userId:
                                                            message.senderId,
                                                        displayName:
                                                            message.senderName,
                                                        username:
                                                            message.senderName,
                                                        size: 24),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                        child: Text(
                                                            message.senderName,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700))),
                                                    if (canEdit || canDelete)
                                                      PopupMenuButton<String>(
                                                          onSelected: (value) =>
                                                              _messageAction(
                                                                  message,
                                                                  value),
                                                          itemBuilder: (_) => [
                                                                if (canEdit)
                                                                  PopupMenuItem(
                                                                      value:
                                                                          'edit',
                                                                      child: Text(_es
                                                                          ? 'Editar'
                                                                          : 'Edit')),
                                                                if (canDelete)
                                                                  PopupMenuItem(
                                                                      value:
                                                                          'delete',
                                                                      child: Text(_es
                                                                          ? 'Eliminar'
                                                                          : 'Delete'))
                                                              ])
                                                  ]),
                                                  Text(message.isDeleted
                                                      ? (_es
                                                          ? 'Mensaje eliminado'
                                                          : 'Message deleted')
                                                      : message.body),
                                                  Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: Text(
                                                          '${DateFormat('HH:mm').format(message.createdAt.toLocal())}${message.editedAt != null ? (_es ? ' · Editado' : ' · Edited') : ''}',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .labelSmall)),
                                                ])))));
                          })),
          const Divider(height: 1),
          Padding(
              padding: const EdgeInsets.all(10),
              child: SafeArea(
                  top: false,
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _composer,
                            maxLength: 2000,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                                hintText: _es
                                    ? 'Escribe un mensaje…'
                                    : 'Write a message…',
                                counterText: '',
                                border: const OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    IconButton.filled(
                        onPressed: _sending || _selected == null ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send))
                  ]))),
        ])),
      ])),
    ]);
  }
}
