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
  final TextEditingController _recentSearchCtrl = TextEditingController();
  int _step = 0;
  String? _clientId;
  _DateFilter _dateFilter = _DateFilter.all;
  int _documentTab = 0;
  // Tracks the last recipient-client we synced from the compose form so we can
  // detect a real change even though widget.state is the same mutable object.
  String? _lastSyncedRecipientClientId;
  bool _loadingInvoices = false;
  bool _loadingReceipts = false;
  bool _loadingPresupuestos = false;
  final Set<String> _previewingDocuments = <String>{};
  bool _attachingDocuments = false;
  String? _attachmentError;
  bool _historyExpanded = false;
  bool _historySentOnly = false;
  int _historyVisibleCount = 4;
  final Set<String> _comparingInvoiceIds = <String>{};
  List<Invoice> _invoices = const [];
  List<Receipt> _receipts = const [];
  List<Map<String, dynamic>> _presupuestos = const [];
  Set<String> _selectedInvoiceIds = <String>{};
  Set<String> _selectedPresupuestoIds = <String>{};
  Set<String> _selectedReceiptIds = <String>{};
  Set<String> _lastComposeInvoiceIds = <String>{};
  Set<String> _lastComposePresupuestoIds = <String>{};
  Set<String> _lastComposeReceiptIds = <String>{};

  @override
  void initState() {
    super.initState();
    final currentIds = widget.state._splitValues(
        widget.state._normalizeInvoiceIds(widget.state._invoiceIdsCtrl.text));
    _selectedInvoiceIds = currentIds.toSet();
    _selectedPresupuestoIds = {...widget.state._selectedPresupuestoIds};
    _selectedReceiptIds = {...widget.state._selectedReceiptIds};
    _lastComposeInvoiceIds = {..._selectedInvoiceIds};
    _lastComposePresupuestoIds = {..._selectedPresupuestoIds};
    _lastComposeReceiptIds = {..._selectedReceiptIds};
    // If the compose form is already in "client mode", pre-select that client.
    final recipientId =
        widget.state._useClientMode ? widget.state._recipientClientId : null;
    _lastSyncedRecipientClientId = recipientId;
    _clientId = recipientId ?? widget.state._inlineClientId;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.state._preparationMode != _ComposePreparationMode.clients) {
        return;
      }
      widget.state._selectPreparationMode(_ComposePreparationMode.clients);
    });
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
  }

  @override
  void dispose() {
    _invoiceSearchCtrl.dispose();
    _recentSearchCtrl.dispose();
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

  Set<String> get _composeInvoiceIds => widget.state._attachedInvoiceIds;

  Set<String> get _composePresupuestoIds => widget.state._attachInvoicePdf
      ? widget.state._selectedPresupuestoIds
      : <String>{};

  Set<String> get _composeReceiptIds => widget.state._attachInvoicePdf
      ? widget.state._selectedReceiptIds
      : <String>{};

  int get _pendingAttachmentCount =>
      _selectedInvoiceIds.difference(_composeInvoiceIds).length +
      _selectedPresupuestoIds.difference(_composePresupuestoIds).length +
      _selectedReceiptIds.difference(_composeReceiptIds).length;

  void _syncSelectedDocumentsFromCompose() {
    final currentInvoiceIds = widget.state
        ._splitValues(widget.state._normalizeInvoiceIds(
          widget.state._invoiceIdsCtrl.text,
        ))
        .toSet();
    final currentPresupuestoIds = {...widget.state._selectedPresupuestoIds};
    final currentReceiptIds = {...widget.state._selectedReceiptIds};
    final composeSelectionChanged =
        !_setEquals(_lastComposeInvoiceIds, currentInvoiceIds) ||
            !_setEquals(
              _lastComposePresupuestoIds,
              currentPresupuestoIds,
            ) ||
            !_setEquals(_lastComposeReceiptIds, currentReceiptIds);
    if (!composeSelectionChanged) return;

    _lastComposeInvoiceIds = {...currentInvoiceIds};
    _lastComposePresupuestoIds = {...currentPresupuestoIds};
    _lastComposeReceiptIds = {...currentReceiptIds};
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

  Future<bool> _applySelectionToCompose() async {
    final id = _clientId;
    if (id == null || id.isEmpty) return false;
    setState(() {
      _attachingDocuments = true;
      _attachmentError = null;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      widget.state._applyInvoicePickerResult(
        _InvoicePickerResult(
          clientId: id,
          invoiceIds: _selectedInvoiceIds.toList(),
          presupuestoIds: <String>{
            ...widget.state._selectedPresupuestoIds,
            ..._selectedPresupuestoIds,
          }.toList(),
          receiptIds: <String>{
            ...widget.state._selectedReceiptIds,
            ..._selectedReceiptIds,
          }.toList(),
        ),
      );
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _attachmentError = widget.state._isSpanishLocale
            ? 'No se pudieron adjuntar los documentos.'
            : 'The documents could not be attached.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _attachingDocuments = false);
    }
  }

  void _removeInvoice(String id) {
    final wasInCompose = widget.state._composerInvoiceIds.contains(id);
    setState(() => _selectedInvoiceIds.remove(id));
    if (!wasInCompose) return;
    widget.state.update(() {
      final remaining = widget.state._composerInvoiceIds..remove(id);
      widget.state._invoiceIdsCtrl.text = remaining.join(',');
    });
  }

  void _removeReceipt(String id) {
    final wasAttached = widget.state._selectedReceiptIds.contains(id);
    setState(() => _selectedReceiptIds.remove(id));
    if (!wasAttached) return;
    widget.state.update(() => widget.state._selectedReceiptIds.remove(id));
  }

  void _removePresupuesto(String id) {
    final wasAttached = widget.state._selectedPresupuestoIds.contains(id);
    setState(() => _selectedPresupuestoIds.remove(id));
    if (!wasAttached) return;
    widget.state.update(() => widget.state._selectedPresupuestoIds.remove(id));
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

  Future<void> _runDocumentPreview(
    String documentKey,
    Future<void> Function() preview,
  ) async {
    if (_previewingDocuments.contains(documentKey)) return;
    setState(() => _previewingDocuments.add(documentKey));
    try {
      await preview();
    } finally {
      if (mounted) {
        setState(() => _previewingDocuments.remove(documentKey));
      }
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
    String? previewKey,
    Future<void> Function()? onPreview,
  }) {
    final previewing =
        previewKey != null && _previewingDocuments.contains(previewKey);
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
                Tooltip(
                  message: previewing
                      ? (widget.state._isSpanishLocale
                          ? 'Abriendo vista previa'
                          : 'Opening preview')
                      : (widget.state._isSpanishLocale
                          ? 'Vista previa'
                          : 'Preview'),
                  child: IconButton(
                    key: previewKey == null
                        ? null
                        : ValueKey('mail-preview-$previewKey'),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: previewing || previewKey == null
                        ? null
                        : () => _runDocumentPreview(previewKey, onPreview),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: previewing
                          ? SizedBox(
                              key: const ValueKey('preview-loading'),
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            )
                          : Icon(
                              Icons.visibility_outlined,
                              key: const ValueKey('preview-idle'),
                              size: 16,
                              color: cs.onSurfaceVariant,
                            ),
                    ),
                  ),
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
    final isSpanish = widget.state._isSpanishLocale;
    final attachedCount = widget.state._totalAttachedDocumentCount;
    final pendingCount = _pendingAttachmentCount;
    return Row(
      children: [
        Icon(Icons.attach_file_rounded, size: 15, color: cs.primary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            isSpanish ? 'Documentos adjuntos' : 'Attached documents',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        Text(
          '$attachedCount ${isSpanish ? 'adjunto${attachedCount == 1 ? '' : 's'}' : 'attached'}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        if (pendingCount > 0) ...[
          const SizedBox(width: 8),
          Text(
            '$pendingCount ${isSpanish ? 'seleccionada${pendingCount == 1 ? '' : 's'}' : 'selected'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewItemCard({
    required IconData typeIcon,
    required String documentId,
    required String documentType,
    required String number,
    required String filename,
    required String clientName,
    required bool attached,
    required ColorScheme cs,
    num? amount,
    String? previewKey,
    Future<void> Function()? onPreview,
    required VoidCallback onRemove,
  }) {
    final previewing =
        previewKey != null && _previewingDocuments.contains(previewKey);
    final isSpanish = widget.state._isSpanishLocale;
    final attaching = _attachingDocuments && !attached;
    final hasError = _attachmentError != null && !attached;
    final stateLabel = hasError
        ? 'Error'
        : attaching
            ? (isSpanish ? 'Adjuntando' : 'Attaching')
            : attached
                ? (isSpanish ? 'Adjunto' : 'Attached')
                : (isSpanish ? 'Seleccionada' : 'Selected');
    final stateColor = hasError
        ? cs.error
        : attached
            ? const Color(0xFF2E7D32)
            : cs.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filename,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    clientName,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (amount != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 78,
                child: Text(
                  _fmtAmount(amount),
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (attaching)
                    SizedBox.square(
                      dimension: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.7,
                        color: stateColor,
                      ),
                    )
                  else
                    Icon(
                      hasError
                          ? Icons.error_outline_rounded
                          : attached
                              ? Icons.check_circle_outline_rounded
                              : Icons.schedule_rounded,
                      size: 12,
                      color: stateColor,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    stateLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: stateColor,
                    ),
                  ),
                ],
              ),
            ),
            if (onPreview != null)
              Tooltip(
                message: previewing
                    ? (widget.state._isSpanishLocale
                        ? 'Abriendo vista previa'
                        : 'Opening preview')
                    : (widget.state._isSpanishLocale
                        ? 'Vista previa'
                        : 'Preview'),
                child: IconButton(
                  key: previewKey == null
                      ? null
                      : ValueKey('mail-review-preview-$previewKey'),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: previewing || previewKey == null
                      ? null
                      : () => _runDocumentPreview(previewKey, onPreview),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: previewing
                        ? SizedBox(
                            key: const ValueKey('preview-loading'),
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          )
                        : Icon(
                            Icons.visibility_outlined,
                            key: const ValueKey('preview-idle'),
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                  ),
                ),
              ),
            Tooltip(
              message: isSpanish ? 'Quitar adjunto' : 'Remove attachment',
              child: IconButton(
                key: ValueKey('mail-review-remove-$documentType:$documentId'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: _attachingDocuments ? null : onRemove,
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ),
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

  DateTime _invoiceHistoryDate(Invoice invoice) =>
      invoice.issueDate ??
      invoice.issuedAt ??
      invoice.registeredAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  List<Invoice> _invoiceHistory({required bool applyLimit}) {
    final attachedIds = _composeInvoiceIds;
    final history = _invoices.where((invoice) {
      final status = (invoice.status ?? '').trim().toLowerCase();
      if (!status.contains('issued')) return false;
      if (attachedIds.contains(invoice.id)) return false;
      if (_historySentOnly) {
        final delivery = normalizedDeliveryStatus(invoice.deliveryStatus);
        if (delivery != 'sent' && delivery != 'delivered') return false;
      }
      return true;
    }).toList(growable: false)
      ..sort(
        (a, b) => _invoiceHistoryDate(b).compareTo(_invoiceHistoryDate(a)),
      );
    return applyLimit
        ? history.take(_historyVisibleCount).toList(growable: false)
        : history;
  }

  Future<void> _showInvoiceComparison(
    Invoice historical,
    List<Invoice> attachedInvoices,
  ) async {
    if (attachedInvoices.isEmpty ||
        _comparingInvoiceIds.contains(historical.id)) {
      return;
    }
    setState(() => _comparingInvoiceIds.add(historical.id));
    try {
      final ids = <String>{
        historical.id,
        ...attachedInvoices.map((invoice) => invoice.id),
      };
      final details = await Future.wait(
        ids.map(widget.state._invoicesApi.getById),
      );
      if (!mounted) return;
      final groupId = widget.state._currentGroupId();
      final clientId = _clientId;
      final byId = <String, Invoice>{
        for (final invoice in details) invoice.id: invoice
      };
      final valid = details.every(
        (invoice) => invoice.groupId == groupId && invoice.clientId == clientId,
      );
      if (!valid) {
        throw Exception(widget.state._isSpanishLocale
            ? 'No se puede comparar una factura de otro cliente o grupo.'
            : 'An invoice from another client or group cannot be compared.');
      }
      setState(() => _comparingInvoiceIds.remove(historical.id));
      await showDialog<void>(
        context: context,
        builder: (_) => _InvoiceComparisonDialog(
          currentInvoices: attachedInvoices
              .map((invoice) => byId[invoice.id] ?? invoice)
              .toList(growable: false),
          historicalInvoice: byId[historical.id] ?? historical,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty
              ? (widget.state._isSpanishLocale
                  ? 'No se pudo cargar la comparación.'
                  : 'The comparison could not be loaded.')
              : message),
        ),
      );
    } finally {
      if (mounted) setState(() => _comparingInvoiceIds.remove(historical.id));
    }
  }

  bool _validateStepAndMaybePrepare(int step, AppLocalizations l) {
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

  Widget _modeSelector({
    required AppTypography typography,
    required ColorScheme colors,
    required bool isSpanish,
  }) {
    final modes = <(_ComposePreparationMode, IconData, String)>[
      (
        _ComposePreparationMode.clients,
        Icons.person_outline_rounded,
        isSpanish ? 'Clientes' : 'Clients'
      ),
      (_ComposePreparationMode.email, Icons.alternate_email_rounded, 'Email'),
      (
        _ComposePreparationMode.recent,
        Icons.history_rounded,
        isSpanish ? 'Recientes' : 'Recent'
      ),
    ];
    return Container(
      key: const ValueKey('mail-compose-preparation-mode-selector'),
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (final item in modes)
            Expanded(
              child: InkWell(
                key: ValueKey('mail-compose-mode-${item.$1.name}'),
                onTap: widget.state._sending
                    ? null
                    : () => widget.state._selectPreparationMode(item.$1),
                borderRadius: BorderRadius.circular(7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.state._preparationMode == item.$1
                        ? colors.primaryContainer.withValues(alpha: .72)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: widget.state._preparationMode == item.$1
                          ? colors.primary.withValues(alpha: .55)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.$2,
                        size: 15,
                        color: widget.state._preparationMode == item.$1
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: widget.state._preparationMode == item.$1
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: widget.state._preparationMode == item.$1
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _manualEmailMode({
    required AppTypography typography,
    required ColorScheme colors,
    required AppLocalizations localizations,
    required bool isSpanish,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isSpanish ? 'Destinatarios' : 'Recipients',
          style: typography.bodySmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: _EmailChipsInput(
            controller: widget.state._toCtrl,
            values: widget.state._toList,
            hint: localizations.mailComposeToHint,
            enabled: !widget.state._sending,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (next) => widget.state.update(() => widget.state._toList
              ..clear()
              ..addAll(next)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isSpanish
              ? 'Puedes escribir varios correos. Cc, Cco y los adjuntos se gestionan en el editor.'
              : 'You can enter multiple addresses. Manage Cc, Bcc, and attachments in the editor.',
          style: typography.bodySmall.copyWith(
            fontSize: 11,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _recentInvoicesMode({
    required AppTypography typography,
    required ColorScheme colors,
    required bool isSpanish,
  }) {
    if (widget.state._loadingRecentInvoices) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = widget.state._recentInvoicesError;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            HexoraButton(
              label: isSpanish ? 'Reintentar' : 'Retry',
              onPressed: () => widget.state._loadRecentIssuedInvoices(
                force: true,
              ),
              variant: HexoraButtonVariant.secondary,
            ),
          ],
        ),
      );
    }

    final clientsById = {
      for (final client in widget.state._recentInvoiceClients)
        client.id: client,
    };
    final query = _recentSearchCtrl.text.trim().toLowerCase();
    final invoices = widget.state._recentIssuedInvoices.where((invoice) {
      final clientName = clientsById[invoice.clientId]?.name ?? '';
      return query.isEmpty ||
          '${invoice.invoiceNumber} $clientName'.toLowerCase().contains(query);
    }).toList(growable: false);
    final selectedIds = widget.state
        ._splitValues(widget.state._normalizeInvoiceIds(
          widget.state._invoiceIdsCtrl.text,
        ))
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('mail-recent-invoices-search'),
          controller: _recentSearchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.surfaceContainerLow,
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            hintText: isSpanish
                ? 'Buscar factura o cliente'
                : 'Search invoice or client',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${isSpanish ? 'Seleccionadas' : 'Selected'}: ${selectedIds.length}',
          style: typography.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color:
                selectedIds.isEmpty ? colors.onSurfaceVariant : colors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: invoices.isEmpty
              ? Center(
                  child: Text(
                    isSpanish
                        ? 'No hay facturas recientes.'
                        : 'No recent invoices found.',
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    final selected = selectedIds.contains(invoice.id);
                    final client = clientsById[invoice.clientId];
                    final delivery =
                        (invoice.deliveryStatus ?? '').toLowerCase();
                    final deliveryLabel = delivery == 'delivered'
                        ? (isSpanish ? 'Entregada' : 'Delivered')
                        : delivery == 'failed'
                            ? (isSpanish ? 'Error de envío' : 'Send error')
                            : (invoice.sentAt != null || delivery == 'sent')
                                ? (isSpanish ? 'Enviada' : 'Sent')
                                : (isSpanish ? 'No enviada' : 'Not sent');
                    return Material(
                      color: selected
                          ? colors.primaryContainer.withValues(alpha: .38)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        key: ValueKey('mail-recent-invoice-${invoice.id}'),
                        onTap: () {
                          widget.state._toggleRecentInvoice(invoice);
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? colors.primary.withValues(alpha: .7)
                                  : colors.outlineVariant
                                      .withValues(alpha: .55),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: selected
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invoice.invoiceNumber,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: typography.bodySmall.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      [
                                        if (client != null) client.name,
                                        widget.state._formatInvoiceDate(
                                          widget.state
                                              ._invoiceDisplayDate(invoice),
                                        ),
                                      ].join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: typography.bodySmall.copyWith(
                                        fontSize: 10.5,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    widget.state._formatInvoiceTotal(invoice),
                                    style: typography.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    deliveryLabel,
                                    style: typography.bodySmall.copyWith(
                                      fontSize: 10,
                                      color: delivery == 'failed'
                                          ? colors.error
                                          : colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final invoicesLabel = isSpanish ? 'Facturas' : 'Invoices';
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
        isSpanish ? 'Cliente' : 'Client',
        invoicesLabel,
        isSpanish ? 'Revisar' : 'Review',
      ];
      final items = <Widget>[];
      for (var i = 0; i < steps.length; i++) {
        final active = _step == i;
        final complete = i < _step;
        final canTap = i <= _step || i == _step + 1;
        items.add(
          Semantics(
            button: true,
            selected: active,
            label: '${steps[i]}, ${i + 1} ${isSpanish ? 'de' : 'of'} 3',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canTap ? () => _tryGoToStep(i, l) : null,
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: active
                        ? cs.primary.withValues(alpha: .14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active
                          ? cs.primary.withValues(alpha: .65)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active || complete
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                        ),
                        child: complete
                            ? Icon(Icons.check_rounded,
                                size: 12, color: cs.onPrimary)
                            : Text(
                                '${i + 1}',
                                style: t.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: active
                                      ? cs.onPrimary
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        steps[i],
                        style: t.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w600,
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
              ),
            ),
          ),
        );
        if (i < steps.length - 1) {
          items.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: i < _step
                    ? cs.primary
                    : cs.onSurfaceVariant.withValues(alpha: .7),
              ),
            ),
          );
        }
      }
      return SizedBox(
        key: const ValueKey('mail-attachment-inline-stepper'),
        height: 32,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: items,
          ),
        ),
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
                    setState(() => _clientId = widget.state._inlineClientId);
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
            widget.state._selectRecipientClient(id);
            _loadInvoices(id);
            _loadReceipts(id);
            _loadPresupuestos(id);
          },
          useDefaultPropertyKind: false,
          maxListHeight: 320,
          compact: true,
          unsentDocumentCounts: widget.state._clientUnsentDocumentCounts,
          unsentDocumentCountsLoading:
              widget.state._clientUnsentDocumentCountsLoading,
          unsentDocumentCountsError:
              widget.state._clientUnsentDocumentCountsError,
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
                hintText: isSpanish ? 'Buscar por número' : 'Search by number',
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
                            child: Builder(
                              builder: (context) {
                                final selected = _dateFilter == f;
                                return ChoiceChip(
                                  label: Text(switch (f) {
                                    _DateFilter.all =>
                                      isSpanish ? 'Todos' : 'All',
                                    _DateFilter.thisMonth =>
                                      isSpanish ? 'Este mes' : 'This month',
                                    _DateFilter.thisYear =>
                                      isSpanish ? 'Este año' : 'This year',
                                  }),
                                  selected: selected,
                                  onSelected: (_) =>
                                      setState(() => _dateFilter = f),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: cs.surfaceContainerHighest,
                                  selectedColor: Color.alphaBlend(
                                    cs.primary.withValues(alpha: 0.24),
                                    cs.surfaceContainerHighest,
                                  ),
                                  surfaceTintColor: Colors.transparent,
                                  side: BorderSide(
                                    color: selected
                                        ? cs.primary
                                        : cs.outlineVariant,
                                  ),
                                  labelStyle: t.bodySmall.copyWith(
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: selected
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  showCheckmark: false,
                                );
                              },
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(3, (index) {
                  final labels = [
                    invoicesLabel,
                    isSpanish ? 'Recibos' : 'Receipts',
                    isSpanish ? 'Presupuestos' : 'Budgets'
                  ];
                  final counts = [
                    filteredInvoices.length,
                    filteredReceipts.length,
                    filteredPresupuestos.length
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${labels[index]} (${counts[index]})'),
                      selected: _documentTab == index,
                      onSelected: (_) => setState(() => _documentTab = index),
                      showCheckmark: false,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${isSpanish ? 'Seleccionadas' : 'Selected'}: $selectedCount',
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
                            if (_documentTab != 1)
                              Expanded(
                                child: ListView(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        _documentTab == 2
                                            ? (isSpanish
                                                ? 'Presupuestos'
                                                : 'Budgets')
                                            : invoicesLabel,
                                        style: t.bodySmall.copyWith(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    ...(_documentTab == 0
                                            ? filteredInvoices
                                            : const <Invoice>[])
                                        .map((invoice) {
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
                                        previewKey: 'invoice:${invoice.id}',
                                        onPreview: () =>
                                            _openInvoicePdfPreview(invoice),
                                      );
                                    }),
                                    if (_documentTab == 2 &&
                                        filteredStructuredPresupuestos
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
                                        final selected = _selectedPresupuestoIds
                                            .contains(id);
                                        return _buildItemCard(
                                          number: number.isEmpty ? id : number,
                                          statusLabel: _presupuestoStatus(item),
                                          selected: selected,
                                          cs: cs,
                                          date: _presupuestoDate(item),
                                          onTap: () => setState(() => selected
                                              ? _selectedPresupuestoIds
                                                  .remove(id)
                                              : _selectedPresupuestoIds
                                                  .add(id)),
                                          previewKey: 'budget:$id',
                                          onPreview: id.isEmpty
                                              ? null
                                              : () => widget.state
                                                  ._openPresupuestoPdfPreviewById(
                                                      id),
                                        );
                                      }),
                                    ],
                                    if (_documentTab == 2 &&
                                        filteredWordPresupuestos
                                            .isNotEmpty) ...[
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
                                        final selected = _selectedPresupuestoIds
                                            .contains(id);
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
                                              ? _selectedPresupuestoIds
                                                  .remove(id)
                                              : _selectedPresupuestoIds
                                                  .add(id)),
                                          previewKey: 'budget:$id',
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
                            if (_documentTab == 1) const SizedBox(width: 8),
                            // Right column: receipts
                            if (_documentTab == 1)
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
                                    ...(_documentTab == 1
                                            ? filteredReceipts
                                            : const <Receipt>[])
                                        .map((receipt) {
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
                                        previewKey: 'receipt:${receipt.id}',
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
      final manualAttachments = widget.state._manualPdfAttachments;
      final selectedCount = selectedInvoices.length +
          selectedPresupuestos.length +
          selectedReceipts.length +
          manualAttachments.length;
      final currentAttachedInvoices = selectedInvoices
          .where((invoice) => _composeInvoiceIds.contains(invoice.id))
          .toList(growable: false);
      final allHistoryInvoices = _invoiceHistory(applyLimit: false);
      final visibleHistoryInvoices = _invoiceHistory(applyLimit: true);
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
            child: ListView(
              children: [
                if (selectedCount == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        l.noInvoicesYet,
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                if (selectedInvoices.isNotEmpty) ...[
                  _previewSectionLabel(invoicesLabel, cs),
                  ...selectedInvoices.map(
                    (invoice) => _buildPreviewItemCard(
                      typeIcon: Icons.receipt_long_outlined,
                      documentId: invoice.id,
                      documentType: 'invoice',
                      number: invoice.invoiceNumber.trim().isEmpty
                          ? invoice.id
                          : invoice.invoiceNumber,
                      filename:
                          '${isSpanish ? 'Factura' : 'Invoice'} ${invoice.invoiceNumber.trim().isEmpty ? invoice.id : invoice.invoiceNumber}.pdf',
                      clientName: _selectedClient?.name ?? '-',
                      attached: _composeInvoiceIds.contains(invoice.id),
                      cs: cs,
                      amount: invoice.total,
                      previewKey: 'invoice:${invoice.id}',
                      onPreview: () => _openInvoicePdfPreview(invoice),
                      onRemove: () => _removeInvoice(invoice.id),
                    ),
                  ),
                ],
                if (selectedReceipts.isNotEmpty) ...[
                  _previewSectionLabel(l.receiptsTitle, cs),
                  ...selectedReceipts.map(
                    (receipt) => _buildPreviewItemCard(
                      typeIcon: Icons.description_outlined,
                      documentId: receipt.id,
                      documentType: 'receipt',
                      number: (receipt.receiptNumber?.trim().isNotEmpty == true)
                          ? receipt.receiptNumber!.trim()
                          : receipt.id,
                      filename:
                          '${isSpanish ? 'Recibo' : 'Receipt'} ${(receipt.receiptNumber?.trim().isNotEmpty == true) ? receipt.receiptNumber!.trim() : receipt.id}.pdf',
                      clientName: _selectedClient?.name ?? '-',
                      attached: _composeReceiptIds.contains(receipt.id),
                      cs: cs,
                      amount: receipt.total,
                      previewKey: 'receipt:${receipt.id}',
                      onPreview: () => _openReceiptPdfPreview(receipt),
                      onRemove: () => _removeReceipt(receipt.id),
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
                      documentId: id,
                      documentType: 'budget',
                      number: number.isEmpty ? id : number,
                      filename:
                          '${isSpanish ? 'Presupuesto' : 'Estimate'} ${number.isEmpty ? id : number}.pdf',
                      clientName: _selectedClient?.name ?? '-',
                      attached: _composePresupuestoIds.contains(id),
                      cs: cs,
                      amount: _presupuestoTotal(item),
                      previewKey: 'budget:$id',
                      onPreview: id.isEmpty
                          ? null
                          : () =>
                              widget.state._openPresupuestoPdfPreviewById(id),
                      onRemove: () => _removePresupuesto(id),
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
                      documentId: id,
                      documentType: 'budget',
                      number: number.isEmpty
                          ? presupuestoDocumentTitle(item)
                          : number,
                      filename:
                          '${number.isEmpty ? presupuestoDocumentTitle(item) : number}.pdf',
                      clientName: _selectedClient?.name ?? '-',
                      attached: _composePresupuestoIds.contains(id),
                      cs: cs,
                      amount: _presupuestoTotal(item),
                      previewKey: 'budget:$id',
                      onPreview: id.isEmpty
                          ? null
                          : () =>
                              widget.state._openPresupuestoPdfPreviewById(id),
                      onRemove: () => _removePresupuesto(id),
                    );
                  }),
                ],
                if (manualAttachments.isNotEmpty) ...[
                  _previewSectionLabel(
                    isSpanish ? 'Otros adjuntos' : 'Other attachments',
                    cs,
                  ),
                  ...manualAttachments.map((attachment) {
                    final name =
                        widget.state._manualPdfAttachmentName(attachment);
                    final key = attachment.storageKey ?? name;
                    return _buildPreviewItemCard(
                      typeIcon: Icons.picture_as_pdf_outlined,
                      documentId: key,
                      documentType: 'file',
                      number: name,
                      filename: name,
                      clientName:
                          isSpanish ? 'Archivo del correo' : 'Email file',
                      attached: true,
                      cs: cs,
                      onRemove: () => widget.state.update(
                        () => widget.state._attachments.remove(attachment),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 8),
                _InvoiceHistorySection(
                  invoices: visibleHistoryInvoices,
                  expanded: _historyExpanded,
                  sentOnly: _historySentOnly,
                  hasMore:
                      allHistoryInvoices.length > visibleHistoryInvoices.length,
                  canCompare: currentAttachedInvoices.isNotEmpty,
                  comparingIds: _comparingInvoiceIds,
                  previewingIds: _previewingDocuments,
                  onToggle: () => setState(
                    () => _historyExpanded = !_historyExpanded,
                  ),
                  onSentOnlyChanged: (value) => setState(() {
                    _historySentOnly = value;
                    _historyVisibleCount = 4;
                  }),
                  onShowMore: () => setState(
                    () => _historyVisibleCount += 4,
                  ),
                  onPreview: (invoice) => _runDocumentPreview(
                    'history:${invoice.id}',
                    () => _openInvoicePdfPreview(invoice),
                  ),
                  onCompare: (invoice) => _showInvoiceComparison(
                    invoice,
                    currentAttachedInvoices,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      key: const ValueKey('mail-compose-selection-workspace'),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _modeSelector(
            typography: t,
            colors: cs,
            isSpanish: isSpanish,
          ),
          const SizedBox(height: 8),
          if (widget.state._preparationMode ==
              _ComposePreparationMode.clients) ...[
            SizedBox(
              key: const ValueKey('mail-attachment-compact-header'),
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.attach_file_rounded,
                      size: 16,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSpanish ? 'Adjuntar facturas' : 'Attach invoices',
                    style: t.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: stepHeader(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(child: stepBody()),
            const SizedBox(height: 6),
            Row(
              children: [
                HexoraButton(
                  onPressed:
                      _step == 0 ? null : () => setState(() => _step -= 1),
                  label: isSpanish ? 'Atrás' : 'Back',
                  size: HexoraButtonSize.standard,
                  variant: HexoraButtonVariant.secondary,
                ),
                const Spacer(),
                HexoraButton(
                  onPressed: () async {
                    if (_step < 2) {
                      _tryGoToStep(_step + 1, l);
                      return;
                    }
                    final pendingCount = _pendingAttachmentCount;
                    if (pendingCount == 0) {
                      widget.state._bodyFocus.requestFocus();
                      return;
                    }
                    final applied = await _applySelectionToCompose();
                    if (!context.mounted || !applied) return;
                    showSuccessSnack(
                      context,
                      _selectionAppliedMessage(l),
                      title: _selectionAppliedTitle(l),
                    );
                  },
                  label: _step < 2
                      ? (isSpanish ? 'Continuar' : 'Continue')
                      : _pendingAttachmentCount == 0
                          ? (isSpanish ? 'Volver al correo' : 'Back to email')
                          : isSpanish
                              ? 'Adjuntar $_pendingAttachmentCount ${_pendingAttachmentCount == 1 ? 'factura' : 'facturas'}'
                              : 'Attach $_pendingAttachmentCount ${_pendingAttachmentCount == 1 ? 'invoice' : 'invoices'}',
                  size: HexoraButtonSize.standard,
                  loading: _attachingDocuments,
                ),
              ],
            ),
          ] else
            Expanded(
              child:
                  widget.state._preparationMode == _ComposePreparationMode.email
                      ? _manualEmailMode(
                          typography: t,
                          colors: cs,
                          localizations: l,
                          isSpanish: isSpanish,
                        )
                      : _recentInvoicesMode(
                          typography: t,
                          colors: cs,
                          isSpanish: isSpanish,
                        ),
            ),
        ],
      ),
    );
  }
}
