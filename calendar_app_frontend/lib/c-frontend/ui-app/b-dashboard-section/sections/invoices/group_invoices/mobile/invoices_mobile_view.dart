part of '../../group_invoices_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mobile layout for the invoices section.
// Shows four tabs: Facturas | Recibos | Clientes | Presupuestos
// Each tab is a simple scrollable list; tapping an item opens a bottom sheet.
// ─────────────────────────────────────────────────────────────────────────────

enum _InvoicesMobileTab { facturas, recibos, clientes, presupuestos }

class _InvoicesMobileView extends StatefulWidget {
  const _InvoicesMobileView({required this.state});
  final _GroupInvoicesScreenState state;

  @override
  State<_InvoicesMobileView> createState() => _InvoicesMobileViewState();
}

class _InvoicesMobileViewState extends State<_InvoicesMobileView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    _InvoicesMobileTab.facturas,
    _InvoicesMobileTab.recibos,
    _InvoicesMobileTab.clientes,
    _InvoicesMobileTab.presupuestos,
  ];

  // ── budget state ─────────────────────────────────────────────────────────
  final _presupuestosApi = PresupuestosApi();
  List<Map<String, dynamic>> _budgets = [];
  bool _loadingBudgets = false;
  String? _budgetsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadBudgets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  String _monthLabel(DateTime date, bool isSpanish) {
    const es = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${(isSpanish ? es : en)[date.month - 1]} ${date.year}';
  }

  GroupClient _clientFor(String? clientId, AppLocalizations l) {
    final s = widget.state;
    return s._clients.firstWhere(
      (c) => c.id == clientId,
      orElse: () => GroupClient(
        id: clientId ?? '',
        name: l.unknownClient,
        isActive: true,
      ),
    );
  }

  GroupClient _clientForInvoice(Invoice invoice, AppLocalizations l) {
    final clientId = invoice.clientId.trim();
    for (final client in widget.state._clients) {
      if (client.id == clientId) return client;
    }
    final fallbackName = [
      invoice.billingName,
      invoice.clientSnapshot?.legalName,
    ].map((value) => value?.trim() ?? '').firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => l.unknownClient,
        );
    return GroupClient(
      id: clientId,
      name: fallbackName,
      isActive: true,
      billing: invoice.clientSnapshot,
    );
  }

  void _openInvoiceDetail(Invoice inv) {
    final l = AppLocalizations.of(context)!;
    final s = widget.state;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => InvoiceDetailSheet(
          key: ValueKey(inv.id),
          invoice: inv,
          client: _clientForInvoice(inv, l),
          billingProfile: s._billingProfile,
          group: s.widget.group,
          onInvoiceChanged: s._refreshInvoiceListsOnly,
        ),
      ),
    );
  }

  void _openReceiptDetail(Receipt r) {
    final l = AppLocalizations.of(context)!;
    final s = widget.state;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => ReceiptDetailCard(
          key: ValueKey(r.id),
          receipt: r,
          client: _clientFor(r.clientId, l),
          billingProfile: s._billingProfile,
          onEdit: () {
            Navigator.of(context).maybePop();
            s._openEditReceipt(r);
          },
          onPreviewPdf: () => s._previewReceiptPdf(r),
          onDownloadPdf: () => s._downloadReceiptPdf(r),
          onIssue: () {
            Navigator.of(context).maybePop();
            s._issueReceipt(r);
          },
          onDeleteDraft: () {
            Navigator.of(context).maybePop();
            s._deleteReceipt(r);
          },
          onImportJson: () => s._openReceiptJsonImportDialog(r),
          onLoadInlinePdf: () => s._loadReceiptInlinePdfBytes(r),
        ),
      ),
    );
  }

  // ── budget helpers ───────────────────────────────────────────────────────

  String _budgetId(Map<String, dynamic> b) =>
      (b['_id'] ?? b['id'] ?? '').toString();

  String _budgetNumber(Map<String, dynamic> b) =>
      (b['presupuestoNumber'] ?? b['budgetNumber'] ?? '').toString();

  bool _budgetIsDraft(Map<String, dynamic> b) {
    final status = (b['status'] ?? '').toString().toLowerCase();
    return status.isEmpty ||
        status.contains('draft') ||
        status.contains('borrador');
  }

  String _budgetClientName(Map<String, dynamic> b) =>
      (b['clientName'] ?? (b['client'] as Map?)?['name'] ?? '').toString();

  String _budgetDate(Map<String, dynamic> b) {
    final raw = b['issueDate'] ??
        b['registeredAt'] ??
        b['createdAt'] ??
        b['occurrenceDate'];
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      return '$d/$m/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  num? _budgetTotal(Map<String, dynamic> b) {
    final v =
        b['total'] ?? b['grandTotal'] ?? b['amountTotal'] ?? b['subtotal'];
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  // ── budget actions ───────────────────────────────────────────────────────

  Future<void> _loadBudgets() async {
    if (!mounted) return;
    setState(() {
      _loadingBudgets = true;
      _budgetsError = null;
    });
    try {
      final groupId = widget.state.widget.group.id;
      final list = await _presupuestosApi.listByGroup(groupId: groupId);
      if (!mounted) return;
      setState(() => _budgets = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _budgetsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingBudgets = false);
    }
  }

  Future<void> _issueBudget(Map<String, dynamic> b) async {
    try {
      await _presupuestosApi.issue(_budgetId(b));
      await _loadBudgets();
    } catch (_) {}
  }

  Future<void> _deleteBudget(Map<String, dynamic> b) async {
    try {
      await _presupuestosApi.remove(_budgetId(b));
      await _loadBudgets();
    } catch (_) {}
  }

  Future<void> _convertBudgetToInvoice(Map<String, dynamic> b) async {
    try {
      await _presupuestosApi.convertToInvoice(_budgetId(b));
      await _loadBudgets();
      await widget.state._refreshInvoiceListsOnly();
    } catch (_) {}
  }

  // ── tab builders ────────────────────────────────────────────────────────────

  Widget _buildFacturasTab(AppLocalizations l) {
    final s = widget.state;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final all = [...s._drafts, ...s._invoices];
    if (all.isEmpty) {
      return _EmptyTab(
        icon: Icons.receipt_long_outlined,
        label: l.noInvoicesYet,
      );
    }

    // Sort newest-first
    all.sort((a, b) {
      final da = a.issueDate ?? a.registeredAt ?? a.occurrenceDate;
      final db = b.issueDate ?? b.registeredAt ?? b.occurrenceDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    // Build flat list: String = month header, Invoice = row
    final items = <Object>[];
    String? lastKey;
    for (final inv in all) {
      final date = inv.issueDate ?? inv.registeredAt ?? inv.occurrenceDate;
      final key = date == null
          ? '__none__'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (key != lastKey) {
        items.add(date == null
            ? (isSpanish ? 'Sin fecha' : 'No date')
            : _monthLabel(date.toLocal(), isSpanish));
        lastKey = key;
      }
      items.add(inv);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is String) {
          return _MonthSectionHeader(label: item, first: i == 0);
        }
        final inv = item as Invoice;
        final invDraft = (inv.status ?? '').toLowerCase().contains('draft') ||
            (inv.status ?? '').trim().isEmpty;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InvoiceListItem(
            invoice: inv,
            client: _clientFor(inv.clientId, l),
            onTap: () => _openInvoiceDetail(inv),
            onDelete: invDraft ? () => s._deleteInvoice(inv) : null,
            onEdit: invDraft ? () => s._openEditDraft(inv) : null,
          ),
        );
      },
    );
  }

  Widget _buildRecibosTab(AppLocalizations l) {
    final s = widget.state;
    final all = [...s._receiptDrafts, ...s._receipts];
    if (all.isEmpty) {
      return _EmptyTab(
        icon: Icons.description_outlined,
        label: l.receiptsTitle,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: all.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final r = all[i];
        final isDraft = (r.status ?? '').toLowerCase().contains('draft') ||
            (r.status ?? '').trim().isEmpty;
        return ReceiptListItem(
          receipt: r,
          client: _clientFor(r.clientId, l),
          onTap: () => _openReceiptDetail(r),
          onPreview: () => s._previewReceiptPdf(r),
          onDownload: () => s._downloadReceiptPdf(r),
          onIssue: isDraft ? () => s._issueReceipt(r) : null,
          onDelete: isDraft ? () => s._deleteReceipt(r) : null,
        );
      },
    );
  }

  Widget _buildClientesTab(AppLocalizations l) {
    final s = widget.state;
    final clients = s._clients;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    if (clients.isEmpty) {
      return _EmptyTab(
        icon: Icons.people_outline,
        label: l.addClient,
      );
    }

    // Compact pill with icon + count; label is shown in tooltip.
    Widget countPill({
      required IconData icon,
      required int count,
      required Color color,
      required String label,
    }) {
      final hasItems = count > 0;
      final bg = hasItems
          ? color.withValues(alpha: 0.18)
          : cs.surfaceContainerHighest.withValues(alpha: 0.85);
      final fg = hasItems
          ? color.withValues(alpha: 0.98)
          : cs.onSurfaceVariant.withValues(alpha: 0.78);
      return Tooltip(
        message: '$label: $count',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: hasItems
                  ? color.withValues(alpha: 0.42)
                  : cs.outlineVariant.withValues(alpha: 0.48),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: t.bodySmall.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: clients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final c = clients[i];
        final issuedCount =
            s._invoices.where((inv) => inv.clientId == c.id).length;
        final draftCount =
            s._drafts.where((inv) => inv.clientId == c.id).length;
        final email =
            (c.email?.trim().isNotEmpty == true) ? c.email!.trim() : null;

        return Card(
          elevation: 0,
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.58)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ClientMobileInvoicesScreen(
                    client: c,
                    state: widget.state,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + optional email + count pills
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: t.bodyMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (email != null)
                          Text(
                            email,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      countPill(
                        icon: Icons.receipt_long_outlined,
                        count: issuedCount,
                        color: cs.primary,
                        label: isSpanish ? 'Facturas' : 'Invoices',
                      ),
                      const SizedBox(width: 6),
                      countPill(
                        icon: Icons.edit_outlined,
                        count: draftCount,
                        color: cs.tertiary,
                        label: isSpanish ? 'Borradores' : 'Drafts',
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: cs.onSurface.withValues(alpha: 0.72),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresupuestosTab(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    if (_loadingBudgets && _budgets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_budgetsError != null && _budgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: cs.error),
            const SizedBox(height: 8),
            Text(_budgetsError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadBudgets,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_budgets.isEmpty) {
      return _EmptyTab(
        icon: Icons.request_quote_outlined,
        label: isSpanish ? 'No hay presupuestos' : 'No quotes yet',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBudgets,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: _budgets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final b = _budgets[i];
          final isDraft = _budgetIsDraft(b);
          final number = _budgetNumber(b);
          final clientName = _budgetClientName(b);
          final dateLabel = _budgetDate(b);
          final total = _budgetTotal(b);
          final totalLabel =
              total == null ? '-' : 'EUR ${total.toStringAsFixed(2)}';

          return Card(
            margin: EdgeInsets.zero,
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: cs.secondaryContainer,
                    child: Icon(
                      Icons.request_quote_outlined,
                      size: 14,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                clientName.isEmpty ? '-' : clientName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              number,
                              style: t.bodyMedium.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDraft
                                    ? cs.tertiaryContainer
                                    : cs.primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isDraft
                                    ? (isSpanish ? 'Borrador' : 'Draft')
                                    : (isSpanish ? 'Emitido' : 'Issued'),
                                style: t.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDraft
                                      ? cs.onTertiaryContainer
                                      : cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (dateLabel.isNotEmpty) dateLabel,
                            totalLabel,
                          ].join(' · '),
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isDraft) ...[
                    IconButton(
                      onPressed: () => _issueBudget(b),
                      tooltip: isSpanish ? 'Emitir' : 'Issue',
                      visualDensity: VisualDensity.compact,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(Icons.publish_outlined, size: 20),
                      color: cs.tertiary.withValues(alpha: 0.8),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                    IconButton(
                      onPressed: () => _deleteBudget(b),
                      tooltip: isSpanish ? 'Eliminar' : 'Delete',
                      visualDensity: VisualDensity.compact,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: cs.error.withValues(alpha: 0.8),
                    ),
                  ] else
                    IconButton(
                      onPressed: () => _convertBudgetToInvoice(b),
                      tooltip: isSpanish
                          ? 'Convertir a factura'
                          : 'Convert to invoice',
                      visualDensity: VisualDensity.compact,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(Icons.receipt_long_outlined, size: 20),
                      color: cs.primary.withValues(alpha: 0.8),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final s = widget.state;

    final tabBar = TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.center,
      dividerColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStatePropertyAll(cs.primary.withValues(alpha: 0.08)),
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
      labelColor: cs.onPrimaryContainer,
      unselectedLabelColor: cs.onSurfaceVariant,
      labelStyle: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
      unselectedLabelStyle: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
      tabs: [
        Tab(
          height: 36,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.receipt_long_outlined, size: 15),
            const SizedBox(width: 5),
            Text(isSpanish ? 'Facturas' : 'Invoices'),
          ]),
        ),
        Tab(
          height: 36,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.description_outlined, size: 15),
            const SizedBox(width: 5),
            Text(isSpanish ? 'Recibos' : l.receiptsTitle),
          ]),
        ),
        Tab(
          height: 36,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.people_outline, size: 15),
            const SizedBox(width: 5),
            Text(isSpanish ? 'Clientes' : 'Clients'),
          ]),
        ),
        Tab(
          height: 36,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.request_quote_outlined, size: 15),
            const SizedBox(width: 5),
            Text(isSpanish ? 'Presupuestos' : 'Quotes'),
          ]),
        ),
      ],
    );

    final body = Column(
      children: [
        Material(
          color: Colors.transparent,
          child: tabBar,
        ),
        Expanded(
          child: s._loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFacturasTab(l),
                    _buildRecibosTab(l),
                    _buildClientesTab(l),
                    _buildPresupuestosTab(l),
                  ],
                ),
        ),
      ],
    );

    if (s.widget.embedded) {
      return body;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── title row ──────────────────────────────────────────────────
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        isSpanish ? 'Facturas' : 'Invoices',
                        style:
                            t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client detail screen (mobile)
// Shown when a client is tapped in the Clientes tab.
// Lists that client's issued invoices and draft invoices in two tabs.
// ─────────────────────────────────────────────────────────────────────────────

class _ClientMobileInvoicesScreen extends StatefulWidget {
  final GroupClient client;
  final _GroupInvoicesScreenState state;

  const _ClientMobileInvoicesScreen({
    required this.client,
    required this.state,
  });

  @override
  State<_ClientMobileInvoicesScreen> createState() =>
      _ClientMobileInvoicesScreenState();
}

class _ClientMobileInvoicesScreenState
    extends State<_ClientMobileInvoicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _monthLabel(DateTime date, bool isSpanish) {
    const es = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${(isSpanish ? es : en)[date.month - 1]} ${date.year}';
  }

  // Refreshes the parent state lists then rebuilds this screen.
  Future<void> _refresh() async {
    await widget.state._refreshInvoiceListsOnly();
    if (mounted) setState(() {});
  }

  void _openInvoiceDetail(Invoice inv) {
    final s = widget.state;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => InvoiceDetailSheet(
          key: ValueKey(inv.id),
          invoice: inv,
          client: widget.client,
          billingProfile: s._billingProfile,
          group: s.widget.group,
          onInvoiceChanged: _refresh,
        ),
      ),
    );
  }

  GroupClient _clientFor(String? clientId) {
    return widget.state._clients.firstWhere(
      (c) => c.id == clientId,
      orElse: () => widget.client,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final s = widget.state;
    final c = widget.client;

    final issuedInvoices =
        s._invoices.where((inv) => inv.clientId == c.id).toList();
    final draftInvoices =
        s._drafts.where((inv) => inv.clientId == c.id).toList();

    Widget buildList(List<Invoice> invoices, bool isDrafts) {
      if (invoices.isEmpty) {
        return _EmptyTab(
          icon: isDrafts ? Icons.drafts_outlined : Icons.receipt_long_outlined,
          label: isDrafts ? l.groupInvoicesDraftInvoicesTitle : l.noInvoicesYet,
        );
      }

      final isSpanish = Localizations.localeOf(context).languageCode == 'es';
      final items = <Object>[];
      String? lastKey;
      for (final inv in invoices) {
        final date = inv.issueDate ?? inv.registeredAt ?? inv.occurrenceDate;
        final key = date == null
            ? '__none__'
            : '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (key != lastKey) {
          items.add(date == null
              ? (isSpanish ? 'Sin fecha' : 'No date')
              : _monthLabel(date.toLocal(), isSpanish));
          lastKey = key;
        }
        items.add(inv);
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          if (item is String) {
            return _MonthSectionHeader(label: item, first: i == 0);
          }
          final inv = item as Invoice;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InvoiceListItem(
              invoice: inv,
              client: _clientFor(inv.clientId),
              onTap: () => _openInvoiceDetail(inv),
              onDelete: isDrafts
                  ? () async {
                      await s._deleteInvoice(inv);
                      await _refresh();
                    }
                  : null,
              onEdit: isDrafts
                  ? () async {
                      await s._openEditDraft(inv);
                      await _refresh();
                    }
                  : null,
            ),
          );
        },
      );
    }

    final tabBar = TabBar(
      controller: _tabController,
      isScrollable: true,
      dividerColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStatePropertyAll(cs.primary.withValues(alpha: 0.08)),
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
      labelColor: cs.onPrimaryContainer,
      unselectedLabelColor: cs.onSurfaceVariant,
      labelStyle: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
      unselectedLabelStyle: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
      tabs: [
        Tab(
          height: 36,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.receipt_long_outlined, size: 15),
            const SizedBox(width: 5),
            Text(l.groupInvoicesTabInvoices(issuedInvoices.length)),
          ]),
        ),
        Tab(
          height: 36,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.drafts_outlined, size: 15),
            const SizedBox(width: 5),
            Text(l.groupInvoicesTabDrafts(draftInvoices.length)),
          ]),
        ),
        Tab(
          height: 36,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.description_outlined, size: 15),
            const SizedBox(width: 5),
            Text(l.contractsTitle),
          ]),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest,
              foregroundColor: cs.primary,
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primaryContainer,
              child: Text(
                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                style: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                c.name,
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l.edit,
            onPressed: () async {
              await s._openEditClient(c);
              await _refresh();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: tabBar,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildList(issuedInvoices, false),
          buildList(draftInvoices, true),
          ClientContractsTab(
            key: ValueKey('mobile-contracts-${c.id}'),
            client: c,
            compact: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _MonthSectionHeader extends StatelessWidget {
  const _MonthSectionHeader({required this.label, this.first = false});
  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 4 : 16, bottom: 6),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            label,
            style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
