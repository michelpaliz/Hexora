import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hexora/services/business_chat/business_chat_api.dart';
import 'package:intl/intl.dart';

class BusinessChatScreen extends StatefulWidget {
  const BusinessChatScreen({super.key, required this.groupId, required this.currentUserId});
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
  bool _loading = false;
  bool _sending = false;
  bool _canCreateTeam = false;
  bool _canCreateIssues = true;
  bool _canManageIssues = false;
  bool _canAssignIssues = false;
  bool _canModerateMessages = false;
  String? _error;
  bool get _es => Localizations.localeOf(context).languageCode == 'es';

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _refresh(silent: true));
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
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_loading) return;
    setState(() { _loading = true; if (!silent) _error = null; });
    try {
      final data = await _api.conversations(widget.groupId);
      if (!mounted) return;
      final next = List<BusinessChatConversation>.from(data['conversations'] as List);
      final oldId = _selected?.id;
      setState(() {
        _conversations = next;
        _selected = next.where((item) => item.id == oldId).firstOrNull ??
            next.where((item) => item.type == 'general').firstOrNull ??
            (next.isEmpty ? null : next.first);
        _canCreateTeam = (data['capabilities'] as Map?)?['canCreateTeam'] == true;
        _canCreateIssues = (data['capabilities'] as Map?)?['canCreateIssues'] == true;
        _canManageIssues = (data['capabilities'] as Map?)?['canManageIssues'] == true;
        _canAssignIssues = (data['capabilities'] as Map?)?['canAssignIssues'] == true;
        _canModerateMessages = (data['capabilities'] as Map?)?['canModerateMessages'] == true;
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
      setState(() => _messages = messages);
      await _api.markRead(widget.groupId, conversation.id);
      if (mounted) {
        final readConversation = conversation.copyWith(unreadCount: 0);
        setState(() {
          _selected = readConversation;
          _conversations = _conversations.map((item) => item.id == conversation.id ? readConversation : item).toList();
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
  });

  Future<void> _createIssue() async {
    try {
      final values = await _issueDialog();
      if (values == null) return;
      final created = await _api.createIssue(widget.groupId, values.$1, values.$2, workerId: values.$3);
      await _refresh();
      final id = (created['conversation'] as Map)['id'].toString();
      if (mounted) setState(() => _selected = _conversations.where((c) => c.id == id).firstOrNull);
      if (_selected != null) await _loadMessages(_selected!);
    } catch (error) { _showError(error); }
  }

  Future<(String, String, String?)?> _issueDialog() async {
    final workers = _canAssignIssues ? await _api.workers(widget.groupId) : const <Map<String, dynamic>>[];
    if (!mounted) return null;
    final title = TextEditingController();
    final description = TextEditingController();
    var workerId = '';
    return showDialog<(String, String, String?)>(context: context, builder: (context) => StatefulBuilder(builder: (context, refreshDialog) => AlertDialog(
      title: Text(_es ? 'Nueva incidencia' : 'New incident'),
      content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, maxLength: 160, decoration: InputDecoration(labelText: _es ? 'Título' : 'Title', border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: description, maxLength: 4000, maxLines: 4, decoration: InputDecoration(labelText: _es ? 'Descripción' : 'Description', border: const OutlineInputBorder())),
        if (_canAssignIssues && workers.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: workerId, decoration: InputDecoration(labelText: _es ? 'Asignar a (opcional)' : 'Assign to (optional)', border: const OutlineInputBorder()),
            items: [DropdownMenuItem<String>(value: '', child: Text(_es ? 'Sin asignar' : 'Unassigned')), ...workers.map((worker) => DropdownMenuItem<String>(value: worker['id'].toString(), child: Text('${worker['name']} · ${worker['role']}')))],
            onChanged: (value) { if (value != null) refreshDialog(() => workerId = value); }),
        ],
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(_es ? 'Cancelar' : 'Cancel')), FilledButton(onPressed: () { final value = title.text.trim(); if (value.isNotEmpty) Navigator.pop(context, (value, description.text.trim(), workerId.isEmpty ? null : workerId)); }, child: Text(_es ? 'Crear' : 'Create'))],
    ))).then((value) { title.dispose(); description.dispose(); return value; });
  }

  Future<void> _assignIssue(BusinessChatConversation conversation) async {
    final issueId = conversation.issue?['id']?.toString();
    if (issueId == null) return;
    try {
      final workers = await _api.workers(widget.groupId);
      if (!mounted) return;
      if (workers.isEmpty) {
        _showError(_es ? 'No hay trabajadores activos con una cuenta Hexora.' : 'No active workers with a Hexora account are available.');
        return;
      }
      final workerId = await showDialog<String>(context: context, builder: (context) => SimpleDialog(
        title: Text(_es ? 'Asignar incidencia' : 'Assign incident'),
        children: workers.map((worker) => SimpleDialogOption(onPressed: () => Navigator.pop(context, worker['id'].toString()), child: Text('${worker['name']} · ${worker['role']}'))).toList(),
      ));
      if (workerId == null) return;
      await _api.assignIssue(widget.groupId, issueId, workerId);
      await _refresh();
    } catch (error) { _showError(error); }
  }

  Future<void> _createTeam() async {
    final title = await _textDialog(_es ? 'Nuevo chat de equipo' : 'New team chat');
    if (title == null) return;
    try {
      final members = await _api.members(widget.groupId);
      if (!mounted) return;
      final selected = <String>{};
      final chosen = await showDialog<List<String>>(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, refreshDialog) => AlertDialog(
          title: Text(_es ? 'Añadir participantes' : 'Add participants'),
          content: SizedBox(width: 420, height: 360, child: ListView(children: members.map((member) {
            final id = (member['id'] ?? '').toString();
            if (id.isEmpty || id == widget.currentUserId) return const SizedBox.shrink();
            return CheckboxListTile(value: selected.contains(id), title: Text((member['name'] ?? member['userName'] ?? '').toString()), onChanged: (value) => refreshDialog(() { value == true ? selected.add(id) : selected.remove(id); }));
          }).toList())),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(_es ? 'Cancelar' : 'Cancel')), FilledButton(onPressed: () => Navigator.pop(context, selected.toList()), child: Text(_es ? 'Crear' : 'Create'))],
        )),
      );
      if (chosen == null) return;
      await _api.createTeam(widget.groupId, title.$1, chosen);
      await _refresh();
    } catch (error) { _showError(error); }
  }

  Future<(String, String)?> _textDialog(String title, {bool withDescription = false, String initialValue = ''}) async {
    final name = TextEditingController(text: initialValue);
    final description = TextEditingController();
    return showDialog<(String, String)>(context: context, builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, maxLength: 160, decoration: InputDecoration(labelText: _es ? 'Título' : 'Title', border: const OutlineInputBorder())),
        if (withDescription) ...[const SizedBox(height: 12), TextField(controller: description, maxLength: 4000, maxLines: 4, decoration: InputDecoration(labelText: _es ? 'Descripción' : 'Description', border: const OutlineInputBorder()))],
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(_es ? 'Cancelar' : 'Cancel')), FilledButton(onPressed: () { final value = name.text.trim(); if (value.isNotEmpty) Navigator.pop(context, (value, description.text.trim())); }, child: Text(_es ? 'Crear' : 'Create'))],
    )).then((value) { name.dispose(); description.dispose(); return value; });
  }

  Future<void> _messageAction(BusinessChatMessage message, String action) async {
    try {
      if (action == 'delete') {
        await _api.delete(widget.groupId, message);
      } else {
        final value = await _textDialog(_es ? 'Editar mensaje' : 'Edit message', initialValue: message.body);
        if (value == null) return;
        await _api.edit(widget.groupId, message, value.$1);
      }
      if (_selected != null) await _loadMessages(_selected!);
    } catch (error) { _showError(error); }
  }

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));

  Future<void> _setIssueStatus(String status) async {
    final issueId = _selected?.issue?['id']?.toString();
    if (issueId == null || issueId.isEmpty) return;
    try {
      await _api.updateIssueStatus(widget.groupId, issueId, status);
      await _refresh();
    } catch (error) { _showError(error); }
  }

  String _typeLabel(String type) => switch (type) {
    'general' => _es ? 'General' : 'General',
    'team' => _es ? 'Equipo' : 'Team',
    'issue' => _es ? 'Incidencia' : 'Incident',
    _ => type,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
        Badge(isLabelVisible: _conversations.fold<int>(0, (sum, item) => sum + item.unreadCount) > 0, label: Text('${_conversations.fold<int>(0, (sum, item) => sum + item.unreadCount)}'), child: Icon(Icons.forum_outlined, color: colors.primary)), const SizedBox(width: 10),
        Expanded(child: Text(_es ? 'Hexora Chat' : 'Hexora Chat', style: Theme.of(context).textTheme.titleMedium)),
        IconButton(onPressed: _loading ? null : _refresh, tooltip: _es ? 'Actualizar' : 'Refresh', icon: const Icon(Icons.refresh)),
        if (_canCreateIssues) IconButton(onPressed: _createIssue, tooltip: _es ? 'Nueva incidencia' : 'New incident', icon: const Icon(Icons.report_gmailerrorred_outlined)),
        if (_canCreateTeam) IconButton(onPressed: _createTeam, tooltip: _es ? 'Nuevo chat de equipo' : 'New team chat', icon: const Icon(Icons.group_add_outlined)),
      ])),
      const Divider(height: 1),
      Expanded(child: Row(children: [
        SizedBox(width: 250, child: _conversations.isEmpty
          ? Center(child: Text(_error ?? (_es ? 'No hay conversaciones' : 'No conversations')))
          : ListView.builder(itemCount: _conversations.length, itemBuilder: (context, index) {
              final conversation = _conversations[index];
              final selected = _selected?.id == conversation.id;
              final status = conversation.issue?['status'];
              final preview = conversation.lastMessage?.body ?? (status?.toString() ?? _typeLabel(conversation.type));
              return ListTile(selected: selected, leading: Icon(conversation.type == 'issue' ? Icons.report_outlined : conversation.type == 'team' ? Icons.groups_outlined : Icons.campaign_outlined), title: Text(conversation.title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: conversation.unreadCount > 0 ? Badge(label: Text('${conversation.unreadCount}')) : null, onTap: () { setState(() { _selected = conversation; _messages = const []; }); _loadMessages(conversation); });
            })),
        const VerticalDivider(width: 1),
        Expanded(child: Column(children: [
          if (_selected != null) Container(width: double.infinity, padding: const EdgeInsets.all(10), color: colors.surfaceContainerLow, child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_selected!.title, style: const TextStyle(fontWeight: FontWeight.w600)), if (_selected!.type == 'issue') Text(_selected!.issue?['assigneeName'] == null ? (_es ? 'Sin asignar' : 'Unassigned') : '${_es ? 'Asignada a' : 'Assigned to'} ${_selected!.issue!['assigneeName']}', style: Theme.of(context).textTheme.bodySmall)])), Text(_typeLabel(_selected!.type)), if (_selected!.issue?['status'] != null && _canAssignIssues) IconButton(tooltip: _es ? 'Cambiar responsable' : 'Change assignee', onPressed: () => _assignIssue(_selected!), icon: const Icon(Icons.assignment_ind_outlined)), if (_selected!.issue?['status'] != null) Padding(padding: const EdgeInsets.only(left: 8), child: _canManageIssues ? DropdownButton<String>(value: _selected!.issue!['status'].toString(), items: const [DropdownMenuItem(value: 'open', child: Text('Open')), DropdownMenuItem(value: 'in_progress', child: Text('In progress')), DropdownMenuItem(value: 'review', child: Text('In review')), DropdownMenuItem(value: 'resolved', child: Text('Resolved')), DropdownMenuItem(value: 'closed', child: Text('Closed'))], onChanged: (value) { if (value != null) _setIssueStatus(value); }) : Chip(label: Text(_selected!.issue!['status'].toString())))])),
          Expanded(child: _error != null && _messages.isEmpty ? Center(child: TextButton(onPressed: _refresh, child: Text(_es ? 'Reintentar' : 'Retry'))) : _messages.isEmpty ? Center(child: Text(_es ? 'Todavía no hay mensajes.' : 'No messages yet.')) : ListView.builder(controller: _scroll, padding: const EdgeInsets.all(14), itemCount: _messages.length, itemBuilder: (context, index) {
            final message = _messages[index];
            final mine = message.senderId == widget.currentUserId;
            final canEdit = mine && !message.isDeleted && DateTime.now().difference(message.createdAt.toLocal()).inMinutes < 15;
            final canDelete = !message.isDeleted && (mine || _canModerateMessages);
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Card(color: mine ? colors.primaryContainer : colors.surfaceContainerHighest, child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(message.senderName, style: const TextStyle(fontWeight: FontWeight.w700))), if (canEdit || canDelete) PopupMenuButton<String>(onSelected: (value) => _messageAction(message, value), itemBuilder: (_) => [if (canEdit) PopupMenuItem(value: 'edit', child: Text(_es ? 'Editar' : 'Edit')), if (canDelete) PopupMenuItem(value: 'delete', child: Text(_es ? 'Eliminar' : 'Delete'))])]),
              Text(message.isDeleted ? (_es ? 'Mensaje eliminado' : 'Message deleted') : message.body),
              Align(alignment: Alignment.centerRight, child: Text('${DateFormat('HH:mm').format(message.createdAt.toLocal())}${message.editedAt != null ? (_es ? ' · Editado' : ' · Edited') : ''}', style: Theme.of(context).textTheme.labelSmall)),
            ])))));
          })),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(10), child: SafeArea(top: false, child: Row(children: [Expanded(child: TextField(controller: _composer, maxLength: 2000, minLines: 1, maxLines: 4, decoration: InputDecoration(hintText: _es ? 'Escribe un mensaje…' : 'Write a message…', counterText: '', border: const OutlineInputBorder()))), const SizedBox(width: 8), IconButton.filled(onPressed: _sending || _selected == null ? null : _send, icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send))]))),
        ])),
      ])),
    ]);
  }
}
