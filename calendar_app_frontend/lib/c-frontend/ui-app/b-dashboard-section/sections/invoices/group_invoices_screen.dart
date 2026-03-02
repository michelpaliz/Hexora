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
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/billing_profile_inline_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/client_classifications_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_clients_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_emails_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_invoices_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_budgets_view.dart';
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
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

part 'group_invoices/group_invoices_view.dart';
part 'group_invoices/view/group_invoices_content.dart';
part 'group_invoices/mobile/invoices_mobile_view.dart';

class GroupInvoicesScreen extends StatefulWidget {
  final Group group;
  final bool embedded;
  final String? initialMenu;

  const GroupInvoicesScreen({
    super.key,
    required this.group,
    this.embedded = false,
    this.initialMenu,
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
  String? _receiptEditorClientId;
  Receipt? _receiptEditorReceipt;
  final GlobalKey<State<InvoiceEditorScreen>> _invoiceEditorKey =
      GlobalKey<State<InvoiceEditorScreen>>();
  GlobalKey<ExpenseUploadScreenState>? _expensesListKey;
  GlobalKey<ExpenseUploadScreenState> get _safeExpensesListKey =>
      _expensesListKey ??= GlobalKey<ExpenseUploadScreenState>();

  bool _loading = true;
  String? _error;
  bool _busyProfile = false;
  String _selectedMenu = 'clients';
  bool _businessExpanded = false;
  bool _facturacionExpanded = true;
  bool _gastosExpanded = true;
  bool _impuestosExpanded = true;
  bool _informesExpanded = false;
  bool _menuCollapsed = false;
  InvoiceSortState? _invoiceSortState;
  bool? _sortingInvoices;
  bool _openingDraft = false;
  bool _downloadingAllPdfs = false;
  int _classificationViewRefreshTick = 0;

  InvoiceSortState get _effectiveInvoiceSortState =>
      _invoiceSortState ??
      const InvoiceSortState(
          by: InvoiceSortBy.number, dir: InvoiceSortDir.desc);
  bool get _effectiveSortingInvoices => _sortingInvoices ?? false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMenu != null && widget.initialMenu!.trim().isNotEmpty) {
      _selectedMenu = widget.initialMenu!.trim();
    }
    _loadAll();
  }

  (String?, String?) _invoiceSortParams() {
    final qp = invoiceSortToQuery(_effectiveInvoiceSortState);
    return (qp.sortBy, qp.sortDir);
  }

  Future<void> _loadAll({
    bool sortingInvoices = false,
    bool showErrorSnack = false,
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
      final results = await Future.wait([
        _clientsApi.list(groupId: widget.group.id, active: null),
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
        _receiptsApi.list(groupId: widget.group.id, status: 'issued'),
        _receiptsApi.list(groupId: widget.group.id, status: 'draft'),
        _billingApi.getByGroup(widget.group.id),
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
        _receipts = List<Receipt>.from(
          results[3] as List<Receipt>,
          growable: true,
        );
        _receiptDrafts = List<Receipt>.from(
          results[4] as List<Receipt>,
          growable: true,
        );
        _billingProfile = results[5] as BillingProfile?;
        _selectedClient = _clients.isNotEmpty ? _clients.first : null;
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
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      if (showErrorSnack) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
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
    await _refreshInvoiceListsOnly(showErrorSnack: true);
  }

  Future<void> _refreshInvoiceListsOnly({
    bool showErrorSnack = false,
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
          results[0] as List<Invoice>,
          growable: true,
        );
        _drafts = List<Invoice>.from(
          results[1] as List<Invoice>,
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
      if (showErrorSnack) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sortingInvoices = false);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noClientsYet)),
        );
        return;
      }
      setState(() {
        _menuBeforeInvoiceEditor = _selectedMenu;
        _invoiceEditorClientId = _selectedClient?.id;
        _invoiceEditorInvoice = null;
        _selectedMenu = 'invoice_editor';
      });
      return;
    }
    if (_clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noClientsYet)),
      );
      return;
    }
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    if (isMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'es'
                ? 'Crear factura en móvil estará disponible pronto.'
                : 'Create invoice on mobile will be available soon.',
          ),
        ),
      );
      return;
    }
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noClientsYet)),
      );
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

  Future<void> _downloadAllInvoicesPdfs() async {
    if (_downloadingAllPdfs) return;
    if (_invoices.isEmpty && _drafts.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.noInvoicesYet)));
      return;
    }
    setState(() => _downloadingAllPdfs = true);
    try {
      final response = await _invoicesApi.downloadAllPdfsZip(widget.group.id);
      final fileName = _zipFileNameFromHeaders(response.headers);
      await launchFileDownload(
        response.bodyBytes,
        fileName: fileName,
        mimeType: 'application/zip',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _downloadingAllPdfs = false);
    }
  }

  String _zipFileNameFromHeaders(Map<String, String> headers) {
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
    return 'invoices-$y$m$d.zip';
  }

  void _closeInlineInvoiceEditor({required bool changed}) {
    setState(() {
      _selectedMenu = _menuBeforeInvoiceEditor;
      _invoiceEditorClientId = null;
      _invoiceEditorInvoice = null;
    });
    if (changed) _loadAll();
  }

  void _closeInlineReceiptEditor({required bool changed}) {
    setState(() {
      _selectedMenu = _menuBeforeReceiptEditor;
      _receiptEditorClientId = null;
      _receiptEditorReceipt = null;
    });
    if (changed) _loadAll();
  }

  Future<void> _openEditDraft(Invoice draft) async {
    if (_openingDraft) return;
    _openingDraft = true;
    try {
      if (draft.id.trim().isEmpty) return;
      var full = await _invoicesApi.getById(draft.id);
      if (full.lines.isEmpty && full.blocks.isEmpty) {
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
            _selectedMenu = 'invoice_editor';
          });
        });
        return;
      }

      await Future<void>.delayed(Duration.zero);
      final isMobile = MediaQuery.sizeOf(context).width < 700;
      final changed = await Navigator.of(context).push<bool>(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openCreateReceipt() async {
    final l = AppLocalizations.of(context)!;
    if (_clients.isEmpty || _selectedClient == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.noClientsYet)));
      return;
    }
    if (widget.embedded && kIsWeb) {
      setState(() {
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
    setState(() => _businessExpanded = !_businessExpanded);
  }

  void _openInvoiceDetail(Invoice invoice) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InvoiceDetailSheet(
        invoice: invoice,
        client: _clients.firstWhere(
          (c) => c.id == invoice.clientId,
          orElse: () => GroupClient(
            id: invoice.clientId,
            name: AppLocalizations.of(context)!.unknownClient,
            isActive: true,
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .clientUpdatedWithName(updated.name))),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .clientCreatedWithName(created.name)),
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.clientClassificationUpdatedSnack)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.failedWithReason(e.toString()))),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.groupInvoicesRemovedSnack)),
      );
    } catch (e) {
      if (!mounted) return;
      final reason = e.toString().replaceFirst('Exception: ', '');
      final api = e is InvoicesApiException ? e : null;

      if (api?.statusCode == 404) {
        setState(() => _removeInvoiceFromLocalState(invoice.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.groupInvoicesInvoiceAlreadyRemovedSnack)),
        );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.groupInvoicesRemoveFailedSnack(reason)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.receiptPreviewFailed : msg)),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.receiptDownloadFailed : msg)),
      );
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
      final issued = await _invoicesApi.issue(invoice.id);
      if (!mounted) return;
      setState(() {
        _drafts.removeWhere((i) => i.id == invoice.id);
        _invoices.removeWhere((i) => i.id == invoice.id);
        if ((issued.status ?? '').toLowerCase().contains('draft')) {
          _drafts.insert(0, issued);
        } else {
          _invoices.insert(0, issued);
        }
        _selectedInvoice = issued;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.invoiceIssueSuccessSnack(
              issued.invoiceNumber.trim().isEmpty ? '-' : issued.invoiceNumber,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? l.invoiceIssueFailedSnack : message,
          ),
        ),
      );
    }
  }

  Future<void> _issueReceipt(Receipt receipt) async {
    final l = AppLocalizations.of(context)!;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.receiptIssueSuccessSnack(issued.receiptNumber ?? '')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.receiptIssueFailed : msg)),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.groupReceiptsRemovedSnack)),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.groupReceiptsAlreadyRemovedSnack)),
        );
        _loadAll();
        return;
      }
      if (api?.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.groupReceiptsCannotRemoveIssuedSnack)),
        );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.groupReceiptsRemoveFailedSnack(reason))),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only draft receipts can be updated via JSON import'),
        ),
      );
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
                await Clipboard.setData(
                  ClipboardData(
                      text: prompt.isEmpty ? jsonEncode(response) : prompt),
                );
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Prompt copied to clipboard')),
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
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Imported $imported lines')),
                );
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
