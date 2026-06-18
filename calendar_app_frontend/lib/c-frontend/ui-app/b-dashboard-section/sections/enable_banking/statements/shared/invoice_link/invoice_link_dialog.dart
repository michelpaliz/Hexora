import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/providers/providers_api.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/wizard_steps_header.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../statements_controller.dart';
import '../statements_expense_upload_dialog.dart';
import 'invoice_link_confirmation.dart';
import 'invoice_link_dialog_state.dart';
import 'invoice_link_dialog_steps.dart';
import 'invoice_link_summary.dart';

/// Main dialog for linking invoices or expenses to statement entries
class InvoiceLinkDialog {
  static Future<void> show(
    BuildContext context,
    StatementsController s,
    Map<String, dynamic> entry, {
    required bool expenseOnly,
  }) async {
    final entryId = (entry['_id'] ?? entry['id'])?.toString();
    if (entryId == null || entryId.isEmpty) return;

    await s.loadClients();
    if (!context.mounted) return;

    // Extract current values from entry
    final currentInvoiceId = expenseOnly
        ? (entry['expenseDocumentId'] ??
                entry['expense_document_id'] ??
                entry['expenseDocument'])
            ?.toString()
        : (entry['invoiceId'] ?? entry['invoice_id'] ?? entry['invoice'])
            ?.toString();
    final currentInvoiceIds = expenseOnly
        ? const <String>[]
        : () {
            final raw = entry['invoiceIds'];
            if (raw is List) {
              final ids = raw
                  .map((e) => e?.toString().trim() ?? '')
                  .where((e) => e.isNotEmpty)
                  .toList(growable: false);
              if (ids.isNotEmpty) return ids;
            }
            final single =
                (entry['invoiceId'] ?? entry['invoice_id'] ?? entry['invoice'])
                    ?.toString()
                    .trim();
            return (single != null && single.isNotEmpty)
                ? <String>[single]
                : const <String>[];
          }();
    final currentClientId = entry['clientId']?.toString();
    final currentProviderId =
        (entry['providerId'] ?? entry['provider_id'] ?? entry['provider'])
            ?.toString();

    // Prepare clients list
    final pickerClients = s.clients
        .map((raw) => GroupClient.fromJson(Map<String, dynamic>.from(raw)))
        .where((c) => c.id.trim().isNotEmpty)
        .toList(growable: false);

    // Create APIs
    final invoicesApi = InvoicesApi();
    final providersApi = ProvidersApi();
    final expensesApi = ExpensesApi();

    // Create state
    final state = InvoiceLinkDialogState(
      currentInvoiceId: currentInvoiceId,
      currentInvoiceIds: currentInvoiceIds,
      currentClientId: currentClientId,
      currentProviderId: currentProviderId,
      expenseOnly: expenseOnly,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final l = AppLocalizations.of(dialogContext)!;
            final cs = Theme.of(dialogContext).colorScheme;
            final screenWidth = MediaQuery.of(dialogContext).size.width;
            final screenHeight = MediaQuery.of(dialogContext).size.height;
            final dialogWidth =
                screenWidth < 1100 ? screenWidth * 0.98 : 1040.0;
            final dialogHeight =
                (screenHeight * 0.78).clamp(420.0, 720.0).toDouble();
            final stacked = dialogWidth < 860;

            // Create steps builder
            final stepsBuilder = InvoiceLinkDialogSteps(
              state: state,
              context: dialogContext,
              cs: cs,
              l: l,
              stacked: stacked,
              groupId: s.groupId,
              pickerClients: pickerClients,
              invoicesApi: invoicesApi,
              expensesApi: expensesApi,
            );

            final maxAllowedStep = state.getMaxAllowedStep(expenseOnly);
            if (state.visibleStep > maxAllowedStep) {
              state.visibleStep = maxAllowedStep;
            }

            final currentStep = state.visibleStep;
            final steps = <Step>[
              Step(
                title: Text(expenseOnly ? 'Proveedor' : 'Facturar a'),
                subtitle: const SizedBox.shrink(),
                content: const SizedBox.shrink(),
                isActive: currentStep == 0,
                state: currentStep > 0 ? StepState.complete : StepState.editing,
              ),
              Step(
                title: Text(expenseOnly ? 'Gasto' : 'IDs de factura'),
                subtitle: const SizedBox.shrink(),
                content: const SizedBox.shrink(),
                isActive: currentStep == 1,
                state: currentStep > 1
                    ? StepState.complete
                    : (currentStep == 1
                        ? StepState.editing
                        : StepState.indexed),
              ),
              Step(
                title: const Text('Vista previa'),
                subtitle: const SizedBox.shrink(),
                content: const SizedBox.shrink(),
                isActive: currentStep == 2,
                state: currentStep == 2 ? StepState.editing : StepState.indexed,
              ),
            ];

            // Load data as needed
            _loadDataAsNeeded(
              dialogContext,
              state,
              s,
              expenseOnly,
              providersApi,
              invoicesApi,
              expensesApi,
              setState,
            );

            return AlertDialog(
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              actionsAlignment: MainAxisAlignment.spaceBetween,
              title: const Center(child: Text('Vincular factura')),
              content: SizedBox(
                width: dialogWidth,
                height: dialogHeight,
                child: stacked
                    ? _buildStackedLayout(
                        dialogContext,
                        entry,
                        state,
                        steps,
                        currentStep,
                        maxAllowedStep,
                        stepsBuilder,
                        expenseOnly,
                        s,
                        l,
                        cs,
                        setState,
                      )
                    : _buildSideBySideLayout(
                        dialogContext,
                        entry,
                        state,
                        steps,
                        currentStep,
                        maxAllowedStep,
                        stepsBuilder,
                        expenseOnly,
                        s,
                        l,
                        cs,
                        setState,
                      ),
              ),
              actions: _buildActions(
                dialogContext,
                state,
                s,
                entryId,
                currentClientId,
                expenseOnly,
                l,
                setState,
              ),
            );
          },
        );
      },
    ).then((_) => state.dispose());
  }

  static Widget _buildStackedLayout(
    BuildContext context,
    Map<String, dynamic> entry,
    InvoiceLinkDialogState state,
    List<Step> steps,
    int currentStep,
    int maxAllowedStep,
    InvoiceLinkDialogSteps stepsBuilder,
    bool expenseOnly,
    StatementsController s,
    AppLocalizations l,
    ColorScheme cs,
    StateSetter setState,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InvoiceLinkSummary.build(
              context, entry, state, expenseOnly, s, l, cs),
          const SizedBox(height: 12),
          WizardStepsHeader(
            steps: steps,
            currentStep: currentStep,
            isWide: true,
            maxWidth: double.infinity,
            height: 118,
            onStepTapped: (target) {
              setState(() {
                if (target <= maxAllowedStep) {
                  state.visibleStep = target;
                }
              });
            },
          ),
          _buildStepContent(
              currentStep, stepsBuilder, expenseOnly, () => setState(() {})),
        ],
      ),
    );
  }

  static Widget _buildSideBySideLayout(
    BuildContext context,
    Map<String, dynamic> entry,
    InvoiceLinkDialogState state,
    List<Step> steps,
    int currentStep,
    int maxAllowedStep,
    InvoiceLinkDialogSteps stepsBuilder,
    bool expenseOnly,
    StatementsController s,
    AppLocalizations l,
    ColorScheme cs,
    StateSetter setState,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: InvoiceLinkSummary.build(
              context, entry, state, expenseOnly, s, l, cs),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              WizardStepsHeader(
                steps: steps,
                currentStep: currentStep,
                isWide: true,
                maxWidth: double.infinity,
                height: 118,
                onStepTapped: (target) {
                  setState(() {
                    if (target <= maxAllowedStep) {
                      state.visibleStep = target;
                    }
                  });
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildStepContent(
                    currentStep,
                    stepsBuilder,
                    expenseOnly,
                    () => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildStepContent(
    int currentStep,
    InvoiceLinkDialogSteps stepsBuilder,
    bool expenseOnly,
    VoidCallback onStateChanged,
  ) {
    if (currentStep == 0) {
      return expenseOnly
          ? stepsBuilder.buildProviderSelector(onStateChanged)
          : stepsBuilder.buildClientSelector(onStateChanged);
    } else if (currentStep == 1) {
      return expenseOnly
          ? stepsBuilder.buildExpenseSelector(onStateChanged)
          : stepsBuilder.buildInvoiceSelector(onStateChanged);
    } else {
      return InvoiceLinkConfirmation.build(
        stepsBuilder.context,
        stepsBuilder.state,
        expenseOnly,
        stepsBuilder.l,
        stepsBuilder.cs,
        onStateChanged,
      );
    }
  }

  static List<Widget> _buildActions(
    BuildContext dialogContext,
    InvoiceLinkDialogState state,
    StatementsController s,
    String entryId,
    String? currentClientId,
    bool expenseOnly,
    AppLocalizations l,
    StateSetter setState,
  ) {
    final currentStep = state.visibleStep;
    final maxAllowedStep = state.getMaxAllowedStep(expenseOnly);

    String? selectedCounterpartyName() {
      if (expenseOnly) {
        final selectedExpense = state.getSelectedExpense();
        final expenseName = (selectedExpense?['providerName'] ??
                selectedExpense?['provider'] ??
                selectedExpense?['vendorName'] ??
                selectedExpense?['vendor'])
            ?.toString()
            .trim();
        if (expenseName != null && expenseName.isNotEmpty) {
          return expenseName;
        }
        final providerId = state.selectedProviderId?.trim() ?? '';
        if (providerId.isEmpty) return null;
        final provider = state.providers.firstWhere(
          (p) =>
              p['id']?.toString() == providerId ||
              p['_id']?.toString() == providerId,
          orElse: () => const <String, dynamic>{},
        );
        final providerName = (provider['name'] ??
                provider['providerName'] ??
                provider['vendorName'])
            ?.toString()
            .trim();
        return providerName != null && providerName.isNotEmpty
            ? providerName
            : null;
      }

      final selectedInvoice = state.getSelectedInvoice();
      final invoiceName =
          selectedInvoice?.billingName?.trim().isNotEmpty == true
              ? selectedInvoice!.billingName!.trim()
              : selectedInvoice?.clientSnapshot?.legalName?.trim();
      if (invoiceName != null && invoiceName.isNotEmpty) {
        return invoiceName;
      }
      final clientId = state.selectedClientId?.trim() ?? '';
      if (clientId.isEmpty) return null;
      final client = s.clients.firstWhere(
        (c) =>
            c['id']?.toString() == clientId || c['_id']?.toString() == clientId,
        orElse: () => const <String, dynamic>{},
      );
      final clientName = (client['name'] ??
              ((client['billing'] is Map)
                  ? (client['billing'] as Map)['legalName']
                  : null))
          ?.toString()
          .trim();
      return clientName != null && clientName.isNotEmpty ? clientName : null;
    }

    // ── Left action ─────────────────────────────────────────────────────────
    final Widget leftAction;
    if (currentStep == 0) {
      if (expenseOnly) {
        leftAction = TextButton.icon(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await StatementsExpenseUploadDialog.show(
              dialogContext,
              s,
              entryId: entryId,
            );
          },
          icon: const Icon(Icons.upload_outlined, size: 16),
          label: const Text('Subir gasto'),
        );
      } else {
        leftAction = TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l.close),
        );
      }
    } else {
      leftAction = TextButton.icon(
        onPressed: () => setState(() => state.visibleStep = currentStep - 1),
        icon: const Icon(Icons.arrow_back_rounded, size: 16),
        label: const Text('Atrás'),
      );
    }

    // ── Right action ─────────────────────────────────────────────────────────
    final Widget rightAction;
    if (currentStep < 2) {
      rightAction = FilledButton(
        onPressed: maxAllowedStep > currentStep
            ? () => setState(() => state.visibleStep = currentStep + 1)
            : null,
        child: const Text('Página siguiente'),
      );
    } else {
      // Step 2: Vincular
      final hasSelection = expenseOnly
          ? state.idController.text.trim().isNotEmpty
          : (state.selectedInvoiceIds.isNotEmpty ||
              state.idController.text.trim().isNotEmpty);
      rightAction = FilledButton(
        onPressed: (hasSelection && state.confirmLink)
            ? () async {
                final value = state.idController.text.trim();
                final selectedInvoice = state.getSelectedInvoice();
                final manualIds = value
                    .split(RegExp(r'[,\n;]'))
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(growable: false);
                final selectedIds = <String>{
                  ...state.selectedInvoiceIds,
                  ...manualIds,
                }.toList(growable: false);
                final counterpartyName = selectedCounterpartyName();
                if (!expenseOnly && state.selectedClientId != currentClientId) {
                  await s.linkClient(
                      entryId: entryId, clientId: state.selectedClientId);
                }
                final outcome = await s.linkInvoice(
                  entryId: entryId,
                  invoiceId:
                      expenseOnly ? (value.isEmpty ? null : value) : null,
                  invoiceIds: expenseOnly ? null : selectedIds,
                  invoiceDisplayNumber:
                      selectedInvoice?.invoiceNumber.trim().isNotEmpty == true
                          ? selectedInvoice!.invoiceNumber.trim()
                          : null,
                  counterpartyName: counterpartyName,
                  expenseOnly: expenseOnly,
                );
                if (!dialogContext.mounted) return;
                if (!outcome.success) {
                  final msg = outcome.errorMessage ?? '';
                  if (outcome.statusCode == 400 &&
                      msg.toLowerCase().contains('invalid invoiceid')) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(l.statementsInvalidInvoiceToast)),
                    );
                  } else if (outcome.statusCode == 404) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          msg.toLowerCase().contains('invoice not found')
                              ? l.statementsInvoiceNotFoundToast
                              : msg,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(dialogContext)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  }
                  return;
                }
                if (outcome.alreadyLinked) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                        content: Text(l.statementsInvoiceAlreadyLinkedToast)),
                  );
                }
                if (outcome.hasRepetitiveInvoiceLink) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        l.statementsRepetitiveInvoiceLinkedToast(
                          (outcome.invoiceLinkedRowsCount > 0
                                  ? outcome.invoiceLinkedRowsCount
                                  : 2)
                              .toString(),
                        ),
                      ),
                    ),
                  );
                }
                Navigator.of(dialogContext).pop();
              }
            : null,
        child: const Text('Vincular'),
      );
    }

    // On the confirmation step expose a secondary Desvincular option
    if (currentStep == 2) {
      return [
        leftAction,
        TextButton(
          onPressed: () async {
            if (!expenseOnly && state.selectedClientId != currentClientId) {
              await s.linkClient(
                  entryId: entryId, clientId: state.selectedClientId);
            }
            await s.linkInvoice(
                entryId: entryId, invoiceId: null, expenseOnly: expenseOnly);
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
          },
          child: Text(l.statementsClearLink),
        ),
        rightAction,
      ];
    }

    return [leftAction, rightAction];
  }

  static void _loadDataAsNeeded(
    BuildContext dialogContext,
    InvoiceLinkDialogState state,
    StatementsController s,
    bool expenseOnly,
    ProvidersApi providersApi,
    InvoicesApi invoicesApi,
    ExpensesApi expensesApi,
    StateSetter setState,
  ) {
    // Load invoices for selected client
    if ((state.selectedClientId?.trim().isNotEmpty ?? false) &&
        !state.invoiceCacheByClient
            .containsKey(state.selectedClientId!.trim()) &&
        !state.loadingInvoices) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!dialogContext.mounted) return;
        _loadInvoicesForClient(dialogContext, state, s, invoicesApi, setState);
      });
    }

    // Load expenses for selected provider
    if (expenseOnly &&
        (state.selectedProviderId?.trim().isNotEmpty ?? false) &&
        !state.expenseCacheByProvider
            .containsKey((state.selectedProviderId ?? '').trim()) &&
        !state.loadingExpenses) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!dialogContext.mounted) return;
        _loadExpensesForProvider(
            dialogContext, state, s, expensesApi, setState);
      });
    }

    // Load providers list
    if (expenseOnly && state.providers.isEmpty && !state.loadingProviders) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!dialogContext.mounted) return;
        _loadProviders(dialogContext, state, s, providersApi, setState);
      });
    }
  }

  static Future<void> _loadProviders(
    BuildContext dialogContext,
    InvoiceLinkDialogState state,
    StatementsController s,
    ProvidersApi providersApi,
    StateSetter setState,
  ) async {
    final groupId = s.groupId;
    if (groupId == null || groupId.trim().isEmpty) {
      setState(() => state.providersError = 'Missing groupId for providers');
      return;
    }
    setState(() {
      state.loadingProviders = true;
      state.providersError = null;
    });
    try {
      final list = await providersApi.list(groupId: groupId);
      if (!dialogContext.mounted) return;
      setState(() => state.providers = list);
    } catch (e) {
      if (!dialogContext.mounted) return;
      setState(() {
        state.providersError =
            e.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (dialogContext.mounted) {
        setState(() => state.loadingProviders = false);
      }
    }
  }

  static Future<void> _loadInvoicesForClient(
    BuildContext dialogContext,
    InvoiceLinkDialogState state,
    StatementsController s,
    InvoicesApi invoicesApi,
    StateSetter setState,
  ) async {
    final clientId = state.selectedClientId?.trim() ?? '';
    if (clientId.isEmpty || state.invoiceCacheByClient.containsKey(clientId)) {
      return;
    }

    final groupId = s.groupId;
    if (groupId == null || groupId.trim().isEmpty) {
      setState(() => state.invoicesError = 'Missing groupId for invoices');
      return;
    }
    setState(() {
      state.loadingInvoices = true;
      state.invoicesError = null;
    });
    try {
      final issued = await invoicesApi.listByGroup(groupId, status: 'issued');
      final drafts = await invoicesApi.listByGroup(groupId, status: 'draft');
      final merged = <String, Invoice>{};
      for (final inv in [...issued, ...drafts]) {
        if (inv.clientId == clientId) {
          merged[inv.id] = inv;
        }
      }
      if (!dialogContext.mounted) return;
      setState(() {
        state.invoiceCacheByClient[clientId] =
            merged.values.toList(growable: false);
      });
    } catch (e) {
      if (!dialogContext.mounted) return;
      setState(() => state.invoicesError =
          e.toString().replaceFirst('Exception: ', '').trim());
    } finally {
      if (dialogContext.mounted) {
        setState(() => state.loadingInvoices = false);
      }
    }
  }

  static Future<void> _loadExpensesForProvider(
    BuildContext dialogContext,
    InvoiceLinkDialogState state,
    StatementsController s,
    ExpensesApi expensesApi,
    StateSetter setState,
  ) async {
    final providerId = state.selectedProviderId?.trim() ?? '';
    if (providerId.isEmpty ||
        state.expenseCacheByProvider.containsKey(providerId)) {
      return;
    }

    final groupId = s.groupId;
    if (groupId == null || groupId.trim().isEmpty) {
      setState(() => state.expensesError = 'Missing groupId for expenses');
      return;
    }
    setState(() {
      state.loadingExpenses = true;
      state.expensesError = null;
    });
    try {
      final list = await expensesApi.listAll(
        groupId: groupId,
        providerId: providerId,
      );
      if (!dialogContext.mounted) return;
      setState(() => state.expenseCacheByProvider[providerId] = list);
    } catch (e) {
      if (!dialogContext.mounted) return;
      setState(() => state.expensesError =
          e.toString().replaceFirst('Exception: ', '').trim());
    } finally {
      if (dialogContext.mounted) {
        setState(() => state.loadingExpenses = false);
      }
    }
  }
}
