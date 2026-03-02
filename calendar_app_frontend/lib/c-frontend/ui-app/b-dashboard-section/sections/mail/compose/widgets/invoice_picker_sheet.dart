part of '../../mail_compose_screen.dart';

class _InvoicePickerResult {
  final String clientId;
  final List<String> invoiceIds;
  final List<String> presupuestoIds;
  final List<String> receiptIds;

  const _InvoicePickerResult({
    required this.clientId,
    required this.invoiceIds,
    required this.presupuestoIds,
    required this.receiptIds,
  });
}

class _InvoicePickerSheet extends StatefulWidget {
  const _InvoicePickerSheet({
    required this.clients,
    required this.initialClientId,
    required this.initialInvoiceIds,
    required this.initialPresupuestoIds,
    required this.initialReceiptIds,
    required this.onLoadInvoices,
    required this.onLoadReceipts,
    required this.onLoadPresupuestos,
    required this.onPreviewPresupuesto,
    this.embedded = false,
    this.splitColumns = false,
    this.onApply,
    this.onClose,
  });

  final List<GroupClient> clients;
  final String initialClientId;
  final List<String> initialInvoiceIds;
  final List<String> initialPresupuestoIds;
  final List<String> initialReceiptIds;
  final Future<List<Invoice>> Function(String clientId) onLoadInvoices;
  final Future<List<Receipt>> Function(String clientId) onLoadReceipts;
  final Future<List<Map<String, dynamic>>> Function(String clientId)
      onLoadPresupuestos;
  final Future<void> Function(String presupuestoId) onPreviewPresupuesto;
  final bool embedded;
  final bool splitColumns;
  final ValueChanged<_InvoicePickerResult>? onApply;
  final VoidCallback? onClose;

  @override
  State<_InvoicePickerSheet> createState() => _InvoicePickerSheetState();
}

class _InvoicePickerSheetState extends State<_InvoicePickerSheet> {
  final _invoiceSearchCtrl = TextEditingController();
  late String _clientId;
  late Set<String> _selectedInvoiceIds;
  late Set<String> _selectedPresupuestoIds;
  late Set<String> _selectedReceiptIds;
  bool _showClientPicker = true;

  bool _loadingInvoices = false;
  bool _loadingReceipts = false;
  bool _loadingPresupuestos = false;
  List<Invoice> _invoices = const [];
  List<Receipt> _receipts = const [];
  List<Map<String, dynamic>> _presupuestos = const [];

  @override
  void initState() {
    super.initState();
    _clientId = widget.initialClientId;
    _selectedInvoiceIds = widget.initialInvoiceIds.toSet();
    _selectedPresupuestoIds = widget.initialPresupuestoIds.toSet();
    _selectedReceiptIds = widget.initialReceiptIds.toSet();
    _showClientPicker = _clientId.trim().isEmpty;
    _fetchInvoices();
    _fetchReceipts();
    _fetchPresupuestos();
  }

  @override
  void dispose() {
    _invoiceSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
    if (widget.clients.isEmpty || _clientId.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadingInvoices = false;
        _invoices = const [];
      });
      return;
    }
    setState(() => _loadingInvoices = true);
    try {
      final list = await widget.onLoadInvoices(_clientId);
      if (!mounted) return;
      setState(() {
        _invoices = list;
        final available = list.map((e) => e.id).toSet();
        _selectedInvoiceIds =
            _selectedInvoiceIds.where(available.contains).toSet();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _invoices = const []);
    } finally {
      if (mounted) setState(() => _loadingInvoices = false);
    }
  }

  Future<void> _fetchReceipts() async {
    if (widget.clients.isEmpty || _clientId.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadingReceipts = false;
        _receipts = const [];
      });
      return;
    }
    setState(() => _loadingReceipts = true);
    try {
      final list = await widget.onLoadReceipts(_clientId);
      if (!mounted) return;
      setState(() {
        _receipts = list;
        final available = list.map((e) => e.id).toSet();
        _selectedReceiptIds =
            _selectedReceiptIds.where(available.contains).toSet();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _receipts = const []);
    } finally {
      if (mounted) setState(() => _loadingReceipts = false);
    }
  }

  String _presupuestoId(Map<String, dynamic> item) {
    return (item['_id'] ?? item['id'] ?? '').toString();
  }

  String _presupuestoNumber(Map<String, dynamic> item) {
    final number = (item['presupuestoNumber'] ?? item['budgetNumber'] ?? '')
        .toString()
        .trim();
    return number;
  }

  String _presupuestoStatus(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'draft').toString().trim();
    return status.isEmpty ? 'draft' : status;
  }

  Future<void> _fetchPresupuestos() async {
    if (widget.clients.isEmpty || _clientId.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadingPresupuestos = false;
        _presupuestos = const [];
      });
      return;
    }
    setState(() => _loadingPresupuestos = true);
    try {
      final list = await widget.onLoadPresupuestos(_clientId);
      if (!mounted) return;
      setState(() {
        _presupuestos = list;
        final available = list.map(_presupuestoId).toSet();
        _selectedPresupuestoIds =
            _selectedPresupuestoIds.where(available.contains).toSet();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _presupuestos = const []);
    } finally {
      if (mounted) setState(() => _loadingPresupuestos = false);
    }
  }

  GroupClient? get _selectedClient {
    final id = _clientId.trim();
    if (id.isEmpty) return null;
    for (final c in widget.clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  Widget _buildClientPanel(
    BuildContext context, {
    double clientListHeight = 220,
  }) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final selected = _selectedClient;

    if (!_showClientPicker && selected != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.person_outline, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected.name,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _showClientPicker = true),
              child: Text(l.change),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.invoiceBillToLabel,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClientSearchSelect(
              clients: widget.clients,
              selectedClientId: _clientId,
              onClientChanged: (value) {
                final id = value;
                if (id == null || id.isEmpty) return;
                setState(() {
                  _clientId = id;
                  _showClientPicker = false;
                });
                _fetchInvoices();
                _fetchReceipts();
                _fetchPresupuestos();
              },
              useDefaultPropertyKind: false,
              maxListHeight: clientListHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicePanel(
    BuildContext context,
    List<Invoice> filteredInvoices,
    List<Map<String, dynamic>> filteredPresupuestos,
    List<Receipt> filteredReceipts,
  ) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final selectedTotal = _selectedInvoiceIds.length +
        _selectedPresupuestoIds.length +
        _selectedReceiptIds.length;
    final busy = _loadingInvoices || _loadingPresupuestos || _loadingReceipts;
    final hasItems =
        filteredInvoices.isNotEmpty ||
        filteredPresupuestos.isNotEmpty ||
        filteredReceipts.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: cs.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _invoiceSearchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: l.mailComposeInvoiceIdsHint,
                      hintStyle: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    style: t.bodySmall,
                  ),
                ),
                if (_invoiceSearchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18, color: cs.onSurfaceVariant),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _invoiceSearchCtrl.clear();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.fact_check_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  '${l.mailComposeInvoiceIdsLabel}: ',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$selectedTotal',
                    style: t.bodySmall.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: busy
                ? const Center(child: CircularProgressIndicator())
                : !hasItems
                    ? Center(
                        child: Text(
                          l.noInvoicesYet,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final listHeight = constraints.maxHeight;
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest
                                            .withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.description_outlined,
                                            size: 16,
                                            color: cs.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            l.mailComposeInvoiceIdsLabel,
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cs.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${filteredInvoices.length + filteredPresupuestos.length}',
                                              style: t.bodySmall.copyWith(
                                                color: cs.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: ListView(
                                        children: [
                                          ...filteredInvoices.map((invoice) {
                                            final selected = _selectedInvoiceIds
                                                .contains(invoice.id);
                                            final status = invoice.status ?? 'draft';
                                            final isDraft = status.toLowerCase() == 'draft' ||
                                                status.toLowerCase() == 'borrador';
                                            final statusColor = isDraft
                                                ? cs.tertiary
                                                : cs.primary;
                                            final statusLabel = isDraft
                                                ? 'Borrador'
                                                : 'Emitida';

                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: selected
                                                      ? cs.primaryContainer
                                                          .withValues(alpha: 0.15)
                                                      : cs.surfaceContainerLowest,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: selected
                                                        ? cs.primary
                                                        : cs.outlineVariant
                                                            .withValues(alpha: 0.3),
                                                    width: selected ? 1.5 : 1,
                                                  ),
                                                ),
                                                child: ListTile(
                                                  dense: true,
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 2,
                                                  ),
                                                  title: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          invoice.invoiceNumber
                                                                  .trim()
                                                                  .isEmpty
                                                              ? invoice.id
                                                              : invoice.invoiceNumber,
                                                          style: t.bodySmall.copyWith(
                                                            fontWeight: FontWeight.w700,
                                                            color: cs.onSurface,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: statusColor
                                                              .withValues(alpha: 0.15),
                                                          borderRadius:
                                                              BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          statusLabel,
                                                          style: t.bodySmall.copyWith(
                                                            color: statusColor,
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  subtitle: Text(
                                                    invoice.id,
                                                    style: t.bodySmall.copyWith(
                                                      color: cs.onSurfaceVariant
                                                          .withValues(alpha: 0.7),
                                                      fontSize: 11,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  trailing: Checkbox(
                                                    value: selected,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        if (value == true) {
                                                          _selectedInvoiceIds
                                                              .add(invoice.id);
                                                        } else {
                                                          _selectedInvoiceIds
                                                              .remove(invoice.id);
                                                        }
                                                      });
                                                    },
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      if (selected) {
                                                        _selectedInvoiceIds
                                                            .remove(invoice.id);
                                                      } else {
                                                        _selectedInvoiceIds
                                                            .add(invoice.id);
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                            );
                                          }),
                                          if (filteredPresupuestos.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                                bottom: 8,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: cs.secondaryContainer
                                                      .withValues(alpha: 0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.assignment_outlined,
                                                      size: 16,
                                                      color: cs.secondary,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      l.budgetsMenuSection,
                                                      style: t.bodySmall.copyWith(
                                                        color: cs.onSurface,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: cs.secondary
                                                            .withValues(alpha: 0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        '${filteredPresupuestos.length}',
                                                        style: t.bodySmall.copyWith(
                                                          color: cs.secondary,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ...filteredPresupuestos.map((presupuesto) {
                                            final id = _presupuestoId(presupuesto);
                                            final number =
                                                _presupuestoNumber(presupuesto);
                                            final selected =
                                                _selectedPresupuestoIds.contains(id);
                                            final status =
                                                _presupuestoStatus(presupuesto);
                                            final isDraft =
                                                status.toLowerCase() == 'draft' ||
                                                    status.toLowerCase() == 'borrador';
                                            final statusColor = isDraft
                                                ? cs.tertiary
                                                : cs.secondary;
                                            final statusLabel =
                                                isDraft ? 'Borrador' : 'Aprobado';

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.only(bottom: 6),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: selected
                                                      ? cs.secondaryContainer
                                                          .withValues(alpha: 0.15)
                                                      : cs.surfaceContainerLowest,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: selected
                                                        ? cs.secondary
                                                        : cs.outlineVariant
                                                            .withValues(alpha: 0.3),
                                                    width: selected ? 1.5 : 1,
                                                  ),
                                                ),
                                                child: ListTile(
                                                  dense: true,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 2,
                                                  ),
                                                  title: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          number.isEmpty ? id : number,
                                                          style: t.bodySmall.copyWith(
                                                            fontWeight: FontWeight.w700,
                                                            color: cs.onSurface,
                                                          ),
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: statusColor
                                                              .withValues(alpha: 0.15),
                                                          borderRadius:
                                                              BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          statusLabel,
                                                          style: t.bodySmall.copyWith(
                                                            color: statusColor,
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  subtitle: Text(
                                                    id,
                                                    style: t.bodySmall.copyWith(
                                                      color: cs.onSurfaceVariant
                                                          .withValues(alpha: 0.7),
                                                      fontSize: 11,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        tooltip: l.preview,
                                                        constraints:
                                                            const BoxConstraints(
                                                          minWidth: 32,
                                                          minHeight: 32,
                                                        ),
                                                        padding: const EdgeInsets.all(4),
                                                        onPressed: id.isEmpty
                                                            ? null
                                                            : () => widget
                                                                .onPreviewPresupuesto(id),
                                                        icon: Icon(
                                                          Icons.visibility_outlined,
                                                          size: 18,
                                                          color: cs.secondary
                                                              .withValues(alpha: 0.8),
                                                        ),
                                                      ),
                                                      Checkbox(
                                                        value: selected,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            if (value == true) {
                                                              _selectedPresupuestoIds
                                                                  .add(id);
                                                            } else {
                                                              _selectedPresupuestoIds
                                                                  .remove(id);
                                                            }
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      if (selected) {
                                                        _selectedPresupuestoIds.remove(
                                                          id,
                                                        );
                                                      } else {
                                                        _selectedPresupuestoIds.add(id);
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest
                                            .withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.receipt_long_outlined,
                                            size: 16,
                                            color: cs.tertiary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Recibos',
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cs.tertiary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${filteredReceipts.length}',
                                              style: t.bodySmall.copyWith(
                                                color: cs.tertiary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: listHeight - 28,
                                      child: ListView(
                                        children: filteredReceipts.map((r) {
                                          final selected =
                                              _selectedReceiptIds.contains(r.id);
                                          final number =
                                              (r.receiptNumber?.trim().isNotEmpty ==
                                                      true)
                                                  ? r.receiptNumber!.trim()
                                                  : r.id;
                                          final status = r.status ?? 'draft';
                                          final isDraft =
                                              status.toLowerCase() == 'draft' ||
                                                  status.toLowerCase() == 'borrador';
                                          final statusColor =
                                              isDraft ? cs.tertiary : cs.primary;
                                          final statusLabel =
                                              isDraft ? 'Borrador' : 'Emitido';

                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(bottom: 6),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? cs.tertiaryContainer
                                                        .withValues(alpha: 0.15)
                                                    : cs.surfaceContainerLowest,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: selected
                                                      ? cs.tertiary
                                                      : cs.outlineVariant
                                                          .withValues(alpha: 0.3),
                                                  width: selected ? 1.5 : 1,
                                                ),
                                              ),
                                              child: ListTile(
                                                dense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 2,
                                                ),
                                                title: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        number,
                                                        style: t.bodySmall.copyWith(
                                                          fontWeight: FontWeight.w700,
                                                          color: cs.onSurface,
                                                        ),
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: statusColor
                                                            .withValues(alpha: 0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        statusLabel,
                                                        style: t.bodySmall.copyWith(
                                                          color: statusColor,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                subtitle: Text(
                                                  r.id,
                                                  style: t.bodySmall.copyWith(
                                                    color: cs.onSurfaceVariant
                                                        .withValues(alpha: 0.7),
                                                    fontSize: 11,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                trailing: Checkbox(
                                                  value: selected,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      if (value == true) {
                                                        _selectedReceiptIds.add(r.id);
                                                      } else {
                                                        _selectedReceiptIds
                                                            .remove(r.id);
                                                      }
                                                    });
                                                  },
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    if (selected) {
                                                      _selectedReceiptIds.remove(r.id);
                                                    } else {
                                                      _selectedReceiptIds.add(r.id);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                          );
                                        }).toList(growable: false),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final material = MaterialLocalizations.of(context);
    final q = _invoiceSearchCtrl.text.trim().toLowerCase();
    final filteredInvoices = _invoices.where((invoice) {
      if (q.isEmpty) return true;
      final haystack = <String>[
        invoice.invoiceNumber,
        invoice.id,
        invoice.status ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
    final filteredPresupuestos = _presupuestos.where((item) {
      if (q.isEmpty) return true;
      final haystack = <String>[
        _presupuestoNumber(item),
        _presupuestoId(item),
        _presupuestoStatus(item),
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList(growable: false);
    final filteredReceipts = _receipts.where((receipt) {
      if (q.isEmpty) return true;
      final number = receipt.receiptNumber ?? '';
      final status = receipt.status ?? '';
      final haystack = '$number ${receipt.id} $status'.toLowerCase();
      return haystack.contains(q);
    }).toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.mailComposeInvoiceOptions,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: material.closeButtonTooltip,
                  onPressed: () {
                    if (widget.embedded) {
                      widget.onClose?.call();
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (widget.splitColumns) {
                    final clientListHeight =
                        (constraints.maxHeight - 150).clamp(90, 260).toDouble();
                    return Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildClientPanel(
                            context,
                            clientListHeight: clientListHeight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: _buildInvoicePanel(
                            context,
                            filteredInvoices,
                            filteredPresupuestos,
                            filteredReceipts,
                          ),
                        ),
                      ],
                    );
                  }

                  final maxClientHeight = _showClientPicker
                      ? (constraints.maxHeight * 0.42)
                          .clamp(160, 280)
                          .toDouble()
                      : 70.0;
                  final clientListHeight =
                      (maxClientHeight - 66).clamp(80, 210).toDouble();

                  return Column(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxClientHeight),
                        child: _buildClientPanel(
                          context,
                          clientListHeight: clientListHeight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _buildInvoicePanel(
                          context,
                          filteredInvoices,
                          filteredPresupuestos,
                          filteredReceipts,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (widget.embedded) {
                        widget.onClose?.call();
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(material.cancelButtonLabel),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: widget.clients.isEmpty
                        ? null
                        : () {
                            final result = _InvoicePickerResult(
                              clientId: _clientId,
                              invoiceIds: _selectedInvoiceIds.toList(),
                              presupuestoIds: _selectedPresupuestoIds.toList(),
                              receiptIds: _selectedReceiptIds.toList(),
                            );
                            if (widget.embedded) {
                              widget.onApply?.call(result);
                              return;
                            }
                            Navigator.of(context).pop(result);
                          },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(material.okButtonLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
