import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/statements/models/statement_expense_suggestion.dart';
import 'package:hexora/b-backend/statements/statements_api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const bool useAggregatedStatementsEntries = true;

class LinkInvoiceOutcome {
  final bool success;
  final bool alreadyLinked;
  final int? linkedEntriesCount;
  final String? linkedEntryId;
  final bool hasRepetitiveInvoiceLink;
  final int invoiceLinkedRowsCount;
  final int invoiceLinkedOtherRowsCount;
  final int? statusCode;
  final String? errorMessage;

  const LinkInvoiceOutcome({
    required this.success,
    this.alreadyLinked = false,
    this.linkedEntriesCount,
    this.linkedEntryId,
    this.hasRepetitiveInvoiceLink = false,
    this.invoiceLinkedRowsCount = 0,
    this.invoiceLinkedOtherRowsCount = 0,
    this.statusCode,
    this.errorMessage,
  });
}

class StatementsController extends ChangeNotifier {
  StatementsController({
    StatementsApi? api,
    ClientsApi? clientsApi,
    this.groupId,
    bool useAggregated = useAggregatedStatementsEntries,
  })  : _api = api ?? StatementsApi(),
        _clientsApi = clientsApi ?? ClientsApi(),
        useAggregatedEntriesFlag = useAggregated;

  bool _isDisposed = false;

  final StatementsApi _api;
  final ClientsApi _clientsApi;
  final String? groupId;
  final bool useAggregatedEntriesFlag;
  static const int _allEntriesBatchConcurrency = 3;
  bool _didAggregated404Fallback = false;
  bool get isUsingAggregatedEntriesPath =>
      useAggregatedEntriesFlag && !_didAggregated404Fallback;

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
  String entriesOrder = 'source';

  // Client linking + suggestions
  final Map<String, bool> loadingSuggestions = {};
  final Map<String, String?> suggestionsError = {};
  final Map<String, List<Map<String, dynamic>>> suggestions = {};

  // Invoice suggestions
  final Map<String, bool> loadingInvoiceSuggestions = {};
  final Map<String, String?> invoiceSuggestionsError = {};
  final Map<String, List<Map<String, dynamic>>> invoiceSuggestions = {};
  final Map<String, bool> loadingExpenseSuggestions = {};
  final Map<String, String?> expenseSuggestionsError = {};
  final Map<String, List<StatementExpenseSuggestion>> expenseSuggestions = {};

  final Map<String, bool> linkingClient = {};
  final Map<String, String?> linkClientError = {};
  final Map<String, bool> linkingInvoice = {};
  final Map<String, String?> linkInvoiceError = {};
  final Map<String, bool> savingEntryNotes = {};
  final Map<String, String?> entryNotesError = {};

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
  int allEntriesSize = 50;
  int allEntriesPage = 1;
  int allEntriesTotal = 0;
  int allEntriesTotalPages = 1;
  String? allEntriesNextCursor;
  final Map<int, String?> _allEntriesCursorByPage = <int, String?>{1: null};
  int? allEntriesYear;
  String? allEntriesDateFrom;
  String? allEntriesDateTo;
  String allEntriesAmountType = 'all';
  double? allEntriesMinAmount;
  double? allEntriesMaxAmount;
  String? allEntriesClientProviderQuery;
  String allEntriesSort = 'date_desc';

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

  void _repairHotReloadState() {
    final self = this as dynamic;
    self.uploading ??= false;
    self.loadingImports ??= false;
    self.loadingEntries ??= false;
    self.entriesPage ??= 1;
    self.entriesSize ??= 100;
    self.entriesTotal ??= 0;
    self.loadingClients ??= false;
    self.loadingSummary ??= false;
    self.summaryGroup ??= 'month';
    self.loadingAllEntries ??= false;
    self.allEntriesSize ??= 50;
    self.allEntriesPage ??= 1;
    self.allEntriesTotal ??= 0;
    self.allEntriesTotalPages ??= 1;
    self.allEntriesAmountType ??= 'all';
    self.allEntriesSort ??= 'date_desc';
    self.statusThreshold ??= 3;
    self.imports ??= <Map<String, dynamic>>[];
    self.entries ??= <Map<String, dynamic>>[];
    self.clients ??= <Map<String, dynamic>>[];
    self.summary ??= <Map<String, dynamic>>[];
    self.allEntries ??= <Map<String, dynamic>>[];
    final cursors = self._allEntriesCursorByPage;
    if (cursors is Map<int, String?>) {
      if (!cursors.containsKey(1)) {
        cursors[1] = null;
      }
    }
  }

  Future<Map<String, dynamic>?> importStatement({
    required List<int> bytes,
    required String filename,
  }) async {
    _repairHotReloadState();
    uploading = true;
    uploadError = null;
    _notify();
    try {
      final r = await _api.importStatement(
        bytes: bytes,
        filename: filename,
        groupId: groupId,
      );
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
      _notify();
    }
  }

  Future<void> listImports() async {
    _repairHotReloadState();
    loadingImports = true;
    importsError = null;
    _notify();
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
      _notify();
    }
  }

  Future<void> fetchBatchEntries(
    String batchId, {
    int? page,
    int? size,
    int? year,
    String? dateFrom,
    String? dateTo,
    String? order,
  }) async {
    selectedBatchId = batchId;
    loadingEntries = true;
    entriesError = null;
    if (page != null) entriesPage = page;
    if (size != null) entriesSize = size;
    if (year != null) entriesYear = year;
    if (dateFrom != null) entriesDateFrom = dateFrom;
    if (dateTo != null) entriesDateTo = dateTo;
    if (order != null) entriesOrder = order;
    _notify();
    try {
      if (kDebugMode) {
        debugPrint(
          '[Statements] fetchBatchEntries batch=$batchId page=$entriesPage size=$entriesSize '
          'year=$entriesYear from=$entriesDateFrom to=$entriesDateTo order=$entriesOrder',
        );
      }
      final r = await _api.batchEntriesPaged(
        batchId: batchId,
        page: entriesPage,
        size: entriesSize,
        year: entriesYear,
        dateFrom: entriesDateFrom,
        dateTo: entriesDateTo,
        order: entriesOrder,
      );
      entries = (r['entries'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => _normalizeEntry(Map<String, dynamic>.from(e)))
          .toList();
      entriesTotal = (r['total'] is int) ? r['total'] as int : entries.length;
      if (kDebugMode) {
        final firstDate =
            _entryDateText(entries.isNotEmpty ? entries.first : null);
        final lastDate =
            _entryDateText(entries.isNotEmpty ? entries.last : null);
        debugPrint(
          '[Statements] entries loaded batch=$batchId count=${entries.length} total=$entriesTotal '
          'firstDate=$firstDate lastDate=$lastDate',
        );
      }
    } catch (e) {
      entriesError = e.toString();
    } finally {
      loadingEntries = false;
      _notify();
    }
  }

  Future<void> fetchBatchStatus(String batchId, {int? threshold}) async {
    loadingStatus[batchId] = true;
    statusError[batchId] = null;
    _notify();
    try {
      final t = threshold ?? statusThreshold;
      final r = await _api.batchStatus(batchId: batchId, threshold: t);
      batchStatus[batchId] = r;
    } catch (e) {
      statusError[batchId] = e.toString();
    } finally {
      loadingStatus[batchId] = false;
      _notify();
    }
  }

  Future<void> fetchReminderSettings(String batchId) async {
    loadingReminderSettings[batchId] = true;
    reminderSettingsError[batchId] = null;
    _notify();
    try {
      final r = await _api.reminderSettings(batchId: batchId);
      final reminder = (r['reminder'] is Map)
          ? Map<String, dynamic>.from(r['reminder'] as Map)
          : (Map<String, dynamic>.from(r));
      reminderSettings[batchId] = reminder;
    } catch (e) {
      reminderSettingsError[batchId] = e.toString();
    } finally {
      loadingReminderSettings[batchId] = false;
      _notify();
    }
  }

  Future<Map<String, dynamic>?> saveReminderSettings(
    String batchId, {
    required bool enabled,
    int? thresholdDays,
  }) async {
    savingReminderSettings[batchId] = true;
    saveReminderSettingsError[batchId] = null;
    _notify();
    try {
      final r = await _api.updateReminderSettings(
        batchId: batchId,
        enabled: enabled,
        thresholdDays: thresholdDays,
      );
      final reminder = (r['reminder'] is Map)
          ? Map<String, dynamic>.from(r['reminder'] as Map)
          : (Map<String, dynamic>.from(r));
      reminderSettings[batchId] = reminder;
      return reminder;
    } catch (e) {
      saveReminderSettingsError[batchId] = e.toString();
      return null;
    } finally {
      savingReminderSettings[batchId] = false;
      _notify();
    }
  }

  Future<Map<String, dynamic>?> notifyBatchStale(String batchId,
      {int? threshold}) async {
    notifyingStatus[batchId] = true;
    notifyError[batchId] = null;
    _notify();
    try {
      final t = threshold ?? statusThreshold;
      final r = await _api.notifyStale(batchId: batchId, threshold: t);
      return r;
    } catch (e) {
      notifyError[batchId] = e.toString();
      return null;
    } finally {
      notifyingStatus[batchId] = false;
      _notify();
    }
  }

  Future<void> setStatusThreshold(int value) async {
    statusThreshold = value;
    _notify();
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
    _notify();
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
      _notify();
    }
  }

  Future<List<Map<String, dynamic>>> suggestClients(String entryId) async {
    loadingSuggestions[entryId] = true;
    suggestionsError[entryId] = null;
    _notify();
    try {
      final r = await _api.suggestClients(entryId);
      suggestions[entryId] = r;
      return r;
    } catch (e) {
      suggestionsError[entryId] = e.toString();
      return const [];
    } finally {
      loadingSuggestions[entryId] = false;
      _notify();
    }
  }

  Future<List<Map<String, dynamic>>> suggestInvoices(
    String entryId, {
    String? type,
    double tolerance = 0.01,
    int limit = 10,
  }) async {
    loadingInvoiceSuggestions[entryId] = true;
    invoiceSuggestionsError[entryId] = null;
    _notify();
    try {
      final r = await _api.suggestInvoices(
        entryId,
        type: type,
        tolerance: tolerance,
        limit: limit,
        groupId: groupId,
      );
      final list = (r['suggestions'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => _normalizeInvoiceSuggestion(Map<String, dynamic>.from(e)))
          .toList();
      invoiceSuggestions[entryId] = list;
      return list;
    } catch (e) {
      invoiceSuggestionsError[entryId] = e.toString();
      return const [];
    } finally {
      loadingInvoiceSuggestions[entryId] = false;
      _notify();
    }
  }

  Future<List<StatementExpenseSuggestion>> suggestExpenses(
    String entryId, {
    double tolerance = 0.01,
    int limit = 10,
  }) async {
    loadingExpenseSuggestions[entryId] = true;
    expenseSuggestionsError[entryId] = null;
    _notify();
    try {
      final r = await _api.suggestExpenses(
        entryId,
        tolerance: tolerance,
        limit: limit,
        groupId: groupId,
      );
      expenseSuggestions[entryId] = r;
      return r;
    } catch (e) {
      expenseSuggestionsError[entryId] = e.toString();
      return const <StatementExpenseSuggestion>[];
    } finally {
      loadingExpenseSuggestions[entryId] = false;
      _notify();
    }
  }

  Future<void> linkClient({required String entryId, String? clientId}) async {
    linkingClient[entryId] = true;
    linkClientError[entryId] = null;
    _notify();
    try {
      await _api.linkEntryClient(entryId: entryId, clientId: clientId);
      // Resolve client name for local display
      String? resolvedName;
      if (clientId != null) {
        final match = clients.firstWhere(
          (c) =>
              c['id']?.toString() == clientId ||
              c['_id']?.toString() == clientId,
          orElse: () => const <String, dynamic>{},
        );
        resolvedName = match['name']?.toString();
      }
      final idx = entries
          .indexWhere((e) => (e['_id'] ?? e['id'])?.toString() == entryId);
      if (idx >= 0) {
        final updated = Map<String, dynamic>.from(entries[idx]);
        updated['clientId'] = clientId;
        if (resolvedName != null) updated['clientName'] = resolvedName;
        entries = List<Map<String, dynamic>>.from(entries)..[idx] = updated;
      }
      final allIdx = allEntries
          .indexWhere((e) => (e['_id'] ?? e['id'])?.toString() == entryId);
      if (allIdx >= 0) {
        final updated = Map<String, dynamic>.from(allEntries[allIdx]);
        updated['clientId'] = clientId;
        if (resolvedName != null) updated['clientName'] = resolvedName;
        allEntries = List<Map<String, dynamic>>.from(allEntries)
          ..[allIdx] = updated;
      }
    } catch (e) {
      linkClientError[entryId] = e.toString();
    } finally {
      linkingClient[entryId] = false;
      _notify();
    }
  }

  Future<String?> updateEntryNotes({
    required String entryId,
    required String notes,
  }) async {
    final normalizedNotes = notes.trim();
    savingEntryNotes[entryId] = true;
    entryNotesError[entryId] = null;
    _notify();
    try {
      final response = await _api.updateEntryNotes(
        entryId: entryId,
        notes: normalizedNotes.isEmpty ? null : normalizedNotes,
      );
      final savedNotes = response['notes']?.toString();

      void applyLocalUpdate(
        List<Map<String, dynamic>> source,
        void Function(List<Map<String, dynamic>>) assign,
      ) {
        final idx = source
            .indexWhere((e) => (e['_id'] ?? e['id'])?.toString() == entryId);
        if (idx < 0) return;
        final updated = Map<String, dynamic>.from(source[idx]);
        updated['notes'] = savedNotes;
        final next = List<Map<String, dynamic>>.from(source)..[idx] = updated;
        assign(next);
      }

      applyLocalUpdate(entries, (next) => entries = next);
      applyLocalUpdate(allEntries, (next) => allEntries = next);
      return savedNotes;
    } catch (e) {
      entryNotesError[entryId] = e.toString();
      rethrow;
    } finally {
      savingEntryNotes[entryId] = false;
      _notify();
    }
  }

  Future<LinkInvoiceOutcome> linkInvoice({
    required String entryId,
    String? invoiceId,
    List<String>? invoiceIds,
    String? invoiceDisplayNumber,
    String? counterpartyName,
    required bool expenseOnly,
  }) async {
    linkingInvoice[entryId] = true;
    linkInvoiceError[entryId] = null;
    _notify();
    try {
      final normalizedInvoiceIds = (invoiceIds ?? const <String>[])
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      final requestInvoiceIds = normalizedInvoiceIds.isNotEmpty
          ? normalizedInvoiceIds
          : (invoiceId != null && invoiceId.trim().isNotEmpty)
              ? <String>[invoiceId.trim()]
              : <String>[];
      final response = expenseOnly
          ? await _api.linkEntryInvoiceExpense(
              entryId: entryId,
              invoiceId: invoiceId,
              invoiceIds:
                  requestInvoiceIds.isNotEmpty ? requestInvoiceIds : null,
            )
          : await _api.linkEntryInvoice(
              entryId: entryId,
              invoiceId: invoiceId,
              invoiceIds:
                  requestInvoiceIds.isNotEmpty ? requestInvoiceIds : null,
            );

      final alreadyLinked = response['invoiceAlreadyLinked'] == true ||
          response['invoice_already_linked'] == true;
      final linkedEntriesCount = (response['invoiceLinkedEntriesCount'] ??
              response['invoice_linked_entries_count']) is num
          ? ((response['invoiceLinkedEntriesCount'] ??
                  response['invoice_linked_entries_count']) as num)
              .toInt()
          : null;
      final linkedEntryId =
          (response['linkedEntryId'] ?? response['linked_entry_id'])
              ?.toString();
      Map<String, dynamic>? normalizedEntry;
      final payloadEntry = response['entry'];
      if (payloadEntry is Map) {
        normalizedEntry = _normalizeEntry(
          Map<String, dynamic>.from(payloadEntry),
        );
      }

      final topLevelInvoiceNumber =
          (response['invoiceNumber'] ?? response['invoice_number'])
              ?.toString()
              .trim();
      List<String> extractStringList(dynamic raw) {
        if (raw is List) {
          return raw
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toList(growable: false);
        }
        return const <String>[];
      }

      final topLevelInvoiceIds = extractStringList(response['invoiceIds']);
      final topLevelInvoiceNumbers =
          extractStringList(response['invoiceNumbers']);

      final effectiveDisplayNumber = (normalizedEntry?['invoiceNumber']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true)
          ? normalizedEntry!['invoiceNumber'].toString().trim()
          : (topLevelInvoiceNumber != null && topLevelInvoiceNumber.isNotEmpty)
              ? topLevelInvoiceNumber
              : (invoiceDisplayNumber != null &&
                      invoiceDisplayNumber.trim().isNotEmpty)
                  ? invoiceDisplayNumber.trim()
                  : null;
      final effectiveInvoiceIds = (() {
        final fromEntry = extractStringList(normalizedEntry?['invoiceIds']);
        if (fromEntry.isNotEmpty) return fromEntry;
        if (topLevelInvoiceIds.isNotEmpty) return topLevelInvoiceIds;
        if (requestInvoiceIds.isNotEmpty) return requestInvoiceIds;
        final legacy = (invoiceId ?? '').trim();
        return legacy.isEmpty ? const <String>[] : <String>[legacy];
      })();
      final effectiveInvoiceNumbers = (() {
        final fromEntry = extractStringList(normalizedEntry?['invoiceNumbers']);
        if (fromEntry.isNotEmpty) return fromEntry;
        if (topLevelInvoiceNumbers.isNotEmpty) return topLevelInvoiceNumbers;
        if (effectiveDisplayNumber != null &&
            effectiveDisplayNumber.isNotEmpty) {
          return <String>[effectiveDisplayNumber];
        }
        return const <String>[];
      })();
      final hasRepetitiveInvoiceLink =
          (normalizedEntry?['hasRepetitiveInvoiceLink'] == true) ||
              (response['hasRepetitiveInvoiceLink'] == true) ||
              (response['has_repetitive_invoice_link'] == true);
      final invoiceLinkedRowsCount =
          (normalizedEntry?['invoiceLinkedRowsCount'] is num)
              ? (normalizedEntry!['invoiceLinkedRowsCount'] as num).toInt()
              : ((response['invoiceLinkedRowsCount'] ??
                      response['invoice_linked_rows_count']) is num)
                  ? ((response['invoiceLinkedRowsCount'] ??
                          response['invoice_linked_rows_count']) as num)
                      .toInt()
                  : 0;
      final invoiceLinkedOtherRowsCount =
          (normalizedEntry?['invoiceLinkedOtherRowsCount'] is num)
              ? (normalizedEntry!['invoiceLinkedOtherRowsCount'] as num).toInt()
              : ((response['invoiceLinkedOtherRowsCount'] ??
                      response['invoice_linked_other_rows_count']) is num)
                  ? ((response['invoiceLinkedOtherRowsCount'] ??
                          response['invoice_linked_other_rows_count']) as num)
                      .toInt()
                  : 0;

      void applyLocalUpdate(List<Map<String, dynamic>> source,
          void Function(List<Map<String, dynamic>>) assign) {
        final idx = source
            .indexWhere((e) => (e['_id'] ?? e['id'])?.toString() == entryId);
        if (idx < 0) return;
        final current = Map<String, dynamic>.from(source[idx]);
        final updated = normalizedEntry != null
            ? (Map<String, dynamic>.from(current)..addAll(normalizedEntry))
            : current;
        final primaryId =
            effectiveInvoiceIds.isNotEmpty ? effectiveInvoiceIds.first : null;
        final primaryNumber = effectiveInvoiceNumbers.isNotEmpty
            ? effectiveInvoiceNumbers.first
            : (effectiveDisplayNumber?.trim().isNotEmpty == true
                ? effectiveDisplayNumber!.trim()
                : null);
        updated['invoiceId'] = primaryId;
        updated['invoice_id'] = primaryId;
        updated['invoiceIds'] = effectiveInvoiceIds;
        if (primaryNumber != null && primaryNumber.isNotEmpty) {
          updated['invoiceNumber'] = primaryNumber;
          updated['invoice_number'] = primaryNumber;
        }
        updated['invoiceNumbers'] = effectiveInvoiceNumbers;
        final resolvedCounterparty = (counterpartyName ?? '').trim();
        if (resolvedCounterparty.isNotEmpty) {
          updated['counterpartyName'] = resolvedCounterparty;
          if (expenseOnly) {
            updated['providerName'] = resolvedCounterparty;
            updated['vendorName'] = resolvedCounterparty;
          } else {
            updated['clientName'] = resolvedCounterparty;
          }
        }
        final next = List<Map<String, dynamic>>.from(source)..[idx] = updated;
        assign(next);
      }

      applyLocalUpdate(entries, (next) => entries = next);
      applyLocalUpdate(allEntries, (next) => allEntries = next);

      return LinkInvoiceOutcome(
        success: true,
        alreadyLinked: alreadyLinked,
        linkedEntriesCount: linkedEntriesCount,
        linkedEntryId: linkedEntryId,
        hasRepetitiveInvoiceLink: hasRepetitiveInvoiceLink,
        invoiceLinkedRowsCount: invoiceLinkedRowsCount,
        invoiceLinkedOtherRowsCount: invoiceLinkedOtherRowsCount,
      );
    } catch (e) {
      linkInvoiceError[entryId] = e.toString();
      if (e is StatementsApiException) {
        String message = e.message;
        if (e.statusCode == 404 &&
            (e.responseBody?.trim().isNotEmpty ?? false)) {
          try {
            final decoded = jsonDecode(e.responseBody!);
            if (decoded is Map && decoded['missingInvoiceIds'] is List) {
              final ids = (decoded['missingInvoiceIds'] as List)
                  .map((v) => v?.toString().trim() ?? '')
                  .where((v) => v.isNotEmpty)
                  .toList(growable: false);
              if (ids.isNotEmpty) {
                message = '${e.message} (${ids.join(', ')})';
              }
            }
          } catch (_) {}
        }
        return LinkInvoiceOutcome(
          success: false,
          statusCode: e.statusCode,
          errorMessage: message,
        );
      }
      return LinkInvoiceOutcome(
        success: false,
        errorMessage: e.toString(),
      );
    } finally {
      linkingInvoice[entryId] = false;
      _notify();
    }
  }

  Future<void> refreshEntryCollections() async {
    await loadAllEntries(
      size: allEntriesSize,
      year: allEntriesYear,
      dateFrom: allEntriesDateFrom ?? '',
      dateTo: allEntriesDateTo ?? '',
      page: allEntriesPage,
      amountType: allEntriesAmountType,
      minAmount: allEntriesMinAmount,
      maxAmount: allEntriesMaxAmount,
      sort: allEntriesSort,
      applyAmountFilters: true,
    );

    final batchId = (selectedBatchId ?? '').trim();
    if (batchId.isEmpty) return;

    await fetchBatchEntries(
      batchId,
      page: entriesPage,
      size: entriesSize,
      year: entriesYear,
      dateFrom: entriesDateFrom ?? '',
      dateTo: entriesDateTo ?? '',
      order: entriesOrder,
    );
  }

  void applyEntryUpdate(Map<String, dynamic> payloadEntry) {
    final normalizedEntry = _normalizeEntry(
      Map<String, dynamic>.from(payloadEntry),
    );
    final entryId =
        (normalizedEntry['_id'] ?? normalizedEntry['id'])?.toString().trim() ??
            '';
    if (entryId.isEmpty) return;

    void applyLocalUpdate(
      List<Map<String, dynamic>> source,
      void Function(List<Map<String, dynamic>>) assign,
    ) {
      final idx = source
          .indexWhere((e) => (e['_id'] ?? e['id'])?.toString() == entryId);
      if (idx < 0) return;
      final current = Map<String, dynamic>.from(source[idx]);
      final updated = Map<String, dynamic>.from(current)
        ..addAll(normalizedEntry);
      final next = List<Map<String, dynamic>>.from(source)..[idx] = updated;
      assign(next);
    }

    applyLocalUpdate(entries, (next) => entries = next);
    applyLocalUpdate(allEntries, (next) => allEntries = next);
    _notify();
  }

  Future<void> loadClients() async {
    _repairHotReloadState();
    if (loadingClients) return;
    loadingClients = true;
    clientsError = null;
    _notify();
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
      _notify();
    }
  }

  Future<http.Response> exportAllEntriesExcel({
    int? year,
    String? dateFrom,
    String? dateTo,
    String amountType = 'all',
    double? minAmount,
    double? maxAmount,
    String? clientProviderQuery,
    String? sort,
  }) {
    final gid = (groupId ?? '').trim();
    if (gid.isEmpty) {
      throw StateError('Select a group first.');
    }
    return _api.exportEntriesExcel(
      groupId: gid,
      year: year,
      dateFrom: dateFrom,
      dateTo: dateTo,
      amountType: amountType,
      minAmount: minAmount,
      maxAmount: maxAmount,
      clientProviderQuery: clientProviderQuery,
      sort: sort,
    );
  }

  Future<void> loadAllEntries({
    int? size,
    int? year,
    String? dateFrom,
    String? dateTo,
    int? page,
    String? amountType,
    double? minAmount,
    double? maxAmount,
    String? clientProviderQuery,
    String? sort,
    String? cursor,
    bool applyAmountFilters = false,
  }) async {
    _repairHotReloadState();
    if (loadingAllEntries) return;
    loadingAllEntries = true;
    allEntriesError = null;
    if (size != null) allEntriesSize = size;
    allEntriesYear = year;
    if (dateFrom != null) {
      final trimmed = dateFrom.trim();
      allEntriesDateFrom = trimmed.isEmpty ? null : trimmed;
    }
    if (dateTo != null) {
      final trimmed = dateTo.trim();
      allEntriesDateTo = trimmed.isEmpty ? null : trimmed;
    }
    if (page != null) {
      allEntriesPage = page;
    } else {
      allEntriesPage = 1;
    }
    if (sort != null && sort.trim().isNotEmpty) {
      allEntriesSort = sort.trim();
    }
    if (applyAmountFilters) {
      allEntriesAmountType = amountType ?? 'all';
      allEntriesMinAmount = minAmount;
      allEntriesMaxAmount = maxAmount;
      final trimmedClientProvider = clientProviderQuery?.trim() ?? '';
      allEntriesClientProviderQuery =
          trimmedClientProvider.isEmpty ? null : trimmedClientProvider;
    } else if (amountType != null && amountType.trim().isNotEmpty) {
      allEntriesAmountType = amountType.trim();
    }

    if (allEntriesPage <= 1) {
      _allEntriesCursorByPage
        ..clear()
        ..[1] = null;
      allEntriesNextCursor = null;
    }
    _notify();
    try {
      if (kDebugMode) {
        debugPrint(
          '[Statements] loadAllEntries size=$allEntriesSize page=$allEntriesPage '
          'year=$allEntriesYear from=$allEntriesDateFrom to=$allEntriesDateTo '
          'amountType=$allEntriesAmountType min=$allEntriesMinAmount max=$allEntriesMaxAmount '
          'clientProvider=$allEntriesClientProviderQuery sort=$allEntriesSort groupId=$groupId',
        );
      }

      if (useAggregatedEntriesFlag) {
        try {
          await _loadAllEntriesAggregated(
            explicitCursor: cursor,
          );
          return;
        } on StatementsApiException catch (e) {
          if (e.statusCode == 404 && !_didAggregated404Fallback) {
            _didAggregated404Fallback = true;
            if (kDebugMode) {
              debugPrint(
                '[Statements] WARNING: aggregated /entries not found (404). '
                'Falling back to legacy per-batch loading.',
              );
            }
            await _loadAllEntriesLegacy();
            return;
          }
          rethrow;
        }
      }
      await _loadAllEntriesLegacy();
    } on StatementsApiException catch (e) {
      if (e.statusCode == 400 &&
          e.message.toLowerCase().contains('groupid') &&
          e.message.toLowerCase().contains('required')) {
        allEntriesError = 'Select a group first.';
      } else if (e.statusCode == 403) {
        allEntriesError = 'You don\'t have access to this group.';
      } else if (e.statusCode == 401) {
        // Keep existing auth refresh/login flow unchanged.
        allEntriesError = e.toString();
      } else {
        allEntriesError = e.toString();
      }
    } catch (e) {
      allEntriesError = e.toString();
    } finally {
      loadingAllEntries = false;
      _notify();
    }
  }

  Future<void> _loadAllEntriesAggregated({String? explicitCursor}) async {
    _repairHotReloadState();
    final gid = (groupId ?? '').trim();
    if (gid.isEmpty) {
      allEntriesError = 'Select a group first.';
      return;
    }

    final page = allEntriesPage < 1 ? 1 : allEntriesPage;
    final size = allEntriesSize <= 0 ? 50 : allEntriesSize;
    final chainedCursor = _allEntriesCursorByPage[page];
    final cursorToUse =
        (explicitCursor != null && explicitCursor.trim().isNotEmpty)
            ? explicitCursor.trim()
            : (chainedCursor != null && chainedCursor.isNotEmpty
                ? chainedCursor
                : null);

    if (kDebugMode) {
      debugPrint(
        '[Statements] aggregated request groupId=$gid page=$page size=$size '
        'cursor=$cursorToUse year=$allEntriesYear from=$allEntriesDateFrom to=$allEntriesDateTo '
        'amountType=$allEntriesAmountType min=$allEntriesMinAmount max=$allEntriesMaxAmount '
        'clientProvider=$allEntriesClientProviderQuery sort=$allEntriesSort',
      );
    }

    final payload = await _api.fetchStatementEntries(
      groupId: gid,
      page: page,
      size: size,
      cursor: cursorToUse,
      year: allEntriesYear,
      dateFrom: allEntriesDateFrom == null
          ? null
          : DateTime.tryParse(allEntriesDateFrom!),
      dateTo: allEntriesDateTo == null
          ? null
          : DateTime.tryParse(allEntriesDateTo!),
      amountType: allEntriesAmountType,
      minAmount: allEntriesMinAmount,
      maxAmount: allEntriesMaxAmount,
      clientProviderQuery: allEntriesClientProviderQuery,
      sort: allEntriesSort,
    );

    allEntriesPage = payload.page < 1 ? page : payload.page;
    allEntriesSize = payload.size;
    allEntriesTotal = payload.total;
    allEntriesTotalPages = payload.totalPages < 1 ? 1 : payload.totalPages;
    allEntriesNextCursor = payload.nextCursor;

    final incoming = payload.items.map((e) => _normalizeEntry(e.raw)).toList();
    final shouldAppend =
        cursorToUse != null && cursorToUse.isNotEmpty && page > 1;
    if (shouldAppend) {
      allEntries = _dedupeById([...allEntries, ...incoming]);
    } else {
      allEntries = incoming;
    }

    if (payload.nextCursor != null && payload.nextCursor!.isNotEmpty) {
      _allEntriesCursorByPage[allEntriesPage + 1] = payload.nextCursor;
    } else if (allEntriesPage < allEntriesTotalPages) {
      _allEntriesCursorByPage.remove(allEntriesPage + 1);
    }

    if (kDebugMode) {
      debugPrint(
        '[Statements] aggregated response items=${payload.items.length} '
        'page=${payload.page}/${payload.totalPages} total=${payload.total} '
        'nextCursor=${payload.nextCursor} timing.dbMs=${payload.timing?.dbMs} '
        'timing.totalMs=${payload.timing?.totalMs}',
      );
    }
  }

  Future<void> _loadAllEntriesLegacy() async {
    _repairHotReloadState();
    if (imports.isEmpty) {
      imports = await _api.listImports();
    }
    allEntries = const [];
    allEntriesTotal = 0;
    allEntriesTotalPages = 1;
    allEntriesNextCursor = null;
    _notify();
    final progressive = <Map<String, dynamic>>[];
    final batchIds = imports
        .map((batch) =>
            (batch['batchId'] ?? batch['_id'] ?? batch['id'])?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final batchJobs = batchIds
        .map<Future<List<Map<String, dynamic>>> Function()>(
          (batchId) => () => _loadAllPagesForBatch(
                batchId,
                onPageLoaded: (pageEntries) {
                  progressive.addAll(pageEntries);
                  allEntries = List<Map<String, dynamic>>.from(progressive);
                  allEntriesTotal = allEntries.length;
                  allEntriesTotalPages = 1;
                  _notify();
                },
              ),
        )
        .toList(growable: false);

    final loadedByBatch = await _runWithConcurrency(
      batchJobs,
      maxConcurrent: _allEntriesBatchConcurrency,
    );
    allEntries = loadedByBatch.expand((e) => e).toList(growable: false);
    allEntriesTotal = allEntries.length;
    allEntriesTotalPages = 1;
    if (kDebugMode) {
      debugPrint('[Statements] allEntries loaded count=${allEntries.length}');
    }
  }

  List<Map<String, dynamic>> _dedupeById(List<Map<String, dynamic>> rows) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final row in rows) {
      final id = (row['_id'] ?? row['id'] ?? row['entryId'] ?? '').toString();
      final key = id.isEmpty ? jsonEncode(row) : id;
      if (seen.add(key)) out.add(row);
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _loadAllPagesForBatch(String batchId,
      {void Function(List<Map<String, dynamic>> pageEntries)?
          onPageLoaded}) async {
    final all = <Map<String, dynamic>>[];
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
          .map((e) => _normalizeEntry(Map<String, dynamic>.from(e)))
          .toList();
      if (kDebugMode) {
        final firstDate =
            _entryDateText(entries.isNotEmpty ? entries.first : null);
        final lastDate =
            _entryDateText(entries.isNotEmpty ? entries.last : null);
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
      if (onPageLoaded != null && entries.isNotEmpty) {
        onPageLoaded(
          all.sublist(all.length - entries.length),
        );
      }
      final total = (r['total'] is int) ? r['total'] as int : null;
      if (total != null) {
        totalPages =
            total == 0 ? 1 : (total / allEntriesSize).ceil().clamp(1, 9999);
      } else {
        totalPages = entries.length < allEntriesSize ? page : page + 1;
      }
      page += 1;
    } while (page <= totalPages && page <= maxPages);
    return all;
  }

  Future<List<T>> _runWithConcurrency<T>(
    List<Future<T> Function()> jobs, {
    required int maxConcurrent,
  }) async {
    if (jobs.isEmpty) return <T>[];
    final results = List<T?>.filled(jobs.length, null);
    var next = 0;

    Future<void> worker() async {
      while (true) {
        if (next >= jobs.length) break;
        final index = next;
        next += 1;
        results[index] = await jobs[index]();
      }
    }

    final workers = (maxConcurrent < 1 ? 1 : maxConcurrent);
    final workerCount = workers > jobs.length ? jobs.length : workers;
    await Future.wait(
      List<Future<void>>.generate(workerCount, (_) => worker()),
    );
    return results.cast<T>();
  }

  String _entryDateText(Map<String, dynamic>? entry) {
    if (entry == null) return '-';
    final raw = entry['date'] ?? entry['valueDate'];
    if (raw == null) return '-';
    final text = raw.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  Map<String, dynamic> _normalizeEntry(Map<String, dynamic> entry) {
    final normalized = Map<String, dynamic>.from(entry);
    List<String> toStringList(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
      return const <String>[];
    }

    final invoiceIds = toStringList(normalized['invoiceIds']);
    final invoiceNumbers = toStringList(normalized['invoiceNumbers']);
    final legacyId = (normalized['invoiceId'] ?? normalized['invoice_id'])
        ?.toString()
        .trim();
    final invoiceNumber =
        (normalized['invoiceNumber'] ?? normalized['invoice_number'])
            ?.toString()
            .trim();
    final expenseDocumentIds = toStringList(
      normalized['expenseDocumentIds'] ?? normalized['expenseIds'],
    );
    final expenseDocumentNumbers = toStringList(
      normalized['expenseDocumentNumbers'] ?? normalized['expenseNumbers'],
    );
    final legacyExpenseId = (normalized['expenseDocumentId'] ??
            normalized['expense_document_id'] ??
            normalized['expenseId'] ??
            normalized['expense_id'])
        ?.toString()
        .trim();
    final expenseDocumentNumber = (normalized['expenseDocumentNumber'] ??
            normalized['expense_document_number'] ??
            normalized['expenseNumber'] ??
            normalized['expense_number'])
        ?.toString()
        .trim();
    if (invoiceIds.isNotEmpty) {
      normalized['invoiceIds'] = invoiceIds;
      normalized['invoiceId'] = invoiceIds.first;
      normalized['invoice_id'] = invoiceIds.first;
    } else if (legacyId != null && legacyId.isNotEmpty) {
      normalized['invoiceId'] = legacyId;
      normalized['invoice_id'] = legacyId;
      normalized['invoiceIds'] = <String>[legacyId];
    } else {
      normalized['invoiceIds'] = const <String>[];
    }
    if (invoiceNumbers.isNotEmpty) {
      normalized['invoiceNumbers'] = invoiceNumbers;
      normalized['invoiceNumber'] = invoiceNumbers.first;
      normalized['invoice_number'] = invoiceNumbers.first;
    } else if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      normalized['invoiceNumber'] = invoiceNumber;
      normalized['invoice_number'] = invoiceNumber;
      normalized['invoiceNumbers'] = <String>[invoiceNumber];
    } else {
      normalized['invoiceNumbers'] = const <String>[];
    }
    if (expenseDocumentIds.isNotEmpty) {
      normalized['expenseDocumentIds'] = expenseDocumentIds;
      normalized['expenseDocumentId'] = expenseDocumentIds.first;
      normalized['expense_document_id'] = expenseDocumentIds.first;
    } else if (legacyExpenseId != null && legacyExpenseId.isNotEmpty) {
      normalized['expenseDocumentId'] = legacyExpenseId;
      normalized['expense_document_id'] = legacyExpenseId;
      normalized['expenseDocumentIds'] = <String>[legacyExpenseId];
    } else {
      normalized['expenseDocumentIds'] = const <String>[];
    }
    if (expenseDocumentNumbers.isNotEmpty) {
      normalized['expenseDocumentNumbers'] = expenseDocumentNumbers;
      normalized['expenseDocumentNumber'] = expenseDocumentNumbers.first;
      normalized['expense_document_number'] = expenseDocumentNumbers.first;
    } else if (expenseDocumentNumber != null &&
        expenseDocumentNumber.isNotEmpty) {
      normalized['expenseDocumentNumber'] = expenseDocumentNumber;
      normalized['expense_document_number'] = expenseDocumentNumber;
      normalized['expenseDocumentNumbers'] = <String>[expenseDocumentNumber];
    } else {
      normalized['expenseDocumentNumbers'] = const <String>[];
    }
    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      normalized['invoiceNumber'] = invoiceNumber;
      normalized['invoice_number'] = invoiceNumber;
    }
    final hasRepetitive = normalized['hasRepetitiveInvoiceLink'] == true ||
        normalized['has_repetitive_invoice_link'] == true;
    final linkedRowsCount = (normalized['invoiceLinkedRowsCount'] is num)
        ? (normalized['invoiceLinkedRowsCount'] as num).toInt()
        : (normalized['invoice_linked_rows_count'] is num)
            ? (normalized['invoice_linked_rows_count'] as num).toInt()
            : 0;
    final linkedOtherRowsCount =
        (normalized['invoiceLinkedOtherRowsCount'] is num)
            ? (normalized['invoiceLinkedOtherRowsCount'] as num).toInt()
            : (normalized['invoice_linked_other_rows_count'] is num)
                ? (normalized['invoice_linked_other_rows_count'] as num).toInt()
                : 0;
    normalized['hasRepetitiveInvoiceLink'] = hasRepetitive;
    normalized['has_repetitive_invoice_link'] = hasRepetitive;
    normalized['invoiceLinkedRowsCount'] = linkedRowsCount;
    normalized['invoice_linked_rows_count'] = linkedRowsCount;
    normalized['invoiceLinkedOtherRowsCount'] = linkedOtherRowsCount;
    normalized['invoice_linked_other_rows_count'] = linkedOtherRowsCount;
    return normalized;
  }

  Map<String, dynamic> _normalizeInvoiceSuggestion(Map<String, dynamic> s) {
    final normalized = Map<String, dynamic>.from(s);
    final alreadyLinked = normalized['alreadyLinked'] == true ||
        normalized['isAlreadyLinked'] == true;
    final linkedEntriesCount = (normalized['linkedEntriesCount'] is num)
        ? (normalized['linkedEntriesCount'] as num).toInt()
        : (normalized['linked_entries_count'] is num)
            ? (normalized['linked_entries_count'] as num).toInt()
            : 0;
    normalized['alreadyLinked'] = alreadyLinked;
    normalized['isAlreadyLinked'] = alreadyLinked;
    normalized['linkedEntriesCount'] = linkedEntriesCount;
    normalized['linkedEntryId'] =
        (normalized['linkedEntryId'] ?? normalized['linked_entry_id'])
            ?.toString();
    normalized['linkedEntryDate'] =
        (normalized['linkedEntryDate'] ?? normalized['linked_entry_date'])
            ?.toString();
    normalized['linkedEntryAmount'] =
        normalized['linkedEntryAmount'] ?? normalized['linked_entry_amount'];
    normalized['linkedEntryDescription'] =
        (normalized['linkedEntryDescription'] ??
                normalized['linked_entry_description'])
            ?.toString();
    return normalized;
  }

  Future<void> deleteBatch(String batchId) async {
    deletingBatch[batchId] = true;
    deleteBatchError[batchId] = null;
    _notify();
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
      _notify();
    }
  }

  Future<void> reprocessBatch(String batchId) async {
    reprocessingBatch[batchId] = true;
    reprocessBatchError[batchId] = null;
    _notify();
    try {
      await _api.reprocessBatch(batchId);
      await listImports();
      await fetchBatchEntries(batchId, page: 1);
    } catch (e) {
      reprocessBatchError[batchId] = e.toString();
    } finally {
      reprocessingBatch[batchId] = false;
      _notify();
    }
  }

  void _notify() {
    _repairHotReloadState();
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
