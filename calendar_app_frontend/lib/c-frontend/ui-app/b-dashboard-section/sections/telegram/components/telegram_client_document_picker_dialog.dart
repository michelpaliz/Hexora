import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/b-backend/receipts/receipts_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/shared/widgets/client_search_select.dart';

class TelegramClientDocumentSelection {
  const TelegramClientDocumentSelection({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
    required this.clientId,
    required this.documentId,
    required this.documentLabel,
  });

  final String fileName;
  final Uint8List bytes;
  final String mimeType;
  final String clientId;
  final String documentId;
  final String documentLabel;
}

Future<TelegramClientDocumentSelection?>
showTelegramClientDocumentPickerDialog(
  BuildContext context, {
  required String groupId,
  String? initialClientId,
}) {
  return showDialog<TelegramClientDocumentSelection>(
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
  });

  final String groupId;
  final String? initialClientId;

  @override
  State<TelegramClientDocumentPickerDialog> createState() =>
      _TelegramClientDocumentPickerDialogState();
}

enum _TelegramClientDocumentType {
  invoice(Icons.receipt_long_rounded),
  receipt(Icons.receipt_rounded),
  presupuesto(Icons.request_quote_rounded);

  const _TelegramClientDocumentType(this.icon);

  final IconData icon;

  String label(bool isEs) => switch (this) {
        invoice => isEs ? 'Facturas' : 'Invoices',
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
  _TelegramClientDocumentType _selectedType =
      _TelegramClientDocumentType.invoice;
  String? _selectedDocumentKey;

  @override
  void initState() {
    super.initState();
    _documentSearchController.addListener(_handleDocumentSearchChanged);
    _loadClients();
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
    final visibleEntries = _visibleEntriesFor(
      clientId: _selectedClientId,
      type: _selectedType,
    );
    setState(() {
      if (!_containsDocumentKey(visibleEntries, _selectedDocumentKey)) {
        _selectedDocumentKey = visibleEntries.isNotEmpty
            ? visibleEntries.first.key
            : null;
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
      final initialClientId =
          preferredClientId != null &&
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
      final visibleEntries = _visibleEntriesFor(
        clientId: clientId,
        type: _selectedType,
      );
      if (mounted) {
        setState(() {
          _documentsError = null;
          if (!_containsDocumentKey(visibleEntries, _selectedDocumentKey)) {
            _selectedDocumentKey = visibleEntries.isNotEmpty
                ? visibleEntries.first.key
                : null;
          }
        });
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

      final visibleEntries = _visibleEntriesFor(
        clientId: clientId,
        type: _selectedType,
      );
      setState(() {
        _loadingDocuments = false;
        if (!_containsDocumentKey(visibleEntries, _selectedDocumentKey)) {
          _selectedDocumentKey = visibleEntries.isNotEmpty
              ? visibleEntries.first.key
              : null;
        }
      });
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
    );
    list.sort((a, b) {
      final aDate = _parseDate(a['createdAt'] ?? a['updatedAt']) ?? DateTime(1970);
      final bDate = _parseDate(b['createdAt'] ?? b['updatedAt']) ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return list;
  }

  List<_TelegramClientDocumentEntry> _visibleEntriesFor({
    required String? clientId,
    required _TelegramClientDocumentType type,
  }) {
    if (clientId == null || clientId.isEmpty) {
      return const <_TelegramClientDocumentEntry>[];
    }

    final rawEntries = switch (type) {
      _TelegramClientDocumentType.invoice => (_invoiceCache[clientId] ?? const <Invoice>[])
          .map(_buildInvoiceEntry),
      _TelegramClientDocumentType.receipt => (_receiptCache[clientId] ?? const <Receipt>[])
          .map(_buildReceiptEntry),
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

  bool _containsDocumentKey(
    List<_TelegramClientDocumentEntry> entries,
    String? key,
  ) {
    if (key == null || key.isEmpty) return false;
    return entries.any((entry) => entry.key == key);
  }

  _TelegramClientDocumentEntry _buildInvoiceEntry(Invoice invoice) {
    final title = invoice.invoiceNumber.trim().isEmpty
        ? invoice.id
        : invoice.invoiceNumber.trim();
    final status = _normalizeStatus(
      invoice.status,
      draftLabel: _isSpanish ? 'Borrador' : 'Draft',
      okLabel: _isSpanish ? 'Emitida' : 'Issued',
    );
    final date = invoice.issueDate ?? invoice.registeredAt;
    final subtitleParts = <String>[
      status,
      if (date != null) _formatDate(date),
      if (invoice.total != null) _formatAmount(invoice.total),
    ];

    return _TelegramClientDocumentEntry(
      key: 'invoice:${invoice.id}',
      documentId: invoice.id,
      title: title,
      subtitle: subtitleParts.join('  -  '),
      statusLabel: status,
      icon: Icons.receipt_long_rounded,
      type: _TelegramClientDocumentType.invoice,
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
    final subtitleParts = <String>[
      status,
      if (date != null) _formatDate(date),
      if (receipt.total != null) _formatAmount(receipt.total),
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
    final total = _parseNum(
      item['grandTotal'] ??
          item['total'] ??
          (item['totals'] is Map ? item['totals']['total'] : null),
    );
    final subtitleParts = <String>[
      status,
      if (date != null) _formatDate(date),
      if (total != null) _formatAmount(total),
    ];

    return _TelegramClientDocumentEntry(
      key: 'presupuesto:$id',
      documentId: id,
      title: title,
      subtitle: subtitleParts.join('  -  '),
      statusLabel: status,
      icon: Icons.request_quote_rounded,
      type: _TelegramClientDocumentType.presupuesto,
      fileName:
          'presupuesto-${_safeFileName(title.isEmpty ? id : title)}.pdf',
      loadBytes: () async {
        final response = await _presupuestosApi.previewPdf(id);
        return response.bodyBytes;
      },
    );
  }

  Future<void> _handleAttachSelected() async {
    final clientId = _selectedClientId;
    if (clientId == null || clientId.isEmpty) return;

    final entries = _visibleEntriesFor(
      clientId: clientId,
      type: _selectedType,
    );
    _TelegramClientDocumentEntry? selected;
    for (final entry in entries) {
      if (entry.key == _selectedDocumentKey) {
        selected = entry;
        break;
      }
    }
    if (selected == null) return;

    setState(() {
      _attachingDocument = true;
      _documentsError = null;
    });

    try {
      final bytes = await selected.loadBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        throw Exception(_isSpanish
            ? 'El PDF seleccionado está vacío.'
            : 'The selected PDF is empty.');
      }

      Navigator.of(context).pop(
        TelegramClientDocumentSelection(
          fileName: selected.fileName,
          bytes: bytes,
          mimeType: 'application/pdf',
          clientId: clientId,
          documentId: selected.documentId,
          documentLabel: selected.title,
        ),
      );
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
    final canAttach =
        !_attachingDocument && !_loadingDocuments && _selectedDocumentKey != null;

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
                      ? 'Elige un cliente y adjunta una factura, recibo o presupuesto en PDF a Telegram.'
                      : 'Choose a client, then attach an invoice, receipt, or presupuesto PDF to Telegram.',
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
              _selectedDocumentKey == null
                  ? (_isSpanish
                      ? 'Selecciona un PDF para adjuntarlo al chat de Telegram.'
                      : 'Select one PDF to attach into the current Telegram chat.')
                  : (_isSpanish
                      ? 'El PDF seleccionado reemplazará el adjunto actual en el compositor.'
                      : 'The selected PDF will replace any current attachment in the composer.'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.58),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed:
                _attachingDocument ? null : () => Navigator.of(context).maybePop(),
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
                                _selectedDocumentKey = null;
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedClient == null
                          ? (_isSpanish
                              ? 'Documentos del cliente'
                              : 'Client documents')
                          : (_isSpanish
                              ? 'Documentos de ${selectedClient.name}'
                              : 'Client documents for ${selectedClient.name}'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedClient == null
                          ? (_isSpanish
                              ? 'Selecciona un cliente para ver sus PDFs.'
                              : 'Select a client to browse its PDFs.')
                          : (_isSpanish
                              ? 'Elige un PDF para adjuntarlo al chat de Telegram.'
                              : 'Pick one PDF to attach to the current Telegram chat.'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.58),
                          ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _TelegramClientDocumentType.values.map((type) {
                  final selected = _selectedType == type;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(type.label(_isSpanish)),
                    avatar: Icon(type.icon, size: 16),
                    onSelected: (value) {
                      if (!value) return;
                      final nextEntries = _visibleEntriesFor(
                        clientId: _selectedClientId,
                        type: type,
                      );
                      setState(() {
                        _selectedType = type;
                        _selectedDocumentKey = nextEntries.isNotEmpty
                            ? nextEntries.first.key
                            : null;
                      });
                    },
                  );
                }).toList(growable: false),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
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
                      hintText: _isSpanish ? 'Buscar PDFs...' : 'Search PDFs...',
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
                  : () => _loadDocumentsForClient(_selectedClientId!, force: true),
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
                            title: _isSpanish
                                ? 'Sin PDFs de ${_selectedType.label(_isSpanish).toLowerCase()}'
                                : 'No ${_selectedType.label(_isSpanish).toLowerCase()} PDFs',
                            message: _isSpanish
                                ? 'Prueba con otro cliente o tipo de documento.'
                                : 'Try another client or another document type.',
                          )
                        : ListView.separated(
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              final selected =
                                  entry.key == _selectedDocumentKey;
                              return _DocumentTile(
                                entry: entry,
                                selected: selected,
                                previewing:
                                    _previewingDocumentKey == entry.key,
                                onTap: () {
                                  setState(() {
                                    _selectedDocumentKey = entry.key;
                                  });
                                },
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
    return num.tryParse(raw.toString().trim().replaceAll(',', '.'));
  }

  String _safeFileName(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
    return cleaned.isEmpty ? 'document' : cleaned;
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
                child: Icon(entry.icon, color: cs.primary, size: 20),
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
