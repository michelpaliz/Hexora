import 'package:hexora/l10n/app_localizations.dart';

import '../statements_controller.dart';

/// Utility functions for statements data extraction and formatting
class StatementsSharedUtils {
  /// Extract text from entry using a list of possible keys
  static String entryText(Map<String, dynamic> entry, List<String> keys) {
    for (final key in keys) {
      final v = entry[key];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  /// Get client label from entry
  static String clientLabel(
    AppLocalizations l,
    StatementsController s,
    Map<String, dynamic> entry,
  ) {
    // 1. Check entry-level name fields
    final directName = entryText(entry, ['clientName', 'client_name']);
    if (directName.isNotEmpty) return directName;

    // 2. Resolve via clientId → clients list
    final clientId = entry['clientId']?.toString();
    if (clientId == null || clientId.trim().isEmpty) {
      return l.statementsUnlinked;
    }
    final match = s.clients.firstWhere(
      (c) =>
          c['id']?.toString() == clientId || c['_id']?.toString() == clientId,
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

    // 3. Friendly fallback instead of raw ObjectId
    return l.statementsHeaderClient;
  }
}
