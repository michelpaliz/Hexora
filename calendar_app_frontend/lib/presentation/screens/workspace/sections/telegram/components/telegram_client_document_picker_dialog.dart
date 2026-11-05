import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/models/presupuesto/presupuesto_kind.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';
import 'package:hexora/services/receipts/receipts_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/documents/presupuesto_document_workspace.dart';
import 'package:hexora/presentation/shared/widgets/client_search_select.dart';

class TelegramClientDocumentSelection {
  const TelegramClientDocumentSelection({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
    required this.clientId,
    required this.documentId,
    required this.documentLabel,
    required this.documentKind,
  });

  final String fileName;
  final Uint8List bytes;
  final String mimeType;
  final String clientId;
  final String documentId;
  final String documentLabel;
  final String documentKind;
}

abstract final class ClientDocumentKinds {
  static const invoice = 'invoice';
  static const draft = 'draft';
  static const receipt = 'receipt';
  static const quote = 'presupuesto';
  static const all = <String>{invoice, draft, receipt, quote};
}

/// Lets the user tick PDFs across clients and document types; returns them in
/// tick order.
Future<List<TelegramClientDocumentSelection>?>
    showTelegramClientDocumentPickerDialog(
  BuildContext context, {
  required String groupId,
  String? initialClientId,
  Set<String> allowedDocumentKinds = ClientDocumentKinds.all,
}) {
  return showHexoraDialog<List<TelegramClientDocumentSelection>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: Theme.of(dialogContext).canvasColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 1040,
        height: 700,
        child: TelegramClientDocumentPickerDialog(
          groupId: groupId,
          initialClientId: initialClientId,
          allowedDocumentKinds: allowedDocumentKinds,
        ),
      ),
    ),
  );
}

class TelegramClientDocumentPickerDialog extends StatefulWidget {
  const TelegramClientDocumentPickerDialog({
    super.key,
    required this.groupId,
    this.initialClientId,
    this.allowedDocumentKinds = ClientDocumentKinds.all,
  });

  final String groupId;
  final String? initialClientId;
  final Set<String> allowedDocumentKinds;

  @override
  State<TelegramClientDocumentPickerDialog> createState() =>
      _TelegramClientDocumentPickerDialogState();
}

enum _TelegramClientDocumentType {
  invoice(Icons.receipt_long_rounded),
  draft(Icons.edit_note_rounded),
  receipt(Icons.receipt_rounded),
  presupuesto(Icons.request_quote_rounded);

  const _TelegramClientDocumentType(this.icon);

  final IconData icon;

  String label(bool isEs) => switch (this) {
        invoice => isEs ? 'Facturas' : 'Invoices',
        draft => isEs ? 'Borradores' : 'Drafts',
        receipt => isEs ? 'Recibos' : 'Receipts',
        presupuesto => 'Presupuestos',
      };
}

class _TelegramClientDocumentEntry {
  const _TelegramClientDocumentEntry({
    required this.key,
    required this.documentId,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.icon,
    required this.type,
    required this.fileName,
    required this.loadBytes,
  });

  final String key;
  final String documentId;
  final String title;
  final String subtitle;
  final String statusLabel;
  final IconData icon;
  final _TelegramClientDocumentType type;
  final String fileName;
  final Future<Uint8List> Function() loadBytes;
}

class _TelegramClientDocumentPickerDialogState
    extends State<TelegramClientDocumentPickerDialog> {
  final ClientsApi _clientsApi = ClientsApi();
  final InvoicesApi _invoicesApi = InvoicesApi();
  final ReceiptsApi _receiptsApi = ReceiptsApi();
  final PresupuestosApi _presupuestosApi = PresupuestosApi();
  final TextEditingController _documentSearchController =
      TextEditingController();

  final Map<String, List<Invoice>> _invoiceCache = <String, List<Invoice>>{};
  final Map<String, List<Receipt>> _receiptCache = <String, List<Receipt>>{};
  final Map<String, List<Map<String, dynamic>>> _presupuestoCache =
      <String, List<Map<String, dynamic>>>{};

  bool _isSpanish = false;

  List<GroupClient> _clients = const <GroupClient>[];
  bool _loadingClients = true;
  bool _loadingDocuments = false;
  bool _attachingDocument = false;
  String? _previewingDocumentKey;
  String? _clientsError;
  String? _documentsError;
  String? _selectedClientId;
  late _TelegramClientDocumentType _selectedType;
  // Keyed by entry key so ticks survive client, type and search changes.
  final Map<String, ({_TelegramClientDocumentEntry entry, String clientId})>
      _selectedEntries =
      <String, ({_TelegramClientDocumentEntry entry, String clientId})>{};

  @override
  void initState() {
    super.initState();
    _selectedType = _availableTypes.first;
    _documentSearchController.addListener(_handleDocumentSearchChanged);
    _loadClients();
  }

  List<_TelegramClientDocumentType> get _availableTypes {
    final available = _TelegramClientDocumentType.values
        .where((type) => widget.allowedDocumentKinds.contains(type.name))
        .toList(growable: false);
    return available.isEmpty
        ? const <_TelegramClientDocumentType>[
            _TelegramClientDocumentType.invoice,
          ]
        : available;
  }

  @override
  void dispose() {
    _documentSearchController
      ..removeListener(_handleDocumentSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleDocumentSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _selectDocumentType(_TelegramClientDocumentType type) {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
  }

  void _toggleEntry(_TelegramClientDocumentEntry entry) {
    final clientId = _selectedClientId;
    if (clientId == null || clientId.isEmpty) return;
    setState(() {
      if (_selectedEntries.remove(entry.key) == null) {
        _selectedEntries[entry.key] = (entry: entry, clientId: clientId);
      }
    });
  }

  Future<void> _loadClients() async {
    setState(() {
      _loadingClients = true;
      _clientsError = null;
    });

    try {
      final loaded = await _clientsApi.list(
        groupId: widget.groupId,
        active: null,
      );
      if (!mounted) return;

      final preferredClientId = widget.initialClientId?.trim();
      final initialClientId = preferredClientId != null &&
              preferredClientId.isNotEmpty &&
              loaded.any((client) => client.id == preferredClientId)
          ? preferredClientId
          : (loaded.isNotEmpty ? loaded.first.id : null);

      setState(() {
        _clients = loaded;
        _selectedClientId = initialClientId;
        _loadingClients = false;
      });

      if (initialClientId != null) {
        await _loadDocumentsForClient(initialClientId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _clientsError = e.toString();
        _loadingClients = false;
      });
    }
  }

  Future<void> _loadDocumentsForClient(
    String clientId, {
    bool force = false,
  }) async {
    if (!force &&
        _invoiceCache.containsKey(clientId) &&
        _receiptCache.containsKey(clientId) &&
        _presupuestoCache.containsKey(clientId)) {
      if (mounted) {
        setState(() => _documentsError = null);
      }
      return;
    }

    setState(() {
      _loadingDocuments = true;
      _documentsError = null;
    });

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _loadInvoicesForClient(clientId, force: force),
        _loadReceiptsForClient(clientId, force: force),
        _loadPresupuestosForClient(clientId, force: force),
      ]);
      if (!mounted) return;

      _invoiceCache[clientId] = List<Invoice>.from(results[0] as List<Invoice>);
      _receiptCache[clientId] = List<Receipt>.from(results[1] as List<Receipt>);
      _presupuestoCache[clientId] = List<Map<String, dynamic>>.from(
        results[2] as List<Map<String, dynamic>>,
      );

      setState(() => _loadingDocuments = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _documentsError = e.toString();
        _loadingDocuments = false;
      });
    }
  }

  Future<List<Invoice>> _loadInvoicesForClient(
    String clientId, {
    bool force = false,
  }) async {
    if (!force && _invoiceCache.containsKey(clientId)) {
      return _invoiceCache[clientId]!;
    }

    final responses = await Future.wait<List<Invoice>>(<Future<List<Invoice>>>[
      _invoicesApi.listByGroup(widget.groupId, status: 'issued'),
      _invoicesApi.listByGroup(widget.groupId, status: 'draft'),
    ]);
    final merged = <String, Invoice>{};
    for (final invoice in <Invoice>[...responses[0], ...responses[1]]) {
      if (invoice.clientId == clientId) {
        merged[invoice.id] = invoice;
      }
    }
    final list = merged.values.toList()
      ..sort((a, b) {
        final aDate = a.issueDate ?? a.registeredAt ?? DateTime(1970);
        final bDate = b.issueDate ?? b.registeredAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    return list;
  }

  Future<List<Receipt>> _loadReceiptsForClient(
    String clientId, {
    bool force = false,
  }) async {
    if (!force && _receiptCache.containsKey(clientId)) {
      return _receiptCache[clientId]!;
    }

    final responses = await Future.wait<List<Receipt>>(<Future<List<Receipt>>>[
      _receiptsApi.list(groupId: widget.groupId, status: 'issued'),
      _receiptsApi.list(groupId: widget.groupId, status: 'draft'),
    ]);
    final merged = <String, Receipt>{};
    for (final receipt in <Receipt>[...responses[0], ...responses[1]]) {
      if (receipt.clientId == clientId) {
        merged[receipt.id] = receipt;
      }
    }
    final list = merged.values.toList()
      ..sort((a, b) {
        final aDate = a.issueDate ?? a.registeredAt ?? DateTime(1970);
        final bDate = b.issueDate ?? b.registeredAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    return list;
  }

  Future<List<Map<String, dynamic>>> _loadPresupuestosForClient(
    String clientId, {
    bool force = false,
  }) async {
    if (!force && _presupuestoCache.containsKey(clientId)) {
      return _presupuestoCache[clientId]!;
    }

    final list = await _presupuestosApi.listByGroup(
      groupId: widget.groupId,
      clientId: clientId,
      presupuestoKind: PresupuestoKind.structured,
    );
    final invoiceStyle = list
        .where((item) => !presupuestoHasDocumentContent(item))
        .toList(growable: false);
    invoiceStyle.sort((a, b) {
      final aDate =
          _parseDate(a['createdAt'] ?? a['updatedAt']) ?? DateTime(1970);
      final bDate =
          _parseDate(b['createdAt'] ?? b['updatedAt']) ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return invoiceStyle;
  }

  List<_TelegramClientDocumentEntry> _visibleEntriesFor({
    required String? clientId,
    required _TelegramClientDocumentType type,
  }) {
    if (clientId == null || clientId.isEmpty) {
      return const <_TelegramClientDocumentEntry>[];
    }

    final rawEntries = switch (type) {
      _TelegramClientDocumentType.invoice =>
        (_invoiceCache[clientId] ?? const <Invoice>[])
            .where((invoice) => !_isDraftStatus(invoice.status))
            .map(_buildInvoiceEntry),
      _TelegramClientDocumentType.draft =>
        (_invoiceCache[clientId] ?? const <Invoice>[])
            .where((invoice) => _isDraftStatus(invoice.status))
            .map(_buildInvoiceEntry),
      _TelegramClientDocumentType.receipt =>
        (_receiptCache[clientId] ?? const <Receipt>[]).map(_buildReceiptEntry),
      _TelegramClientDocumentType.presupuesto =>
        (_presupuestoCache[clientId] ?? const <Map<String, dynamic>>[])
            .map(_buildPresupuestoEntry),
    };

    final query = _documentSearchController.text.trim().toLowerCase();
    final entries = rawEntries.where((entry) {
      if (query.isEmpty) return true;
      return <String>[
        entry.title,
        entry.subtitle,
        entry.statusLabel,
        entry.documentId,
      ].join(' ').toLowerCase().contains(query);
    }).toList(growable: false);
    return entries;
  }

  _TelegramClientDocumentEntry _buildInvoiceEntry(Invoice invoice) {
    final isDraft = _isDraftStatus(invoice.status);
    final title = invoice.invoiceNumber.trim().isEmpty
        ? _draftInvoiceTitle(invoice)
        : invoice.invoiceNumber.trim();
    final status = _normalizeStatus(
      invoice.status,
      draftLabel: _isSpanish ? 'Borrador' : 'Draft',
      okLabel: _isSpanish ? 'Emitida' : 'Issued',
    );
    final date = invoice.issueDate ?? invoice.registeredAt;
    final total = _invoiceTotal(invoice);
    final subtitleParts = <String>[
      status,
      if (date != null) _formatDate(date),
      'Total ${_formatAmount(total)}',
    ];

    return _TelegramClientDocumentEntry(
      key: 'invoice:${invoice.id}',
      documentId: invoice.id,
      title: title,
      subtitle: subtitleParts.join('  -  '),
      statusLabel: status,
      icon: isDraft ? Icons.edit_note_rounded : Icons.receipt_long_rounded,
      type: isDraft
          ? _TelegramClientDocumentType.draft
          : _TelegramClientDocumentType.invoice,
      fileName:
          'invoice-${_safeFileName(title.isEmpty ? invoice.id : title)}.pdf',
      loadBytes: () async {
        final response = await _invoicesApi.previewPdf(invoice.id);
        return response.bodyBytes;
      },
    );
  }

  _TelegramClientDocumentEntry _buildReceiptEntry(Receipt receipt) {
    final title = (receipt.receiptNumber ?? '').trim().isEmpty
        ? receipt.id
        : receipt.receiptNumber!.trim();
    final status = _normalizeStatus(
      receipt.status,
      draftLabel: _isSpanish ? 'Borrador' : 'Draft',
      okLabel: _isSpanish ? 'Emitido' : 'Issued',
    );
    final date = receipt.issueDate ?? receipt.registeredAt;
    final total = _receiptTotal(receipt);
    final subtitleParts = <String>[
      status,
      if (date != null) _formatDate(date),
      'Total ${_formatAmount(total)}',
    ];

    return _TelegramClientDocumentEntry(
      key: 'receipt:${receipt.id}',
      documentId: receipt.id,
      title: title,
      subtitle: subtitleParts.join('  -  '),
      statusLabel: status,
      icon: Icons.receipt_rounded,
      type: _TelegramClientDocumentType.receipt,
      fileName:
          'receipt-${_safeFileName(title.isEmpty ? receipt.id : title)}.pdf',
      loadBytes: () async {
        final response = await _receiptsApi.previewPdf(receipt.id);
        return response.bodyBytes;
      },
    );
  }

  _TelegramClientDocumentEntry _buildPresupuestoEntry(
    Map<String, dynamic> item,
  ) {
    final id = (item['_id'] ?? item['id'] ?? '').toString();
    final number = (item['presupuestoNumber'] ?? item['budgetNumber'] ?? '')
        .toString()
        .trim();
    final title = number.isEmpty ? id : number;
    final status = _normalizeStatus(
      item['status']?.toString(),
      draftLabel: _isSpanish ? 'Borrador' : 'Draft',
      okLabel: _isSpanish ? 'Aprobado' : 'Approved',
    );
    final date = _parseDate(item['createdAt'] ?? item['updatedAt']);
    final total = _presupuestoTotal(item);
    final subtitleParts = <String>[
      status,
      if (date != null) _formatDate(date),
      if (total != null) 'Total ${_formatAmount(total)}',
    ];

    return _TelegramClientDocumentEntry(
      key: 'presupuesto:$id',
      documentId: id,
      title: title,
      subtitle: subtitleParts.join('  -  '),
      statusLabel: status,
      icon: Icons.request_quote_rounded,
      type: _TelegramClientDocumentType.presupuesto,
      fileName: 'presupuesto-${_safeFileName(title.isEmpty ? id : title)}.pdf',
      loadBytes: () async {
        final response = await _presupuestosApi.previewPdf(id);
        return response.bodyBytes;
      },
    );
  }

  Future<void> _handleAttachSelected() async {
    if (_selectedEntries.isEmpty) return;
    final picked = _selectedEntries.values.toList(growable: false);

    setState(() {
      _attachingDocument = true;
      _documentsError = null;
    });

    try {
      final allBytes = await Future.wait(
        picked.map((item) => item.entry.loadBytes()),
      );
      if (!mounted) return;
      for (final (index, bytes) in allBytes.indexed) {
        if (bytes.isEmpty) {
          throw Exception(_isSpanish
              ? 'El PDF "${picked[index].entry.title}" está vacío.'
              : 'The PDF "${picked[index].entry.title}" is empty.');
        }
      }

      Navigator.of(context).pop(<TelegramClientDocumentSelection>[
        for (final (index, item) in picked.indexed)
          TelegramClientDocumentSelection(
            fileName: item.entry.fileName,
            bytes: allBytes[index],
            mimeType: 'application/pdf',
            clientId: item.clientId,
            documentId: item.entry.documentId,
            documentLabel: item.entry.title,
            documentKind: item.entry.type.name,
          ),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attachingDocument = false;
        _documentsError = e.toString();
      });
    }
  }

  Future<void> _handlePreviewEntry(_TelegramClientDocumentEntry entry) async {
    if (_previewingDocumentKey == entry.key) return;

    setState(() {
      _previewingDocumentKey = entry.key;
      _documentsError = null;
    });

    try {
      final bytes = await entry.loadBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        throw Exception(_isSpanish
            ? 'El PDF seleccionado está vacío.'
            : 'The selected PDF is empty.');
      }

      await pdf_launcher.launchPdfPreview(
        bytes,
        fileName: entry.fileName,
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? (_isSpanish
                    ? 'No se pudo previsualizar el PDF seleccionado.'
                    : 'Could not preview the selected PDF.')
                : message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (_previewingDocumentKey == entry.key) {
            _previewingDocumentKey = null;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final selectedClient = _selectedClient;
    final entries = _visibleEntriesFor(
      clientId: _selectedClientId,
      type: _selectedType,
    );
    final canAttach = !_attachingDocument &&
        !_loadingDocuments &&
        _selectedEntries.isNotEmpty;

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 860;
              if (isCompact) {
                return _buildCompactLayout(context, entries, selectedClient);
              }
              return _buildWideLayout(context, entries, selectedClient);
            },
          ),
        ),
        _buildFooter(context, canAttach),
      ],
    );
  }

  GroupClient? get _selectedClient {
    final selectedClientId = _selectedClientId;
    if (selectedClientId == null || selectedClientId.isEmpty) {
      return null;
    }
    for (final client in _clients) {
      if (client.id == selectedClientId) return client;
    }
    return null;
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_rounded, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isSpanish ? 'Adjuntar PDF de cliente' : 'Attach client PDF',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSpanish
                      ? 'Elige un cliente y adjunta una factura, borrador, recibo o presupuesto en PDF a Telegram.'
                      : 'Choose a client, then attach an invoice, draft, receipt, or budget PDF to Telegram.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.64),
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadingClients ? null : _loadClients,
            tooltip: _isSpanish ? 'Recargar clientes' : 'Reload clients',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: l.close,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool canAttach) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedEntries.isEmpty
                  ? (_isSpanish
                      ? 'Selecciona uno o varios PDFs para adjuntarlos al chat de Telegram.'
                      : 'Select one or more PDFs to attach into the current Telegram chat.')
                  : (_isSpanish
                      ? '${_selectedEntries.length} PDF(s) seleccionado(s). Se añadirán a los adjuntos del mensaje.'
                      : '${_selectedEntries.length} PDF(s) selected. They will be added to the message attachments.'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.58),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: _attachingDocument
                ? null
                : () => Navigator.of(context).maybePop(),
            child: Text(_isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: canAttach ? _handleAttachSelected : null,
            icon: _attachingDocument
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file_rounded, size: 16),
            label: Text(_attachingDocument
                ? (_isSpanish ? 'Adjuntando...' : 'Attaching...')
                : _selectedEntries.length > 1
                    ? (_isSpanish
                        ? 'Adjuntar ${_selectedEntries.length} PDFs'
                        : 'Attach ${_selectedEntries.length} PDFs')
                    : (_isSpanish ? 'Adjuntar PDF' : 'Attach PDF')),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    List<_TelegramClientDocumentEntry> entries,
    GroupClient? selectedClient,
  ) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: _buildClientPanel(context),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: _buildDocumentPanel(context, entries, selectedClient),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    List<_TelegramClientDocumentEntry> entries,
    GroupClient? selectedClient,
  ) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: _buildClientPanel(context),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildDocumentPanel(context, entries, selectedClient),
          ),
        ],
      ),
    );
  }

  Widget _buildClientPanel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canvasColor = Theme.of(context).canvasColor;

    return Container(
      decoration: BoxDecoration(
        color: canvasColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.26)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSpanish ? 'Clientes' : 'Clients',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSpanish
                ? 'Usa la lista de clientes para seleccionar el cliente de origen.'
                : 'Reuse the existing searchable client list to pick the source client first.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.58),
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loadingClients
                ? const Center(child: CircularProgressIndicator())
                : _clientsError != null
                    ? _InlineErrorCard(
                        title: _isSpanish
                            ? 'Error al cargar los clientes'
                            : 'Failed to load clients',
                        message: _clientsError!,
                        onRetry: _loadClients,
                      )
                    : _clients.isEmpty
                        ? _EmptyCard(
                            icon: Icons.people_outline_rounded,
                            title: _isSpanish
                                ? 'Sin clientes'
                                : 'No clients found',
                            message: _isSpanish
                                ? 'Este grupo no tiene clientes disponibles todavía.'
                                : 'This group has no clients available for document selection yet.',
                          )
                        : ClientSearchSelect(
                            clients: _clients,
                            selectedClientId: _selectedClientId,
                            useDefaultPropertyKind: false,
                            maxListHeight: 9999,
                            onClientChanged: (value) async {
                              final clientId = value?.trim();
                              if (clientId == null || clientId.isEmpty) return;
                              setState(() {
                                _selectedClientId = clientId;
                              });
                              await _loadDocumentsForClient(clientId);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPanel(
    BuildContext context,
    List<_TelegramClientDocumentEntry> entries,
    GroupClient? selectedClient,
  ) {
    final cs = Theme.of(context).colorScheme;
    final canvasColor = Theme.of(context).canvasColor;

    return Container(
      decoration: BoxDecoration(
        color: canvasColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.26)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedClient == null
                ? (_isSpanish ? 'Documentos del cliente' : 'Client documents')
                : (_isSpanish
                    ? 'Documentos de ${selectedClient.name}'
                    : 'Client documents for ${selectedClient.name}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            selectedClient == null
                ? (_isSpanish
                    ? 'Selecciona un cliente para ver sus PDFs.'
                    : 'Select a client to browse its PDFs.')
                : (_isSpanish
                    ? 'Elige el tipo de documento y selecciona un PDF.'
                    : 'Choose the document type, then select one PDF.'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.58),
                ),
          ),
          const SizedBox(height: 14),
          _DocumentTypeTabs(
            selectedType: _selectedType,
            availableTypes: _availableTypes,
            isSpanish: _isSpanish,
            enabled: selectedClient != null && !_loadingDocuments,
            counts: {
              for (final type in _availableTypes)
                type: _documentCountForClient(_selectedClientId, type),
            },
            onSelected: _selectDocumentType,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(_selectedType.icon, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isSpanish
                      ? '${_selectedType.label(_isSpanish)} disponibles'
                      : 'Available ${_selectedType.label(_isSpanish).toLowerCase()}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  '${entries.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _documentSearchController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          _isSpanish ? 'Buscar PDFs...' : 'Search PDFs...',
                    ),
                  ),
                ),
                if (_documentSearchController.text.trim().isNotEmpty)
                  IconButton(
                    onPressed: () => _documentSearchController.clear(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: _isSpanish ? 'Limpiar búsqueda' : 'Clear search',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_documentsError != null) ...[
            _InlineErrorCard(
              title: _isSpanish
                  ? 'No se pudieron cargar los documentos'
                  : 'Could not load the selected documents',
              message: _documentsError!,
              onRetry: _selectedClientId == null
                  ? null
                  : () =>
                      _loadDocumentsForClient(_selectedClientId!, force: true),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: _selectedClientId == null
                ? _EmptyCard(
                    icon: Icons.folder_open_rounded,
                    title: _isSpanish
                        ? 'Primero elige un cliente'
                        : 'Choose a client first',
                    message: _isSpanish
                        ? 'La lista de documentos aparecerá aquí al seleccionar un cliente.'
                        : 'The document list appears here once a client is selected.',
                  )
                : _loadingDocuments
                    ? const Center(child: CircularProgressIndicator())
                    : entries.isEmpty
                        ? _EmptyCard(
                            icon: _selectedType.icon,
                            title: _selectedType ==
                                    _TelegramClientDocumentType.draft
                                ? (_isSpanish
                                    ? 'Sin borradores'
                                    : 'No invoice drafts')
                                : (_isSpanish
                                    ? 'Sin PDFs de ${_selectedType.label(_isSpanish).toLowerCase()}'
                                    : 'No ${_selectedType.label(_isSpanish).toLowerCase()} PDFs'),
                            message: _selectedType ==
                                    _TelegramClientDocumentType.draft
                                ? (_isSpanish
                                    ? 'Este cliente no tiene facturas guardadas como borrador.'
                                    : 'This client has no invoices saved as drafts.')
                                : (_isSpanish
                                    ? 'Prueba con otro cliente o tipo de documento.'
                                    : 'Try another client or another document type.'),
                          )
                        : ListView.separated(
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              final selected =
                                  _selectedEntries.containsKey(entry.key);
                              return _DocumentTile(
                                entry: entry,
                                selected: selected,
                                previewing: _previewingDocumentKey == entry.key,
                                onTap: () => _toggleEntry(entry),
                                onPreview: () => _handlePreviewEntry(entry),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _normalizeStatus(
    String? raw, {
    required String draftLabel,
    required String okLabel,
  }) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return okLabel;
    if (value == 'draft' || value == 'borrador') return draftLabel;
    if (value == 'issued' ||
        value == 'emitida' ||
        value == 'active' ||
        value == 'approved' ||
        value == 'aprobado') {
      return okLabel;
    }
    return value
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  bool _isDraftStatus(String? status) {
    final value = (status ?? '').trim().toLowerCase();
    return value == 'draft' || value == 'borrador';
  }

  int _documentCountForClient(
    String? clientId,
    _TelegramClientDocumentType type,
  ) {
    if (clientId == null || clientId.isEmpty) return 0;
    return switch (type) {
      _TelegramClientDocumentType.invoice =>
        (_invoiceCache[clientId] ?? const <Invoice>[])
            .where((invoice) => !_isDraftStatus(invoice.status))
            .length,
      _TelegramClientDocumentType.draft =>
        (_invoiceCache[clientId] ?? const <Invoice>[])
            .where((invoice) => _isDraftStatus(invoice.status))
            .length,
      _TelegramClientDocumentType.receipt =>
        (_receiptCache[clientId] ?? const <Receipt>[]).length,
      _TelegramClientDocumentType.presupuesto =>
        (_presupuestoCache[clientId] ?? const <Map<String, dynamic>>[]).length,
    };
  }

  String _draftInvoiceTitle(Invoice invoice) {
    for (final line in invoice.lines) {
      for (final value in <String?>[
        line.conceptTitle,
        line.description,
      ]) {
        final label = value?.trim() ?? '';
        if (label.isNotEmpty) return label;
      }
    }
    for (final block in invoice.blocks) {
      for (final value in <String?>[
        block.conceptTitle,
        block.description,
        block.title,
      ]) {
        final label = value?.trim() ?? '';
        if (label.isNotEmpty) return label;
      }
    }
    return _isSpanish ? 'Borrador de factura' : 'Invoice draft';
  }

  String _formatDate(DateTime value) {
    return DateFormat('dd MMM yyyy').format(value.toLocal());
  }

  String _formatAmount(num? value) {
    if (value == null) return '';
    return NumberFormat.currency(
      locale: 'es_ES',
      symbol: 'EUR ',
      decimalDigits: 2,
    ).format(value);
  }

  num _invoiceTotal(Invoice invoice) {
    if (invoice.total != null) return invoice.total!;
    if (invoice.lines.isNotEmpty) {
      return invoice.lines.fold<num>(0, (sum, line) {
        if (line.lineTotal != null) return sum + line.lineTotal!;
        final base =
            line.quantity * line.unitPrice * (1 - (line.discountRate / 100));
        return sum + base * (1 + (line.taxRate / 100));
      });
    }
    if (invoice.blocks.isNotEmpty) {
      return invoice.blocks.fold<num>(0, (sum, block) {
        if (block.isBillable == false) return sum;
        if (block.lineTotal != null) return sum + block.lineTotal!;
        final quantity = block.qty ?? 0;
        final unitPrice = block.unitPrice ?? 0;
        final discount = block.discountRate ?? 0;
        final tax = block.taxRate ?? 0;
        final base = quantity * unitPrice * (1 - (discount / 100));
        return sum + base * (1 + (tax / 100));
      });
    }
    return (invoice.subtotal ?? 0) + (invoice.taxTotal ?? 0);
  }

  num _receiptTotal(Receipt receipt) {
    if (receipt.total != null) return receipt.total!;
    if (receipt.lines.isNotEmpty) {
      return receipt.lines.fold<num>(
        0,
        (sum, line) => sum + (line.total ?? line.quantity * line.unitPrice),
      );
    }
    return receipt.subtotal ?? 0;
  }

  num? _presupuestoTotal(Map<String, dynamic> item) {
    if (PresupuestoKind.fromJson(item) == PresupuestoKind.document) {
      return presupuestoDocumentAmount(item);
    }
    final totals = item['totals'];
    for (final value in <dynamic>[
      item['grandTotal'],
      item['total'],
      item['totalAmount'],
      item['amountTotal'],
      item['amount'],
      if (totals is Map) totals['total'],
      if (totals is Map) totals['grandTotal'],
      if (totals is Map) totals['amount'],
    ]) {
      final parsed = _parseNum(value);
      if (parsed != null) return parsed;
    }

    for (final group in <dynamic>[item['lines'], item['blocks']]) {
      if (group is! List || group.isEmpty) continue;
      num total = 0;
      var hasAmount = false;
      for (final raw in group.whereType<Map>()) {
        if (raw['isBillable'] == false) continue;
        final lineTotal = _parseNum(raw['lineTotal'] ?? raw['total']);
        if (lineTotal != null) {
          total += lineTotal;
          hasAmount = true;
          continue;
        }
        final quantity = _parseNum(raw['quantity'] ?? raw['qty']) ?? 1;
        final unitPrice = _parseNum(
              raw['unitPrice'] ?? raw['price'] ?? raw['unit_price'],
            ) ??
            0;
        if (unitPrice == 0) continue;
        final discount =
            _parseNum(raw['discountRate'] ?? raw['discountPercent']) ?? 0;
        final tax = _parseNum(
              raw['taxRate'] ?? raw['tax'] ?? raw['vat'] ?? raw['iva'],
            ) ??
            0;
        final base = quantity * unitPrice * (1 - discount.clamp(0, 100) / 100);
        total += base * (1 + tax / 100);
        hasAmount = true;
      }
      if (hasAmount) return total;
    }
    return null;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        raw.abs() < 1000000000000 ? raw * 1000 : raw,
      );
    }
    final value = raw.toString().trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  num? _parseNum(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw;
    final text = raw.toString().trim().replaceAll(RegExp(r'\s'), '');
    if (text.isEmpty) return null;
    if (text.contains(',') && text.contains('.')) {
      final commaIsDecimal = text.lastIndexOf(',') > text.lastIndexOf('.');
      return num.tryParse(
        commaIsDecimal
            ? text.replaceAll('.', '').replaceAll(',', '.')
            : text.replaceAll(',', ''),
      );
    }
    return num.tryParse(text.replaceAll(',', '.'));
  }

  String _safeFileName(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
    return cleaned.isEmpty ? 'document' : cleaned;
  }
}

class _DocumentTypeTabs extends StatelessWidget {
  const _DocumentTypeTabs({
    required this.selectedType,
    required this.availableTypes,
    required this.isSpanish,
    required this.enabled,
    required this.counts,
    required this.onSelected,
  });

  final _TelegramClientDocumentType selectedType;
  final List<_TelegramClientDocumentType> availableTypes;
  final bool isSpanish;
  final bool enabled;
  final Map<_TelegramClientDocumentType, int> counts;
  final ValueChanged<_TelegramClientDocumentType> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.26),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final tabs = [
            for (final type in availableTypes)
              _DocumentTypeTabButton(
                type: type,
                label: type.label(isSpanish),
                count: counts[type] ?? 0,
                selected: selectedType == type,
                enabled: enabled,
                onTap: () => onSelected(type),
              ),
          ];

          if (compact) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tab in tabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: SizedBox(width: 150, child: tab),
                    ),
                ],
              ),
            );
          }

          return Row(
            children: [
              for (final tab in tabs)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: tab,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentTypeTabButton extends StatelessWidget {
  const _DocumentTypeTabButton({
    required this.type,
    required this.label,
    required this.count,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final _TelegramClientDocumentType type;
  final String label;
  final int count;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected
        ? cs.onPrimary
        : enabled
            ? cs.onSurface
            : cs.onSurface.withValues(alpha: 0.42);
    final countFg = selected
        ? cs.primary
        : enabled
            ? cs.onSurfaceVariant
            : cs.onSurfaceVariant.withValues(alpha: 0.48);

    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 450),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.18),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(type.icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.onPrimary.withValues(alpha: 0.92)
                      : cs.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : cs.outlineVariant.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: countFg,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.entry,
    required this.selected,
    required this.previewing,
    required this.onTap,
    required this.onPreview,
  });

  final _TelegramClientDocumentEntry entry;
  final bool selected;
  final bool previewing;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.16)
                : cs.surfaceContainerHighest.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.24),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  selected ? Icons.check_circle_rounded : entry.icon,
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.62),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 34,
                height: 34,
                child: IconButton.outlined(
                  onPressed: previewing ? null : onPreview,
                  tooltip: Localizations.localeOf(context).languageCode == 'es'
                      ? 'Vista previa PDF'
                      : 'Preview PDF',
                  icon: previewing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                      : const Icon(Icons.visibility_outlined, size: 18),
                  style: IconButton.styleFrom(
                    foregroundColor: cs.primary,
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.34),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.error.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onErrorContainer,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onErrorContainer,
                ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                Localizations.localeOf(context).languageCode == 'es'
                    ? 'Reintentar'
                    : 'Retry',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: cs.onSurface.withValues(alpha: 0.26)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.54),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
