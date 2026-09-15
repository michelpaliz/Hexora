import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';

/// Keeps the query when switching invoice tabs or returning from client details.
class MobileClientSearchList extends StatefulWidget {
  const MobileClientSearchList(
      {super.key, required this.clients, required this.itemBuilder});
  final List<GroupClient> clients;
  final Widget Function(BuildContext context, GroupClient client) itemBuilder;

  @override
  State<MobileClientSearchList> createState() => _MobileClientSearchListState();
}

class _MobileClientSearchListState extends State<MobileClientSearchList>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final es = Localizations.localeOf(context).languageCode == 'es';
    final query = _search.text.trim().toLowerCase();
    final clients = widget.clients
        .where((c) => [
              c.name,
              c.email ?? '',
              c.phone ?? '',
              c.billing?.legalName ?? ''
            ].join(' ').toLowerCase().contains(query))
        .toList();
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText:
                  es ? 'Buscar por nombre o email' : 'Search by name or email',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: es ? 'Borrar búsqueda' : 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(_search.clear),
                    ),
            ),
          )),
      if (query.isNotEmpty)
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    es
                        ? '${clients.length} resultados'
                        : '${clients.length} results',
                    style: Theme.of(context).textTheme.bodySmall))),
      Expanded(
          child: clients.isEmpty
              ? ListView(padding: const EdgeInsets.all(24), children: [
                  const Icon(Icons.search_off_rounded, size: 36),
                  const SizedBox(height: 12),
                  Text(es ? 'No se encontraron clientes' : 'No clients found',
                      textAlign: TextAlign.center),
                  TextButton(
                      onPressed: () => setState(_search.clear),
                      child: Text(es ? 'Borrar búsqueda' : 'Clear search')),
                ])
              : ListView.separated(
                  key: const PageStorageKey('invoice-clients'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: clients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) =>
                      widget.itemBuilder(context, clients[index]),
                )),
    ]);
  }
}
