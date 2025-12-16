import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/invoice_editor_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/billing_profile_sheet/billing_profile_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/client_billing_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_list_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/add_client_sheet.dart';
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

  List<Invoice> _invoices = [];
  List<Invoice> _drafts = [];
  BillingProfile? _billingProfile;
  List<GroupClient> _clients = [];
  GroupClient? _selectedClient;
  Invoice? _selectedInvoice;

  bool _loading = true;
  String? _error;
  bool _busyProfile = false;
  String _selectedMenu = 'clients';
  bool _businessExpanded = false;
  bool _totalsExpanded = false;

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
        _invoicesApi.listByGroup(widget.group.id, status: 'issued'),
        _invoicesApi.listByGroup(widget.group.id, status: 'draft'),
        _billingApi.getByGroup(widget.group.id),
      ]);
      if (!mounted) return;
      setState(() {
        _clients = results[0] as List<GroupClient>;
        _invoices = results[1] as List<Invoice>;
        _drafts = results[2] as List<Invoice>;
        _billingProfile = results[3] as BillingProfile?;
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceEditorScreen(
          group: widget.group,
          clients: _clients,
          initialClientId: _selectedClient?.id,
        ),
      ),
    );
    if (mounted) _loadAll();
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

  void _toggleTotalsExpanded() {
    setState(() => _totalsExpanded = !_totalsExpanded);
  }

  String _formatBillingAddress(BillingProfile p) {
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

  Future<void> _deleteInvoice(Invoice invoice) async {
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
      if (!mounted) return;
      setState(() => _invoices.removeWhere((inv) => inv.id == invoice.id));
      setState(() => _drafts.removeWhere((inv) => inv.id == invoice.id));
      if (_selectedInvoice?.id == invoice.id) {
        setState(() => _selectedInvoice = null);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not remove invoice: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
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
      final draftInvoices = _selectedClient == null
          ? _drafts
          : _drafts
              .where((inv) => inv.clientId == _selectedClient!.id)
              .toList();
      body = RefreshIndicator(
        onRefresh: _loadAll,
        child: Row(
          children: [
            // Left column: navigation
            SizedBox(
              width: 280,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage:
                                NetworkImage(widget.group.photoUrl ?? ''),
                            child: widget.group.photoUrl == null
                                ? const Icon(Icons.group)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.group.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: _toggleBusinessExpanded,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        'Business',
                                        style: t.bodySmall.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: l.edit,
                                  onPressed:
                                      _busyProfile ? null : _openBillingProfile,
                                  icon: _busyProfile
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip:
                                      _businessExpanded ? 'Collapse' : 'Expand',
                                  onPressed: _toggleBusinessExpanded,
                                  icon: Icon(
                                    _businessExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _billingProfile?.legalName.isNotEmpty == true
                                  ? _billingProfile!.legalName
                                  : l.billingProfileEmpty,
                              maxLines: _businessExpanded ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _billingProfile?.email?.isNotEmpty == true
                                  ? _billingProfile!.email!
                                  : '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            if (_businessExpanded) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 220),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _MiniInfoRow(
                                        label: l.billingTaxId,
                                        value: _billingProfile?.taxId ?? '-',
                                      ),
                                      _MiniInfoRow(
                                        label: l.billingWebsite,
                                        value: _billingProfile
                                                    ?.website?.isNotEmpty ==
                                                true
                                            ? _billingProfile!.website!
                                            : '-',
                                      ),
                                      _MiniInfoRow(
                                        label: l.billingIban,
                                        value:
                                            _billingProfile?.iban?.isNotEmpty ==
                                                    true
                                                ? _billingProfile!.iban!
                                                : '-',
                                      ),
                                      _MiniInfoRow(
                                        label: l.billingAddress,
                                        value: _billingProfile == null
                                            ? '-'
                                            : _formatBillingAddress(
                                                _billingProfile!,
                                              ),
                                      ),
                                      _MiniInfoRow(
                                        label: l.billingTaxRate,
                                        value: _billingProfile == null
                                            ? '-'
                                            : '${_billingProfile!.vatRate}%',
                                      ),
                                      _MiniInfoRow(
                                        label: l.billingCurrency,
                                        value: _billingProfile?.currency ?? '-',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: _toggleTotalsExpanded,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        'Invoices totals',
                                        style: t.bodySmall.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip:
                                      _totalsExpanded ? 'Collapse' : 'Expand',
                                  onPressed: _toggleTotalsExpanded,
                                  icon: Icon(
                                    _totalsExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                ),
                              ],
                            ),
                            if (!_totalsExpanded)
                              Text(
                                'Drafts: ${_drafts.length} • Invoices: ${_invoices.length}',
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else ...[
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 160),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.tonalIcon(
                                          icon: const Icon(
                                            Icons.drafts_outlined,
                                          ),
                                          label: Text(
                                            'Drafts: ${_drafts.length}',
                                          ),
                                          onPressed: () {},
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                          ),
                                          label: Text(
                                            'Invoices: ${_invoices.length}',
                                          ),
                                          onPressed: () {},
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.people_outline),
                        label: const Text('Clients invoice flow'),
                        onPressed: () => setState(() {
                          _selectedMenu = 'clients';
                        }),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(l.invoicesListTitle),
                        onPressed: () => setState(() {
                          _selectedMenu = 'invoices';
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _selectedMenu == 'clients'
                  ? Column(
                      children: [
                        const SizedBox(height: 16),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            l.clientsTitle,
                                            style: t.bodyMedium.copyWith(
                                                fontWeight: FontWeight.w800),
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
                                                        _selectedClient?.id ==
                                                            c.id;
                                                    return ListTile(
                                                      selected: selected,
                                                      title: Text(c.name),
                                                      subtitle: Text(c.billing
                                                              ?.legalName ??
                                                          (c.email ?? '')),
                                                      onTap: () => setState(
                                                          () =>
                                                              _selectedClient =
                                                                  c),
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
                                                style: t.bodyMedium.copyWith(
                                                    color: cs.onSurfaceVariant),
                                              ),
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      _selectedClient!.name,
                                                      style: t.titleLarge
                                                          .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800),
                                                    ),
                                                    Wrap(
                                                      spacing: 8,
                                                      children: [
                                                        OutlinedButton.icon(
                                                          icon: const Icon(Icons
                                                              .edit_outlined),
                                                          label: Text(l.edit),
                                                          onPressed: () =>
                                                              _openEditClient(
                                                                  _selectedClient!),
                                                        ),
                                                        FilledButton.icon(
                                                          icon: const Icon(
                                                              Icons.add),
                                                          label: Text(l
                                                              .createInvoiceCta),
                                                          onPressed:
                                                              _openCreateInvoice,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                ClientBillingView(
                                                  client: _selectedClient!,
                                                  headline: t.bodyMedium
                                                      .copyWith(
                                                          fontWeight:
                                                              FontWeight.w800),
                                                  onSurface: cs.onSurface,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  l.invoicesListTitle,
                                                  style: t.bodyMedium.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800),
                                                ),
                                                const SizedBox(height: 6),
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      Expanded(
                                                        child: visibleInvoices
                                                                .isEmpty
                                                            ? EmptyView(
                                                                icon: Icons
                                                                    .receipt_long_outlined,
                                                                title: l
                                                                    .noInvoicesYet,
                                                                subtitle: l
                                                                    .noInvoicesYetSubtitle,
                                                              )
                                                            : ListView.builder(
                                                                itemCount:
                                                                    visibleInvoices
                                                                        .length,
                                                                itemBuilder:
                                                                    (_, i) {
                                                                  final inv =
                                                                      visibleInvoices[
                                                                          i];
                                                                  final client =
                                                                      _clients
                                                                          .firstWhere(
                                                                    (c) =>
                                                                        c.id ==
                                                                        inv.clientId,
                                                                    orElse: () =>
                                                                        _selectedClient!,
                                                                  );
                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        bottom:
                                                                            8),
                                                                    child:
                                                                        InvoiceListItem(
                                                                      invoice:
                                                                          inv,
                                                                      client:
                                                                          client,
                                                                      onTap: () =>
                                                                          _openInvoiceDetail(
                                                                              inv),
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                      ),
                                                      if (draftInvoices
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                            height: 12),
                                                        Align(
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                'Draft invoices',
                                                                style: t
                                                                    .bodyMedium
                                                                    .copyWith(
                                                                        fontWeight:
                                                                            FontWeight.w800),
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                '${draftInvoices.length}',
                                                                style: t
                                                                    .bodySmall
                                                                    .copyWith(
                                                                        color: cs
                                                                            .onSurfaceVariant),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        SizedBox(
                                                          height: 160,
                                                          child:
                                                              ListView.builder(
                                                            itemCount:
                                                                draftInvoices
                                                                    .length,
                                                            itemBuilder:
                                                                (_, i) {
                                                              final inv =
                                                                  draftInvoices[
                                                                      i];
                                                              final client =
                                                                  _clients
                                                                      .firstWhere(
                                                                (c) =>
                                                                    c.id ==
                                                                    inv.clientId,
                                                                orElse: () =>
                                                                    _selectedClient ??
                                                                    GroupClient(
                                                                        id: inv
                                                                            .clientId,
                                                                        name: l
                                                                            .unknownClient,
                                                                        isActive:
                                                                            true),
                                                              );
                                                              return ListTile(
                                                                leading: const Icon(
                                                                    Icons
                                                                        .drafts_outlined),
                                                                title: Text(inv
                                                                        .invoiceNumber
                                                                        .isNotEmpty
                                                                    ? inv
                                                                        .invoiceNumber
                                                                    : l.invoicesListTitle),
                                                                subtitle: Text(
                                                                    '${client.name} • ${inv.status ?? 'draft'}'),
                                                                trailing:
                                                                    IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .delete_outline),
                                                                  onPressed: () =>
                                                                      _deleteInvoice(
                                                                          inv),
                                                                ),
                                                                onTap: () =>
                                                                    _openInvoiceDetail(
                                                                        inv),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ],
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
                    )
                  : // Invoices view
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DefaultTabController(
                              length: 2,
                              child: Card(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        0,
                                      ),
                                      child: TabBar(
                                        dividerColor: Colors.transparent,
                                        tabs: [
                                          Tab(
                                            text: 'Drafts (${_drafts.length})',
                                          ),
                                          Tab(
                                            text:
                                                'Invoices (${_invoices.length})',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    Expanded(
                                      child: TabBarView(
                                        children: [
                                          ListView.separated(
                                            padding: const EdgeInsets.all(12),
                                            itemCount: _drafts.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 8),
                                            itemBuilder: (_, i) {
                                              final inv = _drafts[i];
                                              final client =
                                                  _clients.firstWhere(
                                                (c) => c.id == inv.clientId,
                                                orElse: () => GroupClient(
                                                  id: inv.clientId,
                                                  name: l.unknownClient,
                                                  isActive: true,
                                                ),
                                              );
                                              return InvoiceListItem(
                                                invoice: inv,
                                                client: client,
                                                onTap: () => setState(() {
                                                  _selectedInvoice = inv;
                                                }),
                                                onDelete: () =>
                                                    _deleteInvoice(inv),
                                              );
                                            },
                                          ),
                                          ListView.separated(
                                            padding: const EdgeInsets.all(12),
                                            itemCount: _invoices.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 8),
                                            itemBuilder: (_, i) {
                                              final inv = _invoices[i];
                                              final client =
                                                  _clients.firstWhere(
                                                (c) => c.id == inv.clientId,
                                                orElse: () => GroupClient(
                                                  id: inv.clientId,
                                                  name: l.unknownClient,
                                                  isActive: true,
                                                ),
                                              );
                                              return InvoiceListItem(
                                                invoice: inv,
                                                client: client,
                                                onTap: () => setState(() {
                                                  _selectedInvoice = inv;
                                                }),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: _selectedInvoice == null
                                  ? Center(
                                      child: Text(
                                        'Select an invoice to see details',
                                        style: t.bodyMedium.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : InvoiceDetailSheet(
                                      key: ValueKey(_selectedInvoice!.id),
                                      invoice: _selectedInvoice!,
                                      client: _clients.firstWhere(
                                        (c) =>
                                            c.id == _selectedInvoice!.clientId,
                                        orElse: () => GroupClient(
                                          id: _selectedInvoice!.clientId,
                                          name: l.unknownClient,
                                          isActive: true,
                                        ),
                                      ),
                                      billingProfile: _billingProfile,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
            )
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

class _MiniInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _MiniInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
