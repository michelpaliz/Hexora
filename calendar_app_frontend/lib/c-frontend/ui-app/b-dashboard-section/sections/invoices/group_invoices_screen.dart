import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/billing_profile_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/billing_profile_sheet/billing_profile_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/client_billing_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_form_sheet/invoice_form_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_list_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupInvoicesScreen extends StatefulWidget {
  final Group group;
  const GroupInvoicesScreen({super.key, required this.group});

  @override
  State<GroupInvoicesScreen> createState() => _GroupInvoicesScreenState();
}

class _GroupInvoicesScreenState extends State<GroupInvoicesScreen> {
  final _invoicesApi = InvoicesApi();
  final _billingApi = BillingProfileApi();
  final _clientsApi = ClientsApi();
  final _linesApi = InvoiceLinesApi();

  List<Invoice> _invoices = [];
  BillingProfile? _billingProfile;
  List<GroupClient> _clients = [];
  GroupClient? _selectedClient;

  bool _loading = true;
  String? _error;
  bool _busyProfile = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _clientsApi.list(groupId: widget.group.id, active: null),
        _invoicesApi.listByGroup(widget.group.id),
        _billingApi.getByGroup(widget.group.id),
      ]);
      if (!mounted) return;
      setState(() {
        _clients = results[0] as List<GroupClient>;
        _invoices = results[1] as List<Invoice>;
        _billingProfile = results[2] as BillingProfile?;
        _selectedClient = _clients.isNotEmpty ? _clients.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateInvoice() async {
    if (_clients.isEmpty || _selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noClientsYet)),
      );
      return;
    }
    final created = await showModalBottomSheet<Invoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InvoiceFormSheet(
        groupId: widget.group.id,
        clients: _clients,
        api: _invoicesApi,
        linesApi: _linesApi,
        selectedClientId: _selectedClient?.id,
      ),
    );
    if (created != null && mounted) {
      setState(() => _invoices.insert(0, created));
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invoiceCreated)));
    }
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ErrorView(message: _error!, onRetry: _loadAll);
    } else {
      final visibleInvoices = _selectedClient == null
          ? _invoices
          : _invoices
              .where((inv) => inv.clientId == _selectedClient!.id)
              .toList();
      body = RefreshIndicator(
        onRefresh: _loadAll,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: BillingProfileCard(
                profile: _billingProfile,
                busy: _busyProfile,
                onEdit: _openBillingProfile,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    // Left column: clients list
                    Expanded(
                      flex: 1,
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                l.clientsTitle,
                                style: t.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: _clients.isEmpty
                                  ? EmptyView(
                                      icon: Icons.person_outline,
                                      title: l.noClientsYet,
                                      subtitle: l.noClientsYet,
                                    )
                                  : ListView.separated(
                                      itemCount: _clients.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (_, i) {
                                        final c = _clients[i];
                                        final selected =
                                            _selectedClient?.id == c.id;
                                        return ListTile(
                                          selected: selected,
                                          title: Text(c.name),
                                          subtitle: Text(c.billing?.legalName ??
                                              (c.email ?? '')),
                                          onTap: () => setState(
                                              () => _selectedClient = c),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right column: client detail + invoices
                    Expanded(
                      flex: 2,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _selectedClient == null
                              ? Center(
                                  child: Text(
                                    l.selectClientFirst,
                                    style: t.bodyMedium
                                        .copyWith(color: cs.onSurfaceVariant),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedClient!.name,
                                          style: t.titleLarge.copyWith(
                                              fontWeight: FontWeight.w800),
                                        ),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              icon: const Icon(
                                                  Icons.edit_outlined),
                                              label: Text(l.edit),
                                              onPressed: () => _openEditClient(
                                                  _selectedClient!),
                                            ),
                                            FilledButton.icon(
                                              icon: const Icon(Icons.add),
                                              label: Text(l.createInvoiceCta),
                                              onPressed: _openCreateInvoice,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClientBillingView(
                                      client: _selectedClient!,
                                      headline: t.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w800),
                                      onSurface: cs.onSurface,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l.invoicesListTitle,
                                      style: t.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: visibleInvoices.isEmpty
                                          ? EmptyView(
                                              icon: Icons.receipt_long_outlined,
                                              title: l.noInvoicesYet,
                                              subtitle: l.noInvoicesYetSubtitle,
                                            )
                                          : ListView.builder(
                                              itemCount: visibleInvoices.length,
                                              itemBuilder: (_, i) {
                                                final inv = visibleInvoices[i];
                                                final client =
                                                    _clients.firstWhere(
                                                  (c) => c.id == inv.clientId,
                                                  orElse: () =>
                                                      _selectedClient!,
                                                );
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8),
                                                  child: InvoiceListItem(
                                                    invoice: inv,
                                                    client: client,
                                                    onTap: () =>
                                                        _openInvoiceDetail(inv),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.invoicesTitle(widget.group.name),
          style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        backgroundColor: cs.surface,
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateInvoice,
        icon: const Icon(Icons.add),
        label: Text(l.createInvoiceCta),
      ),
    );
  }
}
