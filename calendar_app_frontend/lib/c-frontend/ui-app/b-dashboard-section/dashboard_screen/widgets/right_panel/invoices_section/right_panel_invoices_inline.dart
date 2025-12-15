import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/billing_profile_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/billing_profile_sheet/billing_profile_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_list_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../../../sections/invoices/widgets/billing_profile_card.dart';

class InvoicesInlinePanel extends StatefulWidget {
  final Group group;
  const InvoicesInlinePanel({super.key, required this.group});

  @override
  State<InvoicesInlinePanel> createState() => _InvoicesInlinePanelState();
}

class _InvoicesInlinePanelState extends State<InvoicesInlinePanel> {
  final _invoicesApi = InvoicesApi();
  final _billingApi = BillingProfileApi();
  final _clientsApi = ClientsApi();

  bool _loading = true;
  String? _error;
  List<Invoice> _invoices = [];
  List<GroupClient> _clients = [];
  BillingProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
        _profile = results[2] as BillingProfile?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openBillingSheet() async {
    final updated = await showModalBottomSheet<BillingProfile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BillingProfileSheet(
        initial: _profile,
        groupId: widget.group.id,
        api: _billingApi,
      ),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
    }
  }

  void _openDetail(Invoice inv) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InvoiceDetailSheet(
        invoice: inv,
        client: _clients.firstWhere(
          (c) => c.id == inv.clientId,
          orElse: () =>
              GroupClient(id: inv.clientId, name: '-', isActive: true),
        ),
        billingProfile: _profile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    final latest = _invoices.take(3).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BillingProfileCard(
            profile: _profile,
            busy: false,
            onEdit: _openBillingSheet,
          ),
          const SizedBox(height: 12),
          Text(
            l.invoicesListTitle,
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (latest.isEmpty)
            EmptyView(
              icon: Icons.receipt_long_outlined,
              title: l.noInvoicesYet,
              subtitle: l.noInvoicesYetSubtitle,
              cta: l.openInvoicesWorkspace,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupInvoicesScreen(group: widget.group),
                ),
              ),
            )
          else
            ...latest.map(
              (inv) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InvoiceListItem(
                  invoice: inv,
                  client: _clients.firstWhere(
                    (c) => c.id == inv.clientId,
                    orElse: () => GroupClient(
                      id: inv.clientId,
                      name: l.unknownClient,
                      isActive: true,
                    ),
                  ),
                  onTap: () => _openDetail(inv),
                ),
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupInvoicesScreen(group: widget.group),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(
                l.openInvoicesWorkspace,
                style: t.bodySmall.copyWith(color: cs.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
