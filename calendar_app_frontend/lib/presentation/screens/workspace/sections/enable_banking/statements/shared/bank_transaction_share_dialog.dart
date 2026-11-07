import 'package:flutter/material.dart';
import 'package:hexora/services/business_chat/business_chat_api.dart';
import 'package:intl/intl.dart';

class BankTransactionShareDialog extends StatefulWidget {
  const BankTransactionShareDialog({
    super.key,
    required this.groupId,
    required this.entry,
    this.initialConversationId,
    this.initialMessage,
  });

  final String groupId;
  final Map<String, dynamic> entry;
  final String? initialConversationId;
  final String? initialMessage;

  static Future<String?> show(
    BuildContext context,
    String groupId,
    Map<String, dynamic> entry, {
    String? initialConversationId,
    String? initialMessage,
  }) =>
      showDialog<String>(
        context: context,
        builder: (_) => BankTransactionShareDialog(
          groupId: groupId,
          entry: entry,
          initialConversationId: initialConversationId,
          initialMessage: initialMessage,
        ),
      );

  @override
  State<BankTransactionShareDialog> createState() =>
      _BankTransactionShareDialogState();
}

class _BankTransactionShareDialogState
    extends State<BankTransactionShareDialog> {
  final _api = BusinessChatApi();
  late final TextEditingController _message;
  List<BusinessChatConversation> _chats = const [];
  String? _selectedId;
  String? _error;
  bool _loading = true;
  bool _sending = false;
  bool _mayShare = true;

  String get _entryId =>
      (widget.entry['_id'] ?? widget.entry['id'] ?? '').toString();
  double get _amount =>
      double.tryParse(widget.entry['amount']?.toString() ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _message = TextEditingController(
        text: widget.initialMessage ?? (_amount < 0
            ? '¿Alguien sabe a qué corresponde este gasto?'
            : '¿Alguien sabe de dónde viene este ingreso?'));
    _loadChats();
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    try {
      final data = await _api.conversations(widget.groupId);
      if (!mounted) return;
      final chats = (data['conversations'] as List<BusinessChatConversation>)
          .where((chat) => chat.canShareBankTransaction)
          .toList();
      setState(() {
        _chats = chats;
        _mayShare =
            (data['capabilities'] as Map?)?['canShareBankTransactions'] == true;
        _selectedId =
            chats.any((chat) => chat.id == widget.initialConversationId)
                ? widget.initialConversationId
                : chats.length == 1
                    ? chats.first.id
                    : null;
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'No se pudieron cargar los chats disponibles.';
        });
    }
  }

  Future<void> _send() async {
    if (_sending || _selectedId == null || _entryId.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _api.shareBankTransaction(
          widget.groupId, _selectedId!, _entryId, _message.text.trim());
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(_selectedId);
      messenger.showSnackBar(
          const SnackBar(content: Text('Movimiento compartido en el chat.')));
    } catch (_) {
      if (mounted)
        setState(() => _error =
            'No se pudo compartir. Comprueba que el chat y el movimiento sigan disponibles.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amount = _amount;
    final date = DateTime.tryParse(
        (widget.entry['valueDate'] ?? widget.entry['date'] ?? '').toString());
    final rawDescription =
        (widget.entry['description'] ?? '').toString().trim();
    final description = rawDescription.replaceAll(
      RegExp(r'\b[A-Z]{2}\d{2}(?:[ -]?[A-Z0-9]){11,30}\b',
          caseSensitive: false),
      '[cuenta oculta]',
    );
    return AlertDialog(
      title: const Text('Compartir en chat'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              description.isEmpty
                                  ? 'Movimiento bancario'
                                  : description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              '${NumberFormat.currency(locale: 'es_ES', symbol: '€').format(amount)}${date == null ? '' : ' · ${DateFormat('dd/MM/yyyy').format(date)}'}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ]),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (!_mayShare)
                  const Text(
                      'No tienes permiso para compartir movimientos bancarios.')
                else if (_chats.isEmpty)
                  const Text(
                      'No hay chats disponibles para compartir datos bancarios. Crea un chat de equipo solo con administradores.'),
                if (_chats.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Chat de destino',
                        border: OutlineInputBorder()),
                    items: _chats
                        .map((chat) => DropdownMenuItem(
                            value: chat.id,
                            child: Text(chat.title,
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: _sending
                        ? null
                        : (value) => setState(() => _selectedId = value),
                  ),
                const SizedBox(height: 12),
                Text('Mensaje sugerido',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  ActionChip(
                    label: const Text('Identificar movimiento'),
                    onPressed: _sending
                        ? null
                        : () => _message.text = _amount < 0
                            ? '¿Alguien sabe a qué corresponde este gasto?'
                            : '¿Alguien sabe de dónde viene este ingreso?',
                  ),
                  ActionChip(
                    label: const Text('Pedir revisión'),
                    onPressed: _sending
                        ? null
                        : () => _message.text =
                            '¿Podéis revisar este movimiento y confirmar si está vinculado correctamente?',
                  ),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: _message,
                  enabled: !_sending,
                  maxLength: 2000,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Mensaje (opcional)',
                      border: OutlineInputBorder()),
                ),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: cs.error)),
              ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _sending ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed:
                _loading || _sending || _selectedId == null ? null : _send,
            child: Text(_sending ? 'Enviando…' : 'Enviar')),
      ],
    );
  }
}
