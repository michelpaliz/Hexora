import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/enable_banking/enable_banking_api.dart';

import 'enable_banking_link_store.dart';

class EnableBankingController extends ChangeNotifier {
  EnableBankingController({EnableBankingApi? api}) : _api = api ?? EnableBankingApi() {
    refreshLinkStatus();
  }

  final EnableBankingApi _api;

  String country = 'ES';
  String? selectedAspspName;

  EnableBankingLinkStatus linkStatus =
      const EnableBankingLinkStatus(linked: null, sessionId: null, error: null, updatedAt: null);

  // Banks
  bool loadingBanks = false;
  String? banksError;
  List<Map<String, dynamic>> banks = const [];

  // Connect
  bool connecting = false;
  String? connectError;
  Map<String, dynamic>? connectResult;

  // Accounts
  bool loadingAccounts = false;
  String? accountsError;
  List<Map<String, dynamic>> accounts = const [];

  // Transactions keyed by accountId
  final Map<String, bool> loadingTransactions = {};
  final Map<String, String?> transactionsError = {};
  final Map<String, Map<String, dynamic>> transactionsResult = {};

  Future<void> refreshLinkStatus() async {
    linkStatus = await EnableBankingLinkStore.load();
    notifyListeners();
  }

  Future<void> clearLinkStatus() async {
    await EnableBankingLinkStore.clear();
    await refreshLinkStatus();
  }

  Future<void> listBanks({String country = 'ES'}) async {
    this.country = country;
    selectedAspspName = null;
    loadingBanks = true;
    banksError = null;
    notifyListeners();
    try {
      banks = await _api.listBanks(country: country);
    } catch (e) {
      banksError = e.toString();
    } finally {
      loadingBanks = false;
      notifyListeners();
    }
  }

  void selectAspsp(String? name) {
    selectedAspspName = (name == null || name.trim().isEmpty) ? null : name.trim();
    notifyListeners();
  }

  void setCountry(String value) {
    final v = value.trim().toUpperCase();
    if (v.isEmpty) return;
    country = v;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> connect() async {
    connecting = true;
    connectError = null;
    notifyListeners();
    try {
      final r = await _api.connect(
        country: country,
        aspspName: selectedAspspName,
      );
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

  Future<void> listAccounts() async {
    loadingAccounts = true;
    accountsError = null;
    notifyListeners();
    try {
      accounts = await _api.listAccounts();
    } catch (e) {
      accountsError = e.toString();
    } finally {
      loadingAccounts = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchTransactions({
    required String accountId,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    loadingTransactions[accountId] = true;
    transactionsError[accountId] = null;
    notifyListeners();
    try {
      final r = await _api.transactions(
        accountId: accountId,
        dateFrom: dateFrom,
        dateTo: dateTo,
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
