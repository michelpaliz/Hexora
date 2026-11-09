import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/services/business_chat/business_chat_api.dart';
import 'package:intl/intl.dart';

class DocumentReviewSelection {
  const DocumentReviewSelection({required this.conversationId, required this.kind,
    required this.documentId, required this.year, required this.quarter,
    required this.body, this.file});
  final String conversationId;
  final String kind;
  final String documentId;
  final int year;
  final int quarter;
  final String body;
  final PlatformFile? file;
}

class DocumentReviewDialog extends StatefulWidget {
  const DocumentReviewDialog({super.key, required this.groupId,
    required this.kind, required this.conversations, this.initialConversationId,
    this.onOpenBanking, this.onCreateExpense});
  final String groupId;
  final String kind;
  final List<BusinessChatConversation> conversations;
  final String? initialConversationId;
  final Future<void> Function()? onOpenBanking;
  final Future<void> Function()? onCreateExpense;

  @override
  State<DocumentReviewDialog> createState() => _DocumentReviewDialogState();
}

class _DocumentReviewDialogState extends State<DocumentReviewDialog> {
  final _api = BusinessChatApi();
  final _search = TextEditingController();
  final _body = TextEditingController();
  late int _year;
  late int _quarter;
  int _page = 1;
  int _total = 0;
  int _revision = 0;
  bool _loading = false;
  bool _acknowledgedUnlinked = false;
  String? _error;
  String? _conversationId;
  Map<String, dynamic>? _selected;
  PlatformFile? _file;
  List<Map<String, dynamic>> _items = const [];
  bool get _es => Localizations.localeOf(context).languageCode == 'es';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _quarter = ((now.month - 1) ~/ 3) + 1;
    _conversationId = widget.conversations.any((c) => c.id == widget.initialConversationId)
        ? widget.initialConversationId : widget.conversations.firstOrNull?.id;
    _load();
  }

  @override
  void dispose() {
    _revision++;
    _search.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    final revision = ++_revision;
    setState(() { _loading = true; _error = null; _selected = null; _acknowledgedUnlinked = false; });
    try {
      final data = await _api.reviewDocuments(widget.groupId,
        kind: widget.kind, year: _year, quarter: _quarter,
        page: page, search: _search.text.trim());
      if (!mounted || revision != _revision) return;
      setState(() {
        _items = (data['items'] as List<dynamic>? ?? const [])
            .whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
        _total = (data['total'] as num?)?.toInt() ?? 0;
        _page = page;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || revision != _revision) return;
      setState(() { _loading = false; _error = error.toString(); });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'csv', 'xlsx'], withData: true);
    if (!mounted || result == null || result.files.isEmpty) return;
    if (result.files.single.size > 10 * 1024 * 1024) {
      setState(() => _error = _es ? 'Máximo 10 MB' : 'Maximum 10 MB');
      return;
    }
    setState(() => _file = result.files.single);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final unlinked = selected != null && widget.kind == 'invoice' &&
        selected['linkedTransactionCount'] is num &&
        (selected['linkedTransactionCount'] as num) == 0;
    final hasWorkerHours = widget.kind != 'worker_hours' ||
        (selected?['timeEntriesCount'] as num? ?? 0) > 0 || _file != null;
    final title = switch (widget.kind) {
      'invoice' => _es ? 'Revisar factura' : 'Review invoice',
      'expense' => _es ? 'Revisar gasto' : 'Review expense',
      _ => _es ? 'Revisar horas' : 'Review hours',
    };
    final canSend = selected != null && _conversationId != null &&
        _body.text.trim().isNotEmpty && hasWorkerHours &&
        (!unlinked || _acknowledgedUnlinked);
    final sorted = [..._items]..sort((a, b) {
      final byName = (a['counterparty'] ?? '').toString().toLowerCase()
          .compareTo((b['counterparty'] ?? '').toString().toLowerCase());
      return byName != 0 ? byName : (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString());
    });
    return AlertDialog(
      title: Text(title),
      content: SizedBox(width: 620, height: 560, child: Column(children: [
        DropdownButtonFormField<String>(
          value: _conversationId,
          decoration: InputDecoration(labelText: _es ? 'Chat de administradores' : 'Admin team chat'),
          items: widget.conversations.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title))).toList(),
          onChanged: (value) => setState(() => _conversationId = value),
        ),
        const SizedBox(height: 8),
        Row(children: [
          SizedBox(width: 120, child: DropdownButtonFormField<int>(
            value: _year,
            decoration: InputDecoration(labelText: _es ? 'Año' : 'Year'),
            items: List.generate(DateTime.now().year - 1999, (i) => DateTime.now().year - i)
                .map((year) => DropdownMenuItem(value: year, child: Text('$year'))).toList(),
            onChanged: (value) { if (value != null) { _year = value; _load(); } },
          )),
          const SizedBox(width: 8),
          SizedBox(width: 145, child: DropdownButtonFormField<int>(
            value: _quarter,
            decoration: InputDecoration(labelText: _es ? 'Trimestre' : 'Quarter'),
            items: List.generate(4, (i) => i + 1)
                .map((quarter) => DropdownMenuItem(value: quarter, child: Text('${_es ? 'T' : 'Q'}$quarter'))).toList(),
            onChanged: (value) { if (value != null) { _quarter = value; _load(); } },
          )),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(isDense: true, labelText: _es ? 'Cliente / proveedor / número' : 'Client / provider / number',
              suffixIcon: IconButton(onPressed: () => _load(), icon: const Icon(Icons.search))),
          )),
        ]),
        const SizedBox(height: 8),
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty ? Center(child: Text(_es ? 'Sin resultados en este trimestre' : 'No results this quarter'))
          : ListView.builder(itemCount: sorted.length, itemBuilder: (context, index) {
              final item = sorted[index];
              final name = (item['counterparty'] ?? '').toString();
              final showHeader = index == 0 ||
                  (sorted[index - 1]['counterparty'] ?? '').toString() != name;
              final date = DateTime.tryParse((item['date'] ?? '').toString());
              final subtitle = [
                if (date != null) DateFormat.yMMMd(_es ? 'es' : 'en').format(date),
                if (widget.kind == 'worker_hours') '${item['timeEntriesCount'] ?? 0} ${_es ? 'registros' : 'entries'}',
                if (item['linkedTransactionCount'] is num) '${item['linkedTransactionCount']} ${_es ? 'movimientos vinculados' : 'linked transactions'}',
              ].join(' · ');
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (showHeader) Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                  child: Text(name, style: Theme.of(context).textTheme.labelMedium)),
                ListTile(dense: true,
                  selected: selected?['id'] == item['id'],
                  title: Text((item['number'] ?? '').toString().isNotEmpty
                      ? item['number'].toString() : name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => setState(() { _selected = item; _acknowledgedUnlinked = false; })),
              ]);
            })),
        Row(children: [
          IconButton(onPressed: _page > 1 && !_loading ? () => _load(page: _page - 1) : null,
            icon: const Icon(Icons.chevron_left)),
          Text('$_page / ${(_total / 30).ceil().clamp(1, 100000)}'),
          IconButton(onPressed: _page * 30 < _total && !_loading ? () => _load(page: _page + 1) : null,
            icon: const Icon(Icons.chevron_right)),
          const Spacer(),
          Text('$_total'),
        ]),
        if (unlinked) CheckboxListTile(
          dense: true, contentPadding: EdgeInsets.zero,
          value: _acknowledgedUnlinked,
          onChanged: (value) => setState(() => _acknowledgedUnlinked = value == true),
          title: Text(_es
            ? 'Sin movimiento vinculado. Vincúlalo en Banco o confirma que enviarás la revisión pendiente de vinculación.'
            : 'No linked transaction. Link it in Banking or confirm you will send the review pending a link.'),
        ),
        if (unlinked && widget.onOpenBanking != null)
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(
            onPressed: () async {
              try {
                await widget.onOpenBanking!();
                if (mounted) _load(page: _page);
              } catch (error) {
                if (mounted) setState(() => _error = error.toString());
              }
            },
            icon: const Icon(Icons.account_balance_outlined),
            label: Text(_es ? 'Abrir Banco para vincular' : 'Open Banking to link'),
          )),
        if (!hasWorkerHours && selected != null)
          Text(_es ? 'Adjunta el parte de horas para continuar.' : 'Attach the hours sheet to continue.'),
        if (widget.kind == 'expense' && widget.onCreateExpense != null)
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(
            onPressed: () async {
              try {
                await widget.onCreateExpense!();
                if (mounted) _load();
              } catch (error) {
                if (mounted) setState(() => _error = error.toString());
              }
            },
            icon: const Icon(Icons.add_circle_outline),
            label: Text(_es ? 'Registrar nuevo gasto' : 'Register new expense'),
          )),
        Row(children: [
          TextButton.icon(onPressed: _pickFile, icon: const Icon(Icons.attach_file),
            label: Text(_file?.name ?? (_es ? 'Adjuntar PDF, imagen o Excel' : 'Attach PDF, image, or Excel'))),
          if (_file != null) IconButton(onPressed: () => setState(() => _file = null), icon: const Icon(Icons.close)),
        ]),
        TextField(controller: _body, maxLength: 2000, maxLines: 2,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: _es ? 'Qué deben revisar o cambiar' : 'What to review or change')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(_es ? 'Cancelar' : 'Cancel')),
        FilledButton(onPressed: canSend ? () => Navigator.pop(context,
          DocumentReviewSelection(conversationId: _conversationId!, kind: widget.kind,
            documentId: selected!['id'].toString(), year: _year, quarter: _quarter,
            body: _body.text.trim(), file: _file)) : null,
          child: Text(_es ? 'Pedir revisión' : 'Request review')),
      ],
    );
  }
}
