import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:hexora/theme/components/themed_buttons.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/presentation/shared/widgets/documents/hexora_status_badge.dart';
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
  Map<String, dynamic>? _editingDocument;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? PresupuestosApi();
    _workspace = PresupuestoDocumentWorkspace(api: _api);
    _search.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {
        _page = 0;
        _selected.clear();
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
      _selected.retainAll(_workspace.documents.map(presupuestoDocumentId));
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

  int get _sectionDocumentCount {
    switch (widget.mode) {
      case PresupuestoDocumentActionMode.all:
        return _workspace.documents.length;
      case PresupuestoDocumentActionMode.drafts:
      case PresupuestoDocumentActionMode.edit:
        return _workspace.drafts.length;
      case PresupuestoDocumentActionMode.issued:
        return _workspace.issued.length;
      case PresupuestoDocumentActionMode.preview:
        return _workspace.documents.length;
    }
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
              content: const Text(
                  'Se eliminarán los borradores seleccionados. Las propuestas emitidas se conservarán. Esta acción no se puede deshacer.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Eliminar')),
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() => _mutationBusy = true);
    var removed = 0;
    try {
      for (final draft in drafts) {
        await _workspace.remove(draft);
        _selected.remove(presupuestoDocumentId(draft));
        removed++;
      }
      if (mounted) showSuccessSnack(context, '$removed borradores eliminados.');
    } catch (_) {
      if (mounted) {
        showErrorSnack(context,
            'Se eliminaron $removed de ${drafts.length} borradores. Los restantes siguen seleccionados; puedes volver a intentarlo.');
      }
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
        setState(() => _selected.remove(presupuestoDocumentId(document)));
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
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(HexoraTableTokens.pagePadding),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1100;
            final heading = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: HexoraDimensions.button,
                  height: HexoraDimensions.button,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(HexoraDimensions.radius),
                  ),
                  child: Icon(
                    widget.mode == PresupuestoDocumentActionMode.issued
                        ? Icons.verified_outlined
                        : Icons.drafts_outlined,
                    size: HexoraTableTokens.icon,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _title,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: HexoraTypography.pageTitle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          _DocumentPill(
                            label: '$_sectionDocumentCount',
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: HexoraTypography.label,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final tools = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: compact
                      ? constraints.maxWidth -
                          HexoraDimensions.touchTarget -
                          HexoraTableTokens.gap
                      : HexoraTableTokens.searchWidth,
                  child: TextField(
                    controller: _search,
                    style: theme.textTheme.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Buscar propuestas...',
                      prefixIconConstraints: BoxConstraints(
                          minWidth: HexoraDimensions.button,
                          minHeight: constraints.maxWidth < 600
                              ? HexoraDimensions.touchTarget
                              : HexoraDimensions.button),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: HexoraTableTokens.cellPadding,
                          vertical: HexoraTableTokens.rowPadding),
                      prefixIcon: const Icon(Icons.search_rounded, size: 19),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar busqueda',
                              onPressed: _search.clear,
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                      isDense: true,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(HexoraDimensions.radius),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(HexoraDimensions.radius),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(HexoraDimensions.radius),
                        borderSide: BorderSide(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Actualizar propuestas',
                  child: IconButton(
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      backgroundColor: theme.colorScheme.surfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(HexoraDimensions.radius),
                      ),
                    ),
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                if (!compact && widget.onCreate != null) ...[
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: widget.onCreate,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nueva propuesta'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, HexoraDimensions.button),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  const SizedBox(height: HexoraTableTokens.gap),
                  tools,
                  if (widget.onCreate != null)
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: widget.onCreate,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nueva propuesta'),
                        )),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: heading),
                const SizedBox(width: 20),
                tools,
              ],
            );
          },
        ),
        const SizedBox(height: HexoraTableTokens.gap),
        _documentTable(documents),
      ],
    );
  }

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
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.mode == PresupuestoDocumentActionMode.all ||
                    widget.mode == PresupuestoDocumentActionMode.preview)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        for (final filter in [
                          ('all', 'Todas', _workspace.documents.length),
                          ('draft', 'Borradores', _workspace.drafts.length),
                          ('issued', 'Emitidas', _workspace.issued.length),
                        ])
                          ButtonSegment(
                              value: filter.$1,
                              label: Text('${filter.$2}  ${filter.$3}')),
                      ],
                      selected: {_statusFilter},
                      onSelectionChanged: (selection) => setState(() {
                        _selected.clear();
                        _statusFilter = selection.single;
                        _page = 0;
                      }),
                      style: SegmentedButton.styleFrom(
                        minimumSize: const Size(0, HexoraDimensions.button),
                        padding: const EdgeInsets.symmetric(
                            horizontal: HexoraTableTokens.gap),
                        textStyle: Theme.of(context).textTheme.labelMedium,
                        selectedBackgroundColor:
                            cs.primary.withValues(alpha: .1),
                        selectedForegroundColor: cs.primary,
                        side: BorderSide(
                            color: cs.outlineVariant.withValues(
                                alpha: HexoraTableTokens.separatorOpacity)),
                      ),
                    ),
                  ),
                PopupMenuButton<bool>(
                  tooltip: 'Ordenar propuestas',
                  initialValue: _newestFirst,
                  onSelected: (value) => setState(() {
                    _newestFirst = value;
                    _page = 0;
                  }),
                  itemBuilder: (_) => const [
                    NavigationPopupMenuItem(
                        value: true, child: Text('Fecha más reciente')),
                    NavigationPopupMenuItem(
                        value: false, child: Text('Fecha más antigua')),
                  ],
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.swap_vert, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                            child: Text(
                                _newestFirst ? 'Más recientes' : 'Más antiguas',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: HexoraTypography.body))),
                        const Icon(Icons.expand_more, size: 16),
                      ])),
                ),
                if (_selected.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _mutationBusy || _selectedDrafts.isEmpty
                        ? null
                        : _removeSelected,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label:
                        Text('Eliminar borradores (${_selectedDrafts.length})'),
                  ),
                if (_selected.isNotEmpty)
                  TextButton(
                      onPressed: () => setState(_selected.clear),
                      child:
                          Text('${_selected.length} seleccionadas · Limpiar')),
              ]),
        ),
        if (documents.isEmpty)
          _DocumentEmptyState(
              mode: widget.mode, searchQuery: _search.text.trim())
        else
          LayoutBuilder(builder: (context, constraints) {
            final table = constraints.maxWidth >= 1100;
            return Column(children: [
              if (table)
                Container(
                  color: cs.primary.withValues(alpha: .035),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                        )),
                    const Expanded(flex: 5, child: Text('Propuesta')),
                    const Expanded(flex: 2, child: Text('Cliente')),
                    const SizedBox(width: 125, child: Text('Fecha')),
                    const SizedBox(width: 100, child: Text('Estado')),
                    const SizedBox(
                        width: 115,
                        child: Padding(
                            padding: EdgeInsets.only(
                                right: HexoraTableTokens.cellPadding),
                            child:
                                Text('Importe', textAlign: TextAlign.right))),
                    const SizedBox(
                        width: HexoraTableTokens.actionColumn,
                        child: Text('Acciones')),
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
                  onPreview: () => _openPdf(document, preview: true),
                  onDownload: () => _openPdf(document, preview: false),
                  onIssue: () => _issue(document),
                  onDelete: () => _remove(document),
                  onDuplicate: () => _duplicate(document),
                  mutationBusy: _mutationBusy,
                ),
            ]);
          }),
        Padding(
            padding: const EdgeInsets.all(12),
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
              Text('${currentPage + 1} / ${pageCount == 0 ? 1 : pageCount}'),
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

  String get _title {
    switch (widget.mode) {
      case PresupuestoDocumentActionMode.all:
        return 'Propuestas';
      case PresupuestoDocumentActionMode.drafts:
        return 'Borradores';
      case PresupuestoDocumentActionMode.issued:
        return 'Emitidas';
      case PresupuestoDocumentActionMode.edit:
        return 'Editar documento';
      case PresupuestoDocumentActionMode.preview:
        return 'Previsualizar PDF';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case PresupuestoDocumentActionMode.all:
        return 'Gestiona tus propuestas y presupuestos.';
      case PresupuestoDocumentActionMode.drafts:
        return 'Propuestas pendientes de emitir.';
      case PresupuestoDocumentActionMode.issued:
        return 'Propuestas emitidas con numeración definitiva.';
      case PresupuestoDocumentActionMode.edit:
        return 'Selecciona un borrador para continuar editando su contenido.';
      case PresupuestoDocumentActionMode.preview:
        return 'Abre el PDF generado para cualquier documento de presupuesto.';
    }
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

  bool get _isIssued => presupuestoDocumentStatus(document) == 'issued';
  bool get _isDraft => presupuestoDocumentStatus(document) == 'draft';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final date = _documentDate(document, issued: _isIssued);
    final amount = presupuestoDocumentAmount(document);
    final client = _clientName(document, clients);
    final accent = _isIssued
        ? ThemeColors.success(context)
        : _isDraft
            ? cs.primary
            : cs.error;
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
        color: selected ? cs.primary.withValues(alpha: .055) : cs.surface,
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
                    child: Checkbox(value: selected, onChanged: onSelect)),
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
                    flex: 2,
                    child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              line(client.isEmpty ? 'Sin cliente' : client),
                              if (email.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                line(email, muted: true)
                              ],
                            ]))),
                SizedBox(
                    width: 125,
                    child: line(
                        date == null
                            ? 'Sin fecha'
                            : DateFormat('d MMM y', 'es').format(date),
                        muted: true)),
                SizedBox(
                    width: 100,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: _DocumentPill(
                            label: _isIssued
                                ? 'Emitida'
                                : _isDraft
                                    ? 'Borrador'
                                    : 'Anulado',
                            color: accent))),
                SizedBox(
                    width: 115,
                    child: Padding(
                        padding: const EdgeInsets.only(
                            right: HexoraTableTokens.cellPadding),
                        child: Text(
                            amount == null
                                ? '—'
                                : NumberFormat.currency(
                                        locale: 'es_ES', symbol: '€')
                                    .format(amount),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontFeatures: HexoraTypography.numericFeatures),
                            textAlign: TextAlign.right))),
                SizedBox(
                    width: HexoraTableTokens.actionColumn,
                    child: _actions(context)),
              ]),
            )),
      );
    }
    return Material(
      color: selected ? cs.primary.withValues(alpha: .055) : cs.surface,
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
              _DocumentPill(
                  label: _isIssued
                      ? 'Emitida'
                      : _isDraft
                          ? 'Borrador'
                          : 'Anulada',
                  color: accent),
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
