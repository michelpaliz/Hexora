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
  bool _initialDocumentOpened = false;

  static const _tabs = [
    _InvoicesMobileTab.facturas,
    _InvoicesMobileTab.recibos,
    _InvoicesMobileTab.presupuestos,
    _InvoicesMobileTab.clientes,
  ];

  // ── budget state ─────────────────────────────────────────────────────────
  final _presupuestosApi = PresupuestosApi();
  List<Map<String, dynamic>> _budgets = [];
  bool _loadingBudgets = false;
  String? _budgetsError;

  @override
  void initState() {
    super.initState();
    final route = widget.state.widget;
    final menu = route.initialMenu ?? '';
    final initialTab =
        route.initialBudgetId != null || menu.startsWith('budgets')
            ? 2
            : route.initialReceiptId != null || menu.startsWith('receipts')
                ? 1
                : menu == 'clients'
                    ? 3
                    : 0;
    _tabController = TabController(
        length: _tabs.length, initialIndex: initialTab, vsync: this);
    _loadBudgets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openInitialDocument() {
    final s = widget.state;
    if (_initialDocumentOpened || s._loading) return;
    _initialDocumentOpened = true;
    final route = s.widget;
    final budgetId = route.initialBudgetId?.trim() ?? '';
    final receiptId = route.initialReceiptId?.trim() ?? '';
    final invoiceId = route.initialInvoiceId?.trim() ?? '';
    if (budgetId.isEmpty && receiptId.isEmpty && invoiceId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (budgetId.isNotEmpty) {
        _openBudgetDetail({'_id': budgetId});
        return;
      }
      if (receiptId.isNotEmpty) {
        for (final receipt in [...s._receipts, ...s._receiptDrafts]) {
          if (receipt.id == receiptId) {
            _openReceiptDetail(receipt);
            return;
          }
        }
      } else {
        for (final invoice in [...s._invoices, ...s._drafts]) {
          if (invoice.id == invoiceId) {
            _openInvoiceDetail(invoice);
            return;
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'es'
              ? 'No se encontró el documento. Actualiza la lista o comprueba tu acceso.'
              : 'Document not found. Refresh the list or check your access.')));
    });
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DocumentDetailPage(
        title:
            '${l.localeName.startsWith('es') ? 'Factura' : 'Invoice'} ${inv.invoiceNumber}',
        child: InvoiceDetailSheet(
          fullPage: true,
          key: ValueKey(inv.id),
          invoice: inv,
          client: _clientForInvoice(inv, l),
          billingProfile: s._billingProfile,
          group: s.widget.group,
          onInvoiceChanged: s._refreshInvoiceListsOnly,
        ),
      ),
    ));
  }

  void _openReceiptDetail(Receipt r) {
    final l = AppLocalizations.of(context)!;
    final s = widget.state;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DocumentDetailPage(
        title: '${l.receiptsTitle} ${r.receiptNumber ?? ''}',
        child: ReceiptDetailCard(
          fullPage: true,
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
          onMarkSent: () {
            Navigator.of(context).maybePop();
            s._markReceiptSent(r);
          },
          onMarkUnsent: () {
            Navigator.of(context).maybePop();
            s._markReceiptUnsent(r);
          },
          onLoadInlinePdf: () => s._loadReceiptInlinePdfBytes(r),
        ),
      ),
    ));
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

  String _budgetClientName(Map<String, dynamic> b) {
    final direct = presupuestoDocumentClientName(b);
    if (direct.isNotEmpty) return direct;
    final clientId = (b['clientId'] ?? '').toString().trim();
    if (clientId.isEmpty) return '';
    for (final client in widget.state._clients) {
      if (client.id == clientId) return client.name;
    }
    return '';
  }

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

  num? _budgetTotal(Map<String, dynamic> b) => presupuestoDocumentAmount(b);

  // ── budget actions ───────────────────────────────────────────────────────

  Future<void> _loadBudgets() async {
    if (!mounted) return;
    setState(() {
      _loadingBudgets = true;
      _budgetsError = null;
    });
    try {
      final groupId = widget.state.widget.group.id;
      final list = await _presupuestosApi.listByGroup(
        groupId: groupId,
        presupuestoKind: PresupuestoKind.structured,
      );
      if (!mounted) return;
      setState(() {
        _budgets = list
            .where((item) => !presupuestoHasDocumentContent(item))
            .toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _budgetsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingBudgets = false);
    }
  }

  Future<void> _openBudgetDetail(Map<String, dynamic> budget) async {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    var busy = false;
    var detailFuture = _presupuestosApi.getById(_budgetId(budget));
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (pageContext) =>
          StatefulBuilder(builder: (context, setPageState) {
        return FutureBuilder<Map<String, dynamic>>(
            future: detailFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return DocumentDetailPage(
                  title: isEs ? 'Presupuesto' : 'Quote',
                  child: Center(
                      child: snapshot.hasError
                          ? TextButton.icon(
                              onPressed: () => setPageState(() {
                                detailFuture =
                                    _presupuestosApi.getById(_budgetId(budget));
                              }),
                              icon: const Icon(Icons.refresh),
                              label: Text(isEs
                                  ? 'Reintentar cargar presupuesto'
                                  : 'Retry loading quote'),
                            )
                          : const CircularProgressIndicator()),
                );
              }
              final document = snapshot.data!;
              Future<void> run(Future<void> Function() action,
                  {bool close = true}) async {
                if (busy) return;
                setPageState(() => busy = true);
                try {
                  await action();
                  if (!context.mounted) return;
                  if (close) Navigator.of(context).pop();
                } catch (_) {
                  if (context.mounted) {
                    showErrorSnack(
                        context,
                        isEs
                            ? 'No se pudo completar la acción. Inténtalo de nuevo.'
                            : 'Could not complete the action. Try again.');
                  }
                } finally {
                  if (context.mounted) setPageState(() => busy = false);
                }
              }

              final lines = document['lines'] is List
                  ? document['lines'] as List
                  : const [];
              return DocumentDetailPage(
                title:
                    '${isEs ? 'Presupuesto' : 'Quote'} ${_budgetNumber(document)}',
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(_budgetClientName(document),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_budgetDate(document)),
                    const SizedBox(height: 8),
                    Text(_budgetIsDraft(document)
                        ? (isEs ? 'Borrador' : 'Draft')
                        : (isEs ? 'Emitido' : 'Issued')),
                    const SizedBox(height: 16),
                    Text(
                        '${document['currency'] ?? 'EUR'} ${_budgetTotal(document)?.toStringAsFixed(2) ?? '—'}',
                        style: Theme.of(context).textTheme.headlineSmall),
                    if ((document['notes'] ?? '').toString().trim().isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(document['notes'].toString())),
                    for (final line in lines.whereType<Map>())
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                              (line['description'] ?? line['name'] ?? '')
                                  .toString()),
                          subtitle: Text(
                              '${line['quantity'] ?? ''} × ${line['unitPrice'] ?? ''}')),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => run(() async {
                                final response = await _presupuestosApi
                                    .previewPdf(_budgetId(document));
                                final bytes =
                                    InvoiceEditorPdf.validatePdf(response);
                                await pdf_launcher.launchPdfPreview(bytes,
                                    fileName:
                                        'presupuesto-${_budgetNumber(document)}.pdf');
                              }, close: false),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label:
                          Text(AppLocalizations.of(context)!.invoicePreviewCta),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => run(() async {
                                final response = await _presupuestosApi
                                    .downloadPdf(_budgetId(document));
                                await launchFileDownload(response.bodyBytes,
                                    fileName:
                                        'presupuesto-${_budgetNumber(document)}.pdf',
                                    mimeType: 'application/pdf');
                              }, close: false),
                      icon: const Icon(Icons.download_outlined),
                      label: Text(isEs ? 'Descargar PDF' : 'Download PDF'),
                    ),
                    if (_budgetIsDraft(document)) ...[
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () => run(() async {
                                  await _presupuestosApi
                                      .issue(_budgetId(document));
                                }),
                        child:
                            Text(isEs ? 'Emitir presupuesto' : 'Issue quote'),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => run(() async {
                                  await _presupuestosApi
                                      .remove(_budgetId(document));
                                }),
                        child: Text(isEs ? 'Eliminar borrador' : 'Delete draft',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ),
                    ] else
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () => run(() async {
                                  await _presupuestosApi
                                      .convertToInvoice(_budgetId(document));
                                  await widget.state._refreshInvoiceListsOnly();
                                }),
                        child: Text(isEs
                            ? 'Convertir a factura'
                            : 'Convert to invoice'),
                      ),
                    if (busy) const LinearProgressIndicator(),
                  ],
                ),
              );
            });
      }),
    ));
    if (mounted) await _loadBudgets();
  }

  // ── tab builders ────────────────────────────────────────────────────────────

  Widget _buildFacturasTab(AppLocalizations l) {
    final s = widget.state;
    final all = [...s._drafts, ...s._invoices];
    if (all.isEmpty) {
      return _EmptyTab(
        icon: Icons.receipt_long_outlined,
        label: l.noInvoicesYet,
      );
    }

    return MobileDocumentList<Invoice>(
      items: all,
      dateOf: (inv) => inv.issueDate ?? inv.registeredAt ?? inv.occurrenceDate,
      itemBuilder: (_, inv) {
        final invDraft = inv.isDraft;
        return Padding(
          key: ValueKey(inv.id),
          padding: EdgeInsets.zero,
          child: InvoiceListItem(
            mobile: true,
            invoice: inv,
            client: _clientForInvoice(inv, l),
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
    return MobileDocumentList<Receipt>(
      items: all,
      dateOf: (receipt) => receipt.registeredAt ?? receipt.issueDate,
      itemBuilder: (_, r) {
        final isDraft = (r.status ?? '').toLowerCase().contains('draft') ||
            (r.status ?? '').trim().isEmpty;
        return ReceiptListItem(
          receipt: r,
          client: _clientFor(r.clientId, l),
          onTap: () => _openReceiptDetail(r),
          onPreview: () async => _openReceiptDetail(r),
          onDownload: () => s._downloadReceiptPdf(r),
          onIssue: isDraft ? () => s._issueReceipt(r) : null,
          onDelete: isDraft ? () => s._deleteReceipt(r) : null,
          onMarkSent:
              receiptCanMarkSent(r) ? () => s._markReceiptSent(r) : null,
          onMarkUnsent:
              receiptCanMarkUnsent(r) ? () => s._markReceiptUnsent(r) : null,
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

    return MobileClientSearchList(
      clients: clients,
      itemBuilder: (_, c) {
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
              FocusScope.of(context).unfocus();
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
      child: MobileDocumentList<Map<String, dynamic>>(
        items: _budgets,
        dateOf: (b) => DateTime.tryParse((b['issueDate'] ??
                b['registeredAt'] ??
                b['createdAt'] ??
                b['occurrenceDate'] ??
                '')
            .toString()),
        itemBuilder: (_, b) {
          final number = _budgetNumber(b);
          final clientName = _budgetClientName(b);
          final dateLabel = _budgetDate(b);
          final total = _budgetTotal(b);
          final totalLabel = total == null
              ? (isSpanish ? 'Importe no disponible' : 'Amount unavailable')
              : NumberFormat.currency(locale: l.localeName, symbol: '€')
                  .format(total);
          return MobileDocumentCard(
            title: clientName.isEmpty ? l.unknownClient : clientName,
            amount: totalLabel,
            metadata: [number, dateLabel]
                .where((value) => value.isNotEmpty)
                .join(' · '),
            isDraft: _budgetIsDraft(b),
            statusLabel: _budgetIsDraft(b) ? l.statusDraft : l.statusIssued,
            onTap: () => _openBudgetDetail(b),
          );
        },
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _openInitialDocument();
    final l = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final s = widget.state;

    final tabBar = MobileSectionTabs(
      scrollable: true,
      controller: _tabController,
      labels: [
        isSpanish ? 'Facturas' : 'Invoices',
        isSpanish ? 'Recibos' : l.receiptsTitle,
        isSpanish ? 'Presupuestos' : 'Quotes',
        isSpanish ? 'Clientes' : 'Clients',
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
                    _buildPresupuestosTab(l),
                    _buildClientesTab(l),
                  ],
                ),
        ),
      ],
    );

    if (s.widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: SectionAppBar(title: isSpanish ? 'Facturas' : 'Invoices'),
      body: SafeArea(child: body),
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
  late GroupClient _client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _client = widget.client;
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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DocumentDetailPage(
        title:
            '${Localizations.localeOf(context).languageCode == 'es' ? 'Factura' : 'Invoice'} ${inv.invoiceNumber}',
        child: InvoiceDetailSheet(
          fullPage: true,
          key: ValueKey(inv.id),
          invoice: inv,
          client: widget.client,
          billingProfile: s._billingProfile,
          group: s.widget.group,
          onInvoiceChanged: _refresh,
        ),
      ),
    ));
  }

  GroupClient _clientFor(String? clientId) {
    return widget.state._clients.firstWhere(
      (c) => c.id == clientId,
      orElse: () => _client,
    );
  }

  Future<void> _editClient() async {
    final s = widget.state;
    final updated = await showClientEditor(
      context: context,
      groupId: s.widget.group.id,
      api: s._clientsApi,
      client: _client,
      existingClients: s._clients,
    );
    if (updated == null || !mounted) return;
    setState(() => _client = updated);
    s.setState(() {
      final idx = s._clients.indexWhere((x) => x.id == updated.id);
      if (idx != -1) s._clients[idx] = updated;
      if (s._selectedClient?.id == updated.id) s._selectedClient = updated;
    });
    final l = AppLocalizations.of(context)!;
    showSuccessSnack(context, l.clientUpdatedWithName(updated.name));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final s = widget.state;
    final c = _client;

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
            key: ValueKey(inv.id),
            padding: const EdgeInsets.only(bottom: 6),
            child: InvoiceListItem(
              mobile: true,
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

    return Scaffold(
      appBar: SectionAppBar(
        title: c.name,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.edit_outlined, size: 19),
              tooltip: l.edit,
              onPressed: _editClient,
              style: IconButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                minimumSize: const Size(38, 38),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ClientInvoicesMobileTabBar(
                controller: _tabController,
                issuedCount: issuedInvoices.length,
                draftCount: draftInvoices.length,
              ),
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

class ClientInvoicesMobileTabBar extends StatelessWidget {
  const ClientInvoicesMobileTabBar({
    super.key,
    required this.controller,
    required this.issuedCount,
    required this.draftCount,
  });

  final TabController controller;
  final int issuedCount;
  final int draftCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
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
      labelStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
      tabs: [
        Tab(
          height: 44,
          text: l.groupInvoicesTabInvoices(issuedCount),
        ),
        Tab(
          height: 44,
          text: l.groupInvoicesTabDrafts(draftCount),
        ),
        Tab(height: 44, text: l.contractsTitle),
      ],
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
      padding: EdgeInsets.only(top: first ? 4 : 12, bottom: 5),
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
