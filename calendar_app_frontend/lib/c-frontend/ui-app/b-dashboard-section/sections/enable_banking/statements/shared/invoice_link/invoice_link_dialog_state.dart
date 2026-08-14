import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice.dart';

/// State management for the invoice/expense link wizard dialog
class InvoiceLinkDialogState {
  // Controllers
  final TextEditingController idController;
  final bool expenseOnly;

  // Entity selection
  String? selectedClientId;
  String? selectedProviderId;
  String providerQuery = '';
  final Set<String> selectedInvoiceIds = <String>{};

  // Data caches
  final Map<String, List<Invoice>> invoiceCacheByClient = {};
  final Map<String, List<Map<String, dynamic>>> expenseCacheByProvider = {};
  List<Map<String, dynamic>> providers = const [];

  // Loading states
  bool loadingProviders = false;
  bool loadingInvoices = false;
  bool loadingExpenses = false;

  // Error states
  String? providersError;
  String? invoicesError;
  String? expensesError;

  // Wizard state
  int visibleStep = 0;
  bool confirmLink = false;

  InvoiceLinkDialogState({
    required String? currentInvoiceId,
    required List<String> currentInvoiceIds,
    required String? currentClientId,
    required String? currentProviderId,
    required this.expenseOnly,
  })  : idController = TextEditingController(text: currentInvoiceId ?? ''),
        selectedClientId = currentClientId,
        selectedProviderId = currentProviderId {
    for (final id in currentInvoiceIds) {
      final normalized = id.trim();
      if (normalized.isNotEmpty) {
        selectedInvoiceIds.add(normalized);
      }
    }
    if (!expenseOnly &&
        selectedInvoiceIds.isNotEmpty &&
        idController.text.trim().isEmpty) {
      idController.text = selectedInvoiceIds.first;
    }

    final hasCurrentDocument = expenseOnly
        ? (currentInvoiceId?.trim().isNotEmpty ?? false)
        : selectedInvoiceIds.isNotEmpty;
    // Initialize visible step based on what's already filled
    visibleStep = hasCurrentDocument
        ? 2
        : (((expenseOnly
                    ? currentProviderId?.trim().isNotEmpty
                    : currentClientId?.trim().isNotEmpty) ??
                false)
            ? 1
            : 0);
  }

  void dispose() {
    idController.dispose();
  }

  /// Get max allowed step based on current selections
  int getMaxAllowedStep(bool expenseOnly) {
    final hasClient = (selectedClientId?.trim().isNotEmpty ?? false);
    final hasProvider = (selectedProviderId?.trim().isNotEmpty ?? false);
    final hasInvoice = expenseOnly
        ? idController.text.trim().isNotEmpty
        : selectedInvoiceIds.isNotEmpty;
    final hasEntity = expenseOnly ? hasProvider : hasClient;
    return !hasEntity ? 0 : (!hasInvoice ? 1 : 2);
  }

  /// Select provider and advance to step 1
  void selectProvider(String providerId, VoidCallback onStateChanged) {
    selectedProviderId = providerId;
    expensesError = null;
    idController.clear();
    selectedInvoiceIds.clear();
    confirmLink = false;
    visibleStep = 1;
    onStateChanged();
  }

  /// Select client and advance to step 1
  void selectClient(String? clientId, VoidCallback onStateChanged) {
    selectedClientId = clientId;
    invoicesError = null;
    selectedInvoiceIds.clear();
    idController.clear();
    confirmLink = false;
    if (clientId == null || clientId.trim().isEmpty) {
      visibleStep = 0;
    } else if (visibleStep < 1) {
      visibleStep = 1;
    }
    onStateChanged();
  }

  /// Select invoice/expense and advance to step 2
  void selectDocument(String id, VoidCallback onStateChanged) {
    idController.text = id;
    if (!expenseOnly) {
      selectedInvoiceIds
        ..clear()
        ..add(id);
    }
    confirmLink = false;
    visibleStep = 2;
    onStateChanged();
  }

  void toggleInvoiceSelection(String id, VoidCallback onStateChanged) {
    if (expenseOnly) {
      selectDocument(id, onStateChanged);
      return;
    }
    final normalized = id.trim();
    if (normalized.isEmpty) return;
    if (selectedInvoiceIds.contains(normalized)) {
      selectedInvoiceIds.remove(normalized);
    } else {
      selectedInvoiceIds.add(normalized);
    }
    idController.text =
        selectedInvoiceIds.isEmpty ? '' : selectedInvoiceIds.first;
    confirmLink = false;
    // Keep the selector open so the user can combine several invoices before
    // explicitly continuing to the preview step.
    visibleStep = 1;
    onStateChanged();
  }

  /// Update text field and adjust step if needed
  void updateTextField(String value, VoidCallback onStateChanged) {
    if (!expenseOnly) return;
    confirmLink = false;
    if (value.trim().isEmpty && visibleStep > 1) {
      visibleStep = 1;
    }
    onStateChanged();
  }

  /// Find selected invoice from cached data
  Invoice? getSelectedInvoice() {
    final targetId = idController.text.trim();
    if (targetId.isEmpty) return null;
    for (final list in invoiceCacheByClient.values) {
      for (final inv in list) {
        if (inv.id == targetId) return inv;
      }
    }
    return null;
  }

  List<Invoice> getSelectedInvoices() {
    if (selectedInvoiceIds.isEmpty) return const <Invoice>[];
    final selected = <Invoice>[];
    for (final list in invoiceCacheByClient.values) {
      for (final inv in list) {
        if (selectedInvoiceIds.contains(inv.id)) {
          selected.add(inv);
        }
      }
    }
    return selected;
  }

  /// Find selected expense from cached data
  Map<String, dynamic>? getSelectedExpense() {
    final targetId = idController.text.trim();
    if (targetId.isEmpty) return null;
    for (final list in expenseCacheByProvider.values) {
      for (final doc in list) {
        final id =
            (doc['id'] ?? doc['_id'] ?? doc['expenseId'])?.toString() ?? '';
        if (id == targetId) return doc;
      }
    }
    return null;
  }
}
