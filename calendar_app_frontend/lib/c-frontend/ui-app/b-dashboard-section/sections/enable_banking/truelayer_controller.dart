import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/truelayer/truelayer_api.dart';

class TrueLayerController extends ChangeNotifier {
  TrueLayerController({TrueLayerApi? api}) : _api = api ?? TrueLayerApi();

  final TrueLayerApi _api;

  // Connect
  bool connecting = false;
  String? connectError;
  Map<String, dynamic>? connectResult;

  // Accounts
  bool loadingAccounts = false;
  String? accountsError;
  Map<String, dynamic>? accountsResult;

  // Transactions keyed by accountId
  final Map<String, bool> loadingTransactions = {};
  final Map<String, String?> transactionsError = {};
  final Map<String, Map<String, dynamic>> transactionsResult = {};

  Future<Map<String, dynamic>?> connect() async {
    connecting = true;
    connectError = null;
    notifyListeners();
    try {
      final r = await _api.connect();
      connectResult = r;
      return r;
    } catch (e) {
      connectError = e.toString();
      return null;
    } finally {
      connecting = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get accounts {
    final r = accountsResult;
    if (r == null) return const [];
    final a = r['accounts'] ?? r['data'] ?? r['items'];
    if (a is List) return a.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    return const [];
  }

  bool get accountsCached => accountsResult?['cached'] == true;
  String? get accountsWarning => accountsResult?['warning']?.toString();

  Future<void> listAccounts() async {
    loadingAccounts = true;
    accountsError = null;
    notifyListeners();
    try {
      accountsResult = await _api.accounts();
    } catch (e) {
      accountsError = e.toString();
    } finally {
      loadingAccounts = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchTransactions({
    required String accountId,
    required String from,
    required String to,
  }) async {
    loadingTransactions[accountId] = true;
    transactionsError[accountId] = null;
    notifyListeners();
    try {
      final r = await _api.transactions(
        accountId: accountId,
        from: from,
        to: to,
      );
      transactionsResult[accountId] = r;
      return r;
    } catch (e) {
      transactionsError[accountId] = e.toString();
      return null;
    } finally {
      loadingTransactions[accountId] = false;
      notifyListeners();
    }
  }
}

