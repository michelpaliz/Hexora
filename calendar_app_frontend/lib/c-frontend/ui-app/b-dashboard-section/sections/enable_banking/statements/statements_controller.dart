import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/statements/statements_api.dart';

class StatementsController extends ChangeNotifier {
  StatementsController({
    StatementsApi? api,
    ClientsApi? clientsApi,
    this.groupId,
  })  : _api = api ?? StatementsApi(),
        _clientsApi = clientsApi ?? ClientsApi();

  final StatementsApi _api;
  final ClientsApi _clientsApi;
  final String? groupId;

  // Upload
  bool uploading = false;
  String? uploadError;
  Map<String, dynamic>? lastImportResult;

  // Past imports
  bool loadingImports = false;
  String? importsError;
  List<Map<String, dynamic>> imports = const [];

  // Batch entries
  String? selectedBatchId;
  bool loadingEntries = false;
  String? entriesError;
  List<Map<String, dynamic>> entries = const [];
  int entriesPage = 1;
  int entriesSize = 100;
  int entriesTotal = 0;
  int? entriesYear;
  String? entriesDateFrom;
  String? entriesDateTo;

  // Client linking + suggestions
  final Map<String, bool> loadingSuggestions = {};
  final Map<String, String?> suggestionsError = {};
  final Map<String, List<Map<String, dynamic>>> suggestions = {};

  final Map<String, bool> linkingClient = {};
  final Map<String, String?> linkClientError = {};

  // Manual client picker data
  bool loadingClients = false;
  String? clientsError;
  List<Map<String, dynamic>> clients = const [];

  // Summary
  bool loadingSummary = false;
  String? summaryError;
  String summaryGroup = 'month';
  List<Map<String, dynamic>> summary = const [];

  // Batch actions
  final Map<String, bool> deletingBatch = {};
  final Map<String, String?> deleteBatchError = {};
  final Map<String, bool> reprocessingBatch = {};
  final Map<String, String?> reprocessBatchError = {};

  // All entries (across batches)
  bool loadingAllEntries = false;
  String? allEntriesError;
  List<Map<String, dynamic>> allEntries = const [];
  int allEntriesSize = 100;
  int allEntriesPage = 1;
  int? allEntriesYear;
  String? allEntriesDateFrom;
  String? allEntriesDateTo;

  // Batch freshness status
  int statusThreshold = 3;
  final Map<String, Map<String, dynamic>> batchStatus = {};
  final Map<String, bool> loadingStatus = {};
  final Map<String, String?> statusError = {};
  final Map<String, bool> notifyingStatus = {};
  final Map<String, String?> notifyError = {};

  // Reminder settings
  final Map<String, Map<String, dynamic>> reminderSettings = {};
  final Map<String, bool> loadingReminderSettings = {};
  final Map<String, String?> reminderSettingsError = {};
  final Map<String, bool> savingReminderSettings = {};
  final Map<String, String?> saveReminderSettingsError = {};

  Future<Map<String, dynamic>?> importStatement({
    required List<int> bytes,
    required String filename,
  }) async {
    uploading = true;
    uploadError = null;
    notifyListeners();
    try {
      final r = await _api.importStatement(bytes: bytes, filename: filename);
      lastImportResult = r;
      final batchId = (r['batchId'] ?? r['_id'] ?? r['id'])?.toString();
      if (batchId != null && batchId.isNotEmpty) {
        selectedBatchId = batchId;
        await fetchBatchEntries(batchId, page: 1);
        await fetchBatchStatus(batchId);
        await fetchReminderSettings(batchId);
      }
      return r;
    } catch (e) {
      if (e is StatementsApiException && e.statusCode == 409) {
        uploadError = 'duplicate_file';
      } else {
        uploadError = e.toString();
      }
      return null;
    } finally {
      uploading = false;
      notifyListeners();
    }
  }

  Future<void> listImports() async {
    loadingImports = true;
    importsError = null;
    notifyListeners();
    try {
      imports = await _api.listImports();
      for (final b in imports) {
        final id = (b['batchId'] ?? b['_id'] ?? b['id'])?.toString() ?? '';
        if (id.isEmpty) continue;
        await fetchBatchStatus(id);
        await fetchReminderSettings(id);
      }
    } catch (e) {
      importsError = e.toString();
    } finally {
      loadingImports = false;
      notifyListeners();
    }
  }

  Future<void> fetchBatchEntries(
    String batchId, {
    int? page,
    int? size,
    int? year,
    String? dateFrom,
    String? dateTo,
  }) async {
    selectedBatchId = batchId;
    loadingEntries = true;
    entriesError = null;
    if (page != null) entriesPage = page;
    if (size != null) entriesSize = size;
    if (year != null) entriesYear = year;
    if (dateFrom != null) entriesDateFrom = dateFrom;
    if (dateTo != null) entriesDateTo = dateTo;
    notifyListeners();
    try {
      if (kDebugMode) {
        debugPrint(
          '[Statements] fetchBatchEntries batch=$batchId page=$entriesPage size=$entriesSize '
          'year=$entriesYear from=$entriesDateFrom to=$entriesDateTo',
        );
      }
      final r = await _api.batchEntriesPaged(
        batchId: batchId,
        page: entriesPage,
        size: entriesSize,
        year: entriesYear,
        dateFrom: entriesDateFrom,
        dateTo: entriesDateTo,
      );
      entries = (r['entries'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      entriesTotal = (r['total'] is int) ? r['total'] as int : entries.length;
      if (kDebugMode) {
        final firstDate = _entryDateText(entries.isNotEmpty ? entries.first : null);
        final lastDate = _entryDateText(entries.isNotEmpty ? entries.last : null);
        debugPrint(
          '[Statements] entries loaded batch=$batchId count=${entries.length} total=$entriesTotal '
          'firstDate=$firstDate lastDate=$lastDate',
        );
      }
    } catch (e) {
      entriesError = e.toString();
    } finally {
      loadingEntries = false;
      notifyListeners();
    }
  }

  Future<void> fetchBatchStatus(String batchId, {int? threshold}) async {
    loadingStatus[batchId] = true;
    statusError[batchId] = null;
    notifyListeners();
    try {
      final t = threshold ?? statusThreshold;
      final r = await _api.batchStatus(batchId: batchId, threshold: t);
      batchStatus[batchId] = r;
    } catch (e) {
      statusError[batchId] = e.toString();
    } finally {
      loadingStatus[batchId] = false;
      notifyListeners();
    }
  }

  Future<void> fetchReminderSettings(String batchId) async {
    loadingReminderSettings[batchId] = true;
    reminderSettingsError[batchId] = null;
    notifyListeners();
    try {
      final r = await _api.reminderSettings(batchId: batchId);
      final reminder = (r['reminder'] is Map)
          ? Map<String, dynamic>.from(r['reminder'] as Map)
          : (r is Map<String, dynamic>
              ? Map<String, dynamic>.from(r)
              : <String, dynamic>{});
      reminderSettings[batchId] = reminder;
    } catch (e) {
      reminderSettingsError[batchId] = e.toString();
    } finally {
      loadingReminderSettings[batchId] = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> saveReminderSettings(
    String batchId, {
    required bool enabled,
    int? thresholdDays,
  }) async {
    savingReminderSettings[batchId] = true;
    saveReminderSettingsError[batchId] = null;
    notifyListeners();
    try {
      final r = await _api.updateReminderSettings(
        batchId: batchId,
        enabled: enabled,
        thresholdDays: thresholdDays,
      );
      final reminder = (r['reminder'] is Map)
          ? Map<String, dynamic>.from(r['reminder'] as Map)
          : (r is Map<String, dynamic>
              ? Map<String, dynamic>.from(r)
              : <String, dynamic>{});
      reminderSettings[batchId] = reminder;
      return reminder;
    } catch (e) {
      saveReminderSettingsError[batchId] = e.toString();
      return null;
    } finally {
      savingReminderSettings[batchId] = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> notifyBatchStale(String batchId,
      {int? threshold}) async {
    notifyingStatus[batchId] = true;
    notifyError[batchId] = null;
    notifyListeners();
    try {
      final t = threshold ?? statusThreshold;
      final r = await _api.notifyStale(batchId: batchId, threshold: t);
      return r;
    } catch (e) {
      notifyError[batchId] = e.toString();
      return null;
    } finally {
      notifyingStatus[batchId] = false;
      notifyListeners();
    }
  }

  Future<void> setStatusThreshold(int value) async {
    statusThreshold = value;
    notifyListeners();
    for (final b in imports) {
      final id = (b['batchId'] ?? b['_id'] ?? b['id'])?.toString() ?? '';
      if (id.isEmpty) continue;
      await fetchBatchStatus(id, threshold: value);
    }
  }

  Future<void> fetchSummary({
    required String batchId,
    String? group,
    int? year,
    String? dateFrom,
    String? dateTo,
  }) async {
    if (loadingSummary) return;
    loadingSummary = true;
    summaryError = null;
    if (group != null) summaryGroup = group;
    notifyListeners();
    try {
      final r = await _api.batchSummary(
        batchId: batchId,
        group: summaryGroup,
        year: year,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      summary = (r['summary'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      summaryError = e.toString();
    } finally {
      loadingSummary = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> suggestClients(String entryId) async {
    loadingSuggestions[entryId] = true;
    suggestionsError[entryId] = null;
    notifyListeners();
    try {
      final r = await _api.suggestClients(entryId);
      suggestions[entryId] = r;
      return r;
    } catch (e) {
      suggestionsError[entryId] = e.toString();
      return const [];
    } finally {
      loadingSuggestions[entryId] = false;
      notifyListeners();
    }
  }

  Future<void> linkClient({required String entryId, String? clientId}) async {
    linkingClient[entryId] = true;
    linkClientError[entryId] = null;
    notifyListeners();
    try {
      await _api.linkEntryClient(entryId: entryId, clientId: clientId);
      final idx = entries.indexWhere((e) => (e['_id'] ?? e['id'])?.toString() == entryId);
      if (idx >= 0) {
        final updated = Map<String, dynamic>.from(entries[idx]);
        updated['clientId'] = clientId;
        entries = List<Map<String, dynamic>>.from(entries)..[idx] = updated;
      }
      final allIdx =
          allEntries.indexWhere((e) => (e['_id'] ?? e['id'])?.toString() == entryId);
      if (allIdx >= 0) {
        final updated = Map<String, dynamic>.from(allEntries[allIdx]);
        updated['clientId'] = clientId;
        allEntries = List<Map<String, dynamic>>.from(allEntries)..[allIdx] = updated;
      }
    } catch (e) {
      linkClientError[entryId] = e.toString();
    } finally {
      linkingClient[entryId] = false;
      notifyListeners();
    }
  }

  Future<void> loadClients() async {
    if (loadingClients) return;
    loadingClients = true;
    clientsError = null;
    notifyListeners();
    try {
      final list = await _clientsApi.list(groupId: groupId, active: true);
      clients = list
          .map((c) => <String, dynamic>{
                'id': c.id,
                'name': c.name,
                'billing': c.billing?.toJson(),
              })
          .toList();
    } catch (e) {
      clientsError = e.toString();
    } finally {
      loadingClients = false;
      notifyListeners();
    }
  }

  Future<void> loadAllEntries({
    int? size,
    int? year,
    String? dateFrom,
    String? dateTo,
    int? page,
  }) async {
    if (loadingAllEntries) return;
    loadingAllEntries = true;
    allEntriesError = null;
    if (size != null) allEntriesSize = size;
    if (year != null) allEntriesYear = year;
    if (dateFrom != null) allEntriesDateFrom = dateFrom;
    if (dateTo != null) allEntriesDateTo = dateTo;
    if (page != null) {
      allEntriesPage = page;
    } else {
      allEntriesPage = 1;
    }
    notifyListeners();
    try {
      if (kDebugMode) {
        debugPrint(
          '[Statements] loadAllEntries size=$allEntriesSize page=$allEntriesPage '
          'year=$allEntriesYear from=$allEntriesDateFrom to=$allEntriesDateTo',
        );
      }
      if (imports.isEmpty) {
        imports = await _api.listImports();
      }
      final all = <Map<String, dynamic>>[];
      for (final batch in imports) {
        final batchId = (batch['batchId'] ?? batch['_id'] ?? batch['id'])?.toString();
        if (batchId == null || batchId.isEmpty) continue;
        int page = 1;
        int totalPages = 1;
        const maxPages = 1000;
        do {
          if (kDebugMode) {
            debugPrint('[Statements] loadAllEntries batch=$batchId page=$page');
          }
          final r = await _api.batchEntriesPaged(
            batchId: batchId,
            page: page,
            size: allEntriesSize,
            year: allEntriesYear,
            dateFrom: allEntriesDateFrom,
            dateTo: allEntriesDateTo,
          );
          final entries = (r['entries'] as List? ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (kDebugMode) {
            final firstDate = _entryDateText(entries.isNotEmpty ? entries.first : null);
            final lastDate = _entryDateText(entries.isNotEmpty ? entries.last : null);
            debugPrint(
              '[Statements] batch=$batchId page=$page entries=${entries.length} '
              'firstDate=$firstDate lastDate=$lastDate',
            );
          }
          for (final entry in entries) {
            final withBatch = Map<String, dynamic>.from(entry);
            withBatch['_batchId'] = batchId;
            all.add(withBatch);
          }
          final total = (r['total'] is int) ? r['total'] as int : null;
          if (total != null) {
            totalPages = total == 0 ? 1 : (total / allEntriesSize).ceil().clamp(1, 9999);
          } else {
            totalPages = entries.length < allEntriesSize ? page : page + 1;
          }
          page += 1;
        } while (page <= totalPages && page <= maxPages);
      }
      allEntries = all;
      if (kDebugMode) {
        debugPrint('[Statements] allEntries loaded count=${allEntries.length}');
      }
    } catch (e) {
      allEntriesError = e.toString();
    } finally {
      loadingAllEntries = false;
      notifyListeners();
    }
  }

  String _entryDateText(Map<String, dynamic>? entry) {
    if (entry == null) return '-';
    final raw = entry['date'] ?? entry['valueDate'];
    if (raw == null) return '-';
    final text = raw.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  Future<void> deleteBatch(String batchId) async {
    deletingBatch[batchId] = true;
    deleteBatchError[batchId] = null;
    notifyListeners();
    try {
      await _api.deleteBatch(batchId);
      if (selectedBatchId == batchId) {
        selectedBatchId = null;
        entries = const [];
        entriesTotal = 0;
      }
      imports = imports.where((b) {
        final id = (b['batchId'] ?? b['_id'] ?? b['id'])?.toString();
        return id != batchId;
      }).toList();
    } catch (e) {
      deleteBatchError[batchId] = e.toString();
    } finally {
      deletingBatch[batchId] = false;
      notifyListeners();
    }
  }

  Future<void> reprocessBatch(String batchId) async {
    reprocessingBatch[batchId] = true;
    reprocessBatchError[batchId] = null;
    notifyListeners();
    try {
      await _api.reprocessBatch(batchId);
      await listImports();
      await fetchBatchEntries(batchId, page: 1);
    } catch (e) {
      reprocessBatchError[batchId] = e.toString();
    } finally {
      reprocessingBatch[batchId] = false;
      notifyListeners();
    }
  }
}
