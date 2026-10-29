import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/presupuesto/presupuesto_kind.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/conversion/presupuesto_advance_final_flow.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:intl/intl.dart';

part 'presupuesto_invoice_conversion_view_helpers.dart';
part 'presupuesto_invoice_conversion_view_widgets.dart';

enum _PresupuestoConversionType { advance, finalInvoice, fullFinalInvoice }

enum _AdvanceAmountMode { percent, fixedGross }

class PresupuestoInvoiceConversionView extends StatefulWidget {
  const PresupuestoInvoiceConversionView({
    super.key,
    required this.groupId,
    required this.clients,
    this.initialSelectedBudgetId,
    this.onOpenInvoiceId,
  });

  final String groupId;
  final List<GroupClient> clients;
  final String? initialSelectedBudgetId;
  final ValueChanged<String>? onOpenInvoiceId;

  @override
  State<PresupuestoInvoiceConversionView> createState() =>
      _PresupuestoInvoiceConversionViewState();
}

class _PresupuestoInvoiceConversionViewState
    extends State<PresupuestoInvoiceConversionView> {
  final PresupuestosApi _presupuestosApi = PresupuestosApi();
  final TextEditingController _advancePercentController =
      TextEditingController();
  final TextEditingController _advanceFixedAmountController =
      TextEditingController();
  final TextEditingController _advanceDescriptionController =
      TextEditingController();
  final TextEditingController _advanceNotesController = TextEditingController();
  final TextEditingController _finalNotesController = TextEditingController();

  int _listRequestId = 0;
  int _detailRequestId = 0;
  int _pdfRequestId = 0;
  bool _loadingList = true;
  bool _loadingDetail = false;
  bool _submitting = false;
  bool _previewingPdf = false;
  bool _loadingPdf = false;
  bool _showEligibleOnly = true;
  bool _advanceDescriptionEdited = false;
  bool _configurationDirty = false;
  String? _listError;
  String? _detailError;
  String? _submitError;
  String? _pdfError;
  Uint8List? _pdfBytes;
  List<Map<String, dynamic>> _presupuestos = const [];
  String? _selectedPresupuestoId;
  Map<String, dynamic>? _selectedPresupuesto;
  String? _formBudgetId;
  String? _selectedAdvanceInvoiceId;
  _PresupuestoConversionType _conversionType =
      _PresupuestoConversionType.advance;
  _AdvanceAmountMode _advanceAmountMode = _AdvanceAmountMode.percent;

  @override
  void initState() {
    super.initState();
    _loadPresupuestos(keepSelection: false);
  }

  @override
  void dispose() {
    _advancePercentController.dispose();
    _advanceFixedAmountController.dispose();
    _advanceDescriptionController.dispose();
    _advanceNotesController.dispose();
    _finalNotesController.dispose();
    super.dispose();
  }

  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';

  String get _localeTag => Localizations.localeOf(context).toLanguageTag();

  NumberFormat get _currencyFormatter => NumberFormat.currency(
        locale: _localeTag,
        symbol: 'EUR ',
        decimalDigits: 2,
      );

  PresupuestoInvoiceActionState? get _selectedActionState {
    final presupuesto = _selectedPresupuesto;
    if (presupuesto == null) return null;
    return resolvePresupuestoInvoiceActionState(presupuesto);
  }

  List<PresupuestoLinkedInvoiceRecord> get _selectedLinkedInvoices {
    final presupuesto = _selectedPresupuesto;
    if (presupuesto == null) return const <PresupuestoLinkedInvoiceRecord>[];
    return extractLinkedInvoiceRecordsFromPresupuesto(presupuesto);
  }

  List<AdvanceInvoiceCandidate> get _advanceCandidates {
    final presupuesto = _selectedPresupuesto;
    if (presupuesto == null) return const <AdvanceInvoiceCandidate>[];
    return extractAdvanceInvoiceCandidatesFromPresupuesto(presupuesto);
  }

  Future<void> _loadPresupuestos({required bool keepSelection}) async {
    final requestId = ++_listRequestId;
    final initialLoad = _presupuestos.isEmpty;
    if (mounted) {
      setState(() {
        if (initialLoad) {
          _loadingList = true;
        }
        _listError = null;
      });
    }

    try {
      final items = await _presupuestosApi.listByGroup(
        groupId: widget.groupId,
        presupuestoKind: PresupuestoKind.structured,
        sortDir: 'desc',
      );
      if (!mounted || requestId != _listRequestId) return;

      final preferredId = keepSelection
          ? _selectedPresupuestoId?.trim()
          : widget.initialSelectedBudgetId?.trim();
      final visibleIds = items
          .map((item) => _presupuestoId(item).trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      String? nextSelectedId;
      if (preferredId != null &&
          preferredId.isNotEmpty &&
          visibleIds.contains(preferredId)) {
        nextSelectedId = preferredId;
      }

      setState(() {
        _presupuestos = List<Map<String, dynamic>>.unmodifiable(items);
        _loadingList = false;
        _selectedPresupuestoId = nextSelectedId;
        if (nextSelectedId == null) {
          _selectedPresupuesto = null;
          _detailError = null;
          _loadingDetail = false;
          _formBudgetId = null;
          _submitError = null;
          _pdfBytes = null;
          _pdfError = null;
          _loadingPdf = false;
        }
      });

      if (nextSelectedId != null) {
        await _loadPresupuestoDetail(nextSelectedId, resetVisibleState: false);
      }
    } on PresupuestosApiException catch (e) {
      if (!mounted || requestId != _listRequestId) return;
      setState(() {
        _listError = e.message;
        _loadingList = false;
      });
    } catch (e) {
      if (!mounted || requestId != _listRequestId) return;
      setState(() {
        _listError = e.toString().replaceFirst('Exception: ', '');
        _loadingList = false;
      });
    }
  }

  Future<void> _loadPresupuestoDetail(
    String presupuestoId, {
    required bool resetVisibleState,
  }) async {
    final trimmedId = presupuestoId.trim();
    if (trimmedId.isEmpty) return;
    final requestId = ++_detailRequestId;
    setState(() {
      _selectedPresupuestoId = trimmedId;
      _loadingDetail = true;
      _detailError = null;
      _submitError = null;
      if (resetVisibleState) {
        _selectedPresupuesto = null;
        _selectedAdvanceInvoiceId = null;
        _pdfBytes = null;
        _pdfError = null;
        _loadingPdf = true;
      }
    });

    try {
      final detail = await _presupuestosApi.getById(trimmedId);
      if (!mounted || requestId != _detailRequestId) return;
      setState(() {
        _selectedPresupuesto = detail;
        _loadingDetail = false;
        _detailError = null;
      });
      _applyFormDefaults(detail);
      _loadSelectedPdf(trimmedId, detail);
    } on PresupuestosApiException catch (e) {
      if (!mounted || requestId != _detailRequestId) return;
      setState(() {
        _loadingDetail = false;
        _detailError = e.message;
      });
    } catch (e) {
      if (!mounted || requestId != _detailRequestId) return;
      setState(() {
        _loadingDetail = false;
        _detailError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _applyFormDefaults(Map<String, dynamic> presupuesto) {
    final presupuestoId = _presupuestoId(presupuesto).trim();
    final preferredAdvanceInvoiceId = _preferredAdvanceInvoiceId(presupuesto);
    if (presupuestoId.isEmpty || _formBudgetId == presupuestoId) {
      final candidates = _advanceCandidates;
      final nextSelectedAdvanceId = _resolveSelectedAdvanceInvoiceId(
        candidates,
        preferredId: preferredAdvanceInvoiceId,
        currentId: _selectedAdvanceInvoiceId,
      );
      if (nextSelectedAdvanceId != _selectedAdvanceInvoiceId) {
        setState(() {
          _selectedAdvanceInvoiceId = nextSelectedAdvanceId;
        });
      }
      return;
    }

    final actionState = resolvePresupuestoInvoiceActionState(presupuesto);
    final candidates = extractAdvanceInvoiceCandidatesFromPresupuesto(
      presupuesto,
    );

    _advancePercentController.text = '70';
    _advanceFixedAmountController.clear();
    _advanceDescriptionController.text =
        _isSpanish ? 'Anticipo 70% del presupuesto' : 'Advance 70% from quote';
    _advanceDescriptionEdited = false;
    _configurationDirty = false;
    _advanceNotesController.clear();
    final presupuestoNumber = _presupuestoNumber(presupuesto);
    _finalNotesController.text = _isSpanish
        ? 'Factura final del presupuesto $presupuestoNumber'
        : 'Final invoice from proposal $presupuestoNumber';

    setState(() {
      _formBudgetId = presupuestoId;
      _selectedAdvanceInvoiceId = _resolveSelectedAdvanceInvoiceId(
        candidates,
        preferredId: preferredAdvanceInvoiceId,
      );
      _conversionType = actionState.canCreateAdvance
          ? _PresupuestoConversionType.advance
          : actionState.canCreateFinal
              ? _PresupuestoConversionType.finalInvoice
              : _PresupuestoConversionType.fullFinalInvoice;
      _advanceAmountMode = _AdvanceAmountMode.percent;
    });
  }

  String? _preferredAdvanceInvoiceId(Map<String, dynamic> presupuesto) {
    final candidates = <dynamic>[
      presupuesto['convertedAdvanceInvoiceId'],
      presupuesto['advanceInvoiceId'],
      presupuesto['convertedAdvanceInvoice'] is Map
          ? (presupuesto['convertedAdvanceInvoice'] as Map)['_id'] ??
              (presupuesto['convertedAdvanceInvoice'] as Map)['id']
          : null,
      presupuesto['advanceInvoice'] is Map
          ? (presupuesto['advanceInvoice'] as Map)['_id'] ??
              (presupuesto['advanceInvoice'] as Map)['id']
          : null,
    ];
    for (final value in candidates) {
      final id = (value ?? '').toString().trim();
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  String? _resolveSelectedAdvanceInvoiceId(
    List<AdvanceInvoiceCandidate> candidates, {
    String? preferredId,
    String? currentId,
  }) {
    if (candidates.isEmpty) return null;
    final normalizedPreferred = preferredId?.trim();
    if (normalizedPreferred != null && normalizedPreferred.isNotEmpty) {
      for (final candidate in candidates) {
        if (candidate.id == normalizedPreferred) {
          return candidate.id;
        }
      }
    }
    final normalizedCurrent = currentId?.trim();
    if (normalizedCurrent != null && normalizedCurrent.isNotEmpty) {
      for (final candidate in candidates) {
        if (candidate.id == normalizedCurrent) {
          return candidate.id;
        }
      }
    }
    for (final candidate in candidates) {
      if (candidate.isIssued) return candidate.id;
    }
    return candidates.first.id;
  }

  Future<void> _loadSelectedPdf(
    String presupuestoId,
    Map<String, dynamic> presupuesto,
  ) async {
    final requestId = ++_pdfRequestId;
    if (mounted) {
      setState(() {
        _loadingPdf = true;
        _pdfError = null;
        _pdfBytes = null;
      });
    }

    try {
      final response = _isDraftPresupuesto(presupuesto)
          ? await _presupuestosApi.previewPdf(presupuestoId)
          : await _presupuestosApi.downloadPdf(presupuestoId);
      if (!mounted ||
          requestId != _pdfRequestId ||
          presupuestoId != (_selectedPresupuestoId ?? '').trim()) {
        return;
      }
      setState(() {
        _pdfBytes = Uint8List.fromList(response.bodyBytes);
        _loadingPdf = false;
        _pdfError = null;
      });
    } on PresupuestosApiException catch (e) {
      if (!mounted || requestId != _pdfRequestId) return;
      setState(() {
        _loadingPdf = false;
        _pdfError = e.message;
      });
    } catch (e) {
      if (!mounted || requestId != _pdfRequestId) return;
      setState(() {
        _loadingPdf = false;
        _pdfError = e.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  Future<void> _showPresupuestoSelector() async {
    final queryController = TextEditingController();
    var eligibleOnly = _showEligibleOnly;
    Map<String, dynamic>? selected;
    try {
      selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final query = queryController.text.trim().toLowerCase();
            final items = _presupuestos.where((item) {
              if (eligibleOnly && !isPresupuestoIssuedOrAccepted(item)) {
                return false;
              }
              if (query.isEmpty) return true;
              return <String>[
                _presupuestoNumber(item),
                _presupuestoClientName(item),
                _presupuestoStatus(item),
                _formatDate(_presupuestoDate(item)),
              ].join(' ').toLowerCase().contains(query);
            }).toList(growable: false);

            return Dialog(
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 760,
                  maxHeight: 680,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.sizeOf(context).height * 0.72,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isSpanish
                                    ? 'Seleccionar presupuesto'
                                    : 'Select proposal',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            IconButton(
                              tooltip: _isSpanish ? 'Cerrar' : 'Close',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: queryController,
                                autofocus: true,
                                onChanged: (_) => setDialogState(() {}),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search_rounded,
                                      size: 18),
                                  hintText: _isSpanish
                                      ? 'Buscar por número o cliente...'
                                      : 'Search by number or client...',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              selected: eligibleOnly,
                              onSelected: (value) =>
                                  setDialogState(() => eligibleOnly = value),
                              label:
                                  Text(_isSpanish ? 'Elegibles' : 'Eligible'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: items.isEmpty
                            ? Center(
                                child: Text(
                                  _isSpanish
                                      ? 'No hay presupuestos coincidentes.'
                                      : 'No matching proposals.',
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final id = _presupuestoId(item).trim();
                                  final isSelected = id ==
                                      (_selectedPresupuestoId ?? '').trim();
                                  final status = _presupuestoStatus(item);
                                  final statusColor = _statusColor(
                                      Theme.of(context).colorScheme, status);
                                  final total = _presupuestoTotal(item);
                                  return HexoraListRow(
                                    selected: isSelected,
                                    minHeight: 58,
                                    verticalPadding: 5,
                                    onTap: id.isEmpty
                                        ? null
                                        : () => Navigator.of(context).pop(item),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.request_quote_outlined,
                                          size: 18,
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${_presupuestoNumber(item)} · ${_presupuestoClientName(item)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                _formatDate(
                                                    _presupuestoDate(item)),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (total != null) ...[
                                          Text(
                                            _currencyFormatter.format(total),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        _TinyPill(
                                          label: _formatStatusLabel(status),
                                          background: statusColor.withValues(
                                              alpha: 0.14),
                                          foreground: statusColor,
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          Icon(Icons.check_circle_rounded,
                                              size: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    } finally {
      queryController.dispose();
    }

    if (!mounted || selected == null) return;
    setState(() => _showEligibleOnly = eligibleOnly);
    final nextId = _presupuestoId(selected).trim();
    if (nextId.isEmpty || nextId == (_selectedPresupuestoId ?? '').trim()) {
      return;
    }
    if (_configurationDirty && _selectedPresupuesto != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_isSpanish ? 'Cambiar presupuesto' : 'Change proposal'),
          content: Text(_isSpanish
              ? 'Los cambios de configuración sin guardar se perderán.'
              : 'Unsaved configuration changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_isSpanish ? 'Cancelar' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_isSpanish ? 'Cambiar' : 'Change'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await _loadPresupuestoDetail(nextId, resetVisibleState: true);
  }

  Future<void> _previewSelectedPresupuesto() async {
    final presupuesto = _selectedPresupuesto;
    final presupuestoId = _selectedPresupuestoId?.trim() ?? '';
    if (presupuesto == null || presupuestoId.isEmpty || _previewingPdf) return;

    setState(() => _previewingPdf = true);
    try {
      final response = _isDraftPresupuesto(presupuesto)
          ? await _presupuestosApi.previewPdf(presupuestoId)
          : await _presupuestosApi.downloadPdf(presupuestoId);
      await pdf_launcher.launchPdfPreview(
        Uint8List.fromList(response.bodyBytes),
        fileName: 'presupuesto-${_presupuestoNumber(presupuesto)}.pdf',
      );
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', '').trim());
    } finally {
      if (mounted) {
        setState(() => _previewingPdf = false);
      }
    }
  }

  Future<void> _submitAdvanceInvoice() async {
    final actionState = _selectedActionState;
    final presupuestoId = _selectedPresupuestoId?.trim() ?? '';
    final presupuesto = _selectedPresupuesto;
    if (actionState == null ||
        presupuesto == null ||
        presupuestoId.isEmpty ||
        !actionState.canCreateAdvance ||
        _submitting) {
      return;
    }

    late final CreateAdvanceInvoiceFromPresupuestoRequest payload;
    if (_advanceAmountMode == _AdvanceAmountMode.percent) {
      final percent = _parseDouble(_advancePercentController.text);
      final input = AdvanceInvoiceConfigInput(
        percent: percent ?? -1,
        description: _advanceDescriptionController.text.trim(),
      );
      final validation = validateAdvanceConfig(input);
      if (!validation.isValid) {
        setState(() => _submitError = validation.message);
        return;
      }
      payload = buildAdvanceInvoiceRequest(
        input,
        notes: _advanceNotesController.text,
      );
    } else {
      final grossAmount = _parseDouble(_advanceFixedAmountController.text);
      final total = _presupuestoTotal(presupuesto);
      if (grossAmount == null || grossAmount <= 0) {
        setState(() {
          _submitError = _isSpanish
              ? 'El importe fijo debe ser mayor que 0.'
              : 'Fixed amount must be greater than 0.';
        });
        return;
      }
      if (total != null && grossAmount > total + 0.005) {
        setState(() {
          _submitError = _isSpanish
              ? 'El importe fijo no puede superar el total del presupuesto.'
              : 'Fixed amount cannot exceed the presupuesto total.';
        });
        return;
      }
      final vatRate = _advanceVatRate(presupuesto);
      final baseAmount =
          double.parse((grossAmount / (1 + vatRate / 100)).toStringAsFixed(2));
      final number = _presupuestoNumber(presupuesto);
      final description = _advanceDescriptionController.text.trim().isNotEmpty
          ? _advanceDescriptionController.text.trim()
          : (_isSpanish
              ? 'Anticipo correspondiente al presupuesto $number'
              : 'Advance corresponding to presupuesto $number');
      payload = CreateAdvanceInvoiceFromPresupuestoRequest(
        advanceConfig: CreateAdvanceInvoiceConfig(
          percent: 100,
          projectBaseAmount: baseAmount,
          description: description,
        ),
        notes: _advanceNotesController.text.trim().isEmpty
            ? null
            : _advanceNotesController.text.trim(),
      );
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final result = await _presupuestosApi.createAdvanceInvoiceFromPresupuesto(
        presupuestoId,
        payload: payload,
      );
      if (!mounted) return;
      await _handleCreateSuccess(
        result,
        successLabel: _isSpanish
            ? 'Factura de anticipo creada correctamente.'
            : 'Advance invoice created successfully.',
      );
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  double _advanceVatRate(Map<String, dynamic> presupuesto) {
    final rates = _presupuestoVatRates(presupuesto);
    if (rates.isEmpty) return 21;
    return rates.first;
  }

  Future<void> _submitFinalInvoice() async {
    final actionState = _selectedActionState;
    final presupuestoId = _selectedPresupuestoId?.trim() ?? '';
    if (actionState == null ||
        presupuestoId.isEmpty ||
        !actionState.canCreateFinal ||
        _submitting) {
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final payload = buildFinalInvoiceRequest(
        advanceInvoiceId: _selectedAdvanceInvoiceId,
        notes: _finalNotesController.text,
      );
      final result = await _presupuestosApi.createFinalInvoiceFromPresupuesto(
        presupuestoId,
        payload: payload,
      );
      if (!mounted) return;
      await _handleCreateSuccess(
        result,
        successLabel: _isSpanish
            ? 'Factura final creada correctamente.'
            : 'Final invoice created successfully.',
      );
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  Future<void> _submitFullFinalInvoice() async {
    final actionState = _selectedActionState;
    final presupuestoId = _selectedPresupuestoId?.trim() ?? '';
    if (actionState == null ||
        presupuestoId.isEmpty ||
        !actionState.canCreateFullFinal ||
        _submitting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            _isSpanish ? 'Crear factura completa' : 'Create complete invoice'),
        content: const Text(
          'Este presupuesto se facturará por el importe total porque no tiene anticipo asociado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_isSpanish ? 'Confirmar' : 'Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final result = await _presupuestosApi.createFinalInvoiceFromPresupuesto(
        presupuestoId,
        payload: const CreateFinalInvoiceFromPresupuestoRequest(),
      );
      if (!mounted) return;
      await _handleCreateSuccess(
        result,
        successLabel: _isSpanish
            ? 'Factura completa creada correctamente.'
            : 'Complete invoice created successfully.',
      );
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  Future<void> _handleCreateSuccess(
    PresupuestoCreateInvoiceResponse response, {
    required String successLabel,
  }) async {
    final createdInvoiceId = _createdInvoiceId(response);
    await _loadPresupuestos(keepSelection: true);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(successLabel),
          action: createdInvoiceId != null &&
                  createdInvoiceId.isNotEmpty &&
                  widget.onOpenInvoiceId != null
              ? SnackBarAction(
                  label: _isSpanish ? 'Abrir factura' : 'Open invoice',
                  onPressed: () => widget.onOpenInvoiceId!(createdInvoiceId),
                )
              : null,
        ),
      );

    if (createdInvoiceId != null &&
        createdInvoiceId.isNotEmpty &&
        widget.onOpenInvoiceId != null) {
      widget.onOpenInvoiceId!(createdInvoiceId);
    }

    setState(() {
      _submitting = false;
      _submitError = null;
    });
  }

  String? _createdInvoiceId(PresupuestoCreateInvoiceResponse response) {
    final direct = response.invoiceId?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final invoice = response.invoice;
    if (invoice == null) return null;
    for (final key in const ['_id', 'id', 'invoiceId']) {
      final value = invoice[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  void _showSnack(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(trimmed)));
  }

  bool get _canSubmitSelectedConversion {
    final actionState = _selectedActionState;
    final presupuesto = _selectedPresupuesto;
    if (_submitting || actionState == null || presupuesto == null) return false;
    switch (_conversionType) {
      case _PresupuestoConversionType.advance:
        if (!actionState.canCreateAdvance) return false;
        if (_advanceAmountMode == _AdvanceAmountMode.percent) {
          final percent = _parseDouble(_advancePercentController.text);
          return percent != null && percent > 0 && percent <= 100;
        }
        final amount = _parseDouble(_advanceFixedAmountController.text);
        final total = _presupuestoTotal(presupuesto);
        return amount != null &&
            amount > 0 &&
            (total == null || amount <= total + 0.005);
      case _PresupuestoConversionType.finalInvoice:
        return actionState.canCreateFinal;
      case _PresupuestoConversionType.fullFinalInvoice:
        return actionState.canCreateFullFinal;
    }
  }

  String get _selectedSubmitLabel => switch (_conversionType) {
        _PresupuestoConversionType.advance =>
          _isSpanish ? 'Crear factura de anticipo' : 'Create advance invoice',
        _PresupuestoConversionType.finalInvoice =>
          _isSpanish ? 'Crear factura final' : 'Create final invoice',
        _PresupuestoConversionType.fullFinalInvoice =>
          _isSpanish ? 'Crear factura completa' : 'Create complete invoice',
      };

  VoidCallback get _selectedSubmitAction => switch (_conversionType) {
        _PresupuestoConversionType.advance => _submitAdvanceInvoice,
        _PresupuestoConversionType.finalInvoice => _submitFinalInvoice,
        _PresupuestoConversionType.fullFinalInvoice => _submitFullFinalInvoice,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    if (_loadingList && _presupuestos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_listError != null && _presupuestos.isEmpty) {
      return ErrorView(
        message: _listError!,
        onRetry: () => _loadPresupuestos(keepSelection: false),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final configurationPanel = _buildDetailPanel(context, cs, typo);
        final previewPanel = _buildPdfPanel(context, cs, typo);
        if (constraints.maxWidth < 820) {
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: _isSpanish ? 'Configuración' : 'Configuration'),
                    Tab(text: _isSpanish ? 'Vista previa' : 'Preview'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [configurationPanel, previewPanel],
                  ),
                ),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: configurationPanel,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
            Expanded(
              flex: 6,
              child: previewPanel,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPdfPanel(
    BuildContext context,
    ColorScheme cs,
    AppTypography typo,
  ) {
    final presupuesto = _selectedPresupuesto;
    final presupuestoId = (_selectedPresupuestoId ?? '').trim();
    if (presupuestoId.isEmpty || presupuesto == null) {
      return _CenteredInfoState(
        icon: Icons.picture_as_pdf_outlined,
        title: _isSpanish ? 'Vista previa del presupuesto' : 'Proposal preview',
        subtitle: _isSpanish
            ? 'Selecciona un presupuesto para cargar su PDF original.'
            : 'Select a proposal to load its original PDF.',
      );
    }

    Widget body;
    if (_loadingPdf) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_pdfError != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf_outlined, size: 34, color: cs.error),
              const SizedBox(height: 8),
              Text(
                _pdfError!,
                textAlign: TextAlign.center,
                style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              HexoraButton(
                onPressed: () => _loadSelectedPdf(
                  presupuestoId,
                  presupuesto,
                ),
                variant: HexoraButtonVariant.secondary,
                size: HexoraButtonSize.compact,
                icon: Icons.refresh_rounded,
                label: _isSpanish ? 'Reintentar' : 'Retry',
              ),
            ],
          ),
        ),
      );
    } else if (_pdfBytes == null) {
      body = _CenteredInfoState(
        icon: Icons.picture_as_pdf_outlined,
        title: _isSpanish ? 'PDF no disponible' : 'PDF unavailable',
        subtitle: _isSpanish
            ? 'La configuración de la factura sigue disponible.'
            : 'Invoice configuration remains available.',
      );
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) => PdfInlinePreview(
          key: ValueKey(presupuestoId),
          bytes: _pdfBytes!,
          height: constraints.maxHeight,
          interactive: true,
          showToolbar: true,
        ),
      );
    }

    return ColoredBox(
      color: cs.surfaceContainerLowest.withValues(alpha: 0.22),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf_outlined,
                    size: 18, color: cs.primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${_isSpanish ? 'Presupuesto' : 'Proposal'} ${_presupuestoNumber(presupuesto)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _isSpanish ? 'Actualizar PDF' : 'Refresh PDF',
                  onPressed: _loadingPdf
                      ? null
                      : () => _loadSelectedPdf(presupuestoId, presupuesto),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
                HexoraButton(
                  onPressed:
                      _previewingPdf ? null : _previewSelectedPresupuesto,
                  variant: HexoraButtonVariant.secondary,
                  size: HexoraButtonSize.compact,
                  loading: _previewingPdf,
                  icon: Icons.open_in_new_rounded,
                  label: _isSpanish ? 'Abrir' : 'Open',
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
          Expanded(child: ClipRect(child: body)),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(
    BuildContext context,
    ColorScheme cs,
    AppTypography typo,
  ) {
    final presupuesto = _selectedPresupuesto;
    final actionState = _selectedActionState;
    final linkedInvoices = _selectedLinkedInvoices;
    final advanceCandidates = _advanceCandidates;

    Widget child;
    if (_selectedPresupuestoId == null) {
      child = _CenteredInfoState(
        icon: Icons.touch_app_outlined,
        title:
            _isSpanish ? 'Selecciona un presupuesto' : 'Select a presupuesto',
        subtitle: _isSpanish
            ? 'Elige el presupuesto que quieres convertir en factura.'
            : 'Choose the proposal you want to convert into an invoice.',
        action: HexoraButton(
          onPressed: _showPresupuestoSelector,
          icon: Icons.search_rounded,
          label: _isSpanish ? 'Seleccionar presupuesto' : 'Select proposal',
        ),
      );
    } else if (_loadingDetail && presupuesto == null) {
      child = const Center(child: CircularProgressIndicator());
    } else if (_detailError != null && presupuesto == null) {
      child = ErrorView(
        message: _detailError!,
        onRetry: () => _loadPresupuestoDetail(
          _selectedPresupuestoId!,
          resetVisibleState: false,
        ),
      );
    } else if (presupuesto == null) {
      child = _CenteredInfoState(
        icon: Icons.info_outline,
        title: _isSpanish ? 'Sin detalle disponible' : 'No detail available',
        subtitle: _isSpanish
            ? 'No se pudo cargar el presupuesto seleccionado.'
            : 'The selected presupuesto could not be loaded.',
      );
    } else {
      final clientName = _presupuestoClientName(presupuesto);
      final statusStr = _presupuestoStatus(presupuesto);
      final statusColor = _statusColor(cs, statusStr);
      final canDoAnything = actionState != null &&
          (actionState.canCreateAdvance ||
              actionState.canCreateFinal ||
              actionState.canCreateFullFinal);

      String disabledTypeReason(_PresupuestoConversionType type) {
        if (actionState == null) {
          return _isSpanish
              ? 'No disponible para este presupuesto.'
              : 'Unavailable for this proposal.';
        }
        return switch (type) {
          _PresupuestoConversionType.advance => actionState.hasAdvance
              ? (_isSpanish
                  ? 'Ya existe una factura de anticipo.'
                  : 'An advance invoice already exists.')
              : (_isSpanish
                  ? 'El presupuesto debe estar emitido.'
                  : 'The proposal must be issued.'),
          _PresupuestoConversionType.finalInvoice => actionState.hasFinal
              ? (_isSpanish
                  ? 'Ya existe una factura final.'
                  : 'A final invoice already exists.')
              : !actionState.hasAdvance
                  ? (_isSpanish
                      ? 'Requiere una factura de anticipo previa.'
                      : 'An advance invoice is required first.')
                  : (_isSpanish
                      ? 'El presupuesto debe estar emitido.'
                      : 'The proposal must be issued.'),
          _PresupuestoConversionType.fullFinalInvoice => actionState.hasAdvance
              ? (_isSpanish
                  ? 'Usa Final para descontar el anticipo existente.'
                  : 'Use Final to deduct the existing advance.')
              : actionState.hasFinal
                  ? (_isSpanish
                      ? 'Ya existe una factura final.'
                      : 'A final invoice already exists.')
                  : (_isSpanish
                      ? 'El presupuesto debe estar emitido.'
                      : 'The proposal must be issued.'),
        };
      }

      Widget typeLabel(
        String label,
        _PresupuestoConversionType type,
        bool enabled,
      ) =>
          enabled
              ? Text(label)
              : Tooltip(
                  message: disabledTypeReason(type),
                  child: Text(label),
                );

      final formContent = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                      style: typo.bodyLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: typo.bodyLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${_presupuestoNumber(presupuesto)} · ${_formatDate(_presupuestoDate(presupuesto))}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: typo.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          _TinyPill(
                            label: _formatStatusLabel(statusStr),
                            background: statusColor.withValues(alpha: 0.14),
                            foreground: statusColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                HexoraButton(
                  onPressed: _showPresupuestoSelector,
                  variant: HexoraButtonVariant.secondary,
                  size: HexoraButtonSize.compact,
                  icon: Icons.swap_horiz_rounded,
                  label: _isSpanish ? 'Cambiar' : 'Change',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // â”€â”€ Linked invoices â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (linkedInvoices.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.link_rounded,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text(
                    _isSpanish ? 'Facturas enlazadas' : 'Linked invoices',
                    style: typo.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${linkedInvoices.length}',
                      style: typo.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...linkedInvoices.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _LinkedInvoiceCard(
                    record: record,
                    isSpanish: _isSpanish,
                    onOpen: widget.onOpenInvoiceId != null
                        ? () => widget.onOpenInvoiceId!(record.id)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Divider(
                  color: cs.outlineVariant.withValues(alpha: 0.3), height: 1),
              const SizedBox(height: 10),
            ],

            // â”€â”€ Conversion section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (!canDoAnything) ...[
              // All done â€” show completion state inline
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: cs.tertiary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_outline_rounded,
                          size: 18, color: cs.tertiary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSpanish
                                ? 'Conversiones completadas'
                                : 'Conversions complete',
                            style: typo.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            _isSpanish
                                ? 'Este presupuesto ya tiene todas las facturas generadas.'
                                : 'All invoices for this presupuesto have been generated.',
                            style: typo.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSpanish ? 'Tipo de factura' : 'Invoice type',
                        style: typo.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Tooltip(
                        message: _isSpanish
                            ? 'Las opciones desactivadas no están disponibles según las facturas ya vinculadas y el estado del presupuesto.'
                            : 'Disabled options are unavailable because of the proposal status or its linked invoices.',
                        child: SegmentedButton<_PresupuestoConversionType>(
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: WidgetStatePropertyAll(Size(0, 36)),
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                          segments: [
                            ButtonSegment<_PresupuestoConversionType>(
                              value: _PresupuestoConversionType.advance,
                              icon:
                                  const Icon(Icons.percent_outlined, size: 15),
                              label: typeLabel(
                                _isSpanish ? 'Anticipo' : 'Advance',
                                _PresupuestoConversionType.advance,
                                actionState.canCreateAdvance,
                              ),
                              enabled: actionState.canCreateAdvance,
                            ),
                            ButtonSegment<_PresupuestoConversionType>(
                              value: _PresupuestoConversionType.finalInvoice,
                              icon: const Icon(Icons.receipt_long_outlined,
                                  size: 15),
                              label: typeLabel(
                                _isSpanish ? 'Final' : 'Final',
                                _PresupuestoConversionType.finalInvoice,
                                actionState.canCreateFinal,
                              ),
                              enabled: actionState.canCreateFinal,
                            ),
                            ButtonSegment<_PresupuestoConversionType>(
                              value:
                                  _PresupuestoConversionType.fullFinalInvoice,
                              icon:
                                  const Icon(Icons.payments_outlined, size: 15),
                              label: typeLabel(
                                _isSpanish ? 'Completa' : 'Complete',
                                _PresupuestoConversionType.fullFinalInvoice,
                                actionState.canCreateFullFinal,
                              ),
                              enabled: actionState.canCreateFullFinal,
                            ),
                          ],
                          selected: {_conversionType},
                          onSelectionChanged: (selected) {
                            setState(() {
                              _conversionType = selected.first;
                              _submitError = null;
                              _configurationDirty = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_submitError != null &&
                          _submitError!.trim().isNotEmpty) ...[
                        _InlineErrorBanner(message: _submitError!),
                        const SizedBox(height: 8),
                      ],
                      if (_conversionType == _PresupuestoConversionType.advance)
                        _buildAdvanceForm(context, cs, typo)
                      else if (_conversionType ==
                          _PresupuestoConversionType.fullFinalInvoice)
                        _buildFullFinalForm(context, cs, typo)
                      else
                        _buildFinalForm(context, cs, typo, advanceCandidates),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
      child = Column(
        children: [
          Expanded(child: formContent),
          if (canDoAnything)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final button = HexoraButton(
                    onPressed: _canSubmitSelectedConversion
                        ? _selectedSubmitAction
                        : null,
                    loading: _submitting,
                    icon: Icons.add_task_outlined,
                    label: _selectedSubmitLabel,
                    size: HexoraButtonSize.compact,
                  );
                  if (constraints.maxWidth < 520) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: button,
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isSpanish
                              ? 'La factura se creará como borrador.'
                              : 'The invoice will be created as a draft.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typo.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      button,
                    ],
                  );
                },
              ),
            ),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Widget _buildAmountPreview(
    BuildContext context,
    ColorScheme cs,
    AppTypography typo,
  ) {
    final presupuesto = _selectedPresupuesto;
    if (presupuesto == null) return const SizedBox.shrink();

    double? valueFor(List<String> keys) {
      for (final key in keys) {
        final value = _toDouble(presupuesto[key]);
        if (value != null) return value;
      }
      return null;
    }

    final proposalGross = _presupuestoTotal(presupuesto);
    final proposalBase = valueFor(
      const ['subtotal', 'taxableBase', 'baseAmount', 'netTotal'],
    );
    final proposalVat = valueFor(
      const ['taxTotal', 'vatTotal', 'ivaTotal', 'totalTax'],
    );

    double? gross;
    double? base;
    double? vat;
    switch (_conversionType) {
      case _PresupuestoConversionType.advance:
        if (_advanceAmountMode == _AdvanceAmountMode.fixedGross) {
          final fixed = _parseDouble(_advanceFixedAmountController.text);
          gross = fixed != null && fixed > 0 ? fixed : null;
        } else {
          final percent = _parseDouble(_advancePercentController.text);
          if (percent != null && percent > 0 && percent <= 100) {
            final factor = percent / 100;
            gross = proposalGross == null ? null : proposalGross * factor;
            base = proposalBase == null ? null : proposalBase * factor;
            vat = proposalVat == null ? null : proposalVat * factor;
          }
        }
        break;
      case _PresupuestoConversionType.finalInvoice:
        // The final amount can depend on the selected advance invoice. The
        // backend remains authoritative, so no speculative total is shown.
        break;
      case _PresupuestoConversionType.fullFinalInvoice:
        gross = proposalGross;
        base = proposalBase;
        vat = proposalVat;
        break;
    }

    if (gross == null) {
      return const SizedBox.shrink();
    }

    Widget metric(String label, double value, {bool emphasized = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label ',
              style: typo.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            Text(
              _currencyFormatter.format(value),
              style: typo.bodySmall.copyWith(
                color: emphasized ? cs.primary : cs.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: emphasized ? 13 : 11.5,
              ),
            ),
          ],
        );

    final isAdvance = _conversionType == _PresupuestoConversionType.advance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            isAdvance
                ? (_isSpanish ? 'Estimación' : 'Estimate')
                : (_isSpanish ? 'Resumen' : 'Summary'),
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (base != null)
            metric(
              isAdvance && _isSpanish ? 'Base estimada' : 'Base',
              base,
            ),
          if (vat != null)
            metric(
              isAdvance && _isSpanish ? 'IVA estimado' : 'VAT',
              vat,
            ),
          metric(
            isAdvance && _isSpanish ? 'Total estimado' : 'Total',
            gross,
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _buildVatNotice(ColorScheme cs, AppTypography typo) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _isSpanish
                ? 'El importe y el IVA se confirmarán al crear la factura.'
                : 'The amount and VAT will be confirmed when the invoice is created.',
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvanceModeSelector(Map<String, dynamic>? presupuesto) {
    return SegmentedButton<_AdvanceAmountMode>(
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: WidgetStatePropertyAll(Size(0, 36)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
      segments: [
        ButtonSegment(
          value: _AdvanceAmountMode.percent,
          icon: const Icon(Icons.percent_outlined, size: 16),
          label: Text(_isSpanish ? 'Porcentaje' : 'Percent'),
        ),
        ButtonSegment(
          value: _AdvanceAmountMode.fixedGross,
          icon: const Icon(Icons.euro_rounded, size: 16),
          label: Text(_isSpanish ? 'Importe fijo' : 'Fixed amount'),
        ),
      ],
      selected: {_advanceAmountMode},
      onSelectionChanged: _submitting
          ? null
          : (selection) {
              final mode = selection.first;
              setState(() {
                _advanceAmountMode = mode;
                _configurationDirty = true;
                if (_advanceDescriptionEdited) return;
                if (mode == _AdvanceAmountMode.percent) {
                  final percent =
                      _parseDouble(_advancePercentController.text) ?? 70;
                  _advanceDescriptionController.text = _isSpanish
                      ? 'Anticipo ${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 2)}% del presupuesto'
                      : 'Advance ${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 2)}% from quote';
                } else {
                  final number = presupuesto == null
                      ? ''
                      : _presupuestoNumber(presupuesto);
                  _advanceDescriptionController.text = _isSpanish
                      ? 'Anticipo correspondiente al presupuesto $number'
                      : 'Advance corresponding to presupuesto $number';
                }
              });
            },
    );
  }

  Widget _buildAdvanceValueField() {
    if (_advanceAmountMode == _AdvanceAmountMode.percent) {
      return TextFormField(
        controller: _advancePercentController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        onChanged: (value) {
          final percent = _parseDouble(value);
          setState(() {
            _configurationDirty = true;
            if (percent == null || _advanceDescriptionEdited) return;
            _advanceDescriptionController.text = _isSpanish
                ? 'Anticipo ${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 2)}% del presupuesto'
                : 'Advance ${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 2)}% from quote';
          });
        },
        decoration: const InputDecoration(
          hintText: '0',
          suffixText: '%',
          isDense: true,
        ),
      );
    }
    return TextFormField(
      controller: _advanceFixedAmountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      onChanged: (value) {
        final amount = _parseDouble(value);
        setState(() {
          _configurationDirty = true;
          if (amount == null || _advanceDescriptionEdited) return;
          final presupuesto = _selectedPresupuesto;
          final number =
              presupuesto == null ? '' : _presupuestoNumber(presupuesto).trim();
          final formatted = _currencyFormatter.format(amount);
          _advanceDescriptionController.text = _isSpanish
              ? 'Anticipo de $formatted${number.isEmpty ? '' : ' del presupuesto $number'}'
              : '$formatted advance${number.isEmpty ? '' : ' from proposal $number'}';
        });
      },
      decoration: const InputDecoration(
        hintText: '0,00',
        suffixText: '€',
        isDense: true,
      ),
    );
  }

  Widget _buildAdvanceForm(
    BuildContext context,
    ColorScheme cs,
    AppTypography typo,
  ) {
    final presupuesto = _selectedPresupuesto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isSpanish ? 'Importe del anticipo' : 'Advance amount',
          style: typo.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 5),
        LayoutBuilder(builder: (context, constraints) {
          final mode = _buildAdvanceModeSelector(presupuesto);
          final amount = SizedBox(
            width: 150,
            child: _buildAdvanceValueField(),
          );
          if (constraints.maxWidth >= 430) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(child: mode),
                const SizedBox(width: 8),
                amount,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              mode,
              const SizedBox(height: 6),
              amount,
            ],
          );
        }),
        const SizedBox(height: 6),
        Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: TextFormField(
              controller: _advanceDescriptionController,
              onChanged: (_) {
                _advanceDescriptionEdited = true;
                _configurationDirty = true;
              },
              decoration: InputDecoration(
                labelText: _isSpanish ? 'Descripción' : 'Description',
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildAmountPreview(context, cs, typo),
        const SizedBox(height: 6),
        _buildVatNotice(cs, typo),
      ],
    );
  }

  Widget _buildFinalForm(
    BuildContext context,
    ColorScheme cs,
    AppTypography typo,
    List<AdvanceInvoiceCandidate> candidates,
  ) {
    final availableIds = candidates.map((candidate) => candidate.id).toSet();
    final dropdownValue = availableIds.contains(_selectedAdvanceInvoiceId)
        ? _selectedAdvanceInvoiceId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: dropdownValue,
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(
                _isSpanish
                    ? 'Sin anticipo seleccionado'
                    : 'No advance invoice selected',
              ),
            ),
            ...candidates.map(
              (candidate) => DropdownMenuItem<String>(
                value: candidate.id,
                child: Text(
                  '${candidate.number}${candidate.status.trim().isEmpty ? '' : ' · ${candidate.status}'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedAdvanceInvoiceId =
                  (value ?? '').trim().isEmpty ? null : value;
              _configurationDirty = true;
            });
          },
          decoration: InputDecoration(
            labelText: _isSpanish ? 'Factura de anticipo' : 'Advance invoice',
            helperText: _isSpanish
                ? 'Opcional. Selecciona el anticipo que debe descontarse de la factura final.'
                : 'Optional. Select the advance invoice that should be deducted from the final invoice.',
            isDense: true,
          ),
        ),
        if (candidates.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _isSpanish
                ? 'No se encontraron facturas de anticipo enlazadas. Puedes crear la factura final sin seleccionar una, si procede.'
                : 'No linked advance invoices were found. You can still create the final invoice without selecting one if that is correct for this project.',
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildAmountPreview(context, cs, typo),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: TextFormField(
              controller: _finalNotesController,
              onChanged: (_) => _configurationDirty = true,
              decoration: InputDecoration(
                labelText: _isSpanish ? 'Descripción' : 'Description',
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildVatNotice(cs, typo),
      ],
    );
  }

  Widget _buildFullFinalForm(
    BuildContext context,
    ColorScheme cs,
    AppTypography typo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAmountPreview(context, cs, typo),
        const SizedBox(height: 8),
        _buildVatNotice(cs, typo),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _isSpanish
                ? 'Este presupuesto se facturará por el importe total porque no tiene anticipo asociado.'
                : 'This presupuesto will be invoiced for the full amount because it has no linked advance invoice.',
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
