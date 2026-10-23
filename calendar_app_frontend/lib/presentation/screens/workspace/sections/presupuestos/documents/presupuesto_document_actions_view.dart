import 'dart:typed_data';

import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:hexora/theme/components/themed_buttons.dart';
import 'package:hexora/presentation/shared/widgets/documents/hexora_status_badge.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_workspace_chrome.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/documents/presupuesto_document_workspace.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/widgets/presupuesto_pdf_preview_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/templates/presupuesto_template_editor_screen.dart';
import 'package:hexora/presentation/shared/widgets/feedback/snack_helper.dart';
import 'package:intl/intl.dart';

enum PresupuestoDocumentActionMode { all, drafts, issued, edit, preview }

class PresupuestoDocumentActionsView extends StatefulWidget {
  const PresupuestoDocumentActionsView({
    super.key,
    required this.groupId,
    required this.clients,
    this.initialSelectedBudgetId,
    this.mode = PresupuestoDocumentActionMode.drafts,
    this.api,
    this.onCreate,
  });

  final String groupId;
  final List<GroupClient> clients;
  final String? initialSelectedBudgetId;
  final PresupuestoDocumentActionMode mode;
  final PresupuestosApi? api;
  final VoidCallback? onCreate;

  @override
  State<PresupuestoDocumentActionsView> createState() =>
      _PresupuestoDocumentActionsViewState();
}

class _PresupuestoDocumentActionsViewState
    extends State<PresupuestoDocumentActionsView> {
  late final PresupuestosApi _api;
  late final PresupuestoDocumentWorkspace _workspace;
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  bool _mutationBusy = false;
  String? _fileBusyId;
  String? _checkingVariablesId;
  String? _error;
  String _statusFilter = 'all';
  bool _newestFirst = true;
  int _page = 0;
  static const _pageSize = 10;
  final Set<String> _selected = {};
  static const _availableFinancialColumns = {
    HexoraFinancialColumn.date,
    HexoraFinancialColumn.total,
  };
  Set<HexoraFinancialColumn> _visibleFinancialColumns =
      Set.of(_availableFinancialColumns);
  Map<String, dynamic>? _editingDocument;
  Map<String, dynamic>? _detailDocument;
  Uint8List? _detailPdfBytes;
  String? _detailPdfError;
  bool _detailPdfLoading = false;
  int _detailTabIndex = 0;
  final ValueNotifier<DocumentViewMode?> _splitModeNotifier =
      ValueNotifier<DocumentViewMode?>(null);

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? PresupuestosApi();
    _workspace = PresupuestoDocumentWorkspace(api: _api);
    _search.addListener(_onSearchChanged);
    HexoraColumnVisibilityStore.load(
      'presupuestos',
      _availableFinancialColumns,
    ).then((value) {
      if (mounted) setState(() => _visibleFinancialColumns = value);
    });
    _load();
  }

  @override
  void dispose() {
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    _splitModeNotifier.dispose();
    super.dispose();
  }

  Future<void> _selectDetail(Map<String, dynamic> document) async {
    final id = presupuestoDocumentId(document);
    if (id.isEmpty) return;
    _splitModeNotifier.value = null;
    setState(() {
      _detailDocument = document;
      _detailPdfBytes = null;
      _detailPdfError = null;
      _detailPdfLoading = true;
      _detailTabIndex = 0;
    });
    try {
      final response = await _api.previewTemplatePdf(id);
      final bytes = InvoiceEditorPdf.validatePdf(response);
      if (!mounted ||
          presupuestoDocumentId(_detailDocument ?? const {}) != id) {
        return;
      }
      setState(() => _detailPdfBytes = bytes);
    } on PresupuestosApiException catch (error) {
      if (mounted && presupuestoDocumentId(_detailDocument ?? const {}) == id) {
        setState(() => _detailPdfError = _friendlyPdfError(error));
      }
    } catch (error) {
      if (mounted && presupuestoDocumentId(_detailDocument ?? const {}) == id) {
        setState(() => _detailPdfError =
            error.toString().replaceFirst('Exception: ', '').trim());
      }
    } finally {
      if (mounted && presupuestoDocumentId(_detailDocument ?? const {}) == id) {
        setState(() => _detailPdfLoading = false);
      }
    }
  }

  void _closeDetail() {
    _splitModeNotifier.value = DocumentViewMode.list;
    setState(() {
      _detailDocument = null;
      _detailPdfBytes = null;
      _detailPdfError = null;
    });
  }

  void _onSearchChanged() => setState(() {
        _page = 0;
      });

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      await _workspace.refresh(widget.groupId);
    } on PresupuestosApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _visibleDocuments {
    final source = switch (widget.mode) {
      PresupuestoDocumentActionMode.all => _workspace.documents,
      PresupuestoDocumentActionMode.drafts ||
      PresupuestoDocumentActionMode.edit =>
        _workspace.drafts,
      PresupuestoDocumentActionMode.issued => _workspace.issued,
      PresupuestoDocumentActionMode.preview => _workspace.documents,
    };
    final documents = source.where((document) =>
        _statusFilter == 'all' ||
        presupuestoDocumentStatus(document) == _statusFilter);
    final query = _search.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? documents.toList(growable: false)
        : documents.where((document) {
            final searchable = <String>[
              presupuestoDocumentTitle(document),
              presupuestoDocumentClientName(document),
              _documentNumber(document),
            ].join(' ').toLowerCase();
            return searchable.contains(query);
          }).toList(growable: false);
    filtered.sort((a, b) {
      final aDate = _documentDate(
            a,
            issued: presupuestoDocumentStatus(a) == 'issued',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _documentDate(
            b,
            issued: presupuestoDocumentStatus(b) == 'issued',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return _newestFirst ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
    });
    return filtered;
  }

  Future<void> _openEditor(Map<String, dynamic> document) async {
    final id = presupuestoDocumentId(document);
    if (id.isEmpty) return;
    setState(() => _editingDocument = document);
  }

  Future<void> _closeEditor() async {
    setState(() => _editingDocument = null);
    await _load();
  }

  Future<void> _openPdf(
    Map<String, dynamic> document, {
    required bool preview,
  }) async {
    final id = presupuestoDocumentId(document);
    if (id.isEmpty || _fileBusyId != null) return;
    setState(() => _fileBusyId = id);
    try {
      final number = _documentNumber(document).replaceAll('/', '-');
      final fileName = 'presupuesto-$number-documento.pdf';
      final variables = await _api.getTemplateVariables(id);
      if (!mounted ||
          !await _confirmUnresolvedVariables(
            _unresolvedKeys(variables),
            action: preview ? 'previsualizar' : 'descargar',
          )) {
        return;
      }
      if (preview) {
        final response = await _api.previewTemplatePdf(id);
        final bytes = InvoiceEditorPdf.validatePdf(response);
        if (!mounted) return;
        await PresupuestoPdfPreviewDialog.show(
          context,
          bytes: bytes,
          onDownload: () => launchFileDownload(
            bytes,
            fileName: fileName,
            mimeType: 'application/pdf',
          ),
        );
      } else {
        final response = await _api.downloadTemplatePdf(id);
        await launchFileDownload(
          response.bodyBytes,
          fileName: fileName,
          mimeType: 'application/pdf',
        );
      }
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, _friendlyPdfError(e));
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _fileBusyId = null);
    }
  }

  String _friendlyPdfError(PresupuestosApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'Tu sesion ha caducado. Vuelve a iniciar sesion e intentalo de nuevo.';
      case 403:
        return 'No tienes permiso para previsualizar este presupuesto.';
      case 404:
        return 'No se encontro el presupuesto solicitado.';
      case 500:
        return 'No se pudo generar el PDF en el servidor. Intentalo de nuevo en unos minutos.';
      default:
        return e.message;
    }
  }

  List<String> _unresolvedKeys(Map<String, dynamic> payload) {
    final raw = payload['unresolvedKeys'];
    if (raw is! List) return const [];
    return raw
        .map((item) => item.toString().trim())
        .where((key) => key.isNotEmpty)
        .toList(growable: false);
  }

  Future<bool> _confirmUnresolvedVariables(
    List<String> unresolved, {
    required String action,
  }) async {
    if (unresolved.isEmpty) return true;
    final keys = unresolved.map((key) => '[$key]').join(', ');
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Variables sin completar'),
            content: Text(
              'Todavía quedan variables sin valor: $keys. Si continúas, aparecerán entre corchetes en el PDF.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text('Continuar y $action'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _issue(Map<String, dynamic> document) async {
    final validation = presupuestoDocumentIssueValidation(document);
    if (validation != null) {
      showErrorSnack(context, validation);
      return;
    }
    final id = presupuestoDocumentId(document);
    if (_workspace.isIssuing(id) || _checkingVariablesId == id) return;
    setState(() => _checkingVariablesId = id);
    List<String> unresolved;
    try {
      unresolved = _unresolvedKeys(await _api.getTemplateVariables(id));
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
      return;
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
      return;
    } finally {
      if (mounted) setState(() => _checkingVariablesId = null);
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Emitir presupuesto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Emitir este presupuesto? Se asignará un número definitivo.',
            ),
            if (unresolved.isNotEmpty) ...[
              const SizedBox(height: HexoraTableTokens.gap),
              Text(
                'Atención: siguen sin valor ${unresolved.map((key) => '[$key]').join(', ')}. Aparecerán entre corchetes en el PDF.',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.publish_rounded),
            label: const Text('Emitir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {});
    try {
      final issued = await _workspace.issue(document);
      await _load();
      final id = presupuestoDocumentId(issued);
      final refreshed = _workspace.documents
          .where((item) => presupuestoDocumentId(item) == id)
          .firstOrNull;
      final number = _documentNumber(refreshed ?? issued);
      if (mounted) {
        showSuccessSnack(
          context,
          'Presupuesto $number emitido correctamente.',
        );
      }
    } on PresupuestoDocumentValidationException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } on PresupuestoDocumentIssueInProgressException catch (_) {
      // The active request owns the UI state and result.
    } on PresupuestosApiException catch (e) {
      if (isAlreadyIssuedDocumentError(e)) await _load();
      if (mounted) {
        showErrorSnack(context, presupuestoDocumentIssueErrorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() {});
    }
  }

  List<Map<String, dynamic>> get _selectedDrafts => _workspace.drafts
      .where((d) => _selected.contains(presupuestoDocumentId(d)))
      .toList();

  Future<void> _removeSelected() async {
    final drafts = _selectedDrafts;
    if (_mutationBusy || drafts.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Eliminar ${drafts.length} borradores'),
        content: const Text('Se eliminarán los borradores seleccionados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _mutationBusy = true);
    try {
      for (final draft in drafts) {
        await _workspace.remove(draft);
        _selected.remove(presupuestoDocumentId(draft));
      }
      await _load();
    } finally {
      if (mounted) setState(() => _mutationBusy = false);
    }
  }

  Future<void> _duplicate(Map<String, dynamic> document) async {
    if (_mutationBusy) return;
    setState(() => _mutationBusy = true);
    try {
      final response =
          await _api.getTemplateContent(presupuestoDocumentId(document));
      final raw = response['content'];
      if (raw is! Map || raw.isEmpty) {
        throw Exception('No se encontró el contenido de la propuesta.');
      }
      final content = <String, dynamic>{
        for (final key in const [
          'templateId',
          'header',
          'watermark',
          'title',
          'subtitle',
          'intro',
          'variables',
          'variableFields',
          'sections',
          'images',
          'totals',
          'seasonConfiguration'
        ])
          if (raw.containsKey(key)) key: raw[key],
        'name': '${raw['name'] ?? presupuestoDocumentTitle(document)} (copia)',
        if ((document['clientId'] ?? response['clientId'] ?? raw['clientId']) !=
            null)
          'clientId':
              document['clientId'] ?? response['clientId'] ?? raw['clientId'],
      };
      await _api.createDocumentDraft(groupId: widget.groupId, content: content);
      if (!mounted) return;
      await _load();
      if (mounted) {
        showSuccessSnack(context, 'Propuesta duplicada como borrador.');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _mutationBusy = false);
    }
  }

  Future<void> _remove(Map<String, dynamic> document) async {
    if (_mutationBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar borrador'),
        content: Text(
          '¿Eliminar la propuesta "${presupuestoDocumentTitle(document)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _mutationBusy = true);
    try {
      await _workspace.remove(document);
      if (mounted) {
        showSuccessSnack(context, 'Borrador eliminado.');
      }
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _mutationBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = _editingDocument;
    if (editing != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _closeEditor();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('back_to_proposals'),
                onPressed: _closeEditor,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver a propuestas'),
              ),
            ),
            Expanded(
              child: PresupuestoTemplateEditorScreen(
                key: ValueKey(
                    'inline-proposal-${presupuestoDocumentId(editing)}'),
                api: _api,
                groupId: widget.groupId,
                presupuestoId: presupuestoDocumentId(editing),
                presupuestoNumber: _documentNumber(editing),
                initialBudget: editing,
                onDocumentSaved: _load,
              ),
            ),
          ],
        ),
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _DocumentErrorState(message: _error!, onRetry: _load);
    }
    final documents = _visibleDocuments;

    final cs = Theme.of(context).colorScheme;
    final list = ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.38),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: _filterToolbar(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _documentTable(documents),
              ),
            ],
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(6),
      child: DocumentSplitView(
        storageKey: 'proposal-documents',
        selectionKey: _detailDocument == null
            ? null
            : presupuestoDocumentId(_detailDocument!),
        modeNotifier: _splitModeNotifier,
        list: list,
        preview: _buildDetailPanel(documents),
      ),
    );
  }

  Widget _buildDetailPanel(List<Map<String, dynamic>> documents) {
    final document = _detailDocument;
    final cs = Theme.of(context).colorScheme;
    if (document == null) {
      return Center(
        child: Text(
          'Selecciona una propuesta',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }
    final id = presupuestoDocumentId(document);
    final index = documents.indexWhere(
      (item) => presupuestoDocumentId(item) == id,
    );
    final status = presupuestoDocumentStatus(document);
    final issued = status == 'issued';
    final date = _documentDate(document, issued: issued);
    final dateLabel =
        date == null ? '' : DateFormat('d MMM y', 'es').format(date.toLocal());
    final amount = presupuestoDocumentAmount(document);
    final amountLabel = amount == null
        ? '—'
        : NumberFormat.currency(locale: 'es_ES', symbol: '€').format(amount);

    return ValueListenableBuilder<DocumentViewMode?>(
      valueListenable: _splitModeNotifier,
      builder: (context, mode, _) => ColoredBox(
        color: cs.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HexoraDocumentDetailHeader(
              title: _documentNumber(document).isEmpty
                  ? presupuestoDocumentTitle(document)
                  : _documentNumber(document),
              clientName: presupuestoDocumentClientName(document),
              statusLabel: issued ? 'Emitida' : 'Borrador',
              statusColor: issued ? Colors.green.shade700 : cs.secondary,
              statusIcon:
                  issued ? Icons.task_alt_outlined : Icons.edit_note_outlined,
              dateLabel: dateLabel,
              trailingLabel: amountLabel,
              onPrevious:
                  index > 0 ? () => _selectDetail(documents[index - 1]) : null,
              onNext: index >= 0 && index + 1 < documents.length
                  ? () => _selectDetail(documents[index + 1])
                  : null,
              onExpand: () {
                _splitModeNotifier.value = mode == DocumentViewMode.document
                    ? DocumentViewMode.split
                    : DocumentViewMode.document;
              },
              isExpanded: mode == DocumentViewMode.document,
              onClose: _closeDetail,
              moreActions: PopupMenuButton<String>(
                tooltip: 'Más acciones',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_horiz_rounded, size: 18),
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      _openEditor(document);
                    case 'download':
                      _openPdf(document, preview: false);
                    case 'issue':
                      _issue(document);
                    case 'delete':
                      _remove(document);
                  }
                },
                itemBuilder: (_) => [
                  if (!issued)
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(
                    value: 'download',
                    child: Text('Descargar PDF'),
                  ),
                  if (!issued)
                    const PopupMenuItem(value: 'issue', child: Text('Emitir')),
                  if (!issued)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar borrador'),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),
            SizedBox(
              height: 38,
              child: Row(
                children: [
                  for (final tab in [(0, 'Vista previa'), (1, 'Datos')])
                    TextButton(
                      onPressed: () => setState(() => _detailTabIndex = tab.$1),
                      style: TextButton.styleFrom(
                        foregroundColor: _detailTabIndex == tab.$1
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                      child: Text(tab.$2),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _detailTabIndex == 0
                  ? _buildDetailPreview(document)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _detailValue(
                            'Propuesta', presupuestoDocumentTitle(document)),
                        _detailValue('Referencia', _documentNumber(document)),
                        _detailValue(
                            'Cliente', presupuestoDocumentClientName(document)),
                        _detailValue('Fecha', dateLabel),
                        _detailValue('Estado', issued ? 'Emitida' : 'Borrador'),
                        _detailValue('Importe', amountLabel),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPreview(Map<String, dynamic> document) {
    final cs = Theme.of(context).colorScheme;
    if (_detailPdfLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    if ((_detailPdfError ?? '').isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _detailPdfError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.error),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _selectDetail(document),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final bytes = _detailPdfBytes;
    if (bytes == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: PdfInlinePreview(bytes: bytes, height: double.infinity),
    );
  }

  Widget _detailValue(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 3),
            Text(value.trim().isEmpty ? '—' : value),
          ],
        ),
      );

  Widget _documentTable(List<Map<String, dynamic>> documents) {
    final cs = Theme.of(context).colorScheme;
    final pageCount = (documents.length / _pageSize).ceil();
    final currentPage = pageCount == 0 ? 0 : _page.clamp(0, pageCount - 1);
    final start = currentPage * _pageSize;
    final visible = documents.skip(start).take(_pageSize).toList();
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        if (documents.isEmpty)
          _DocumentEmptyState(
              mode: widget.mode, searchQuery: _search.text.trim())
        else
          LayoutBuilder(builder: (context, constraints) {
            final table = constraints.maxWidth >= 760;
            return Column(children: [
              if (table)
                Container(
                  color: cs.primary.withValues(alpha: .035),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Row(children: [
                    SizedBox(
                      width: 36,
                      child: Checkbox(
                        value: visible.every((d) =>
                            _selected.contains(presupuestoDocumentId(d))),
                        onChanged: (value) => setState(() {
                          for (final d in visible) {
                            final id = presupuestoDocumentId(d);
                            if (value == true) {
                              _selected.add(id);
                            } else {
                              _selected.remove(id);
                            }
                          }
                        }),
                      ),
                    ),
                    Expanded(
                        flex: 5,
                        child: _tableHeaderLabel(context, 'Propuesta')),
                    Expanded(
                        flex: 3, child: _tableHeaderLabel(context, 'Cliente')),
                    if (_visibleFinancialColumns
                        .contains(HexoraFinancialColumn.date))
                      const HexoraFinancialHeaderCell(
                          label: 'Fecha', width: 104),
                    SizedBox(
                        width: 110,
                        child: _tableHeaderLabel(context, 'Estado')),
                    if (_visibleFinancialColumns
                        .contains(HexoraFinancialColumn.total))
                      const HexoraFinancialHeaderCell(
                          label: 'Total', width: 120, numeric: true),
                    SizedBox(
                        width: HexoraTableTokens.actionColumn,
                        child: _tableHeaderLabel(context, 'Acciones')),
                  ]),
                ),
              for (final document in visible)
                _DocumentRow(
                  document: document,
                  clients: widget.clients,
                  mode: widget.mode,
                  table: table,
                  selected: _selected.contains(presupuestoDocumentId(document)),
                  onSelect: (value) => setState(() {
                    final id = presupuestoDocumentId(document);
                    if (value == true) {
                      _selected.add(id);
                    } else {
                      _selected.remove(id);
                    }
                  }),
                  fileBusy: _fileBusyId == presupuestoDocumentId(document),
                  fileActionsDisabled: _fileBusyId != null,
                  issuing: _workspace
                          .isIssuing(presupuestoDocumentId(document)) ||
                      _checkingVariablesId == presupuestoDocumentId(document),
                  onOpen: presupuestoDocumentStatus(document) == 'draft'
                      ? () => _openEditor(document)
                      : () => _openPdf(document, preview: true),
                  onPreview: () => _selectDetail(document),
                  onDownload: () => _openPdf(document, preview: false),
                  onIssue: () => _issue(document),
                  onDelete: () => _remove(document),
                  onDuplicate: () => _duplicate(document),
                  mutationBusy: _mutationBusy,
                  visibleFinancialColumns: _visibleFinancialColumns,
                ),
            ]);
          }),
        if (pageCount > 1 || documents.length != _workspace.documents.length)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                Expanded(
                    child: Text(
                        'Mostrando ${documents.isEmpty ? 0 : start + 1}–${start + visible.length} de ${documents.length} propuestas',
                        style: Theme.of(context).textTheme.bodySmall)),
                IconButton(
                    tooltip: 'Página anterior',
                    onPressed: currentPage > 0
                        ? () => setState(() => _page = currentPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 18)),
                Text('${currentPage + 1} / $pageCount'),
                IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: currentPage + 1 < pageCount
                        ? () => setState(() => _page = currentPage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right, size: 18)),
              ])),
      ]),
    );
  }

  Widget _tableHeaderLabel(
    BuildContext context,
    String text, {
    TextAlign align = TextAlign.start,
  }) {
    return Text(
      text,
      textAlign: align,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _filterToolbar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final leftGroup = Wrap(
          spacing: HexoraTableTokens.gap,
          runSpacing: HexoraTableTokens.gap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_selected.isNotEmpty) _bulkDeleteButton(context),
            _statusFilters(context),
          ],
        );
        final rightGroup = wide
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: HexoraTableTokens.searchWidth,
                    child: _searchField(context),
                  ),
                  const SizedBox(width: HexoraTableTokens.gap),
                  _sortButton(context),
                  const SizedBox(width: HexoraTableTokens.gap),
                  HexoraColumnVisibilityMenu(
                    moduleKey: 'presupuestos',
                    availableColumns: _availableFinancialColumns,
                    visibleColumns: _visibleFinancialColumns,
                    onChanged: (value) =>
                        setState(() => _visibleFinancialColumns = value),
                  ),
                  const SizedBox(width: HexoraTableTokens.gap),
                  _refreshButton(context),
                  if (widget.onCreate != null) ...[
                    const SizedBox(width: HexoraTableTokens.gap),
                    _createButton(context),
                  ],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _searchField(context),
                  const SizedBox(height: HexoraTableTokens.gap),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _sortButton(context),
                        const SizedBox(width: HexoraTableTokens.gap),
                        HexoraColumnVisibilityMenu(
                          moduleKey: 'presupuestos',
                          availableColumns: _availableFinancialColumns,
                          visibleColumns: _visibleFinancialColumns,
                          onChanged: (value) =>
                              setState(() => _visibleFinancialColumns = value),
                        ),
                        const SizedBox(width: HexoraTableTokens.gap),
                        _refreshButton(context),
                        if (widget.onCreate != null) ...[
                          const SizedBox(width: HexoraTableTokens.gap),
                          _createButton(context),
                        ],
                      ],
                    ),
                  ),
                ],
              );
        if (wide) {
          return Row(
            children: [
              Expanded(child: leftGroup),
              const SizedBox(width: 12),
              rightGroup,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            leftGroup,
            const SizedBox(height: HexoraTableTokens.gap),
            rightGroup,
          ],
        );
      },
    );
  }

  Widget _statusFilters(BuildContext context) {
    const values = ['all', 'draft', 'issued'];
    return HexoraDocumentStatusTabs(
      selectedIndex: values.indexOf(_statusFilter).clamp(0, values.length - 1),
      onSelected: (index) => setState(() {
        _statusFilter = values[index];
        _page = 0;
      }),
      tabs: [
        HexoraDocumentStatusTab(
          label: 'Todas',
          count: _workspace.documents.length,
          icon: Icons.description_outlined,
        ),
        HexoraDocumentStatusTab(
          label: 'Borradores',
          count: _workspace.drafts.length,
          icon: Icons.edit_note_outlined,
        ),
        HexoraDocumentStatusTab(
          label: 'Emitidas',
          count: _workspace.issued.length,
          icon: Icons.task_alt_outlined,
        ),
      ],
    );
  }

  Widget _createButton(BuildContext context) => FilledButton.icon(
        onPressed: widget.onCreate,
        icon: const Icon(Icons.add_rounded, size: 17),
        label: const Text('Nueva propuesta'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, HexoraDimensions.button),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HexoraDimensions.radius),
          ),
        ),
      );

  Widget _searchField(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _search,
      style: theme.textTheme.bodySmall,
      decoration: InputDecoration(
        hintText: 'Buscar propuestas...',
        prefixIcon: const Icon(Icons.search_rounded, size: 19),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: _search.clear,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        isDense: true,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: HexoraTableTokens.cellPadding,
            vertical: HexoraTableTokens.rowPadding),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HexoraDimensions.radius),
          borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HexoraDimensions.radius),
          borderSide: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HexoraDimensions.radius),
          borderSide: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _sortButton(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<bool>(
      tooltip: 'Ordenar propuestas',
      initialValue: _newestFirst,
      onSelected: (value) => setState(() {
        _newestFirst = value;
        _page = 0;
      }),
      itemBuilder: (_) => const [
        NavigationPopupMenuItem(value: true, child: Text('Fecha más reciente')),
        NavigationPopupMenuItem(value: false, child: Text('Fecha más antigua')),
      ],
      child: Container(
        height: HexoraDimensions.button + 4,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(HexoraDimensions.radius),
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _newestFirst ? 'Más recientes' : 'Más antiguas',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const Icon(Icons.expand_more, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _refreshButton(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Actualizar propuestas',
      child: IconButton(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(HexoraDimensions.button + 4),
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HexoraDimensions.radius),
          ),
        ),
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
    );
  }

  Widget _bulkDeleteButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed:
          _mutationBusy || _selectedDrafts.isEmpty ? null : _removeSelected,
      icon: const Icon(Icons.delete_outline, size: 18),
      label: Text('Eliminar borradores (${_selectedDrafts.length})'),
    );
  }

  String _documentNumber(Map<String, dynamic> document) {
    final value =
        (document['presupuestoNumber'] ?? document['budgetNumber'] ?? '')
            .toString()
            .trim();
    return value.isEmpty ? presupuestoDocumentId(document) : value;
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.document,
    required this.clients,
    required this.mode,
    required this.fileBusy,
    required this.fileActionsDisabled,
    required this.issuing,
    required this.onOpen,
    required this.onPreview,
    required this.onDownload,
    required this.onIssue,
    required this.onDelete,
    required this.onDuplicate,
    required this.mutationBusy,
    this.table = false,
    this.selected = false,
    this.onSelect,
    this.visibleFinancialColumns = const {
      HexoraFinancialColumn.date,
      HexoraFinancialColumn.total,
    },
  });

  final Map<String, dynamic> document;
  final List<GroupClient> clients;
  final PresupuestoDocumentActionMode mode;
  final bool fileBusy;
  final bool fileActionsDisabled;
  final bool issuing;
  final VoidCallback onOpen;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback onIssue;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final bool mutationBusy;
  final bool table;
  final bool selected;
  final ValueChanged<bool?>? onSelect;
  final Set<HexoraFinancialColumn> visibleFinancialColumns;

  bool get _isIssued => presupuestoDocumentStatus(document) == 'issued';
  bool get _isDraft => presupuestoDocumentStatus(document) == 'draft';

  HexoraDocumentStatus get _statusKind {
    if (_isIssued) return HexoraDocumentStatus.issued;
    if (_isDraft) return HexoraDocumentStatus.draft;
    return HexoraDocumentStatus.cancelled;
  }

  String get _statusLabel => _isIssued
      ? 'Emitida'
      : _isDraft
          ? 'Borrador'
          : 'Anulada';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final date = _documentDate(document, issued: _isIssued);
    final amount = presupuestoDocumentAmount(document);
    final client = _clientName(document, clients);
    final title = presupuestoDocumentTitle(document);

    if (table) {
      String email = '';
      for (final entry in clients) {
        if (entry.id == document['clientId'] || entry.name == client) {
          email = entry.email ?? '';
          break;
        }
      }
      Widget line(String text, {bool muted = false}) => Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
              fontSize: HexoraTypography.body,
              color: muted ? cs.onSurfaceVariant : cs.onSurface));
      return Material(
        color: cs.surface,
        child: InkWell(
            onTap: onOpen,
            child: Container(
              constraints: const BoxConstraints(
                  minHeight: HexoraTableTokens.rowMinHeight),
              padding: const EdgeInsets.symmetric(
                  horizontal: HexoraTableTokens.cellPadding,
                  vertical: HexoraTableTokens.rowPadding),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: cs.outlineVariant.withValues(
                              alpha: HexoraTableTokens.separatorOpacity)))),
              child: Row(children: [
                SizedBox(
                  width: 36,
                  child: Checkbox(value: selected, onChanged: onSelect),
                ),
                Expanded(
                    flex: 5,
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            line(title),
                            const SizedBox(height: 5),
                            Wrap(spacing: 6, runSpacing: 4, children: [
                              if (_documentNumber(document).isNotEmpty)
                                _DocumentPill(
                                    label: _documentNumber(document),
                                    color: cs.primary),
                              if (_isDraft)
                                Text(
                                    '${presupuestoDocumentImageCount(document)} imágenes',
                                    style: theme.textTheme.bodySmall),
                            ]),
                          ])),
                      const SizedBox(width: 12),
                    ])),
                Expanded(
                    flex: 3,
                    child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Row(children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  cs.primaryContainer.withValues(alpha: 0.38),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _clientInitials(client),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Tooltip(
                                      message: client.isEmpty
                                          ? 'Sin cliente'
                                          : client,
                                      child: line(client.isEmpty
                                          ? 'Sin cliente'
                                          : client)),
                                  if (email.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    line(email, muted: true)
                                  ],
                                ]),
                          ),
                        ]))),
                if (visibleFinancialColumns
                    .contains(HexoraFinancialColumn.date))
                  HexoraDateCell(value: date, width: 104),
                SizedBox(
                    width: 110,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: HexoraStatusBadge.document(
                          context,
                          status: _statusKind,
                          label: _statusLabel,
                        ))),
                if (visibleFinancialColumns
                    .contains(HexoraFinancialColumn.total))
                  HexoraFinancialCell(value: amount, total: true, width: 120),
                SizedBox(
                    width: HexoraTableTokens.actionColumn,
                    child: _actions(context)),
              ]),
            )),
      );
    }
    return Material(
      color: cs.surface,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: cs.outlineVariant.withValues(
                          alpha: HexoraTableTokens.separatorOpacity)))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Checkbox(value: selected, onChanged: onSelect),
              Expanded(
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: HexoraTypography.body,
                          fontWeight: FontWeight.w600))),
            ]),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                  [
                    client.isEmpty ? 'Sin cliente' : client,
                    if (date != null) DateFormat('d MMM y', 'es').format(date),
                    if (_isDraft)
                      '${presupuestoDocumentImageCount(document)} imágenes',
                    if (_documentNumber(document).isNotEmpty)
                      _documentNumber(document),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              HexoraStatusBadge.document(
                context,
                status: _statusKind,
                label: _statusLabel,
              ),
              const SizedBox(width: HexoraTableTokens.gap),
              Expanded(
                  child: Text(
                      amount == null
                          ? ''
                          : NumberFormat.currency(locale: 'es_ES', symbol: '€')
                              .format(amount),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: HexoraTypography.numericFeatures))),
            ]),
            Align(alignment: Alignment.centerRight, child: _actions(context)),
          ]),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Descargar',
          onPressed: fileActionsDisabled ? null : onDownload,
          style: ThemedButtons.iconAction(context),
          icon: fileBusy
              ? const SizedBox.square(
                  dimension: HexoraTableTokens.icon,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.download_outlined,
                  size: HexoraTableTokens.icon),
        ),
        const SizedBox(width: HexoraTableTokens.gap),
        PopupMenuButton<String>(
          tooltip: 'Más acciones',
          offset: const Offset(0, 46),
          elevation: 8,
          color: cs.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          constraints: const BoxConstraints(minWidth: 220),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          onSelected: (value) {
            switch (value) {
              case 'open':
                onOpen();
              case 'preview':
                onPreview();
              case 'issue':
                onIssue();
              case 'delete':
                onDelete();
              case 'download':
                onDownload();
              case 'duplicate':
                onDuplicate();
            }
          },
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            NavigationPopupMenuItem<String>(
              value: 'duplicate',
              enabled: !mutationBusy,
              child: _actionMenuItem(context,
                  icon: Icons.copy_outlined, label: 'Duplicar como borrador'),
            ),
            NavigationPopupMenuItem<String>(
              value: 'download',
              enabled: !fileActionsDisabled,
              child: _actionMenuItem(context,
                  icon: Icons.download_outlined, label: 'Descargar'),
            ),
            if (_isDraft)
              NavigationPopupMenuItem<String>(
                value: 'open',
                child: _actionMenuItem(
                  context,
                  icon: Icons.edit_note_rounded,
                  label: 'Editar propuesta',
                ),
              ),
            NavigationPopupMenuItem<String>(
              value: 'preview',
              enabled: !fileActionsDisabled,
              child: _actionMenuItem(
                context,
                icon: Icons.picture_as_pdf_outlined,
                label: 'Vista previa del PDF',
              ),
            ),
            if (_isDraft)
              NavigationPopupMenuItem<String>(
                value: 'issue',
                enabled: !issuing,
                child: _actionMenuItem(
                  context,
                  icon: Icons.publish_rounded,
                  label: issuing ? 'Comprobando…' : 'Emitir propuesta',
                  color: cs.primary,
                ),
              ),
            if (_isDraft) const PopupMenuDivider(),
            if (_isDraft)
              NavigationPopupMenuItem<String>(
                value: 'delete',
                enabled: !mutationBusy,
                child: _actionMenuItem(
                  context,
                  icon: Icons.delete_outline_rounded,
                  label: 'Eliminar borrador',
                  color: cs.error,
                ),
              ),
          ],
          child: SizedBox.square(
            dimension: HexoraDimensions.touchTarget,
            child: Icon(Icons.more_vert_rounded,
                size: HexoraTableTokens.icon, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _actionMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: foreground.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: foreground),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  String _documentNumber(Map<String, dynamic> source) {
    final value = (source['presupuestoNumber'] ?? source['budgetNumber'] ?? '')
        .toString()
        .trim();
    return value;
  }

  String _clientInitials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (words.isEmpty) return '?';
    return words.map((word) => word[0].toUpperCase()).join();
  }
}

class _DocumentPill extends StatelessWidget {
  const _DocumentPill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      HexoraStatusBadge(label: label, color: color);
}

class _DocumentEmptyState extends StatelessWidget {
  const _DocumentEmptyState({
    required this.mode,
    required this.searchQuery,
  });

  final PresupuestoDocumentActionMode mode;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final issued = mode == PresupuestoDocumentActionMode.issued;
    final all = mode == PresupuestoDocumentActionMode.all;
    final searching = searchQuery.isNotEmpty;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 28),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              searching
                  ? Icons.search_off_rounded
                  : issued
                      ? Icons.verified_outlined
                      : Icons.drafts_outlined,
              size: 26,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: HexoraTableTokens.gap),
          Text(
            searching
                ? 'No hay resultados para "$searchQuery"'
                : issued
                    ? 'No hay propuestas emitidas.'
                    : all
                        ? 'No hay propuestas.'
                        : 'No hay borradores.',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            searching
                ? 'Prueba con otro nombre de cliente o documento.'
                : issued
                    ? 'Los presupuestos emitidos apareceran aqui.'
                    : all
                        ? 'Las propuestas aparecerán aquí.'
                        : 'Crea una propuesta para verla listada aquí.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _DocumentErrorState extends StatelessWidget {
  const _DocumentErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

String _clientName(
  Map<String, dynamic> document,
  List<GroupClient> clients,
) {
  final direct = presupuestoDocumentClientName(document);
  if (direct.isNotEmpty) return direct;
  final clientId = (document['clientId'] ?? '').toString().trim();
  for (final client in clients) {
    if (client.id == clientId) return client.name;
  }
  return '';
}

DateTime? _documentDate(
  Map<String, dynamic> document, {
  required bool issued,
}) {
  final raw = issued
      ? document['issueDate'] ?? document['issuedAt']
      : document['updatedAt'] ?? document['createdAt'];
  return DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
}
