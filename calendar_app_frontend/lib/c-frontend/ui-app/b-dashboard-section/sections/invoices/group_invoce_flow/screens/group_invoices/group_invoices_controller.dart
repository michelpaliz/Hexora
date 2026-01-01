import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/invoice_editor_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/billing_profile_sheet/billing_profile_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/add_client_sheet.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'group_invoices_state.dart';

class GroupInvoicesController extends ChangeNotifier {
  final Group group;

  GroupInvoicesController({required this.group});

  final _invoicesApi = InvoicesApi();
  final _billingApi = BillingProfileApi();
  final _clientsApi = ClientsApi();

  GroupInvoicesState _s = const GroupInvoicesState();
  GroupInvoicesState get state => _s;

  void _set(GroupInvoicesState next) {
    _s = next;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _set(_s.copyWith(loading: true, error: null));
    try {
      final results = await Future.wait([
        _clientsApi.list(groupId: group.id, active: null),
        _invoicesApi.listByGroup(group.id, status: 'issued'),
        _invoicesApi.listByGroup(group.id, status: 'draft'),
        _billingApi.getByGroup(group.id),
      ]);

      final clients = results[0] as List<GroupClient>;
      final invoices = results[1] as List<Invoice>;
      final drafts = results[2] as List<Invoice>;
      final billing = results[3] as BillingProfile?;

      // keep selection if still exists
      Invoice? selectedInvoice = _s.selectedInvoice;
      if (selectedInvoice != null) {
        final stillExists = invoices.any((i) => i.id == selectedInvoice!.id) ||
            drafts.any((i) => i.id == selectedInvoice!.id);
        if (!stillExists) selectedInvoice = null;
      }

      selectedInvoice ??= drafts.isNotEmpty
          ? drafts.first
          : (invoices.isNotEmpty ? invoices.first : null);

      _set(
        _s.copyWith(
          clients: clients,
          invoices: invoices,
          drafts: drafts,
          billingProfile: billing,
          selectedClient: clients.isNotEmpty ? clients.first : null,
          selectedInvoice: selectedInvoice,
          loading: false,
          error: null,
        ),
      );
    } catch (e) {
      _set(_s.copyWith(loading: false, error: e.toString()));
    }
  }

  // --- UI state toggles ---
  void setMenu(String key) => _set(_s.copyWith(selectedMenu: key));
  void toggleBusinessExpanded() =>
      _set(_s.copyWith(businessExpanded: !_s.businessExpanded));
  void toggleTotalsExpanded() =>
      _set(_s.copyWith(totalsExpanded: !_s.totalsExpanded));
  void selectClient(GroupClient c) => _set(_s.copyWith(selectedClient: c));
  void selectInvoice(Invoice? i) => _set(_s.copyWith(selectedInvoice: i));

  // --- derived lists ---
  List<Invoice> visibleInvoicesForSelectedClient() {
    final c = _s.selectedClient;
    if (c == null) return _s.invoices;
    return _s.invoices.where((inv) => inv.clientId == c.id).toList();
  }

  List<Invoice> visibleDraftsForSelectedClient() {
    final c = _s.selectedClient;
    if (c == null) return _s.drafts;
    return _s.drafts.where((inv) => inv.clientId == c.id).toList();
  }

  // --- actions ---
  Future<void> openCreateInvoice(BuildContext context) async {
    final l = AppLocalizations.of(context)!;

    if (_s.clients.isEmpty || _s.selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.noClientsYet)),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorScreen(
          group: group,
          clients: _s.clients,
          initialClientId: _s.selectedClient?.id,
        ),
      ),
    );

    if (context.mounted) {
      await loadAll();
    }
  }

  Future<void> openBillingProfile(BuildContext context) async {
    _set(_s.copyWith(busyProfile: true));
    try {
      final updated = await showModalBottomSheet<BillingProfile>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => BillingProfileSheet(
          initial: _s.billingProfile,
          groupId: group.id,
          api: _billingApi,
        ),
      );

      if (updated != null && context.mounted) {
        _set(_s.copyWith(billingProfile: updated));
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.billingProfileSaved)),
        );
      }
    } finally {
      if (context.mounted) _set(_s.copyWith(busyProfile: false));
    }
  }

  Future<void> openEditClient(BuildContext context, GroupClient client) async {
    final updated = await showModalBottomSheet<GroupClient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddClientSheet(
        groupId: group.id,
        api: _clientsApi,
        client: client,
      ),
    );

    if (updated != null && context.mounted) {
      final nextClients = [..._s.clients];
      final idx = nextClients.indexWhere((c) => c.id == updated.id);
      if (idx != -1) nextClients[idx] = updated;

      _set(
        _s.copyWith(
          clients: nextClients,
          selectedClient: (_s.selectedClient?.id == updated.id)
              ? updated
              : _s.selectedClient,
        ),
      );

      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.clientUpdatedWithName(updated.name))),
      );
    }
  }

  void openInvoiceDetailSheet(
    BuildContext context, {
    required Invoice invoice,
  }) {
    // NOTE: we keep this logic in the screen/widgets because it needs InvoiceDetailSheet
    // (if you want, we can move it here too by passing a builder callback).
  }

  Future<void> deleteInvoice(BuildContext context, Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          (invoice.status ?? '').toLowerCase().contains('draft')
              ? 'Remove draft?'
              : 'Remove invoice?',
        ),
        content: Text(
          'This will delete the invoice ${invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : ''}'
              .trim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _invoicesApi.delete(invoice.id);
      if (!context.mounted) return;

      final nextInvoices =
          _s.invoices.where((inv) => inv.id != invoice.id).toList();
      final nextDrafts =
          _s.drafts.where((inv) => inv.id != invoice.id).toList();
      final nextSelected =
          (_s.selectedInvoice?.id == invoice.id) ? null : _s.selectedInvoice;

      _set(_s.copyWith(
          invoices: nextInvoices,
          drafts: nextDrafts,
          selectedInvoice: nextSelected));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice removed')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not remove invoice: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  String formatBillingAddress(BillingProfile p) {
    final parts = [
      p.addressStreet,
      p.addressExtra,
      p.addressCity,
      p.addressProvince,
      p.addressPostalCode,
      p.addressCountry,
    ].whereType<String>().where((e) => e.trim().isNotEmpty).toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }
}
