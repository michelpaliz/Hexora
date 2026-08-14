import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

typedef InvoiceItemBuilder = Widget Function(
  Invoice inv,
  GroupClient client, {
  VoidCallback? onDelete,
  VoidCallback? onEdit,
  required VoidCallback onTap,
});

class InvoicesView extends StatefulWidget {
  final AppTypography typography;
  final ColorScheme colorScheme;

  final List<Invoice> drafts;
  final List<Invoice> invoices;
  final List<GroupClient> clients;

  final Invoice? selectedInvoice;

  final ValueChanged<Invoice> onSelectInvoice;
  final ValueChanged<Invoice> onDeleteDraft;
  final ValueChanged<Invoice> onEditDraft;

  /// Called when user taps "Emitir todos". Receives the list of draft invoices
  /// that should be issued. Null means the button is hidden.
  final Future<void> Function(List<Invoice> drafts)? onIssueAll;

  final Widget Function(Invoice inv) detailBuilder;
  final InvoiceItemBuilder invoiceItemBuilder;

  const InvoicesView({
    super.key,
    required this.typography,
    required this.colorScheme,
    required this.drafts,
    required this.invoices,
    required this.clients,
    required this.selectedInvoice,
    required this.onSelectInvoice,
    required this.onDeleteDraft,
    required this.onEditDraft,
    required this.detailBuilder,
    required this.invoiceItemBuilder,
    this.onIssueAll,
  });

  @override
  State<InvoicesView> createState() => _InvoicesViewState();
}

class _InvoicesViewState extends State<InvoicesView> {
  bool _issuingAll = false;
  bool _confirmingIssueAll = false;

  GroupClient _clientOrUnknown(AppLocalizations l, String id) {
    return widget.clients.firstWhere(
      (c) => c.id == id,
      orElse: () => GroupClient(id: id, name: l.unknownClient, isActive: true),
    );
  }

  Future<void> _handleIssueAll(AppLocalizations l) async {
    if (_issuingAll || _confirmingIssueAll || widget.onIssueAll == null) {
      return;
    }
    final drafts = widget.drafts;
    if (drafts.isEmpty) return;

    final isEs = l.localeName.toLowerCase().startsWith('es');
    setState(() => _confirmingIssueAll = true);
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.publish_outlined, size: 28),
          title:
              Text(isEs ? 'Emitir todas las facturas' : 'Issue all invoices'),
          content: Text(
            isEs
                ? 'Se emitirán ${drafts.length} facturas. El servidor determinará el orden cronológico y asignará la numeración.'
                : '${drafts.length} invoices will be issued. The server will determine the chronological order and assign numbering.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.publish_outlined, size: 16),
              label: Text(isEs ? 'Emitir todas' : 'Issue all'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _confirmingIssueAll = false);
    }
    if (confirmed != true || !mounted || _issuingAll) return;

    setState(() => _issuingAll = true);
    try {
      await widget.onIssueAll!(drafts);
    } finally {
      if (mounted) setState(() => _issuingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = widget.typography;
    final cs = widget.colorScheme;
    final isEs = l.localeName.toLowerCase().startsWith('es');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // ── Invoice list panel ─────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: DefaultTabController(
              length: 2,
              child: Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Tab bar + Emitir todos button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 10, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TabBar(
                              dividerColor: Colors.transparent,
                              labelStyle: t.bodySmall
                                  .copyWith(fontWeight: FontWeight.w700),
                              tabs: [
                                Tab(
                                  text:
                                      '${isEs ? 'Borradores' : 'Drafts'} (${widget.drafts.length})',
                                ),
                                Tab(
                                  text:
                                      '${isEs ? 'Facturas' : 'Invoices'} (${widget.invoices.length})',
                                ),
                              ],
                            ),
                          ),
                          if (widget.onIssueAll != null &&
                              widget.drafts.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _IssueAllButton(
                              count: widget.drafts.length,
                              loading: _issuingAll,
                              isEs: isEs,
                              onTap: () => _handleIssueAll(l),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Drafts tab
                          widget.drafts.isEmpty
                              ? _EmptyTab(
                                  icon: Icons.drafts_outlined,
                                  label: isEs ? 'Sin borradores' : 'No drafts',
                                  cs: cs,
                                  t: t,
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(10),
                                  itemCount: widget.drafts.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (_, i) {
                                    final inv = widget.drafts[i];
                                    final client =
                                        _clientOrUnknown(l, inv.clientId);
                                    return widget.invoiceItemBuilder(
                                      inv,
                                      client,
                                      onTap: () => widget.onSelectInvoice(inv),
                                      onDelete: () => widget.onDeleteDraft(inv),
                                      onEdit: () => widget.onEditDraft(inv),
                                    );
                                  },
                                ),

                          // Issued invoices tab
                          widget.invoices.isEmpty
                              ? _EmptyTab(
                                  icon: Icons.receipt_long_outlined,
                                  label: isEs
                                      ? 'Sin facturas emitidas'
                                      : 'No invoices',
                                  cs: cs,
                                  t: t,
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(10),
                                  itemCount: widget.invoices.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (_, i) {
                                    final inv = widget.invoices[i];
                                    final client =
                                        _clientOrUnknown(l, inv.clientId);
                                    return widget.invoiceItemBuilder(
                                      inv,
                                      client,
                                      onTap: () => widget.onSelectInvoice(inv),
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

          // ── Detail panel ───────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: widget.selectedInvoice == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isEs
                                ? 'Selecciona una factura'
                                : 'Select an invoice',
                            style: t.bodyMedium
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : widget.detailBuilder(widget.selectedInvoice!),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Emitir todos button ────────────────────────────────────────────────────────

class _IssueAllButton extends StatefulWidget {
  final int count;
  final bool loading;
  final bool isEs;
  final VoidCallback onTap;

  const _IssueAllButton({
    required this.count,
    required this.loading,
    required this.isEs,
    required this.onTap,
  });

  @override
  State<_IssueAllButton> createState() => _IssueAllButtonState();
}

class _IssueAllButtonState extends State<_IssueAllButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Tooltip(
      message: widget.isEs
          ? 'Emitir los ${widget.count} borradores de una vez'
          : 'Issue all ${widget.count} drafts at once',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.loading ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _hovered
                  ? cs.tertiary.withValues(alpha: 0.18)
                  : cs.tertiary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: _hovered
                    ? cs.tertiary.withValues(alpha: 0.5)
                    : cs.tertiary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.loading)
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.tertiary,
                    ),
                  )
                else
                  Icon(
                    Icons.publish_outlined,
                    size: 14,
                    color: cs.tertiary,
                  ),
                const SizedBox(width: 5),
                Text(
                  widget.isEs ? 'Emitir todos' : 'Issue all',
                  style: t.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.tertiary,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: cs.tertiary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: cs.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final AppTypography t;

  const _EmptyTab({
    required this.icon,
    required this.label,
    required this.cs,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 36, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Text(
            label,
            style: t.bodyMedium
                .copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
