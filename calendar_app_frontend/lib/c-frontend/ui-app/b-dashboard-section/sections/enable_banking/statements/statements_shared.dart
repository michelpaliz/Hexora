import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'statements_controller.dart';

class StatementsShared {
  static String entryText(Map<String, dynamic> entry, List<String> keys) {
    for (final key in keys) {
      final v = entry[key];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  static String clientLabel(
    AppLocalizations l,
    StatementsController s,
    Map<String, dynamic> entry,
  ) {
    final clientId = entry['clientId']?.toString();
    if (clientId == null || clientId.trim().isEmpty) return l.statementsUnlinked;
    final match = s.clients.firstWhere(
      (c) => c['id']?.toString() == clientId || c['_id']?.toString() == clientId,
      orElse: () => const <String, dynamic>{},
    );
    if (match.isNotEmpty) {
      final name = match['name']?.toString().trim();
      final legal = (match['billing'] is Map)
          ? (match['billing'] as Map)['legalName']?.toString().trim()
          : null;
      if (name != null && name.isNotEmpty) return name;
      if (legal != null && legal.isNotEmpty) return legal;
    }
    return clientId;
  }

  static Future<void> showSuggestionsDialog(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry,
  ) async {
    final entryId = (entry['_id'] ?? entry['id'])?.toString();
    if (entryId == null || entryId.isEmpty) return;
    final options = await s.suggestClients(entryId);
    if (!context.mounted) return;
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.statementsNoSuggestions)),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l.statementsSuggestedClientsTitle),
          content: SizedBox(
            width: 420,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final opt = options[i];
                final id = opt['_id']?.toString() ?? opt['id']?.toString() ?? '';
                final name = opt['name']?.toString() ?? l.statementsUnnamedClient;
                final legal = (opt['billing'] is Map)
                    ? (opt['billing'] as Map)['legalName']?.toString()
                    : null;
                return ListTile(
                  title: Text(name),
                  subtitle: Text(
                    [if (legal != null && legal.isNotEmpty) legal, if (id.isNotEmpty) id]
                        .where((v) => v.isNotEmpty)
                        .join(' • '),
                  ),
                  onTap: () async {
                    await s.linkClient(entryId: entryId, clientId: id.isEmpty ? null : id);
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.close),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showClientPickerDialog(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry,
  ) async {
    final entryId = (entry['_id'] ?? entry['id'])?.toString();
    if (entryId == null || entryId.isEmpty) return;
    await s.loadClients();
    if (!context.mounted) return;
    String query = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = s.clients.where((c) {
              final name = c['name']?.toString().toLowerCase() ?? '';
              final legal = (c['billing'] is Map)
                  ? (c['billing'] as Map)['legalName']?.toString().toLowerCase() ?? ''
                  : '';
              return query.isEmpty || name.contains(query) || legal.contains(query);
            }).toList();
            final l = AppLocalizations.of(dialogContext)!;
            return AlertDialog(
              title: Text(l.statementsLinkClientTitle),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: l.statementsSearchClients,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    if (s.loadingClients)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    else if (s.clientsError != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          s.clientsError!,
                          style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                        ),
                      )
                    else if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(l.statementsNoClientsMatch),
                      )
                    else
                      SizedBox(
                        height: 280,
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = filtered[i];
                            final id = c['id']?.toString() ?? c['_id']?.toString() ?? '';
                            final name = c['name']?.toString() ?? l.statementsUnnamedClient;
                            final legal = (c['billing'] is Map)
                                ? (c['billing'] as Map)['legalName']?.toString()
                                : null;
                            return ListTile(
                              title: Text(name),
                              subtitle: Text(
                                [if (legal != null && legal.isNotEmpty) legal, if (id.isNotEmpty) id]
                                    .where((v) => v.isNotEmpty)
                                    .join(' • '),
                              ),
                              onTap: () async {
                                await s.linkClient(entryId: entryId, clientId: id.isEmpty ? null : id);
                                if (!dialogContext.mounted) return;
                                Navigator.of(dialogContext).pop();
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await s.linkClient(entryId: entryId, clientId: null);
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(l.statementsClearLink),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l.close),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
