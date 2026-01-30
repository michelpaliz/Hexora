import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/receipts/receipts_api.dart';
import 'package:hexora/b-backend/vat/vat_summary_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/invoice_editor_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/billing_profile_sheet/billing_profile_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/client_classifications_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_clients_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_emails_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_invoices_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_invoices_side_menu.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/group_receipts_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/vat_summary_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/receipt_editor_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/recurring_invoices_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/client_classification_store.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/add_client_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

part 'group_invoices/group_invoices_view.dart';

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
  String _menuBeforeInvoiceEditor = 'clients';
  String? _invoiceEditorClientId;

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
  InvoiceNumberSort? _invoiceNumberSort;
  bool? _sortingInvoices;

  InvoiceNumberSort get _effectiveInvoiceNumberSort =>
      _invoiceNumberSort ?? InvoiceNumberSort.recent;
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
    return switch (_effectiveInvoiceNumberSort) {
      InvoiceNumberSort.recent => (null, null),
      InvoiceNumberSort.numberAsc => ('number', 'asc'),
      InvoiceNumberSort.numberDesc => ('number', 'desc'),
    };
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
        _clients = results[0] as List<GroupClient>;
        _invoices = results[1] as List<Invoice>;
        _drafts = results[2] as List<Invoice>;
        _receipts = results[3] as List<Receipt>;
        _receiptDrafts = results[4] as List<Receipt>;
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

  Future<void> _handleInvoiceSortChanged(InvoiceNumberSort sort) async {
    if (sort == _effectiveInvoiceNumberSort) return;
    setState(() => _invoiceNumberSort = sort);
    await _loadAll(sortingInvoices: true, showErrorSnack: true);
  }

  Future<void> _openCreateInvoice() async {
    if (_clients.isEmpty || _selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noClientsYet)),
      );
      return;
    }
    if (widget.embedded && kIsWeb) {
      setState(() {
        _menuBeforeInvoiceEditor = _selectedMenu;
        _invoiceEditorClientId = _selectedClient?.id;
        _selectedMenu = 'invoice_editor';
      });
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

  void _closeInlineInvoiceEditor({required bool changed}) {
    setState(() {
      _selectedMenu = _menuBeforeInvoiceEditor;
      _invoiceEditorClientId = null;
    });
    if (changed) _loadAll();
  }

  Future<void> _openCreateReceipt() async {
    final l = AppLocalizations.of(context)!;
    if (_clients.isEmpty || _selectedClient == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.noClientsYet)));
      return;
    }
    bool? changed;
    if (widget.embedded && kIsWeb) {
      changed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) {
          final media = MediaQuery.of(dialogCtx).size;
          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1200,
                maxHeight: media.height * 0.92,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ReceiptEditorScreen(
                  group: widget.group,
                  clients: _clients,
                  initialClientId: _selectedClient?.id,
                ),
              ),
            ),
          );
        },
      );
    } else {
      changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ReceiptEditorScreen(
            group: widget.group,
            clients: _clients,
            initialClientId: _selectedClient?.id,
          ),
        ),
      );
    }
    if (mounted && changed == true) _loadAll();
  }

  Future<void> _openEditReceipt(Receipt receipt) async {
    bool? changed;
    if (widget.embedded && kIsWeb) {
      changed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) {
          final media = MediaQuery.of(dialogCtx).size;
          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1200,
                maxHeight: media.height * 0.92,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ReceiptEditorScreen(
                  group: widget.group,
                  clients: _clients,
                  initialReceipt: receipt,
                  initialClientId: receipt.clientId,
                ),
              ),
            ),
          );
        },
      );
    } else {
      changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ReceiptEditorScreen(
            group: widget.group,
            clients: _clients,
            initialReceipt: receipt,
            initialClientId: receipt.clientId,
          ),
        ),
      );
    }
    if (mounted && changed == true) _loadAll();
  }

  Future<void> _openBillingProfile() async {
    setState(() => _busyProfile = true);
    try {
      final updated = await showModalBottomSheet<BillingProfile>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => BillingProfileSheet(
          initial: _billingProfile,
          groupId: widget.group.id,
          api: _billingApi,
        ),
      );
      if (updated != null && mounted) {
        setState(() => _billingProfile = updated);
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.billingProfileSaved)));
      }
    } finally {
      if (mounted) setState(() => _busyProfile = false);
    }
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
      setState(() => _invoices.removeWhere((inv) => inv.id == invoice.id));
      setState(() => _drafts.removeWhere((inv) => inv.id == invoice.id));
      if (_selectedInvoice?.id == invoice.id) {
        setState(() => _selectedInvoice = null);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.groupInvoicesRemovedSnack)),
      );
    } catch (e) {
      if (!mounted) return;
      final reason = e.toString().replaceFirst('Exception: ', '');
      final api = e is InvoicesApiException ? e : null;

      if (api?.statusCode == 404) {
        setState(() => _invoices.removeWhere((inv) => inv.id == invoice.id));
        setState(() => _drafts.removeWhere((inv) => inv.id == invoice.id));
        if (_selectedInvoice?.id == invoice.id) {
          setState(() => _selectedInvoice = null);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.groupInvoicesInvoiceAlreadyRemovedSnack)),
        );
        _loadAll();
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

  Future<void> _downloadReceiptPdf(Receipt receipt) async {
    final l = AppLocalizations.of(context)!;
    try {
      final r = await _receiptsApi.downloadPdf(receipt.id);
      final Uint8List bytes = InvoiceEditorPdf.validatePdf(r);
      final fileName = (receipt.receiptNumber?.trim().isNotEmpty == true)
          ? 'receipt-${receipt.receiptNumber!.trim()}.pdf'
          : 'receipt.pdf';
      await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.receiptDownloadFailed : msg)),
      );
    }
  }

  Future<void> _issueReceipt(Receipt receipt) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.receiptIssueConfirmTitle),
        content: Text(l.receiptIssueConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
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

  @override
  Widget build(BuildContext context) {
    return _GroupInvoicesView(state: this);
  }
}
