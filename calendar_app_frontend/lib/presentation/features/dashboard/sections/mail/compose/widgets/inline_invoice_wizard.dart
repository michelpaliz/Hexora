part of '../../mail_compose_screen.dart';

enum _DateFilter { all, thisMonth, thisYear }

class _InlineInvoiceFlowPanel extends StatelessWidget {
  const _InlineInvoiceFlowPanel({required this.state});

  final _MailComposeScreenState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (state._inlineInvoiceLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if ((state._inlineInvoiceError ?? '').trim().isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state._inlineInvoiceError!,
                style: t.bodySmall.copyWith(color: cs.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: state._prepareInlineInvoiceFlow,
                child: Text(l.refreshAction),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: _InlineInvoiceWizardPanel(state: state),
    );
  }
}

class _InlineInvoiceWizardPanel extends StatefulWidget {
  const _InlineInvoiceWizardPanel({required this.state});

  final _MailComposeScreenState state;

  @override
  State<_InlineInvoiceWizardPanel> createState() =>
      _InlineInvoiceWizardPanelState();
}

class _InlineInvoiceWizardPanelState extends State<_InlineInvoiceWizardPanel> {
  final TextEditingController _invoiceSearchCtrl = TextEditingController();
  int _step = 0;
  String? _clientId;
  _DateFilter _dateFilter = _DateFilter.all;
  // Tracks the last recipient-client we synced from the compose form so we can
  // detect a real change even though widget.state is the same mutable object.
  String? _lastSyncedRecipientClientId;
  bool _loadingInvoices = false;
  bool _loadingReceipts = false;
  bool _loadingPresupuestos = false;
  List<Invoice> _invoices = const [];
  List<Receipt> _receipts = const [];
  List<Map<String, dynamic>> _presupuestos = const [];
  Set<String> _selectedInvoiceIds = <String>{};
  Set<String> _selectedPresupuestoIds = <String>{};
  Set<String> _selectedReceiptIds = <String>{};

  @override
  void initState() {
    super.initState();
    final currentIds = widget.state._splitValues(
        widget.state._normalizeInvoiceIds(widget.state._invoiceIdsCtrl.text));
    _selectedInvoiceIds = currentIds.toSet();
    _selectedPresupuestoIds = {...widget.state._selectedPresupuestoIds};
    _selectedReceiptIds = {...widget.state._selectedReceiptIds};
    // If the compose form is already in "client mode", pre-select that client.
    final recipientId =
        widget.state._useClientMode ? widget.state._recipientClientId : null;
    _lastSyncedRecipientClientId = recipientId;
    _clientId = recipientId ??
        widget.state._inlineClientId ??
        (widget.state._pickerClients.isNotEmpty
            ? widget.state._pickerClients.first.id
            : null);
    if (_clientId != null && _clientId!.isNotEmpty) {
      _loadInvoices(_clientId!);
      _loadReceipts(_clientId!);
      _loadPresupuestos(_clientId!);
      // If this client was already synced from the compose form (client mode),
      // skip step 0. If documents are already selected, jump to review.
      if (recipientId != null && recipientId.isNotEmpty) {
        _step = _hasSelectedDocuments ? 2 : 1;
      }
    }
  }

  @override
  void didUpdateWidget(covariant _InlineInvoiceWizardPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedDocumentsFromCompose();

    // Auto-sync: because widget.state is the SAME mutable object on every
    // rebuild we cannot compare old vs new via oldWidget.state. Instead we
    // remember the last ID we synced in _lastSyncedRecipientClientId.
    final currentRecipientId =
        widget.state._useClientMode ? widget.state._recipientClientId : null;
    if (currentRecipientId != null &&
        currentRecipientId.isNotEmpty &&
        currentRecipientId != _lastSyncedRecipientClientId) {
      _lastSyncedRecipientClientId = currentRecipientId;
      if (currentRecipientId != _clientId) {
        setState(() {
          _clientId = currentRecipientId;
          _step = _hasSelectedDocuments ? 2 : 1;
        });
        _loadInvoices(currentRecipientId);
        _loadReceipts(currentRecipientId);
        _loadPresupuestos(currentRecipientId);
        return;
      }
    }

    // Fallback: once clients finish loading and nothing is selected yet, pick
    // the first client.
    final hadNoClients = oldWidget.state._pickerClients.isEmpty;
    final hasClientsNow = widget.state._pickerClients.isNotEmpty;
    final hasSelected = _clientId != null && _clientId!.trim().isNotEmpty;
    if (hadNoClients && hasClientsNow && !hasSelected) {
      final firstId = widget.state._pickerClients.first.id;
      setState(() => _clientId = firstId);
      _loadInvoices(firstId);
      _loadReceipts(firstId);
      _loadPresupuestos(firstId);
    }
  }

  @override
  void dispose() {
    _invoiceSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices(String clientId) async {
    final groupId = widget.state._currentGroupId();
    if (groupId == null || groupId.isEmpty) return;
    setState(() => _loadingInvoices = true);
    try {
      final list = await widget.state._loadInvoicesForClient(
        groupId: groupId,
        clientId: clientId,
      );
      if (!mounted) return;
      setState(() {
        _invoices = list;
        final available = list.map((e) => e.id).toSet();
        _selectedInvoiceIds =
            _selectedInvoiceIds.where(available.contains).toSet();
      });
    } finally {
      if (mounted) setState(() => _loadingInvoices = false);
    }
  }

  Future<void> _loadReceipts(String clientId) async {
    final groupId = widget.state._currentGroupId();
    if (groupId == null || groupId.isEmpty) return;
    setState(() => _loadingReceipts = true);
    try {
      final list = await widget.state._loadReceiptsForClient(
        groupId: groupId,
        clientId: clientId,
      );
      if (!mounted) return;
      setState(() {
        _receipts = list;
        final available = list.map((e) => e.id).toSet();
        _selectedReceiptIds =
            _selectedReceiptIds.where(available.contains).toSet();
      });
    } finally {
      if (mounted) setState(() => _loadingReceipts = false);
    }
  }

  String _presupuestoId(Map<String, dynamic> item) {
    return (item['presupuestoId'] ?? item['_id'] ?? item['id'] ?? '')
        .toString();
  }

  String _presupuestoNumber(Map<String, dynamic> item) {
    return (item['presupuestoNumber'] ?? item['budgetNumber'] ?? '')
        .toString()
        .trim();
  }

  String _presupuestoStatus(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'draft').toString().trim();
    return status.isEmpty ? 'draft' : status;
  }

  DateTime? _presupuestoDate(Map<String, dynamic> item) {
    final v = item['issueDate'] ?? item['issuedAt'] ?? item['createdAt'];
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  bool _matchesDateFilter(DateTime? date) {
    if (_dateFilter == _DateFilter.all || date == null) return true;
    final now = DateTime.now();
    if (_dateFilter == _DateFilter.thisYear) return date.year == now.year;
    return date.year == now.year && date.month == now.month;
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year % 100}';

  String _fmtAmount(num? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  num? _presupuestoTotal(Map<String, dynamic> item) {
    if (widget.state._isWordPresupuesto(item)) {
      return presupuestoDocumentAmount(item);
    }
    final direct = item['total'];
    if (direct is num) return direct;
    if (direct != null) return num.tryParse(direct.toString());
    final totals = item['totals'];
    if (totals is Map) {
      final nested = totals['total'];
      if (nested is num) return nested;
      if (nested != null) return num.tryParse(nested.toString());
    }
    return null;
  }

  String _localizedStatusLabel(AppLocalizations l, String? statusRaw) {
    final status = (statusRaw ?? '').trim().toLowerCase();
    if (status.isEmpty || status.contains('draft')) return l.statusDraft;
    if (status.contains('issue')) return l.statusIssued;
    return statusRaw?.toString().trim().isNotEmpty == true
        ? statusRaw!.toString().trim()
        : l.statusDraft;
  }

  Future<void> _loadPresupuestos(String clientId) async {
    final groupId = widget.state._currentGroupId();
    if (groupId == null || groupId.isEmpty) return;
    setState(() => _loadingPresupuestos = true);
    try {
      final list = await widget.state._loadPresupuestosForClient(
        groupId: groupId,
        clientId: clientId,
      );
      if (!mounted) return;
      setState(() {
        _presupuestos = list;
        final available = list.map(_presupuestoId).toSet();
        _selectedPresupuestoIds =
            _selectedPresupuestoIds.where(available.contains).toSet();
      });
    } finally {
      if (mounted) setState(() => _loadingPresupuestos = false);
    }
  }

  GroupClient? get _selectedClient {
    final id = _clientId;
    if (id == null) return null;
    for (final c in widget.state._pickerClients) {
      if (c.id == id) return c;
    }
    return null;
  }

  bool get _hasSelectedDocuments =>
      _selectedInvoiceIds.isNotEmpty ||
      _selectedPresupuestoIds.isNotEmpty ||
      _selectedReceiptIds.isNotEmpty;

  void _syncSelectedDocumentsFromCompose() {
    final currentInvoiceIds = widget.state
        ._splitValues(widget.state._normalizeInvoiceIds(
          widget.state._invoiceIdsCtrl.text,
        ))
        .toSet();
    final currentPresupuestoIds = {...widget.state._selectedPresupuestoIds};
    final currentReceiptIds = {...widget.state._selectedReceiptIds};
    if (_setEquals(_selectedInvoiceIds, currentInvoiceIds) &&
        _setEquals(_selectedPresupuestoIds, currentPresupuestoIds) &&
        _setEquals(_selectedReceiptIds, currentReceiptIds)) {
      return;
    }
    setState(() {
      _selectedInvoiceIds = currentInvoiceIds;
      _selectedPresupuestoIds = currentPresupuestoIds;
      _selectedReceiptIds = currentReceiptIds;
      if (_hasSelectedDocuments && _clientId != null) {
        _step = 2;
      }
    });
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  void _applySelectionToCompose() {
    final id = _clientId;
    if (id == null || id.isEmpty) return;
    widget.state._applyInvoicePickerResult(
      _InvoicePickerResult(
        clientId: id,
        invoiceIds: _selectedInvoiceIds.toList(),
        presupuestoIds: _selectedPresupuestoIds.toList(),
        receiptIds: _selectedReceiptIds.toList(),
      ),
    );
  }

  String _selectionAppliedMessage(AppLocalizations l) {
    final invoiceCount = _selectedInvoiceIds.length;
    final presupuestoCount = _selectedPresupuestoIds.length;
    final receiptCount = _selectedReceiptIds.length;
    final manualPdfCount = widget.state._manualPdfAttachmentCount;
    final total = invoiceCount + presupuestoCount + receiptCount;
    final attachmentTotal = total + manualPdfCount;
    if (l.localeName.toLowerCase().startsWith('es')) {
      final parts = <String>[
        if (invoiceCount > 0)
          '$invoiceCount factura${invoiceCount == 1 ? '' : 's'}',
        if (presupuestoCount > 0)
          '$presupuestoCount presupuesto${presupuestoCount == 1 ? '' : 's'}',
        if (receiptCount > 0)
          '$receiptCount recibo${receiptCount == 1 ? '' : 's'}',
        if (manualPdfCount > 0)
          '$manualPdfCount PDF${manualPdfCount == 1 ? '' : 's'} del correo',
      ];
      return attachmentTotal == 0
          ? 'No hay documentos seleccionados.'
          : parts.join(' + ');
    }
    final parts = <String>[
      if (invoiceCount > 0)
        '$invoiceCount invoice${invoiceCount == 1 ? '' : 's'}',
      if (presupuestoCount > 0)
        '$presupuestoCount budget${presupuestoCount == 1 ? '' : 's'}',
      if (receiptCount > 0)
        '$receiptCount receipt${receiptCount == 1 ? '' : 's'}',
      if (manualPdfCount > 0)
        '$manualPdfCount email PDF${manualPdfCount == 1 ? '' : 's'}',
    ];
    return attachmentTotal == 0 ? 'No documents selected.' : parts.join(' + ');
  }

  String _selectionAppliedTitle(AppLocalizations l) {
    return l.localeName.toLowerCase().startsWith('es')
        ? 'Adjuntos actualizados'
        : 'Attachments updated';
  }

  Future<void> _openInvoicePdfPreview(Invoice invoice) async {
    final l = AppLocalizations.of(context)!;
    try {
      final r = await widget.state._invoicesApi.previewPdf(invoice.id);
      final bytes = InvoiceEditorPdf.validatePdf(r);
      final fileName = invoice.invoiceNumber.trim().isNotEmpty
          ? 'invoice-${invoice.invoiceNumber.trim()}.pdf'
          : 'invoice-preview-${invoice.id}.pdf';
      await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.failedWithReason('') : msg)),
      );
    }
  }

  Future<void> _openPreviewScreen({List<Invoice>? invoices}) async {
    final selected = invoices ??
        _invoices
            .where((inv) => _selectedInvoiceIds.contains(inv.id))
            .toList(growable: false);
    final selectedPresupuestos = _presupuestos
        .where((item) => _selectedPresupuestoIds.contains(_presupuestoId(item)))
        .toList(growable: false);
    final selectedReceipts = _receipts
        .where((r) => _selectedReceiptIds.contains(r.id))
        .toList(growable: false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _InvoiceSelectionPreviewScreen(
          clientName: _selectedClient?.name ?? '-',
          invoices: selected,
          receipts: selectedReceipts,
          presupuestos: selectedPresupuestos,
          onPreviewInvoice: _openInvoicePdfPreview,
          onPreviewReceipt: _openReceiptPdfPreview,
          onPreviewPresupuesto: widget.state._openPresupuestoPdfPreviewById,
        ),
      ),
    );
  }

  Future<void> _openReceiptPdfPreview(Receipt receipt) async {
    final l = AppLocalizations.of(context)!;
    try {
      final r = await widget.state._receiptsApi.previewPdf(receipt.id);
      final bytes = InvoiceEditorPdf.validatePdf(r);
      final fileName = (receipt.receiptNumber?.trim().isNotEmpty == true)
          ? 'receipt-${receipt.receiptNumber!.trim()}.pdf'
          : 'receipt-preview-${receipt.id}.pdf';
      await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.failedWithReason('') : msg)),
      );
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Widget _statusPill(String label, ColorScheme cs) {
    final low = label.toLowerCase();
    final isIssued = low.contains('emitida') || low.contains('issued');
    final color = isIssued ? cs.tertiary : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildItemCard({
    required String number,
    required String statusLabel,
    required bool selected,
    required ColorScheme cs,
    required VoidCallback onTap,
    DateTime? date,
    bool? isSent,
    VoidCallback? onPreview,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.45)
                : cs.surfaceContainerLow,
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.8)
                  : cs.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: selected
                    ? Icon(Icons.check_circle_rounded,
                        size: 18, color: cs.primary, key: const ValueKey(true))
                    : Icon(Icons.radio_button_unchecked,
                        size: 18,
                        color: cs.outlineVariant,
                        key: const ValueKey(false)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _statusPill(statusLabel, cs),
                        if (date != null) ...[
                          const SizedBox(width: 5),
                          Text(
                            _fmtDate(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Right-side icons: sent status + preview, vertically centred
              if (isSent != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: isSent ? 'Enviado' : 'Sin envío previo',
                  child: Icon(
                    isSent
                        ? Icons.mark_email_read_outlined
                        : Icons.mail_outline_rounded,
                    size: 14,
                    color: isSent
                        ? cs.tertiary
                        : cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              ],
              if (onPreview != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(Icons.visibility_outlined,
                      size: 16, color: cs.onSurfaceVariant),
                  onPressed: onPreview,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Vista previa helpers ────────────────────────────────────────────────────

  Widget _buildAttachmentSummary({
    required List<Invoice> invoices,
    required List<Receipt> receipts,
    required List<Map<String, dynamic>> presupuestos,
    required ColorScheme cs,
  }) {
    final invoiceColor = cs.primary;
    final receiptColor = cs.tertiary;
    final budgetColor = cs.secondary;
    final pdfAttachments = widget.state._manualPdfAttachments;
    final pdfCount = pdfAttachments.length;
    final pdfSummary = widget.state._manualPdfAttachmentNamesSummary();
    final chips = <Widget>[
      if (invoices.isNotEmpty)
        _summaryChip(
          icon: Icons.receipt_long_outlined,
          label: '${invoices.length} factura${invoices.length == 1 ? '' : 's'}',
          color: invoiceColor,
        ),
      if (receipts.isNotEmpty)
        _summaryChip(
          icon: Icons.description_outlined,
          label: '${receipts.length} recibo${receipts.length == 1 ? '' : 's'}',
          color: receiptColor,
        ),
      if (presupuestos.isNotEmpty)
        _summaryChip(
          icon: Icons.calculate_outlined,
          label:
              '${presupuestos.length} presupuesto${presupuestos.length == 1 ? '' : 's'}',
          color: budgetColor,
        ),
      if (pdfAttachments.isNotEmpty)
        _summaryChip(
          icon: Icons.picture_as_pdf_outlined,
          label: '$pdfCount PDF${pdfCount == 1 ? '' : 's'} del correo',
          color: cs.error,
          tooltip: pdfSummary,
        ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file_rounded, size: 14, color: cs.primary),
              const SizedBox(width: 4),
              Text(
                'Documentos adjuntos al correo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: chips),
          ],
        ],
      ),
    );
  }

  Widget _summaryChip({
    required IconData icon,
    required String label,
    required Color color,
    String? tooltip,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
    final message = tooltip?.trim();
    return message == null || message.isEmpty
        ? chip
        : Tooltip(message: message, child: chip);
  }

  Widget _buildPreviewItemCard({
    required IconData typeIcon,
    required String number,
    required String statusLabel,
    required ColorScheme cs,
    num? amount,
    VoidCallback? onPreview,
    bool? isSent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: cs.surfaceContainerLowest,
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          children: [
            Icon(typeIcon, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          number,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusPill(statusLabel, cs),
                      if (amount != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _fmtAmount(amount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isSent != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: isSent ? 'Enviado por email' : 'Sin envío previo',
                child: Icon(
                  isSent
                      ? Icons.mark_email_read_outlined
                      : Icons.mail_outline_rounded,
                  size: 16,
                  color: isSent ? const Color(0xFF2E7D32) : cs.onSurfaceVariant,
                ),
              ),
            ],
            if (onPreview != null)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(Icons.visibility_outlined,
                    size: 16, color: cs.onSurfaceVariant),
                onPressed: onPreview,
              ),
          ],
        ),
      ),
    );
  }

  Widget _previewSectionLabel(String label, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  bool _validateStepAndMaybePrepare(int step, AppLocalizations l) {
    if (step == 0 && (_clientId == null || _clientId!.trim().isEmpty)) {
      if (widget.state._pickerClients.isNotEmpty) {
        final firstId = widget.state._pickerClients.first.id;
        setState(() => _clientId = firstId);
        _loadInvoices(firstId);
        _loadReceipts(firstId);
        _loadPresupuestos(firstId);
      }
    }
    if (step == 0 && (_clientId == null || _clientId!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.selectClientFirst)),
      );
      return false;
    }
    if (step == 1 &&
        _selectedInvoiceIds.isEmpty &&
        _selectedPresupuestoIds.isEmpty &&
        _selectedReceiptIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.noInvoicesYet)),
      );
      return false;
    }
    return true;
  }

  void _tryGoToStep(int targetStep, AppLocalizations l) {
    if (targetStep == _step) return;
    if (targetStep < _step) {
      setState(() => _step = targetStep);
      return;
    }
    if (targetStep > _step + 1) return;
    if (!_validateStepAndMaybePrepare(_step, l)) return;
    setState(() => _step = targetStep);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final q = _invoiceSearchCtrl.text.trim().toLowerCase();
    final filteredInvoices = _invoices.where((invoice) {
      if (!_matchesDateFilter(invoice.issueDate ?? invoice.registeredAt)) {
        return false;
      }
      if (q.isEmpty) return true;
      final haystack =
          '${invoice.invoiceNumber} ${invoice.id} ${invoice.status ?? ''}'
              .toLowerCase();
      return haystack.contains(q);
    }).toList();
    final filteredPresupuestos = _presupuestos.where((item) {
      if (!_matchesDateFilter(_presupuestoDate(item))) return false;
      if (q.isEmpty) return true;
      final haystack = <String>[
        _presupuestoNumber(item),
        _presupuestoId(item),
        _presupuestoStatus(item),
        if (widget.state._isWordPresupuesto(item))
          presupuestoDocumentTitle(item),
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList(growable: false);
    final filteredStructuredPresupuestos = filteredPresupuestos
        .where((item) => !widget.state._isWordPresupuesto(item))
        .toList(growable: false);
    final filteredWordPresupuestos = filteredPresupuestos
        .where(widget.state._isWordPresupuesto)
        .toList(growable: false);
    final filteredReceipts = _receipts.where((receipt) {
      if (!_matchesDateFilter(receipt.issueDate ?? receipt.registeredAt)) {
        return false;
      }
      if (q.isEmpty) return true;
      final haystack =
          '${receipt.receiptNumber ?? ''} ${receipt.id} ${receipt.status ?? ''}'
              .toLowerCase();
      return haystack.contains(q);
    }).toList(growable: false);

    Widget stepHeader() {
      final steps = [
        l.invoiceBillToLabel,
        l.mailComposeInvoiceIdsLabel,
        l.preview,
      ];
      // Build interleaved list: step — connector — step — connector — step
      final items = <Widget>[];
      for (var i = 0; i < steps.length; i++) {
        final active = _step == i;
        final complete = i < _step;
        final canTap = i <= _step || i == _step + 1;
        items.add(
          GestureDetector(
            onTap: canTap ? () => _tryGoToStep(i, l) : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (active || complete)
                        ? cs.primary
                        : cs.surfaceContainerHighest,
                    border: Border.all(
                      color: (active || complete)
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.5),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: complete
                        ? Icon(Icons.check_rounded,
                            size: 14, color: cs.onPrimary)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  active ? cs.onPrimary : cs.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  style: t.bodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? cs.primary
                        : complete
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
        if (i < steps.length - 1) {
          final lineComplete = i < _step;
          items.add(
            Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.only(bottom: 18),
                color: lineComplete
                    ? cs.primary.withValues(alpha: 0.6)
                    : cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          );
        }
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      );
    }

    Widget stepBody() {
      if (_step == 0) {
        if (widget.state._pickerClients.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.noClientsYet,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () async {
                    await widget.state._prepareInlineInvoiceFlow();
                    if (!mounted) return;
                    setState(() {
                      _clientId = widget.state._inlineClientId ??
                          (widget.state._pickerClients.isNotEmpty
                              ? widget.state._pickerClients.first.id
                              : null);
                    });
                    if (_clientId != null && _clientId!.isNotEmpty) {
                      _loadInvoices(_clientId!);
                      _loadReceipts(_clientId!);
                      _loadPresupuestos(_clientId!);
                    }
                  },
                  child: Text(l.refreshAction),
                ),
              ],
            ),
          );
        }
        return ClientSearchSelect(
          clients: widget.state._pickerClients,
          selectedClientId: _clientId,
          onClientChanged: (value) {
            final id = value;
            if (id == null || id.isEmpty) return;
            setState(() => _clientId = id);
            _loadInvoices(id);
            _loadReceipts(id);
            _loadPresupuestos(id);
          },
          useDefaultPropertyKind: false,
          maxListHeight: 320,
        );
      }

      if (_step == 1) {
        final isBusy =
            _loadingInvoices || _loadingPresupuestos || _loadingReceipts;
        final selectedCount = _selectedInvoiceIds.length +
            _selectedPresupuestoIds.length +
            _selectedReceiptIds.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Search ───────────────────────────────────────────────────────
            TextField(
              controller: _invoiceSearchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
                hintText: l.mailComposeInvoiceIdsHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.primary, width: 1.3),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: cs.surfaceContainerLow,
              ),
            ),
            const SizedBox(height: 8),
            // ── Client + date filter chips on same row ────────────────────────
            Row(
              children: [
                if (_selectedClient != null) ...[
                  Icon(Icons.person_outline_rounded,
                      size: 13, color: cs.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _selectedClient!.name,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in _DateFilter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(switch (f) {
                                _DateFilter.all => 'Todos',
                                _DateFilter.thisMonth => 'Este mes',
                                _DateFilter.thisYear => 'Este año',
                              }),
                              selected: _dateFilter == f,
                              onSelected: (_) =>
                                  setState(() => _dateFilter = f),
                              visualDensity: VisualDensity.compact,
                              labelStyle: const TextStyle(fontSize: 11),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              showCheckmark: false,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── Count badge ──────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  '${l.mailComposeInvoiceIdsLabel}: $selectedCount',
                  style: t.bodySmall.copyWith(
                    color: selectedCount > 0 ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (selectedCount > 0) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() {
                      _selectedInvoiceIds.clear();
                      _selectedReceiptIds.clear();
                      _selectedPresupuestoIds.clear();
                    }),
                    child: Text(
                      'Limpiar',
                      style: t.bodySmall.copyWith(
                        color: cs.error,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // ── Document columns ─────────────────────────────────────────────
            Expanded(
              child: isBusy
                  ? const Center(child: CircularProgressIndicator())
                  : (filteredInvoices.isEmpty &&
                          filteredPresupuestos.isEmpty &&
                          filteredReceipts.isEmpty)
                      ? Center(
                          child: Text(
                            l.noInvoicesYet,
                            style: t.bodySmall
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left column: invoices + presupuestos
                            Expanded(
                              child: ListView(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      l.mailComposeInvoiceIdsLabel,
                                      style: t.bodySmall.copyWith(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  ...filteredInvoices.map((invoice) {
                                    final selected = _selectedInvoiceIds
                                        .contains(invoice.id);
                                    return _buildItemCard(
                                      number:
                                          invoice.invoiceNumber.trim().isEmpty
                                              ? invoice.id
                                              : invoice.invoiceNumber,
                                      statusLabel: _localizedStatusLabel(
                                          l, invoice.status),
                                      selected: selected,
                                      cs: cs,
                                      date: invoice.issueDate ??
                                          invoice.registeredAt,
                                      isSent: invoice.sentAt != null,
                                      onTap: () => setState(() => selected
                                          ? _selectedInvoiceIds
                                              .remove(invoice.id)
                                          : _selectedInvoiceIds
                                              .add(invoice.id)),
                                      onPreview: () =>
                                          _openInvoicePdfPreview(invoice),
                                    );
                                  }),
                                  if (filteredStructuredPresupuestos
                                      .isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 6, bottom: 6),
                                      child: Text(
                                        l.budgetsMenuSection,
                                        style: t.bodySmall.copyWith(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    ...filteredStructuredPresupuestos
                                        .map((item) {
                                      final id = _presupuestoId(item);
                                      final number = _presupuestoNumber(item);
                                      final selected =
                                          _selectedPresupuestoIds.contains(id);
                                      return _buildItemCard(
                                        number: number.isEmpty ? id : number,
                                        statusLabel: _presupuestoStatus(item),
                                        selected: selected,
                                        cs: cs,
                                        date: _presupuestoDate(item),
                                        onTap: () => setState(() => selected
                                            ? _selectedPresupuestoIds.remove(id)
                                            : _selectedPresupuestoIds.add(id)),
                                        onPreview: id.isEmpty
                                            ? null
                                            : () => widget.state
                                                ._openPresupuestoPdfPreviewById(
                                                    id),
                                      );
                                    }),
                                  ],
                                  if (filteredWordPresupuestos.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 6, bottom: 6),
                                      child: Text(
                                        widget.state
                                            ._wordPresupuestoSectionLabel(l),
                                        style: t.bodySmall.copyWith(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    ...filteredWordPresupuestos.map((item) {
                                      final id = _presupuestoId(item);
                                      final number = _presupuestoNumber(item);
                                      final selected =
                                          _selectedPresupuestoIds.contains(id);
                                      return _buildItemCard(
                                        number: number.isEmpty
                                            ? presupuestoDocumentTitle(item)
                                            : number,
                                        statusLabel: _localizedStatusLabel(
                                          l,
                                          _presupuestoStatus(item),
                                        ),
                                        selected: selected,
                                        cs: cs,
                                        date: _presupuestoDate(item),
                                        onTap: () => setState(() => selected
                                            ? _selectedPresupuestoIds.remove(id)
                                            : _selectedPresupuestoIds.add(id)),
                                        onPreview: id.isEmpty
                                            ? null
                                            : () => widget.state
                                                ._openPresupuestoPdfPreviewById(
                                                    id),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Right column: receipts
                            Expanded(
                              child: ListView(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      l.receiptsTitle,
                                      style: t.bodySmall.copyWith(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  ...filteredReceipts.map((receipt) {
                                    final selected = _selectedReceiptIds
                                        .contains(receipt.id);
                                    final number = (receipt.receiptNumber
                                                ?.trim()
                                                .isNotEmpty ==
                                            true)
                                        ? receipt.receiptNumber!.trim()
                                        : receipt.id;
                                    return _buildItemCard(
                                      number: number,
                                      statusLabel: _localizedStatusLabel(
                                          l, receipt.status),
                                      selected: selected,
                                      cs: cs,
                                      date: receipt.issueDate ??
                                          receipt.registeredAt,
                                      onTap: () => setState(() => selected
                                          ? _selectedReceiptIds
                                              .remove(receipt.id)
                                          : _selectedReceiptIds
                                              .add(receipt.id)),
                                      onPreview: () =>
                                          _openReceiptPdfPreview(receipt),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        );
      }

      final selectedInvoices = _invoices
          .where((inv) => _selectedInvoiceIds.contains(inv.id))
          .toList(growable: false);
      final selectedPresupuestos = _presupuestos
          .where(
              (item) => _selectedPresupuestoIds.contains(_presupuestoId(item)))
          .toList(growable: false);
      final selectedStructuredPresupuestos = selectedPresupuestos
          .where((item) => !widget.state._isWordPresupuesto(item))
          .toList(growable: false);
      final selectedWordPresupuestos = selectedPresupuestos
          .where(widget.state._isWordPresupuesto)
          .toList(growable: false);
      final selectedReceipts = _receipts
          .where((r) => _selectedReceiptIds.contains(r.id))
          .toList(growable: false);
      final selectedCount = selectedInvoices.length +
          selectedPresupuestos.length +
          selectedReceipts.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client row
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _selectedClient?.name ?? '-',
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Attachment summary banner
          _buildAttachmentSummary(
            invoices: selectedInvoices,
            receipts: selectedReceipts,
            presupuestos: selectedPresupuestos,
            cs: cs,
          ),
          const SizedBox(height: 10),
          // Document list
          Expanded(
            child: selectedCount == 0
                ? Center(
                    child: Text(
                      l.noInvoicesYet,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView(
                    children: [
                      if (selectedInvoices.isNotEmpty) ...[
                        _previewSectionLabel(l.mailComposeInvoiceIdsLabel, cs),
                        ...selectedInvoices.map(
                          (invoice) => _buildPreviewItemCard(
                            typeIcon: Icons.receipt_long_outlined,
                            number: invoice.invoiceNumber.trim().isEmpty
                                ? invoice.id
                                : invoice.invoiceNumber,
                            statusLabel:
                                _localizedStatusLabel(l, invoice.status),
                            cs: cs,
                            amount: invoice.total,
                            isSent: invoice.sentAt != null,
                            onPreview: () => _openInvoicePdfPreview(invoice),
                          ),
                        ),
                      ],
                      if (selectedReceipts.isNotEmpty) ...[
                        _previewSectionLabel(l.receiptsTitle, cs),
                        ...selectedReceipts.map(
                          (receipt) => _buildPreviewItemCard(
                            typeIcon: Icons.description_outlined,
                            number: (receipt.receiptNumber?.trim().isNotEmpty ==
                                    true)
                                ? receipt.receiptNumber!.trim()
                                : receipt.id,
                            statusLabel:
                                _localizedStatusLabel(l, receipt.status),
                            cs: cs,
                            amount: receipt.total,
                            onPreview: () => _openReceiptPdfPreview(receipt),
                          ),
                        ),
                      ],
                      if (selectedStructuredPresupuestos.isNotEmpty) ...[
                        _previewSectionLabel(l.budgetsMenuSection, cs),
                        ...selectedStructuredPresupuestos.map((item) {
                          final id = _presupuestoId(item);
                          final number = _presupuestoNumber(item);
                          return _buildPreviewItemCard(
                            typeIcon: Icons.calculate_outlined,
                            number: number.isEmpty ? id : number,
                            statusLabel: _presupuestoStatus(item),
                            cs: cs,
                            amount: _presupuestoTotal(item),
                            onPreview: id.isEmpty
                                ? null
                                : () => widget.state
                                    ._openPresupuestoPdfPreviewById(id),
                          );
                        }),
                      ],
                      if (selectedWordPresupuestos.isNotEmpty) ...[
                        _previewSectionLabel(
                          widget.state._wordPresupuestoSectionLabel(l),
                          cs,
                        ),
                        ...selectedWordPresupuestos.map((item) {
                          final id = _presupuestoId(item);
                          final number = _presupuestoNumber(item);
                          return _buildPreviewItemCard(
                            typeIcon: Icons.article_outlined,
                            number: number.isEmpty
                                ? presupuestoDocumentTitle(item)
                                : number,
                            statusLabel: _localizedStatusLabel(
                              l,
                              _presupuestoStatus(item),
                            ),
                            cs: cs,
                            amount: _presupuestoTotal(item),
                            onPreview: id.isEmpty
                                ? null
                                : () => widget.state
                                    ._openPresupuestoPdfPreviewById(id),
                          );
                        }),
                      ],
                    ],
                  ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          stepHeader(),
          const SizedBox(height: 10),
          Expanded(child: stepBody()),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: _step == 0 ? null : () => setState(() => _step -= 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(
                    color: _step == 0
                        ? cs.outlineVariant.withValues(alpha: 0.4)
                        : cs.outlineVariant,
                  ),
                ),
                child:
                    Text(MaterialLocalizations.of(context).backButtonTooltip),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  if (_step < 2) {
                    _tryGoToStep(_step + 1, l);
                    return;
                  }
                  if (_selectedInvoiceIds.isEmpty &&
                      _selectedPresupuestoIds.isEmpty &&
                      _selectedReceiptIds.isEmpty) {
                    return;
                  }
                  _applySelectionToCompose();
                  showSuccessSnack(
                    context,
                    _selectionAppliedMessage(l),
                    title: _selectionAppliedTitle(l),
                  );
                },
                child: Text(
                  _step < 2
                      ? MaterialLocalizations.of(context).nextPageTooltip
                      : MaterialLocalizations.of(context).okButtonLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
