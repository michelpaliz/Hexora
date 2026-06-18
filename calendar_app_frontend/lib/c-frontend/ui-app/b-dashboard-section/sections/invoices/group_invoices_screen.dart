import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
import 'package:hexora/b-backend/receipts/receipts_api.dart';
import 'package:hexora/b-backend/vat/vat_summary_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/invoice_editor_mobile_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/invoice_editor_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/prompt_clipboard_helper.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/billing_profile_inline_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/client_classifications_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/client_contracts_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/client_invoice_comparison_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_clients_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_emails_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_invoices_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_budgets_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/expense_vat_audit_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/invoice_accountant_compare_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/invoice_vat_audit_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_invoice_conversion_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/invoice_sort_query.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_side_menu.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_receipts_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/invoice_row_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/receipts_view/receipt_detail_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/receipts_view/receipt_list_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/vat_summary_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/receipt_editor_wizard_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/recurring_invoices_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_receipts/recurring_receipts_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/client_classification_store.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/add_client_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/client_classification_manager_dialog.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/bulk_download_dialog.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/snack_helper.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

part 'group_invoices/group_invoices_view.dart';
part 'group_invoices/view/group_invoices_content.dart';
part 'group_invoices/mobile/invoices_mobile_view.dart';

class GroupInvoicesRouteArgs {
  const GroupInvoicesRouteArgs({
    required this.group,
    this.initialMenu,
    this.initialInvoiceId,
    this.initialReceiptId,
    this.initialBudgetId,
  });

  final Group group;
  final String? initialMenu;
  final String? initialInvoiceId;
  final String? initialReceiptId;
  final String? initialBudgetId;
}

class GroupInvoicesScreen extends StatefulWidget {
  final Group group;
  final bool embedded;
  final String? initialMenu;
  final String? initialInvoiceId;
  final String? initialReceiptId;
  final String? initialBudgetId;

  const GroupInvoicesScreen({
    super.key,
    required this.group,
    this.embedded = false,
    this.initialMenu,
    this.initialInvoiceId,
    this.initialReceiptId,
    this.initialBudgetId,
  });

  @override
  State<GroupInvoicesScreen> createState() => _GroupInvoicesScreenState();
}

class _GroupInvoicesScreenState extends State<GroupInvoicesScreen> {
  final _invoicesApi = InvoicesApi();
  final _billingApi = BillingProfileApi();
  final _clientsApi = ClientsApi();
  final _receiptsApi = ReceiptsApi();
  final _vatApi = VatSummaryApi();
  final _linesApi = InvoiceLinesApi();

  List<Invoice> _invoices = [];
  List<Invoice> _drafts = [];
  List<Receipt> _receipts = [];
  List<Receipt> _receiptDrafts = [];
  BillingProfile? _billingProfile;
  List<GroupClient> _clients = [];
  GroupClient? _selectedClient;
  Invoice? _selectedInvoice;
  Receipt? _selectedReceipt;
  String? _recurringSeriesToOpen;
  RecurringInvoicesActions? _recurringActions;
  RecurringReceiptsActions? _recurringReceiptsActions;
  String _menuBeforeInvoiceEditor = 'clients';
  String _menuBeforeReceiptEditor = 'receipts';
  String? _invoiceEditorClientId;
  Invoice? _invoiceEditorInvoice;
  bool _inlineInvoiceEditorUnsaved = false;
  bool _inlineReceiptEditorUnsaved = false;
  bool _budgetEditorUnsaved = false;
  String? _receiptEditorClientId;
  Receipt? _receiptEditorReceipt;
  GlobalKey<ExpenseUploadScreenState>? _expensesListKey;
  GlobalKey<ExpenseUploadScreenState> get _safeExpensesListKey =>
      _expensesListKey ??= GlobalKey<ExpenseUploadScreenState>();

  bool _loading = true;
  String? _error;
  bool _busyProfile = false;
  bool _disableReceiptPreviewInteraction = false;
  String _selectedMenu = 'clients';
  bool _businessExpanded = false;
  bool _facturacionExpanded = false;
  bool _gastosExpanded = false;
  bool _impuestosExpanded = false;
  bool _informesExpanded = false;
  bool _clientsExpanded = false;
  bool _invoiceSideMenuCollapsed = false;
  InvoiceSortState? _invoiceSortState;
  bool? _sortingInvoices;
  bool _openingDraft = false;
  bool _downloadingAllPdfs = false;
  bool _exportingInvoiceConcepts = false;
  bool? _issuingAllDrafts = false;
  bool? _refreshingClientsSection = false;
  int _classificationViewRefreshTick = 0;
  int _invoiceEditorSession = 0;
  int _receiptEditorSession = 0;
  String? _budgetEditorBudgetId;
  DateTime? _issuedInvoicesFromDate;
  DateTime? _issuedInvoicesToDate;
  late String? _pendingInitialInvoiceId;
  late String? _pendingInitialReceiptId;

  InvoiceSortState get _effectiveInvoiceSortState =>
      _invoiceSortState ??
      const InvoiceSortState(
          by: InvoiceSortBy.number, dir: InvoiceSortDir.desc);

  bool _isDraftReceipt(Receipt receipt) {
    final status = (receipt.status ?? '').trim().toLowerCase();
    final number = (receipt.receiptNumber ?? '').trim();
    if (status.contains('void')) return false;
    if (status.contains('issued')) return false;
    if (status.contains('draft')) return true;
    return number.isEmpty;
  }

  ({List<Receipt> drafts, List<Receipt> issued}) _splitReceipts(
    List<Receipt> receipts,
  ) {
    final drafts = <Receipt>[];
    final issued = <Receipt>[];
    for (final receipt in receipts) {
      if (_isDraftReceipt(receipt)) {
        drafts.add(receipt);
      } else {
        issued.add(receipt);
      }
    }
    return (drafts: drafts, issued: issued);
  }

  bool get _effectiveSortingInvoices => _sortingInvoices ?? false;

  void _toggleInvoiceSideMenuCollapsed() {
    setState(() {
      _invoiceSideMenuCollapsed = !_invoiceSideMenuCollapsed;
    });
  }

  @override
  void initState() {
    super.initState();
    _pendingInitialInvoiceId = _normalizedEntityId(widget.initialInvoiceId);
    _pendingInitialReceiptId = _normalizedEntityId(widget.initialReceiptId);
    if (widget.initialMenu != null && widget.initialMenu!.trim().isNotEmpty) {
      _selectedMenu = widget.initialMenu!.trim();
    }
    _syncInitialMenuExpansion();
    _loadAll();
  }

  void _syncInitialMenuExpansion() {
    final menu = _selectedMenu;
    _clientsExpanded = menu == 'clients' ||
        menu == 'client_classifications' ||
        menu == 'client_invoice_stats' ||
        menu == 'clients_flow';
    _facturacionExpanded = true;
    _businessExpanded = menu.startsWith('budgets');
    _informesExpanded = menu == 'receipts' ||
        menu == 'receipt_editor' ||
        menu == 'recurring_receipts';
    if (!_clientsExpanded &&
        !_facturacionExpanded &&
        !_businessExpanded &&
        !_informesExpanded) {
      _clientsExpanded = true;
    }
  }

  String? _normalizedEntityId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  bool _isInvoiceMenu(String menu) {
    return menu == 'invoices' ||
        menu == 'invoices_issued' ||
        menu == 'invoices_drafts';
  }

  void _openExpenseForEdit(String expenseId) {
    final trimmedId = expenseId.trim();
    if (trimmedId.isEmpty) return;
    setState(() => _selectedMenu = 'expenses_list');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _safeExpensesListKey.currentState?.openExpenseEditorById(trimmedId);
    });
  }

  void _openDraftBudgetEditor(String budgetId) {
    final trimmedId = budgetId.trim();
    if (trimmedId.isEmpty) return;
    setState(() {
      _budgetEditorBudgetId = trimmedId;
      _selectedMenu = 'budgets_new';
    });
  }

  void _closeBudgetEditorToList() {
    setState(() {
      _budgetEditorBudgetId = null;
      _budgetEditorUnsaved = false;
      _selectedMenu = 'budgets_list';
    });
  }

  void _applyPendingInitialSelections() {
    final pendingInvoiceId = _pendingInitialInvoiceId;
    if (pendingInvoiceId != null) {
      Invoice? target;
      for (final invoice in <Invoice>[..._drafts, ..._invoices]) {
        if (invoice.id.trim() == pendingInvoiceId) {
          target = invoice;
          break;
        }
      }
      if (target != null) {
        _selectedInvoice = target;
        if (!_isInvoiceMenu(_selectedMenu)) {
          _selectedMenu = _drafts.any((draft) => draft.id == target!.id)
              ? 'invoices_drafts'
              : 'invoices_issued';
        }
        _pendingInitialInvoiceId = null;
      }
    }

    final pendingReceiptId = _pendingInitialReceiptId;
    if (pendingReceiptId != null) {
      Receipt? target;
      for (final receipt in <Receipt>[..._receiptDrafts, ..._receipts]) {
        if (receipt.id.trim() == pendingReceiptId) {
          target = receipt;
          break;
        }
      }
      if (target != null) {
        _selectedReceipt = target;
        if (_selectedMenu != 'receipts') {
          _selectedMenu = 'receipts';
        }
        _pendingInitialReceiptId = null;
      }
    }
  }

  (String?, String?) _invoiceSortParams() {
    final qp = invoiceSortToQuery(_effectiveInvoiceSortState);
    return (qp.sortBy, qp.sortDir);
  }

  Future<void> _loadAll({
    bool sortingInvoices = false,
    bool emitErrorSnack = false,
  }) async {
    if (sortingInvoices) {
      setState(() => _sortingInvoices = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final (sortBy, sortDir) = _invoiceSortParams();
      final previousSelectedClientId = _selectedClient?.id;
      final results = await Future.wait([
        _clientsApi.list(
          groupId: widget.group.id,
          active: null,
          includeCurrentMonthInvoiceFlag: true,
        ),
        _invoicesApi.listByGroup(
          widget.group.id,
          status: 'issued',
          sortBy: sortBy,
          sortDir: sortDir,
        ),
        _invoicesApi.listByGroup(
          widget.group.id,
          status: 'draft',
          sortBy: sortBy,
          sortDir: sortDir,
        ),
        _receiptsApi.list(groupId: widget.group.id),
        _billingApi.getByGroup(widget.group.id),
      ]);
      if (!mounted) return;
      final receiptSplit =
          _splitReceipts(List<Receipt>.from(results[3] as List<Receipt>));
      setState(() {
        _clients = List<GroupClient>.from(
          results[0] as List<GroupClient>,
          growable: true,
        );
        _invoices = List<Invoice>.from(
          results[1] as List<Invoice>,
          growable: true,
        );
        _drafts = List<Invoice>.from(
          results[2] as List<Invoice>,
          growable: true,
        );
        _receipts = List<Receipt>.from(
          receiptSplit.issued,
          growable: true,
        );
        _receiptDrafts = List<Receipt>.from(
          receiptSplit.drafts,
          growable: true,
        );
        _billingProfile = results[4] as BillingProfile?;
        _selectedClient = previousSelectedClientId == null
            ? (_clients.isNotEmpty ? _clients.first : null)
            : _clients.cast<GroupClient?>().firstWhere(
                  (client) => client?.id == previousSelectedClientId,
                  orElse: () => _clients.isNotEmpty ? _clients.first : null,
                );
        if (_selectedInvoice != null) {
          final stillExists =
              _invoices.any((i) => i.id == _selectedInvoice!.id) ||
                  _drafts.any((i) => i.id == _selectedInvoice!.id);
          if (!stillExists) _selectedInvoice = null;
        }
        _selectedInvoice ??= _drafts.isNotEmpty
            ? _drafts.first
            : (_invoices.isNotEmpty ? _invoices.first : null);

        if (_selectedReceipt != null) {
          final stillExists =
              _receipts.any((r) => r.id == _selectedReceipt!.id) ||
                  _receiptDrafts.any((r) => r.id == _selectedReceipt!.id);
          if (!stillExists) _selectedReceipt = null;
        }
        _selectedReceipt ??= _receiptDrafts.isNotEmpty
            ? _receiptDrafts.first
            : (_receipts.isNotEmpty ? _receipts.first : null);
        _applyPendingInitialSelections();
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      if (emitErrorSnack) {
        showErrorSnack(context, message);
      }
      if (!sortingInvoices) {
        setState(() => _error = message);
      }
    } finally {
      if (!mounted) return;
      if (sortingInvoices) {
        setState(() => _sortingInvoices = false);
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleInvoiceSortBySelected(InvoiceSortBy by) async {
    final next = nextInvoiceSortState(_effectiveInvoiceSortState, by);
    if (next.by == _effectiveInvoiceSortState.by &&
        next.dir == _effectiveInvoiceSortState.dir) {
      return;
    }
    setState(() => _invoiceSortState = next);
    await _refreshInvoiceListsOnly(emitErrorSnack: true);
  }

  Future<void> _refreshInvoiceListsOnly({
    bool emitErrorSnack = false,
  }) async {
    setState(() => _sortingInvoices = true);
    try {
      final (sortBy, sortDir) = _invoiceSortParams();
      final results = await Future.wait([
        _invoicesApi.listByGroup(
          widget.group.id,
          status: 'issued',
          sortBy: sortBy,
          sortDir: sortDir,
        ),
        _invoicesApi.listByGroup(
          widget.group.id,
          status: 'draft',
          sortBy: sortBy,
          sortDir: sortDir,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _invoices = List<Invoice>.from(
          results[0],
          growable: true,
        );
        _drafts = List<Invoice>.from(
          results[1],
          growable: true,
        );
        if (_selectedInvoice != null) {
          final stillExists =
              _invoices.any((i) => i.id == _selectedInvoice!.id) ||
                  _drafts.any((i) => i.id == _selectedInvoice!.id);
          if (!stillExists) _selectedInvoice = null;
        }
        _selectedInvoice ??= _drafts.isNotEmpty
            ? _drafts.first
            : (_invoices.isNotEmpty ? _invoices.first : null);
      });
    } catch (e) {
      if (!mounted) return;
      if (emitErrorSnack) {
        showErrorSnack(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _sortingInvoices = false);
    }
  }

  Future<void> _refreshClientsSection() async {
    if (_refreshingClientsSection == true) return;
    setState(() => _refreshingClientsSection = true);
    try {
      final (sortBy, sortDir) = _invoiceSortParams();
      final previousSelectedClientId = _selectedClient?.id;
      final results = await Future.wait([
        _clientsApi.list(
          groupId: widget.group.id,
          active: null,
          includeCurrentMonthInvoiceFlag: true,
        ),
        _invoicesApi.listByGroup(
          widget.group.id,
          status: 'issued',
          sortBy: sortBy,
          sortDir: sortDir,
        ),
        _invoicesApi.listByGroup(
          widget.group.id,
          status: 'draft',
          sortBy: sortBy,
          sortDir: sortDir,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _clients = List<GroupClient>.from(
          results[0] as List<GroupClient>,
          growable: true,
        );
        _invoices = List<Invoice>.from(
          results[1] as List<Invoice>,
          growable: true,
        );
        _drafts = List<Invoice>.from(
          results[2] as List<Invoice>,
          growable: true,
        );
        _selectedClient = previousSelectedClientId == null
            ? (_clients.isNotEmpty ? _clients.first : null)
            : _clients.cast<GroupClient?>().firstWhere(
                  (client) => client?.id == previousSelectedClientId,
                  orElse: () => _clients.isNotEmpty ? _clients.first : null,
                );
        if (_selectedInvoice != null) {
          final stillExists =
              _invoices.any((i) => i.id == _selectedInvoice!.id) ||
                  _drafts.any((i) => i.id == _selectedInvoice!.id);
          if (!stillExists) _selectedInvoice = null;
        }
        _selectedInvoice ??= _drafts.isNotEmpty
            ? _drafts.first
            : (_invoices.isNotEmpty ? _invoices.first : null);
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(
          context, message.isEmpty ? 'Failed to refresh clients' : message);
    } finally {
      if (mounted) {
        setState(() => _refreshingClientsSection = false);
      }
    }
  }

  Future<void> _refreshExpensesListOnly() async {
    final listState = _safeExpensesListKey.currentState;
    if (listState == null) return;
    await listState.loadRecentUploads();
  }

  Future<void> _openClientClassificationManager() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ClientClassificationManagerDialog(
        groupId: widget.group.id,
      ),
    );
    if (!mounted) return;
    setState(() => _classificationViewRefreshTick++);
  }

  void _removeInvoiceFromLocalState(String invoiceId) {
    _invoices =
        _invoices.where((inv) => inv.id != invoiceId).toList(growable: true);
    _drafts =
        _drafts.where((inv) => inv.id != invoiceId).toList(growable: true);
    if (_selectedInvoice?.id == invoiceId) {
      _selectedInvoice = null;
    }
  }

  Future<void> _openCreateInvoice() async {
    if (widget.embedded && kIsWeb) {
      if (_clients.isEmpty || _selectedClient == null) {
        showInfoSnack(context, AppLocalizations.of(context)!.noClientsYet);
        return;
      }
      setState(() {
        _menuBeforeInvoiceEditor = _selectedMenu;
        _invoiceEditorClientId = _selectedClient?.id;
        _invoiceEditorInvoice = null;
        _invoiceEditorSession++;
        _selectedMenu = 'invoice_editor';
      });
      return;
    }
    if (_clients.isEmpty) {
      showInfoSnack(context, AppLocalizations.of(context)!.noClientsYet);
      return;
    }
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    if (isMobile) {
      showInfoSnack(context,
          AppLocalizations.of(context)!.invoiceCreateMobileComingSoonSnack);
      return;
    }
    if (_selectedClient == null) {
      showInfoSnack(context, AppLocalizations.of(context)!.noClientsYet);
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorScreen(
          group: widget.group,
          clients: _clients,
          initialClientId: _selectedClient?.id,
        ),
      ),
    );
    if (mounted && changed == true) _loadAll();
  }

  void _showBulkDownloadDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 720),
          child: BulkDownloadDialog(
            onDownload: _downloadAllInvoicesPdfs,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadAllInvoicesPdfs(BulkDownloadFilter filter) async {
    if (_downloadingAllPdfs) return;
    if (_invoices.isEmpty && _drafts.isEmpty) {
      final l = AppLocalizations.of(context)!;
      showInfoSnack(context, l.noInvoicesYet);
      return;
    }
    setState(() => _downloadingAllPdfs = true);
    try {
      final params = filter.toQueryParams(widget.group.id);
      final response = await _invoicesApi.downloadAllPdfsZip(
        widget.group.id,
        queryParams: params,
      );
      final fileName = _zipFileNameFromHeaders(response.headers);
      await launchFileDownload(
        response.bodyBytes,
        fileName: fileName,
        mimeType: 'application/zip',
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _downloadingAllPdfs = false);
    }
  }

  Future<void> _downloadFilteredInvoices(List<Invoice> invoices) async {
    final ids = invoices
        .map((inv) => inv.id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isEmpty) {
      if (!mounted) return;
      showInfoSnack(context, AppLocalizations.of(context)!.noInvoicesYet);
      return;
    }
    try {
      final response = await _invoicesApi.downloadAllPdfsZip(
        widget.group.id,
        queryParams: <String, String>{
          'groupId': widget.group.id,
          'invoiceIds': ids.join(','),
        },
      );
      final fileName = _zipFileNameFromHeaders(response.headers);
      await launchFileDownload(
        response.bodyBytes,
        fileName: fileName,
        mimeType: 'application/zip',
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.toString());
    }
  }

  Future<void> _downloadVisibleInvoicesPdfs(List<Invoice> invoices) async {
    if (_downloadingAllPdfs) return;
    final ids = invoices
        .map((invoice) => invoice.id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isEmpty) {
      showInfoSnack(context, AppLocalizations.of(context)!.noInvoicesYet);
      return;
    }
    setState(() => _downloadingAllPdfs = true);
    try {
      final response = await _invoicesApi.downloadAllPdfsZip(
        widget.group.id,
        queryParams: <String, String>{
          'groupId': widget.group.id,
          'invoiceIds': ids.join(','),
        },
      );
      final fileName = _zipFileNameFromHeaders(response.headers);
      await launchFileDownload(
        response.bodyBytes,
        fileName: fileName,
        mimeType: 'application/zip',
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _downloadingAllPdfs = false);
    }
  }

  Future<void> _exportInvoiceConceptsExcel() async {
    if (_exportingInvoiceConcepts) return;
    final groupId = widget.group.id.trim();
    if (groupId.isEmpty) return;

    String? formatDate(DateTime? value) {
      if (value == null) return null;
      final y = value.year.toString().padLeft(4, '0');
      final m = value.month.toString().padLeft(2, '0');
      final d = value.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    final from = formatDate(_issuedInvoicesFromDate);
    final to = formatDate(_issuedInvoicesToDate);
    final currency = (_billingProfile?.currency ?? 'EUR').trim();

    setState(() => _exportingInvoiceConcepts = true);
    try {
      final response = await _invoicesApi.exportConceptsExcel(
        groupId: groupId,
        from: from,
        to: to,
        status: 'issued',
        currency: currency.isEmpty ? 'EUR' : currency,
      );
      final fileName = _fileNameFromHeaders(
        response.headers,
        fallback: 'invoice_concepts_${from ?? 'all'}_${to ?? 'all'}.xlsx',
      );
      await launchFileDownload(
        response.bodyBytes,
        fileName: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnack(context,
          AppLocalizations.of(context)!.invoiceExportConceptsExcelFailed);
    } finally {
      if (mounted) setState(() => _exportingInvoiceConcepts = false);
    }
  }

  String _fileNameFromHeaders(
    Map<String, String> headers, {
    required String fallback,
  }) {
    final raw =
        headers['content-disposition'] ?? headers['Content-Disposition'];
    if (raw != null && raw.isNotEmpty) {
      final utf8Match =
          RegExp(r"filename\\*=UTF-8''([^;]+)", caseSensitive: false)
              .firstMatch(raw);
      if (utf8Match != null) {
        final name = Uri.decodeComponent(utf8Match.group(1)!);
        if (name.trim().isNotEmpty) return name;
      }
      final match = RegExp(r'filename="?([^";]+)"?', caseSensitive: false)
          .firstMatch(raw);
      if (match != null) {
        final name = match.group(1);
        if (name != null && name.trim().isNotEmpty) return name.trim();
      }
    }
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return fallback.isNotEmpty ? fallback : 'invoices-$y$m$d.zip';
  }

  String _zipFileNameFromHeaders(Map<String, String> headers) {
    return _fileNameFromHeaders(
      headers,
      fallback:
          'invoices-${DateTime.now().year.toString().padLeft(4, '0')}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}.zip',
    );
  }

  void _updateIssuedInvoiceDateFilter(InvoiceDateFilterState filters) {
    setState(() {
      _issuedInvoicesFromDate = filters.fromDate;
      _issuedInvoicesToDate = filters.toDate;
    });
  }

  void _closeInlineInvoiceEditor({required bool changed}) {
    setState(() {
      _selectedMenu = _menuBeforeInvoiceEditor;
      _invoiceEditorClientId = null;
      _invoiceEditorInvoice = null;
      _inlineInvoiceEditorUnsaved = false;
    });
    if (changed) _loadAll();
  }

  Future<bool> _confirmLeaveActiveEditor() async {
    final hasUnsaved = (_selectedMenu == 'invoice_editor' &&
            _inlineInvoiceEditorUnsaved) ||
        (_selectedMenu == 'receipt_editor' && _inlineReceiptEditorUnsaved) ||
        (_selectedMenu == 'budgets_new' && _budgetEditorUnsaved);
    if (!hasUnsaved) {
      return true;
    }
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Tienes cambios sin guardar' : 'Unsaved changes'),
        content: Text(
          isEs
              ? 'Guarda el borrador desde el editor o sal sin guardar.'
              : 'Save the draft from the editor or leave without saving.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(isEs ? 'Quedarme' : 'Stay'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isEs ? 'Salir sin guardar' : 'Leave without saving'),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _changeInvoicesMenu(String menu) {
    setState(() {
      _selectedMenu = menu;
      _budgetEditorBudgetId = null;
      _inlineInvoiceEditorUnsaved = false;
      _inlineReceiptEditorUnsaved = false;
      _budgetEditorUnsaved = false;
    });
  }

  void _closeInlineReceiptEditor({required bool changed}) {
    setState(() {
      _selectedMenu = _menuBeforeReceiptEditor;
      _receiptEditorClientId = null;
      _receiptEditorReceipt = null;
      _inlineReceiptEditorUnsaved = false;
    });
    if (changed) _loadAll();
  }

  Future<void> _openEditDraft(Invoice draft) async {
    if (_openingDraft) return;
    _openingDraft = true;
    try {
      if (draft.id.trim().isEmpty) return;
      var full = await _invoicesApi.getById(draft.id);
      if (full.lines.isEmpty) {
        final lines = await _linesApi.list(draft.id);
        if (lines.isNotEmpty) {
          full = full.copyWith(lines: lines);
        }
      }
      if (!mounted) return;

      if (widget.embedded && kIsWeb) {
        if (_selectedMenu == 'invoice_editor') return;
        Future<void>.delayed(const Duration(milliseconds: 10), () {
          if (!mounted) return;
          setState(() {
            _menuBeforeInvoiceEditor = _selectedMenu;
            _invoiceEditorClientId = full.clientId;
            _invoiceEditorInvoice = full;
            _invoiceEditorSession++;
            _selectedMenu = 'invoice_editor';
          });
        });
        return;
      }

      final isMobile = MediaQuery.sizeOf(context).width < 700;
      final navigator = Navigator.of(context);
      final changed = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => isMobile
              ? InvoiceEditorMobileScreen(
                  group: widget.group,
                  clients: _clients,
                  initialClientId: full.clientId,
                  initialInvoice: full,
                )
              : InvoiceEditorScreen(
                  group: widget.group,
                  clients: _clients,
                  initialClientId: full.clientId,
                  initialInvoice: full,
                ),
        ),
      );
      if (mounted && changed == true) _loadAll();
    } finally {
      _openingDraft = false;
    }
  }

  Future<void> _openInvoiceFromBudgetConversion(String invoiceId) async {
    final id = invoiceId.trim();
    if (id.isEmpty) return;
    try {
      final invoice = await _invoicesApi.getById(id);
      if (!mounted) return;

      if (widget.embedded && kIsWeb) {
        setState(() {
          _menuBeforeInvoiceEditor = _selectedMenu == 'invoice_editor'
              ? _menuBeforeInvoiceEditor
              : _selectedMenu;
          _invoiceEditorClientId = invoice.clientId;
          _invoiceEditorInvoice = invoice;
          _invoiceEditorSession++;
          _selectedMenu = 'invoice_editor';
        });
        return;
      }

      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => InvoiceEditorScreen(
            group: widget.group,
            clients: _clients,
            initialClientId: invoice.clientId,
            initialInvoice: invoice,
          ),
        ),
      );
      if (mounted && changed == true) _loadAll();
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openCreateReceipt() async {
    if (widget.embedded && kIsWeb) {
      setState(() {
        _receiptEditorSession++;
        _menuBeforeReceiptEditor = _selectedMenu;
        _receiptEditorClientId = _selectedClient?.id;
        _receiptEditorReceipt = null;
        _selectedMenu = 'receipt_editor';
      });
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReceiptEditorWizardScreen(
          group: widget.group,
          clients: _clients,
          initialClientId: _selectedClient?.id,
        ),
      ),
    );
    if (mounted && changed == true) _loadAll();
  }

  Future<void> _openEditReceipt(Receipt receipt) async {
    if (widget.embedded && kIsWeb) {
      setState(() {
        _receiptEditorSession++;
        _menuBeforeReceiptEditor = _selectedMenu == 'receipt_editor'
            ? _menuBeforeReceiptEditor
            : _selectedMenu;
        _receiptEditorClientId = receipt.clientId;
        _receiptEditorReceipt = receipt;
        _selectedMenu = 'receipt_editor';
      });
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReceiptEditorWizardScreen(
          group: widget.group,
          clients: _clients,
          initialReceipt: receipt,
          initialClientId: receipt.clientId,
        ),
      ),
    );
    if (mounted && changed == true) _loadAll();
  }

  Future<void> _openBillingProfile() async {
    if (!mounted) return;
    setState(() => _selectedMenu = 'billing_profile');
  }

  void _toggleBusinessExpanded() {
    setState(() {
      final next = !_businessExpanded;
      if (next) {
        _clientsExpanded = false;
        _facturacionExpanded = false;
        _gastosExpanded = false;
        _impuestosExpanded = false;
        _informesExpanded = false;
      }
      _businessExpanded = next;
    });
  }

  GroupClient _resolveInvoiceClient(
    Invoice invoice,
    List<GroupClient> clients,
    AppLocalizations l,
  ) {
    final invoiceClientId = invoice.clientId.trim();
    for (final client in clients) {
      if (client.id == invoiceClientId) return client;
    }
    final fallbackName = [
      invoice.billingName,
      invoice.clientSnapshot?.legalName,
    ].map((value) => value?.trim() ?? '').firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => l.unknownClient,
        );
    return GroupClient(
      id: invoiceClientId,
      name: fallbackName,
      isActive: true,
      billing: invoice.clientSnapshot,
    );
  }

  void _openInvoiceDetail(Invoice invoice) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InvoiceDetailSheet(
        invoice: invoice,
        client: _resolveInvoiceClient(
          invoice,
          _clients,
          AppLocalizations.of(context)!,
        ),
        billingProfile: _billingProfile,
        group: widget.group,
        onInvoiceChanged: () {
          _refreshInvoiceListsOnly();
        },
        onOpenRecurringSeries: (seriesId) {
          Navigator.of(context).pop();
          setState(() {
            _recurringSeriesToOpen = seriesId;
            _selectedMenu = 'recurring';
          });
        },
      ),
    );
  }

  Future<void> _openEditClient(GroupClient client) async {
    final updated = await showModalBottomSheet<GroupClient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddClientSheet(
        groupId: widget.group.id,
        api: _clientsApi,
        client: client,
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        final idx = _clients.indexWhere((c) => c.id == updated.id);
        if (idx != -1) _clients[idx] = updated;
        if (_selectedClient?.id == updated.id) _selectedClient = updated;
      });
      showSuccessSnack(context,
          AppLocalizations.of(context)!.clientUpdatedWithName(updated.name));
    }
  }

  Future<void> _openCreateClient() async {
    final created = await showModalBottomSheet<GroupClient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddClientSheet(
        groupId: widget.group.id,
        api: _clientsApi,
      ),
    );
    if (created != null && mounted) {
      setState(() {
        _clients.insert(0, created);
        _selectedClient = created;
      });
      showSuccessSnack(context,
          AppLocalizations.of(context)!.clientCreatedWithName(created.name));
    }
  }

  Future<void> _updateClientClassification(
    GroupClient client, {
    String? entityType,
    String? propertyKind,
  }) async {
    final l = AppLocalizations.of(context)!;
    try {
      final updated = await _clientsApi.updateFields(
        client.id,
        {
          'entityType': entityType,
          'propertyKind': propertyKind,
        },
      );
      if (!mounted) return;
      await ClientClassificationStore.merge(
        groupId: widget.group.id,
        entityType: updated.entityType,
        propertyKind: updated.propertyKind,
      );
      setState(() {
        final idx = _clients.indexWhere((c) => c.id == updated.id);
        if (idx != -1) _clients[idx] = updated;
        if (_selectedClient?.id == updated.id) _selectedClient = updated;
      });
      showSuccessSnack(context, l.clientClassificationUpdatedSnack);
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, l.failedWithReason(e.toString()));
    }
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          (invoice.status ?? '').toLowerCase().contains('draft')
              ? l.groupInvoicesRemoveDraftTitle
              : l.groupInvoicesRemoveInvoiceTitle,
        ),
        content: Text(
          l.groupInvoicesRemoveInvoiceMessage(
            invoice.invoiceNumber.isNotEmpty
                ? invoice.invoiceNumber
                : l.invoicesListTitle,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _invoicesApi.delete(invoice.id);
      if (!mounted) return;
      setState(() => _removeInvoiceFromLocalState(invoice.id));
      showSuccessSnack(context, l.groupInvoicesRemovedSnack);
    } catch (e) {
      if (!mounted) return;
      final reason = e.toString().replaceFirst('Exception: ', '');
      final api = e is InvoicesApiException ? e : null;

      if (api?.statusCode == 404) {
        setState(() => _removeInvoiceFromLocalState(invoice.id));
        showInfoSnack(context, l.groupInvoicesInvoiceAlreadyRemovedSnack);
        await _refreshInvoiceListsOnly();
        return;
      }
      debugPrint(
        '[GroupInvoicesScreen] delete failed '
        'groupId=${widget.group.id} invoiceId=${invoice.id} '
        'invoiceNumber=${invoice.invoiceNumber} status=${invoice.status} '
        'request=${api?.method ?? '-'} ${api?.url ?? '-'} '
        'statusCode=${api?.statusCode.toString() ?? '-'} '
        'responseBody=${api?.responseBody ?? '-'} '
        'error=$e',
      );

      showErrorSnack(
        context,
        l.groupInvoicesRemoveFailedSnack(reason),
        action: SnackBarAction(
          label: l.details,
          onPressed: () {
            if (!mounted) return;
            showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(l.details),
                content: SelectableText(
                  [
                    'groupId: ${widget.group.id}',
                    'invoiceId: ${invoice.id}',
                    'invoiceNumber: ${invoice.invoiceNumber}',
                    'invoice.groupId: ${invoice.groupId}',
                    'invoice.clientId: ${invoice.clientId}',
                    'status: ${invoice.status ?? '-'}',
                    if (api != null) ...[
                      'request: ${api.method} ${api.url}',
                      'statusCode: ${api.statusCode}',
                      if (api.responseHeaders != null)
                        'responseHeaders: ${api.responseHeaders}',
                      if (api.responseBody != null)
                        'responseBody: ${api.responseBody}',
                    ],
                    'error: ${e.toString()}',
                    if (kDebugMode)
                      'hint: If you see "not found", the invoice may have already been deleted or the list is stale; try refresh.',
                  ].join('\n'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                        MaterialLocalizations.of(context).closeButtonLabel),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _loadAll();
                    },
                    child: Text(l.tryAgain),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }

  Future<void> _previewReceiptPdf(Receipt receipt) async {
    final l = AppLocalizations.of(context)!;
    try {
      final r = await _receiptsApi.previewPdf(receipt.id);
      final Uint8List bytes = InvoiceEditorPdf.validatePdf(r);
      final fileName = (receipt.receiptNumber?.trim().isNotEmpty == true)
          ? 'receipt-${receipt.receiptNumber!.trim()}.pdf'
          : 'receipt-preview.pdf';
      await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(context, msg.isEmpty ? l.receiptPreviewFailed : msg);
    }
  }

  Future<Uint8List?> _loadReceiptInlinePdfBytes(Receipt receipt) async {
    final r = await _receiptsApi.previewPdf(receipt.id);
    return InvoiceEditorPdf.validatePdf(r);
  }

  Future<void> _downloadReceiptPdf(Receipt receipt) async {
    final l = AppLocalizations.of(context)!;
    try {
      final r = await _receiptsApi.downloadPdf(receipt.id);
      final Uint8List bytes = InvoiceEditorPdf.validatePdf(r);
      final fileName = (receipt.receiptNumber?.trim().isNotEmpty == true)
          ? 'receipt-${receipt.receiptNumber!.trim()}.pdf'
          : 'receipt.pdf';
      await launchFileDownload(
        bytes,
        fileName: fileName,
        mimeType: 'application/pdf',
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(context, msg.isEmpty ? l.receiptDownloadFailed : msg);
    }
  }

  bool _isDraftInvoice(Invoice invoice) {
    final status = (invoice.status ?? '').toLowerCase();
    return status.contains('draft') || status.trim().isEmpty;
  }

  void _applyIssuedInvoiceLocally({
    required Invoice original,
    required Invoice updated,
  }) {
    _drafts.removeWhere((i) => i.id == original.id);
    _invoices.removeWhere((i) => i.id == original.id || i.id == updated.id);

    if (_isDraftInvoice(updated)) {
      _drafts.insert(0, updated);
    } else {
      _invoices.insert(0, updated);
    }

    if (_selectedInvoice?.id == original.id ||
        _selectedInvoice?.id == updated.id) {
      _selectedInvoice = updated;
    }
  }

  static const _invoiceChronologyErrorMessage =
      'Esta factura tiene una fecha anterior a la última factura emitida. '
      'Para mantener la numeración cronológica, debes emitir primero las '
      'facturas de fechas anteriores o corregir la fecha.';

  DateTime? _invoiceChronologyDate(Invoice invoice) {
    return invoice.issueDate ?? invoice.occurrenceDate ?? invoice.registeredAt;
  }

  DateTime? _latestIssuedInvoiceDate() {
    DateTime? latest;
    for (final invoice in _invoices) {
      final date = _invoiceChronologyDate(invoice);
      if (date == null) continue;
      if (latest == null || date.isAfter(latest)) latest = date;
    }
    return latest;
  }

  bool _isBeforeCalendarDay(DateTime value, DateTime limit) {
    final valueDay = DateTime(value.year, value.month, value.day);
    final limitDay = DateTime(limit.year, limit.month, limit.day);
    return valueDay.isBefore(limitDay);
  }

  bool _canIssueInvoiceByDate(Invoice invoice) {
    final selectedDate = _invoiceChronologyDate(invoice);
    final latestIssuedDate = _latestIssuedInvoiceDate();
    if (selectedDate == null || latestIssuedDate == null) return true;
    return !_isBeforeCalendarDay(selectedDate, latestIssuedDate);
  }

  Future<Invoice> _issueInvoiceDirect(Invoice invoice) async {
    if (!_canIssueInvoiceByDate(invoice)) {
      throw Exception(_invoiceChronologyErrorMessage);
    }
    final updated = await _invoicesApi.issue(invoice.id);
    if (!mounted) return updated;
    setState(() {
      _applyIssuedInvoiceLocally(
        original: invoice,
        updated: updated,
      );
    });
    return updated;
  }

  bool _isDuplicateInvoiceNumberError(Object error) {
    final lower = error.toString().toLowerCase();
    return (lower.contains('e11000') && lower.contains('invoicenumber')) ||
        (lower.contains('duplicate key') && lower.contains('invoicenumber'));
  }

  String _friendlyInvoiceIssueError(Object error, AppLocalizations l) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (!_isDuplicateInvoiceNumberError(error)) {
      return raw.isEmpty ? l.invoiceIssueFailedSnack : raw;
    }

    final numberMatch = RegExp(r'invoiceNumber:\s*"([^"]+)"').firstMatch(raw) ??
        RegExp(r'invoiceNumber:\s*([^,}\s]+)').firstMatch(raw);
    final number = numberMatch?.group(1)?.trim() ?? '';
    return number.isEmpty
        ? l.invoiceIssueDuplicateNumberSnack
        : l.invoiceIssueDuplicateNumberValueSnack(number);
  }

  Future<void> _issueAllDraftInvoices([List<Invoice>? orderedDrafts]) async {
    if (_issuingAllDrafts == true) return;
    final source = orderedDrafts ?? _drafts;
    final draftsToIssue = source.where(_isDraftInvoice).toList(growable: false);
    if (draftsToIssue.isEmpty) return;

    final l = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final count = draftsToIssue.length;
    final confirmTitle =
        isSpanish ? 'Emitir todos los borradores' : 'Issue all drafts';
    final confirmMessage = isSpanish
        ? 'Se emitirán $count facturas en borrador. ${l.invoiceIssueConfirmMessage}'
        : '$count draft invoices will be issued. ${l.invoiceIssueConfirmMessage}';
    final confirmCta = isSpanish ? 'Emitir $count' : 'Issue $count';

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(confirmMessage),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(true),
            icon: const Icon(Icons.publish_outlined),
            label: Text(confirmCta),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _issuingAllDrafts = true);

    var successCount = 0;
    String? firstError;
    try {
      for (final draft in draftsToIssue) {
        try {
          await _issueInvoiceDirect(draft);
          successCount += 1;
        } catch (e) {
          firstError ??= _friendlyInvoiceIssueError(e, l);
        }
      }

      if (!mounted) return;
      await _refreshInvoiceListsOnly();
      if (!mounted) return;

      final failedCount = count - successCount;
      if (failedCount == 0) {
        showSuccessSnack(
            context, l.invoiceBatchIssueSuccessSnack(successCount.toString()));
      } else if (successCount > 0) {
        showInfoSnack(
            context,
            l.invoiceBatchIssuePartialSnack(
                successCount.toString(), failedCount.toString()));
      } else {
        showErrorSnack(
            context,
            firstError?.isNotEmpty == true
                ? firstError!
                : l.invoiceIssueFailedSnack);
      }
    } finally {
      if (mounted) {
        setState(() => _issuingAllDrafts = false);
      }
    }
  }

  Future<void> _issueInvoice(Invoice invoice) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.invoiceIssueConfirmTitle),
        content: Text(l.invoiceIssueConfirmMessage),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(true),
            child: Text(l.invoiceIssueCta),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final issued = await _issueInvoiceDirect(invoice);
      if (!mounted) return;
      showSuccessSnack(
        context,
        l.invoiceIssueSuccessSnack(
          issued.invoiceNumber.trim().isEmpty ? '-' : issued.invoiceNumber,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = _friendlyInvoiceIssueError(e, l);
      showErrorSnack(context, message);
      await _refreshInvoiceListsOnly();
    }
  }

  Future<void> _issueReceipt(Receipt receipt) async {
    final l = AppLocalizations.of(context)!;
    if (mounted) {
      setState(() => _disableReceiptPreviewInteraction = true);
    }
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.receiptIssueConfirmTitle),
        content: Text(l.receiptIssueConfirmMessage),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(true),
            child: Text(l.receiptIssueCta),
          ),
        ],
      ),
    );
    if (mounted) {
      setState(() => _disableReceiptPreviewInteraction = false);
    }
    if (confirmed != true) return;

    try {
      final issued = await _receiptsApi.issue(receipt.id);
      if (!mounted) return;
      setState(() {
        _receiptDrafts.removeWhere((r) => r.id == receipt.id);
        _receipts.removeWhere((r) => r.id == receipt.id);
        if ((issued.status ?? '').toLowerCase().contains('draft')) {
          _receiptDrafts.insert(0, issued);
        } else {
          _receipts.insert(0, issued);
        }
        _selectedReceipt = issued;
      });
      showSuccessSnack(
          context, l.receiptIssueSuccessSnack(issued.receiptNumber ?? ''));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(context, msg.isEmpty ? l.receiptIssueFailed : msg);
    }
  }

  Future<void> _deleteReceipt(Receipt receipt) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.groupReceiptsRemoveDraftTitle),
        content: Text(
          l.groupReceiptsRemoveDraftMessage(
            (receipt.receiptNumber?.trim().isNotEmpty == true)
                ? receipt.receiptNumber!.trim()
                : l.receiptDraftNumberPlaceholder,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _receiptsApi.delete(receipt.id);
      if (!mounted) return;
      setState(() {
        _receiptDrafts.removeWhere((r) => r.id == receipt.id);
        _receipts.removeWhere((r) => r.id == receipt.id);
        if (_selectedReceipt?.id == receipt.id) _selectedReceipt = null;
      });
      showSuccessSnack(context, l.groupReceiptsRemovedSnack);
    } catch (e) {
      if (!mounted) return;
      final api = e is ReceiptsApiException ? e : null;
      final reason = e.toString().replaceFirst('Exception: ', '');

      if (api?.statusCode == 404) {
        setState(() {
          _receiptDrafts.removeWhere((r) => r.id == receipt.id);
          _receipts.removeWhere((r) => r.id == receipt.id);
          if (_selectedReceipt?.id == receipt.id) _selectedReceipt = null;
        });
        showInfoSnack(context, l.groupReceiptsAlreadyRemovedSnack);
        _loadAll();
        return;
      }
      if (api?.statusCode == 409) {
        showErrorSnack(context, l.groupReceiptsCannotRemoveIssuedSnack);
        _loadAll();
        return;
      }

      debugPrint(
        '[GroupInvoicesScreen] receipt delete failed '
        'groupId=${widget.group.id} receiptId=${receipt.id} '
        'receiptNumber=${receipt.receiptNumber} status=${receipt.status} '
        'request=${api?.method ?? '-'} ${api?.url ?? '-'} '
        'statusCode=${api?.statusCode.toString() ?? '-'} '
        'responseBody=${api?.responseBody ?? '-'} '
        'error=$e',
      );

      showErrorSnack(context, l.groupReceiptsRemoveFailedSnack(reason));
    }
  }

  Future<void> _refreshReceiptById(String receiptId) async {
    final refreshed = await _receiptsApi.getById(receiptId);
    if (!mounted) return;
    setState(() {
      _receiptDrafts.removeWhere((r) => r.id == receiptId);
      _receipts.removeWhere((r) => r.id == receiptId);
      final status = (refreshed.status ?? '').toLowerCase();
      if (status.contains('draft') || status.trim().isEmpty) {
        _receiptDrafts.insert(0, refreshed);
      } else {
        _receipts.insert(0, refreshed);
      }
      _selectedReceipt = refreshed;
    });
  }

  dynamic _normalizeReceiptJsonImportPayload(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      if (map['lines'] is List) {
        return {'lines': map['lines']};
      }
      if (map['draftLines'] is List) {
        return {'draftLines': map['draftLines']};
      }
    }
    return null;
  }

  Future<void> _openReceiptJsonImportDialog(Receipt receipt) async {
    final l = AppLocalizations.of(context)!;
    final status = (receipt.status ?? '').toLowerCase();
    final isDraft = status.contains('draft') || status.trim().isEmpty;
    if (!isDraft) {
      showErrorSnack(context, l.receiptJsonImportDraftOnlySnack);
      return;
    }

    final jsonCtrl = TextEditingController();
    bool fileMode = false;
    bool loading = false;
    String? fileName;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> loadJsonFile() async {
              final picked = await FilePicker.platform.pickFiles(
                allowMultiple: false,
                type: FileType.custom,
                allowedExtensions: const ['json'],
                withData: true,
              );
              final file = (picked?.files.isNotEmpty ?? false)
                  ? picked!.files.first
                  : null;
              final bytes = file?.bytes;
              if (file == null || bytes == null || bytes.isEmpty) return;
              try {
                final text = utf8.decode(bytes);
                jsonDecode(text);
                setStateDialog(() {
                  jsonCtrl.text = text;
                  fileName = file.name;
                  errorText = null;
                });
              } catch (_) {
                setStateDialog(() {
                  errorText = 'Invalid JSON';
                });
              }
            }

            Future<void> copyPrompt() async {
              if (loading) return;
              setStateDialog(() {
                loading = true;
                errorText = null;
              });
              try {
                final response =
                    await _receiptsApi.getImportJsonPromptTemplate(receipt.id);
                final prompt = (response['promptTemplate'] ??
                        response['prompt'] ??
                        response['template'] ??
                        response['text'] ??
                        '')
                    .toString();
                if (!dialogContext.mounted) return;
                await copyTextWithManualFallbackDialog(
                  dialogContext,
                  text: prompt.isEmpty ? jsonEncode(response) : prompt,
                  successMessage: 'Prompt copied to clipboard',
                );
              } on ReceiptsApiException catch (e) {
                if (!dialogContext.mounted) return;
                setStateDialog(() => errorText = e.message);
              } finally {
                if (dialogContext.mounted) {
                  setStateDialog(() => loading = false);
                }
              }
            }

            Future<void> submitImport() async {
              if (loading) return;
              final raw = jsonCtrl.text.trim();
              if (raw.isEmpty) {
                setStateDialog(() => errorText = 'Invalid JSON');
                return;
              }
              dynamic decoded;
              try {
                decoded = jsonDecode(raw);
              } catch (_) {
                setStateDialog(() => errorText = 'Invalid JSON');
                return;
              }
              final payload = _normalizeReceiptJsonImportPayload(decoded);
              if (payload == null) {
                setStateDialog(() => errorText = 'Invalid JSON');
                return;
              }

              setStateDialog(() {
                loading = true;
                errorText = null;
              });
              try {
                final response =
                    await _receiptsApi.importJson(receipt.id, payload);
                await _refreshReceiptById(receipt.id);
                if (!dialogContext.mounted) return;
                final imported = (response['importedCount'] ??
                        response['lineCount'] ??
                        response['createdCount'] ??
                        response['count'] ??
                        0)
                    .toString();
                showSuccessSnack(
                    dialogContext, l.receiptJsonImportSuccessSnack(imported));
                Navigator.of(dialogContext).pop();
              } on ReceiptsApiException catch (e) {
                String msg;
                if (e.statusCode == 403) {
                  msg = 'No permission';
                } else if (e.statusCode == 404) {
                  msg = 'Record not found';
                } else if (e.statusCode == 409) {
                  msg = 'Only draft receipts can be updated via JSON import';
                } else if (e.statusCode == 400) {
                  msg = e.message;
                } else {
                  msg = l.failedWithReason('');
                }
                setStateDialog(() => errorText = msg);
              } catch (_) {
                setStateDialog(() => errorText = l.failedWithReason(''));
              } finally {
                if (dialogContext.mounted) {
                  setStateDialog(() => loading = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Import JSON'),
              content: SizedBox(
                width: 680,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Paste JSON'),
                          selected: !fileMode,
                          onSelected: loading
                              ? null
                              : (v) => setStateDialog(
                                  () => fileMode = !v ? fileMode : false),
                        ),
                        ChoiceChip(
                          label: const Text('Upload .json'),
                          selected: fileMode,
                          onSelected: loading
                              ? null
                              : (v) => setStateDialog(() => fileMode = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (fileMode) ...[
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: loading ? null : loadJsonFile,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Choose file'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              fileName ?? 'No file selected',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: jsonCtrl,
                      minLines: 7,
                      maxLines: 11,
                      enabled: !loading,
                      decoration: const InputDecoration(
                        hintText: 'Paste JSON payload',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if ((errorText ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      loading ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(l.close),
                ),
                OutlinedButton.icon(
                  onPressed: loading ? null : copyPrompt,
                  icon: const Icon(Icons.content_copy_outlined),
                  label: const Text('Get AI Prompt'),
                ),
                FilledButton.icon(
                  onPressed: loading ? null : submitImport,
                  icon: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.playlist_add_check_circle_outlined),
                  label: const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );

    jsonCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GroupInvoicesView(state: this);
  }
}
