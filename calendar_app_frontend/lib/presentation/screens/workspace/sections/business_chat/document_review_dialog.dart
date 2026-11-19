import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/services/business_chat/business_chat_api.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:intl/intl.dart';

class DocumentReviewSelection {
  const DocumentReviewSelection(
      {required this.conversationId,
      required this.kind,
      required this.documentId,
      required this.year,
      required this.quarter,
      required this.body,
      this.file});
  final String conversationId;
  final String kind;
  final String documentId;
  final int year;
  final int quarter;
  final String body;
  final PlatformFile? file;
}

enum DocumentReviewPresentation { dialog, sidePanel }

class DocumentReviewDialog extends StatefulWidget {
  const DocumentReviewDialog(
      {super.key,
      required this.groupId,
      required this.kind,
      required this.conversations,
      this.initialConversationId,
      this.onOpenBanking,
      this.onCreateExpense,
      this.presentation = DocumentReviewPresentation.dialog,
      this.onSelection,
      this.onClose,
      this.onCollapse});
  final String groupId;
  final String kind;
  final List<BusinessChatConversation> conversations;
  final String? initialConversationId;
  final Future<void> Function()? onOpenBanking;
  final Future<void> Function()? onCreateExpense;
  final DocumentReviewPresentation presentation;
  final ValueChanged<DocumentReviewSelection>? onSelection;
  final VoidCallback? onClose;

  /// Collapses the side panel to a slim rail while keeping its state alive.
  /// Only wired by the side-panel host; null hides the collapse control.
  final VoidCallback? onCollapse;

  @override
  State<DocumentReviewDialog> createState() => _DocumentReviewDialogState();
}

class _DocumentReviewDialogState extends State<DocumentReviewDialog> {
  final _api = BusinessChatApi();
  final _invoicesApi = InvoicesApi();
  final _search = TextEditingController();
  final _body = TextEditingController();
  late int _year;
  late int _quarter;
  int _page = 1;
  int _total = 0;
  int _revision = 0;
  bool _loading = false;
  bool _acknowledgedUnlinked = false;
  String? _error;
  String? _conversationId;
  Map<String, dynamic>? _selected;
  PlatformFile? _file;
  List<Map<String, dynamic>> _items = const [];
  Uint8List? _pdfBytes;
  bool _pdfLoading = false;
  String? _pdfError;
  bool get _es => Localizations.localeOf(context).languageCode == 'es';

  bool get _isSidePanel =>
      widget.presentation == DocumentReviewPresentation.sidePanel;

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context).pop();
  }

  void _submit(DocumentReviewSelection selection) {
    if (widget.onSelection != null) {
      widget.onSelection!(selection);
      return;
    }
    Navigator.of(context).pop(selection);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _quarter = ((now.month - 1) ~/ 3) + 1;
    _conversationId =
        widget.conversations.any((c) => c.id == widget.initialConversationId)
            ? widget.initialConversationId
            : widget.conversations.firstOrNull?.id;
    _load();
  }

  @override
  void dispose() {
    _revision++;
    _search.dispose();
    _body.dispose();
    super.dispose();
  }

  bool _isActiveWorker(Map<String, dynamic> item) {
    final explicit = item['isActive'] ?? item['active'];
    if (explicit is bool) return explicit;
    if (explicit is num) return explicit != 0;
    final worker = item['worker'];
    final status = (item['workerStatus'] ??
            item['status'] ??
            (worker is Map ? worker['status'] : null))
        ?.toString()
        .trim()
        .toLowerCase();
    // Older review payloads did not include a worker status. Keep those rows
    // visible until the API supplies an explicit status rather than hiding
    // potentially active workers.
    return status == null ||
        status.isEmpty ||
        status == 'active' ||
        status == 'activo';
  }

  Future<void> _load({int page = 1}) async {
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
      _selected = null;
      _acknowledgedUnlinked = false;
    });
    try {
      final data = await _api.reviewDocuments(widget.groupId,
          kind: widget.kind,
          year: _year,
          quarter: _quarter,
          page: page,
          search: _search.text.trim());
      if (!mounted || revision != _revision) return;
      setState(() {
        final items = (data['items'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _items = widget.kind == 'worker_hours'
            ? items.where(_isActiveWorker).toList()
            : items;
        _total = widget.kind == 'worker_hours'
            ? _items.length
            : (data['total'] as num?)?.toInt() ?? 0;
        _page = page;
        _loading = false;
        _pdfBytes = null;
        _pdfError = null;
      });
    } catch (error) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _loadPdf(Map<String, dynamic> item) async {
    if (widget.kind != 'invoice') return;
    final id = item['id']?.toString().trim() ?? '';
    if (id.isEmpty) return;
    setState(() {
      _pdfLoading = true;
      _pdfError = null;
      _pdfBytes = null;
    });
    try {
      final response = await _invoicesApi.previewPdf(id);
      if (!mounted || _selected?['id']?.toString() != id) return;
      setState(() => _pdfBytes = response.bodyBytes);
    } catch (error) {
      if (!mounted || _selected?['id']?.toString() != id) return;
      setState(
          () => _pdfError = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && _selected?['id']?.toString() == id) {
        setState(() => _pdfLoading = false);
      }
    }
  }

  IconData get _kindIcon => switch (widget.kind) {
        'invoice' => Icons.receipt_long_outlined,
        'expense' => Icons.account_balance_wallet_outlined,
        _ => Icons.schedule_outlined,
      };

  /// Opens a lightweight PDF preview for an invoice without selecting it or
  /// advancing the review workflow, so list state (selection, scroll, filters)
  /// is untouched.
  void _previewInvoicePdf(Map<String, dynamic> item) {
    if (widget.kind != 'invoice') return;
    final id = item['id']?.toString().trim() ?? '';
    if (id.isEmpty) return;
    final number = (item['number'] ?? item['counterparty'] ?? '').toString();
    showDialog<void>(
      context: context,
      builder: (_) => _InvoicePreviewDialog(
        api: _invoicesApi,
        invoiceId: id,
        title: number.isEmpty ? (_es ? 'Vista previa' : 'Preview') : number,
        es: _es,
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'csv', 'xlsx'],
        withData: true);
    if (!mounted || result == null || result.files.isEmpty) return;
    if (result.files.single.size > 10 * 1024 * 1024) {
      setState(() => _error = _es ? 'Máximo 10 MB' : 'Maximum 10 MB');
      return;
    }
    setState(() => _file = result.files.single);
  }

  void _returnToSelection() {
    setState(() {
      _selected = null;
      _pdfBytes = null;
      _pdfError = null;
      _acknowledgedUnlinked = false;
    });
  }

  Future<void> _downloadPdf(Map<String, dynamic> selected) async {
    if (_pdfBytes == null) return;
    final number =
        (selected['number'] ?? selected['id'] ?? 'invoice').toString();
    try {
      await launchFileDownload(
        _pdfBytes!,
        fileName: 'factura-$number.pdf',
        mimeType: 'application/pdf',
      );
    } catch (error) {
      if (mounted) setState(() => _pdfError = error.toString());
    }
  }

  void _openPdfFullscreen(Map<String, dynamic> selected) {
    if (_pdfBytes == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width - 40,
          height: MediaQuery.sizeOf(context).height - 40,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _buildPdfPreview(selected),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfPreview(Map<String, dynamic>? selected) {
    final uploadedBytes = _file?.bytes;
    final hasUploadedPdf = _file?.extension?.toLowerCase() == 'pdf';
    if (widget.kind != 'invoice' && uploadedBytes != null && hasUploadedPdf) {
      return LayoutBuilder(
        builder: (context, constraints) => PdfInlinePreview(
          bytes: uploadedBytes,
          height: constraints.hasBoundedHeight
              ? constraints.maxHeight.clamp(220.0, 1200.0).toDouble()
              : 440,
          interactive: true,
        ),
      );
    }
    if (widget.kind == 'expense') return _expensePdfEmpty();
    if (widget.kind != 'invoice') {
      return _previewEmpty(
        Icons.description_outlined,
        _es
            ? 'La vista previa PDF está disponible para facturas.'
            : 'PDF preview is available for invoices.',
      );
    }
    if (selected == null) {
      return _previewEmpty(
        Icons.picture_as_pdf_outlined,
        _es
            ? 'Selecciona una factura para ver su PDF.'
            : 'Select an invoice to preview its PDF.',
      );
    }
    if (_pdfLoading) return const Center(child: CircularProgressIndicator());
    if (_pdfError != null) {
      return _previewEmpty(Icons.error_outline, _pdfError!, error: true);
    }
    if (_pdfBytes == null) {
      return _previewEmpty(
        Icons.picture_as_pdf_outlined,
        _es
            ? 'Esta factura no tiene un PDF disponible.'
            : 'This invoice has no PDF available.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight.clamp(220.0, 1200.0).toDouble()
            : 440.0;
        return PdfInlinePreview(
          bytes: _pdfBytes!,
          height: previewHeight,
          interactive: true,
        );
      },
    );
  }

  Widget _expensePdfEmpty() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: const Color(0xFFF8FAFC),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.description_outlined, size: 36, color: cs.onSurfaceVariant),
        const SizedBox(height: 10),
        Text(
          _es
              ? 'Adjunta el PDF del gasto para ver la vista previa.'
              : 'Attach the expense PDF to view its preview.',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.add, size: 18),
          label: Text(_es ? 'Subir PDF' : 'Upload PDF'),
        ),
      ]),
    );
  }

  Widget _previewEmpty(IconData icon, String message, {bool error = false}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: error ? cs.error : cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: error ? cs.error : cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildSelectedSummary(Map<String, dynamic> item) {
    final cs = Theme.of(context).colorScheme;
    final number = (item['number'] ?? '').toString().trim();
    final counterparty = (item['counterparty'] ?? '').toString().trim();
    final date = DateTime.tryParse((item['date'] ?? '').toString());
    final total = item['total'] ?? item['totalAmount'] ?? item['amount'];
    final linked = item['linkedTransactionCount'];
    final sending = item['sendingStatus'] ?? item['status'];
    final payment = item['paymentStatus'];
    final values = <String>[
      if (number.isNotEmpty) number,
      if (counterparty.isNotEmpty) counterparty,
      if (date != null) DateFormat.yMMMd(_es ? 'es' : 'en').format(date),
      if (total != null) '$total €',
    ];
    final badges = <Widget>[
      if (sending != null && sending.toString().trim().isNotEmpty)
        _statusChip(sending.toString(), cs.primary),
      if (payment != null && payment.toString().trim().isNotEmpty)
        _statusChip(payment.toString(), cs.tertiary),
      if (linked is num)
        _statusChip(
          linked == 0
              ? (_es ? 'Sin vincular' : 'Unlinked')
              : (_es ? 'Vinculada' : 'Linked'),
          linked == 0 ? cs.onSurfaceVariant : cs.secondary,
        ),
    ];
    if (values.isEmpty && badges.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minHeight: 40, maxHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(values.join(' · '), maxLines: 1),
            if (badges.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...badges.expand((badge) => [
                    badge,
                    const SizedBox(width: 6),
                  ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewActionPane({
    required bool unlinked,
    required bool hasWorkerHours,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _es ? 'Solicitar cambios' : 'Request changes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          if (unlinked)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _acknowledgedUnlinked,
                    onChanged: (value) =>
                        setState(() => _acknowledgedUnlinked = value == true),
                    title: Text(
                      _es
                          ? 'Confirmar sin movimiento vinculado'
                          : 'Confirm no linked movement',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                if (widget.onOpenBanking != null)
                  IconButton(
                    tooltip: _es ? 'Abrir Banco' : 'Open Banking',
                    onPressed: () async {
                      try {
                        await widget.onOpenBanking!();
                        if (mounted) _load(page: _page);
                      } catch (error) {
                        if (mounted) setState(() => _error = error.toString());
                      }
                    },
                    icon: const Icon(Icons.account_balance_outlined, size: 18),
                  ),
              ],
            ),
          if (!hasWorkerHours)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _es
                    ? 'Adjunta el parte de horas para continuar.'
                    : 'Attach the hours sheet to continue.',
                style: TextStyle(color: cs.error, fontSize: 12),
              ),
            ),
          TextField(
            controller: _body,
            maxLength: 2000,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              labelText: _es
                  ? 'Qué deben revisar o cambiar'
                  : 'What to review or change',
              alignLabelWithHint: true,
              counterText: '${_body.text.length}/2000',
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                    color: cs.outlineVariant, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _file?.name ?? (_es ? 'Adjuntar archivo' : 'Attach file'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (_file != null)
                    IconButton(
                      tooltip: _es ? 'Quitar archivo' : 'Remove file',
                      onPressed: () => setState(() => _file = null),
                      icon: const Icon(Icons.close, size: 17),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      );

  Widget? _compactAmount(Map<String, dynamic> item) {
    final value = item['total'] ?? item['totalAmount'] ?? item['amount'];
    if (value == null || value.toString().trim().isEmpty) return null;
    return Text(
      '${value.toString()} €',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _panelFilters() => LayoutBuilder(
        builder: (context, constraints) {
          final controls = [
            DropdownButtonFormField<int>(
              value: _year,
              isExpanded: true,
              decoration: InputDecoration(
                  isDense: true,
                  hintText: _es ? 'Año' : 'Year',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              items: List.generate(DateTime.now().year - 1999,
                      (index) => DateTime.now().year - index)
                  .map((year) =>
                      DropdownMenuItem(value: year, child: Text('$year')))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _year = value;
                  _load();
                }
              },
            ),
            DropdownButtonFormField<int>(
              value: _quarter,
              isExpanded: true,
              decoration: InputDecoration(
                  isDense: true,
                  hintText: _es ? 'Trimestre' : 'Quarter',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              items: List.generate(4, (index) => index + 1)
                  .map((quarter) => DropdownMenuItem(
                      value: quarter,
                      child: Text('${_es ? 'T' : 'Q'}$quarter')))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _quarter = value;
                  _load();
                }
              },
            ),
          ];
          final search = TextField(
            controller: _search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              isDense: true,
              hintText: _es
                  ? 'Cliente, proveedor o número'
                  : 'Client, provider, or number',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              suffixIcon: IconButton(
                tooltip: _es ? 'Buscar' : 'Search',
                onPressed: _load,
                icon: const Icon(Icons.search),
              ),
            ),
          );
          if (constraints.maxWidth < 500) {
            return Column(children: [
              Row(children: [
                Expanded(child: controls[0]),
                const SizedBox(width: 8),
                Expanded(child: controls[1]),
              ]),
              const SizedBox(height: 8),
              search,
            ]);
          }
          return Row(children: [
            SizedBox(width: 88, child: controls[0]),
            const SizedBox(width: 6),
            SizedBox(width: 96, child: controls[1]),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: search),
          ]);
        },
      );

  Widget _panelInvoiceList(
      List<Map<String, dynamic>> sorted, Map<String, dynamic>? selected) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (sorted.isEmpty) {
      return Center(
        child: Text(_es
            ? 'Sin resultados en este trimestre'
            : 'No results this quarter'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 2),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color:
            Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .35),
      ),
      itemBuilder: (context, index) => _InvoiceRow(
        item: sorted[index],
        selected: selected?['id'] == sorted[index]['id'],
        icon: _kindIcon,
        es: _es,
        showEye: widget.kind == 'invoice',
        onTap: () {
          setState(() {
            _selected = sorted[index];
            _acknowledgedUnlinked = false;
          });
          _loadPdf(sorted[index]);
        },
        onPreview: () => _previewInvoicePdf(sorted[index]),
      ),
    );
  }

  Widget _panelPagination() {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final totalPages = (_total / 30).ceil().clamp(1, 100000);
    final totalLabel = widget.kind == 'worker_hours'
        ? (_es
            ? '$_total ${_total == 1 ? 'trabajador activo' : 'trabajadores activos'}'
            : '$_total ${_total == 1 ? 'active worker' : 'active workers'}')
        : (_es
            ? '$_total ${_total == 1 ? 'factura' : 'facturas'}'
            : '$_total ${_total == 1 ? 'invoice' : 'invoices'}');
    Widget navButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
    }) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            foregroundColor: cs.onSurfaceVariant,
            disabledForegroundColor: cs.onSurface.withValues(alpha: 0.3),
          ),
        );
    return Row(children: [
      Text(
        totalLabel,
        style: t.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      const Spacer(),
      navButton(
        icon: Icons.chevron_left_rounded,
        tooltip: _es ? 'Página anterior' : 'Previous page',
        onPressed: _page > 1 && !_loading ? () => _load(page: _page - 1) : null,
      ),
      Text(
        '${_es ? 'Pág.' : 'Page'} $_page / $totalPages',
        style: t.bodySmall?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      navButton(
        icon: Icons.chevron_right_rounded,
        tooltip: _es ? 'Página siguiente' : 'Next page',
        onPressed: _page * 30 < _total && !_loading
            ? () => _load(page: _page + 1)
            : null,
      ),
    ]);
  }

  Widget _panelHeader({
    required String title,
    required Map<String, dynamic>? selected,
    required String? destination,
    required List<Map<String, dynamic>> sorted,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    Widget headerButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
    }) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon, size: 19),
        );
    final subtitle =
        destination ?? (_es ? 'Sin chat seleccionado' : 'No chat selected');
    final selectedIndex = selected == null
        ? -1
        : sorted.indexWhere((item) => item['id'] == selected['id']);
    final queue = selectedIndex < 0
        ? const SizedBox.shrink()
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: _es ? 'Factura anterior' : 'Previous invoice',
                onPressed: selectedIndex > 0
                    ? () {
                        final item = sorted[selectedIndex - 1];
                        setState(() {
                          _selected = item;
                          _acknowledgedUnlinked = false;
                        });
                        _loadPdf(item);
                      }
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '${_es ? 'Factura' : 'Invoice'} ${selectedIndex + 1} / ${sorted.length}',
                style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              IconButton(
                tooltip: _es ? 'Factura siguiente' : 'Next invoice',
                onPressed:
                    selectedIndex >= 0 && selectedIndex < sorted.length - 1
                        ? () {
                            final item = sorted[selectedIndex + 1];
                            setState(() {
                              _selected = item;
                              _acknowledgedUnlinked = false;
                            });
                            _loadPdf(item);
                          }
                        : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          );
    final destinationMenu = widget.conversations.isEmpty
        ? Text(subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant))
        : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _conversationId,
              isDense: true,
              iconSize: 15,
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              items: widget.conversations
                  .map((conversation) => DropdownMenuItem<String>(
                        value: conversation.id,
                        child: Text(conversation.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _conversationId = value),
            ),
          );
    return SizedBox(
      height: 60,
      child: Padding(
        padding: EdgeInsets.only(left: selected != null ? 4 : 14, right: 6),
        child: Row(children: [
          if (selected != null)
            headerButton(
              icon: Icons.arrow_back_rounded,
              tooltip: _es ? 'Volver a facturas' : 'Back to invoices',
              onPressed: _returnToSelection,
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(_kindIcon, size: 18, color: cs.primary),
            ),
          SizedBox(width: selected != null ? 6 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Row(children: [
                  Expanded(
                    child: Text(
                      selected == null
                          ? subtitle
                          : 'Administration / Facturas / ${(selected['number'] ?? '').toString()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  if (selected == null) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.forum_outlined, size: 12),
                    const SizedBox(width: 2),
                    SizedBox(width: 124, child: destinationMenu),
                  ],
                ]),
              ],
            ),
          ),
          if (selected != null) queue,
          if (selected != null && widget.kind == 'invoice') ...[
            headerButton(
              icon: Icons.download_outlined,
              tooltip: _es ? 'Descargar PDF' : 'Download PDF',
              onPressed:
                  _pdfBytes == null ? null : () => _downloadPdf(selected),
            ),
            headerButton(
              icon: Icons.open_in_full_rounded,
              tooltip: _es ? 'Pantalla completa' : 'Fullscreen',
              onPressed:
                  _pdfBytes == null ? null : () => _openPdfFullscreen(selected),
            ),
          ],
          if (widget.onCollapse != null)
            headerButton(
              icon: Icons.chevron_right_rounded,
              tooltip: _es ? 'Contraer panel' : 'Collapse panel',
              onPressed: widget.onCollapse,
            ),
          headerButton(
            icon: Icons.close_rounded,
            tooltip: _es ? 'Cerrar' : 'Close',
            onPressed: _close,
          ),
        ]),
      ),
    );
  }

  Widget _buildSelectedWorkspace({
    required Map<String, dynamic> selected,
    required bool unlinked,
    required bool hasWorkerHours,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSelectedSummary(selected)),
            IconButton(
              tooltip: _es ? 'Descargar PDF' : 'Download PDF',
              onPressed:
                  _pdfBytes == null ? null : () => _downloadPdf(selected),
              icon: const Icon(Icons.download_outlined, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: ColoredBox(
                  color: const Color(0xFFF8FAFC),
                  child: _buildPdfPreview(selected),
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                flex: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: .7),
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: _buildReviewActionPane(
                      unlinked: unlinked,
                      hasWorkerHours: hasWorkerHours,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidePanel({
    required String title,
    required Map<String, dynamic>? selected,
    required List<Map<String, dynamic>> sorted,
    required bool unlinked,
    required bool hasWorkerHours,
    required bool canSend,
  }) {
    final destination = widget.conversations
        .where((conversation) => conversation.id == _conversationId)
        .map((conversation) => conversation.title)
        .firstOrNull;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(children: [
          _panelHeader(
            title: title,
            selected: selected,
            destination: destination,
            sorted: sorted,
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: selected == null
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: selected == null
                  ? Column(children: [
                      const SizedBox(height: 4),
                      _panelFilters(),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Expanded(child: _panelInvoiceList(sorted, selected)),
                      const SizedBox(height: 4),
                      _panelPagination(),
                    ])
                  : _buildSelectedWorkspace(
                      selected: selected,
                      unlinked: unlinked,
                      hasWorkerHours: hasWorkerHours,
                    ),
              /*
                      _buildSelectedSummary(selected),
                      const SizedBox(height: 6),
                      Expanded(child: _buildPdfPreview(selected)),
                      if (unlinked) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          Expanded(
                            child: CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: _acknowledgedUnlinked,
                              onChanged: (value) => setState(
                                  () => _acknowledgedUnlinked = value == true),
                              title: Text(_es
                                  ? 'Confirmo que no hay movimiento vinculado.'
                                  : 'I confirm there is no linked transaction.'),
                            ),
                          ),
                          if (widget.onOpenBanking != null)
                            TextButton.icon(
                              onPressed: () async {
                                try {
                                  await widget.onOpenBanking!();
                                  if (mounted) _load(page: _page);
                                } catch (error) {
                                  if (mounted) {
                                    setState(() => _error = error.toString());
                                  }
                                }
                              },
                              icon: const Icon(Icons.account_balance_outlined,
                                  size: 17),
                              label: Text(_es ? 'Abrir Banco' : 'Open Banking'),
                            ),
                        ]),
                      ],
                      if (!hasWorkerHours)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_es
                              ? 'Adjunta el parte de horas para continuar.'
                              : 'Attach the hours sheet to continue.'),
                        ),
                      const SizedBox(height: 4),
                      Row(children: [
                        TextButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.attach_file),
                          label: Text(_es ? 'Adjuntar archivo' : 'Attach file'),
                        ),
                        if (_file != null)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: InputChip(
                                label: Text(_file!.name,
                                    overflow: TextOverflow.ellipsis),
                                onDeleted: () => setState(() => _file = null),
                              ),
                            ),
                          ),
                      ]),
                      TextField(
                        controller: _body,
                        maxLength: 2000,
                        minLines: 1,
                        maxLines: 3,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: _es
                              ? 'Qué deben revisar o cambiar'
                              : 'What to review or change',
                        ),
                      ),
                    ]), */
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: _close, child: Text(_es ? 'Cancelar' : 'Cancel')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: canSend
                    ? () => _submit(DocumentReviewSelection(
                          conversationId: _conversationId!,
                          kind: widget.kind,
                          documentId: selected!['id'].toString(),
                          year: _year,
                          quarter: _quarter,
                          body: _body.text.trim(),
                          file: _file,
                        ))
                    : null,
                child: Text(_es ? 'Pedir revisión' : 'Request review'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final wide = _isSidePanel || viewport.width >= 720;
    final dialogWidth = _isSidePanel
        ? (viewport.width * .46).clamp(520.0, 650.0).toDouble()
        : wide
            ? 1080.0
            : (viewport.width - 32).clamp(280.0, 620.0).toDouble();
    final dialogHeight = _isSidePanel
        ? viewport.height
        : wide
            ? 680.0
            : (viewport.height - 150).clamp(420.0, 680.0).toDouble();
    final selected = _selected;
    final unlinked = selected != null &&
        widget.kind == 'invoice' &&
        selected['linkedTransactionCount'] is num &&
        (selected['linkedTransactionCount'] as num) == 0;
    final hasWorkerHours = widget.kind != 'worker_hours' ||
        (selected?['timeEntriesCount'] as num? ?? 0) > 0 ||
        _file != null;
    final title = switch (widget.kind) {
      'invoice' => _es ? 'Revisar factura' : 'Review invoice',
      'expense' => _es ? 'Revisar gasto' : 'Review expense',
      _ => _es ? 'Revisar horas' : 'Review hours',
    };
    final canSend = selected != null &&
        _conversationId != null &&
        _body.text.trim().isNotEmpty &&
        hasWorkerHours &&
        (!unlinked || _acknowledgedUnlinked);
    final sorted = [..._items]..sort((a, b) {
        final byName = (a['counterparty'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo((b['counterparty'] ?? '').toString().toLowerCase());
        return byName != 0
            ? byName
            : (b['date'] ?? '')
                .toString()
                .compareTo((a['date'] ?? '').toString());
      });
    if (_isSidePanel) {
      return _buildSidePanel(
        title: title,
        selected: selected,
        sorted: sorted,
        unlinked: unlinked,
        hasWorkerHours: hasWorkerHours,
        canSend: canSend,
      );
    }
    final dialog = AlertDialog(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 2),
                Text(
                  _es
                      ? 'Selecciona una factura, revisa su PDF y envía las instrucciones al equipo.'
                      : 'Select an invoice, review its PDF, and send instructions to the team.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _es ? 'Cerrar' : 'Close',
            onPressed: _close,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Row(children: [
          Expanded(
            flex: 45,
            child: Column(children: [
              DropdownButtonFormField<String>(
                value: _conversationId,
                decoration: InputDecoration(
                    labelText:
                        _es ? 'Chat de administradores' : 'Admin team chat'),
                items: widget.conversations
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.title)))
                    .toList(),
                onChanged: (value) => setState(() => _conversationId = value),
              ),
              const SizedBox(height: 8),
              Row(children: [
                SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<int>(
                      value: _year,
                      decoration:
                          InputDecoration(labelText: _es ? 'Año' : 'Year'),
                      items: List.generate(DateTime.now().year - 1999,
                              (i) => DateTime.now().year - i)
                          .map((year) => DropdownMenuItem(
                              value: year, child: Text('$year')))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _year = value;
                          _load();
                        }
                      },
                    )),
                const SizedBox(width: 8),
                SizedBox(
                    width: 145,
                    child: DropdownButtonFormField<int>(
                      value: _quarter,
                      decoration: InputDecoration(
                          labelText: _es ? 'Trimestre' : 'Quarter'),
                      items: List.generate(4, (i) => i + 1)
                          .map((quarter) => DropdownMenuItem(
                              value: quarter,
                              child: Text('${_es ? 'T' : 'Q'}$quarter')))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _quarter = value;
                          _load();
                        }
                      },
                    )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                      isDense: true,
                      labelText: _es
                          ? 'Cliente / proveedor / número'
                          : 'Client / provider / number',
                      suffixIcon: IconButton(
                          onPressed: () => _load(),
                          icon: const Icon(Icons.search))),
                )),
              ]),
              const SizedBox(height: 8),
              if (_error != null)
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              if (selected != null && widget.kind == 'invoice')
                _buildSelectedSummary(selected),
              Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _items.isEmpty
                          ? Center(
                              child: Text(_es
                                  ? 'Sin resultados en este trimestre'
                                  : 'No results this quarter'))
                          : ListView.builder(
                              itemCount: sorted.length,
                              itemBuilder: (context, index) {
                                final item = sorted[index];
                                final name =
                                    (item['counterparty'] ?? '').toString();
                                final showHeader = index == 0 ||
                                    (sorted[index - 1]['counterparty'] ?? '')
                                            .toString() !=
                                        name;
                                final date = DateTime.tryParse(
                                    (item['date'] ?? '').toString());
                                final subtitle = [
                                  if (date != null)
                                    DateFormat.yMMMd(_es ? 'es' : 'en')
                                        .format(date),
                                  if (widget.kind == 'worker_hours')
                                    '${item['timeEntriesCount'] ?? 0} ${_es ? 'registros' : 'entries'}',
                                  if (item['linkedTransactionCount'] is num)
                                    '${item['linkedTransactionCount']} ${_es ? 'movimientos vinculados' : 'linked transactions'}',
                                ].join(' · ');
                                return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (showHeader)
                                        Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                12, 8, 12, 2),
                                            child: Text(name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium)),
                                      ListTile(
                                          dense: true,
                                          selected:
                                              selected?['id'] == item['id'],
                                          title: Text(
                                              (item['number'] ?? '')
                                                      .toString()
                                                      .isNotEmpty
                                                  ? item['number'].toString()
                                                  : name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          subtitle: Text(subtitle,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                          trailing: _compactAmount(item),
                                          onTap: () {
                                            setState(() {
                                              _selected = item;
                                              _acknowledgedUnlinked = false;
                                            });
                                            _loadPdf(item);
                                          }),
                                    ]);
                              })),
              Row(children: [
                IconButton(
                    onPressed: _page > 1 && !_loading
                        ? () => _load(page: _page - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left)),
                Text('$_page / ${(_total / 30).ceil().clamp(1, 100000)}'),
                IconButton(
                    onPressed: _page * 30 < _total && !_loading
                        ? () => _load(page: _page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right)),
                const Spacer(),
                Text('$_total'),
              ]),
              if (unlinked)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _es
                        ? 'Esta factura no tiene movimientos bancarios vinculados.'
                        : 'This invoice has no linked bank transactions.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (unlinked)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _acknowledgedUnlinked,
                  onChanged: (value) =>
                      setState(() => _acknowledgedUnlinked = value == true),
                  title: Text(_es
                      ? 'Sin movimiento vinculado. Vincúlalo en Banco o confirma que enviarás la revisión pendiente de vinculación.'
                      : 'No linked transaction. Link it in Banking or confirm you will send the review pending a link.'),
                ),
              if (unlinked && widget.onOpenBanking != null)
                Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        try {
                          await widget.onOpenBanking!();
                          if (mounted) _load(page: _page);
                        } catch (error) {
                          if (mounted)
                            setState(() => _error = error.toString());
                        }
                      },
                      icon: const Icon(Icons.account_balance_outlined),
                      label: Text(_es
                          ? 'Abrir Banco para vincular'
                          : 'Open Banking to link'),
                    )),
              if (!hasWorkerHours && selected != null)
                Text(_es
                    ? 'Adjunta el parte de horas para continuar.'
                    : 'Attach the hours sheet to continue.'),
              if (widget.kind == 'expense' && widget.onCreateExpense != null)
                Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        try {
                          await widget.onCreateExpense!();
                          if (mounted) _load();
                        } catch (error) {
                          if (mounted)
                            setState(() => _error = error.toString());
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(_es
                          ? 'Registrar nuevo gasto'
                          : 'Register new expense'),
                    )),
              Row(children: [
                TextButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_file?.name ??
                        (_es
                            ? 'Adjuntar PDF, imagen o Excel'
                            : 'Attach PDF, image, or Excel'))),
                if (_file != null)
                  IconButton(
                      onPressed: () => setState(() => _file = null),
                      icon: const Icon(Icons.close)),
              ]),
              TextField(
                  controller: _body,
                  maxLength: 2000,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                      labelText: _es
                          ? 'Qué deben revisar o cambiar'
                          : 'What to review or change')),
            ]),
          ),
          if (wide) ...[
            const VerticalDivider(width: 24, thickness: 1),
            Expanded(
              flex: 55,
              child: _buildPdfPreview(selected),
            ),
          ],
        ]),
      ),
      actions: [
        if (!wide && selected != null && widget.kind == 'invoice')
          TextButton.icon(
            onPressed: _pdfBytes == null
                ? null
                : () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: viewport.width - 32,
                            height: viewport.height - 120,
                            child: _buildPdfPreview(selected),
                          ),
                        ),
                      ),
                    ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_es ? 'Ver PDF' : 'View PDF'),
          ),
        TextButton(onPressed: _close, child: Text(_es ? 'Cancelar' : 'Cancel')),
        FilledButton(
            onPressed: canSend
                ? () => _submit(DocumentReviewSelection(
                    conversationId: _conversationId!,
                    kind: widget.kind,
                    documentId: selected['id'].toString(),
                    year: _year,
                    quarter: _quarter,
                    body: _body.text.trim(),
                    file: _file))
                : null,
            child: Text(_es ? 'Pedir revisión' : 'Request review')),
      ],
    );
    return dialog;
  }
}

class _InvoicePreviewDialog extends StatefulWidget {
  const _InvoicePreviewDialog({
    required this.api,
    required this.invoiceId,
    required this.title,
    required this.es,
  });

  final InvoicesApi api;
  final String invoiceId;
  final String title;
  final bool es;

  @override
  State<_InvoicePreviewDialog> createState() => _InvoicePreviewDialogState();
}

class _InvoicePreviewDialogState extends State<_InvoicePreviewDialog> {
  late final Future<dynamic> _pdf = widget.api.previewPdf(widget.invoiceId);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: (MediaQuery.sizeOf(context).width - 48).clamp(320.0, 900.0),
        height: (MediaQuery.sizeOf(context).height - 96).clamp(360.0, 900.0),
        child: Column(
          children: [
            ListTile(
              dense: true,
              title: Text(widget.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<dynamic>(
                future: _pdf,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || snapshot.data?.bodyBytes == null) {
                    return Center(
                      child: Text(widget.es
                          ? 'No se pudo cargar la vista previa.'
                          : 'Unable to load the preview.'),
                    );
                  }
                  final bytes = snapshot.data.bodyBytes;
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: PdfInlinePreview(
                      bytes: bytes,
                      height: double.infinity,
                      interactive: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact invoice list row: icon, client name + number, date and linked
/// movement status on a second line, and a dedicated eye action that previews
/// the PDF without selecting the row or advancing the review workflow.
class _InvoiceRow extends StatefulWidget {
  const _InvoiceRow({
    required this.item,
    required this.selected,
    required this.icon,
    required this.es,
    required this.showEye,
    required this.onTap,
    required this.onPreview,
  });

  final Map<String, dynamic> item;
  final bool selected;
  final IconData icon;
  final bool es;
  final bool showEye;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  @override
  State<_InvoiceRow> createState() => _InvoiceRowState();
}

class _InvoiceRowState extends State<_InvoiceRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final item = widget.item;
    final name = (item['counterparty'] ?? '').toString().trim();
    final number = (item['number'] ?? '').toString().trim();
    final date = DateTime.tryParse((item['date'] ?? '').toString());
    final linked = item['linkedTransactionCount'];
    final amount = item['total'] ?? item['totalAmount'] ?? item['amount'];
    final title = name.isEmpty
        ? (number.isEmpty ? (widget.es ? 'Sin nombre' : 'Untitled') : number)
        : name;
    final dateStr = date != null
        ? DateFormat.yMMMd(widget.es ? 'es' : 'en').format(date)
        : null;
    final unlinked = linked is num && linked == 0;
    final linkLabel = linked is num
        ? '${linked.toInt()} ${widget.es ? 'movimientos' : 'transactions'}'
        : null;
    final hasAmount = amount != null && amount.toString().trim().isNotEmpty;

    final secondarySpans = <InlineSpan>[];
    void addSeparator() {
      if (secondarySpans.isNotEmpty)
        secondarySpans.add(const TextSpan(text: ' · '));
    }

    if (dateStr != null) secondarySpans.add(TextSpan(text: dateStr));
    if (linkLabel != null) {
      addSeparator();
      secondarySpans.add(TextSpan(
        text: linkLabel,
        style: TextStyle(
          color: unlinked ? cs.onSurfaceVariant : cs.secondary,
          fontWeight: FontWeight.w500,
        ),
      ));
    }
    if (hasAmount) {
      addSeparator();
      secondarySpans.add(TextSpan(text: '$amount €'));
    }

    final border = widget.selected
        ? cs.primary.withValues(alpha: 0.5)
        : cs.outlineVariant.withValues(alpha: 0.6);
    final bg = widget.selected
        ? cs.primary.withValues(alpha: 0.08)
        : (_hover ? cs.onSurface.withValues(alpha: 0.03) : cs.surface);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: bg,
        child: InkWell(
          borderRadius: BorderRadius.zero,
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                bottom: BorderSide(color: border.withValues(alpha: .45)),
              ),
            ),
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(widget.icon, size: 16, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Tooltip(
                          message: title,
                          waitDuration: const Duration(milliseconds: 500),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                      if (number.isNotEmpty && name.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '#$number',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ]),
                    if (secondarySpans.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          style: t.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          children: secondarySpans,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.showEye) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: widget.es ? 'Vista previa del PDF' : 'Preview PDF',
                  onPressed: widget.onPreview,
                  icon: Icon(Icons.visibility_outlined,
                      size: 18, color: cs.onSurfaceVariant),
                  constraints:
                      const BoxConstraints.tightFor(width: 34, height: 34),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
