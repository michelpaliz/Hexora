import 'package:flutter/material.dart';
import 'package:hexora/services/business_chat/business_chat_api.dart';
import 'package:intl/intl.dart';

class BusinessChatSearchDialog extends StatefulWidget {
  const BusinessChatSearchDialog(
      {super.key,
      required this.api,
      required this.groupId,
      required this.conversationId});

  final BusinessChatApi api;
  final String groupId;
  final String conversationId;

  @override
  State<BusinessChatSearchDialog> createState() =>
      _BusinessChatSearchDialogState();
}

class _BusinessChatSearchDialogState extends State<BusinessChatSearchDialog> {
  final _query = TextEditingController();
  List<BusinessChatMessage> _results = const [];
  bool _loading = false;
  bool _searched = false;
  String? _error;
  int _revision = 0;

  @override
  void dispose() {
    _revision++;
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final text = _query.text.trim();
    if (text.length < 2 || text.length > 80) {
      setState(() => _error = 'Escribe entre 2 y 80 caracteres.');
      return;
    }
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.api
          .searchMessages(widget.groupId, widget.conversationId, text);
      if (!mounted || revision != _revision) return;
      setState(() {
        _results = results;
        _loading = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo buscar. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    return AlertDialog(
      title: Text(es ? 'Buscar mensajes' : 'Search messages'),
      content: SizedBox(
        width: 520,
        height: 430,
        child: Column(children: [
          TextField(
            controller: _query,
            autofocus: true,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: es ? 'Texto del mensaje' : 'Message text',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: es ? 'Buscar' : 'Search',
                onPressed: _loading ? null : _search,
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 8),
          if (_searched && _results.isNotEmpty)
            Text(
                es
                    ? 'Selecciona un mensaje para responderle.'
                    : 'Select a message to reply to.',
                style: Theme.of(context).textTheme.labelSmall),
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : !_searched
                      ? Center(
                          child: Text(es
                              ? 'Busca en todo el historial de este chat.'
                              : 'Search this chat’s full history.'))
                      : _results.isEmpty
                          ? Center(
                              child: Text(
                                  es ? 'No hay resultados.' : 'No results.'))
                          : ListView.builder(
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final message = _results[index];
                                return ListTile(
                                  title: Text(message.senderName, maxLines: 1),
                                  subtitle: Text(message.body,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis),
                                  trailing: Text(DateFormat('dd/MM/yy')
                                      .format(message.createdAt.toLocal())),
                                  onTap: () => Navigator.pop(context, message),
                                );
                              },
                            )),
          if (_searched && _results.length == 40)
            Text(es
                ? 'Mostrando los 40 resultados más recientes.'
                : 'Showing the 40 most recent results.'),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(es ? 'Cerrar' : 'Close'))
      ],
    );
  }
}
