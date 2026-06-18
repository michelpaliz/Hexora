import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/snack_helper.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
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
  final _linesApi = InvoiceLinesApi();

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

  static const _invoiceChronologyErrorMessage =
      'Esta factura tiene una fecha anterior a la última factura emitida. '
      'Para mantener la numeración cronológica, debes emitir primero las '
      'facturas de fechas anteriores o corregir la fecha.';

  DateTime? _invoiceChronologyDate(Invoice invoice) {
    return invoice.issueDate ?? invoice.occurrenceDate ?? invoice.registeredAt;
  }

  DateTime? _latestIssuedInvoiceDate() {
    DateTime? latest;
    for (final invoice in _s.invoices) {
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

  // --- actions ---
  Future<void> openCreateInvoice(BuildContext context) async {
    final l = AppLocalizations.of(context)!;

    if (_s.clients.isEmpty || _s.selectedClient == null) {
      showInfoSnack(context, l.noClientsYet);
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

  Future<void> openEditDraft(BuildContext context, Invoice draft) async {
    if (_s.clients.isEmpty) return;
    if (draft.id.trim().isEmpty) {
      if (!context.mounted) return;
      showErrorSnack(context, 'Draft is missing an id');
      return;
    }
    try {
      var full = await _invoicesApi.getById(draft.id);
      if (full.lines.isEmpty && full.blocks.isEmpty) {
        final lines = await _linesApi.list(draft.id);
        if (lines.isNotEmpty) {
          full = full.copyWith(lines: lines);
        }
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InvoiceEditorScreen(
            group: group,
            clients: _s.clients,
            initialClientId: draft.clientId,
            initialInvoice: full,
          ),
        ),
      );
      if (context.mounted) {
        await loadAll();
      }
    } catch (e) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      final reason = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(context, l.invoiceDraftOpenFailed(reason));
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
        showSuccessSnack(context, l.billingProfileSaved);
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
      showSuccessSnack(context, l.clientUpdatedWithName(updated.name));
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

      final l = AppLocalizations.of(context)!;
      showSuccessSnack(context, l.groupInvoicesRemovedSnack);
    } catch (e) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      final reason = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(context, l.groupInvoicesRemoveFailedSnack(reason));
    }
  }

  Future<void> issueAllDrafts(
    BuildContext context,
    List<Invoice> drafts,
  ) async {
    int issued = 0;
    int failed = 0;
    final errors = <String>[];

    for (final draft in drafts) {
      if (!context.mounted) break;
      try {
        if (!_canIssueInvoiceByDate(draft)) {
          throw Exception(_invoiceChronologyErrorMessage);
        }
        final updated = await _invoicesApi.issue(draft.id);
        issued++;
        // Move from drafts to invoices in local state
        final nextDrafts = _s.drafts.where((d) => d.id != draft.id).toList();
        final nextInvoices = [..._s.invoices, updated];
        final nextSelected =
            _s.selectedInvoice?.id == draft.id ? updated : _s.selectedInvoice;
        _set(_s.copyWith(
          drafts: nextDrafts,
          invoices: nextInvoices,
          selectedInvoice: nextSelected,
        ));
      } catch (e) {
        failed++;
        final msg = e.toString().replaceFirst('Exception: ', '').trim();
        errors.add(
            '${draft.invoiceNumber.isNotEmpty ? draft.invoiceNumber : draft.id}: $msg');
      }
    }

    if (!context.mounted) return;

    final l = AppLocalizations.of(context)!;
    if (failed == 0) {
      showSuccessSnack(
          context, l.invoiceBatchIssueSuccessSnack(issued.toString()));
    } else {
      showInfoSnack(
        context,
        l.invoiceBatchIssuePartialSnack(issued.toString(), failed.toString()),
        action: errors.isNotEmpty
            ? SnackBarAction(
                label: l.details,
                onPressed: () {
                  if (!context.mounted) return;
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(l.invoiceBatchIssueErrorsTitle),
                      content: SingleChildScrollView(
                        child: Text(errors.join('\n')),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            MaterialLocalizations.of(context).closeButtonLabel,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
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
