import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_advance_final_flow.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
  final TextEditingController _searchController = TextEditingController();
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
  bool _loadingList = true;
  bool _refreshingList = false;
  bool _loadingDetail = false;
  bool _submitting = false;
  bool _previewingPdf = false;
  bool _showEligibleOnly = true;
  String? _listError;
  String? _detailError;
  String? _submitError;
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
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadPresupuestos(keepSelection: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  List<Map<String, dynamic>> get _visiblePresupuestos {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _presupuestos.where((item) {
      if (_showEligibleOnly && !isPresupuestoIssuedOrAccepted(item)) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = <String>[
        _presupuestoNumber(item),
        _presupuestoClientName(item),
        _presupuestoStatus(item),
        _presupuestoDate(item)?.toIso8601String() ?? '',
        (item['notes'] ?? '').toString(),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);

    filtered.sort((a, b) {
      final numberCompare = compareInvoiceLikeNumberDesc(
        _presupuestoNumber(a),
        _presupuestoNumber(b),
      );
      if (numberCompare != 0) return numberCompare;

      final bDate = _presupuestoDate(b);
      final aDate = _presupuestoDate(a);
      if (aDate != null && bDate != null) {
        final dateCompare = bDate.compareTo(aDate);
        if (dateCompare != 0) return dateCompare;
      } else if (aDate != null) {
        return -1;
      } else if (bDate != null) {
        return 1;
      }
      return _presupuestoNumber(a)
          .toLowerCase()
          .compareTo(_presupuestoNumber(b).toLowerCase());
    });
    return filtered;
  }

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
        } else {
          _refreshingList = true;
        }
        _listError = null;
      });
    }

    try {
      final items = await _presupuestosApi.listByGroup(
        groupId: widget.groupId,
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
      } else {
        final fallbackEligible = items.where((item) {
          return isPresupuestoIssuedOrAccepted(item) &&
              _presupuestoId(item).trim().isNotEmpty;
        });
        final fallbackAny = items.where(
          (item) => _presupuestoId(item).trim().isNotEmpty,
        );
        nextSelectedId = _presupuestoId(
          fallbackEligible.isNotEmpty
              ? fallbackEligible.first
              : (fallbackAny.isNotEmpty
                  ? fallbackAny.first
                  : const <String, dynamic>{}),
        ).trim();
        if (nextSelectedId.isEmpty) {
          nextSelectedId = null;
        }
      }

      setState(() {
        _presupuestos = List<Map<String, dynamic>>.unmodifiable(items);
        _loadingList = false;
        _refreshingList = false;
        _selectedPresupuestoId = nextSelectedId;
        if (nextSelectedId == null) {
          _selectedPresupuesto = null;
          _detailError = null;
          _loadingDetail = false;
          _formBudgetId = null;
          _submitError = null;
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
        _refreshingList = false;
      });
    } catch (e) {
      if (!mounted || requestId != _listRequestId) return;
      setState(() {
        _listError = e.toString().replaceFirst('Exception: ', '');
        _loadingList = false;
        _refreshingList = false;
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
    _advanceNotesController.clear();
    _finalNotesController.clear();

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

  Future<void> _selectPresupuesto(Map<String, dynamic> presupuesto) async {
    final presupuestoId = _presupuestoId(presupuesto).trim();
    if (presupuestoId.isEmpty) return;
    if (_selectedPresupuestoId == presupuestoId &&
        _selectedPresupuesto != null &&
        _detailError == null) {
      return;
    }
    await _loadPresupuestoDetail(presupuestoId, resetVisibleState: true);
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
        final useTwoColumns = constraints.maxWidth >= 1080;
        final listPanel = _buildListPanel(context, cs, typo);
        final detailPanel = _buildDetailPanel(context, cs, typo);

        if (!useTwoColumns) {
          return Column(
            children: [
              SizedBox(height: 280, child: listPanel),
              const SizedBox(height: 14),
              Expanded(child: detailPanel),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 300, child: listPanel),
            const SizedBox(width: 14),
            Expanded(child: detailPanel),
          ],
        );
      },
    );
  }

  Widget _buildListPanel(
    BuildContext context,
    ColorScheme cs,
    AppTypography typo,
  ) {
    final visiblePresupuestos = _visiblePresupuestos;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isSpanish
                        ? 'Seleccionar presupuesto'
                        : 'Select presupuesto',
                    style: typo.bodyLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _refreshingList
                      ? null
                      : () => _loadPresupuestos(keepSelection: true),
                  tooltip: _isSpanish ? 'Actualizar' : 'Refresh',
                  icon: _refreshingList
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close, size: 16),
                      ),
                hintText: _isSpanish
                    ? 'Buscar presupuesto...'
                    : 'Search presupuesto...',
                isDense: true,
                filled: true,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text(
                        _isSpanish ? 'Emitidos/Aceptados' : 'Issued/accepted',
                      ),
                      selected: _showEligibleOnly,
                      onSelected: (_) =>
                          setState(() => _showEligibleOnly = true),
                    ),
                    ChoiceChip(
                      label: Text(_isSpanish ? 'Todos' : 'All'),
                      selected: !_showEligibleOnly,
                      onSelected: (_) =>
                          setState(() => _showEligibleOnly = false),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _isSpanish
                        ? '${visiblePresupuestos.length} visibles'
                        : '${visiblePresupuestos.length} visible',
                    style: typo.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _listError != null && _presupuestos.isNotEmpty
                  ? Column(
                      children: [
                        _InlineErrorBanner(message: _listError!),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildPresupuestoList(
                            context,
                            cs,
                            typo,
                            visiblePresupuestos,
                          ),
                        ),
                      ],
                    )
                  : _buildPresupuestoList(
                      context,
                      cs,
                      typo,
                      visiblePresupuestos,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresupuestoList(
    BuildContext context,
    ColorScheme cs,
    AppTypography typo,
    List<Map<String, dynamic>> visiblePresupuestos,
  ) {
    if (visiblePresupuestos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 36,
                color: cs.onSurfaceVariant.withValues(alpha: 0.65),
              ),
              const SizedBox(height: 8),
              Text(
                _showEligibleOnly
                    ? (_isSpanish
                        ? 'No hay presupuestos emitidos o aceptados para convertir.'
                        : 'There are no issued or accepted quotes ready to convert.')
                    : (_isSpanish
                        ? 'No hay presupuestos para mostrar.'
                        : 'There are no quotes to show.'),
                textAlign: TextAlign.center,
                style: typo.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: visiblePresupuestos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final presupuesto = visiblePresupuestos[index];
        final presupuestoId = _presupuestoId(presupuesto).trim();
        final selected = presupuestoId == (_selectedPresupuestoId ?? '').trim();
        final status = _presupuestoStatus(presupuesto);
        final statusColor = _statusColor(cs, status);
        final total = _presupuestoTotal(presupuesto);

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _selectPresupuesto(presupuesto),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primaryContainer.withValues(alpha: 0.28)
                  : cs.surface.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? cs.primary.withValues(alpha: 0.92)
                    : cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: client name + total pill
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _presupuestoClientName(presupuesto),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typo.bodyMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (total != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _currencyFormatter.format(total),
                          style: typo.bodySmall.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Row 2: number · date + status pill
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_presupuestoNumber(presupuesto)} · ${_formatDate(_presupuestoDate(presupuesto))}',
                        style: typo.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    _TinyPill(
                      label: _formatStatusLabel(status),
                      background: statusColor.withValues(alpha: 0.18),
                      foreground: statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
            ? 'Elige un presupuesto a la izquierda para crear una factura de anticipo o final.'
            : 'Choose a presupuesto on the left to create an advance or final invoice.',
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
      final total = _presupuestoTotal(presupuesto);
      final canDoAnything = actionState != null &&
          (actionState.canCreateAdvance ||
              actionState.canCreateFinal ||
              actionState.canCreateFullFinal);

      child = SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar circle
                Container(
                  width: 40,
                  height: 40,
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
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: typo.bodyLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_presupuestoNumber(presupuesto)} · ${_formatDate(_presupuestoDate(presupuesto))}',
                        style: typo.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed:
                      _previewingPdf ? null : _previewSelectedPresupuesto,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: _previewingPdf
                      ? const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.visibility_outlined, size: 14),
                  label: Text(
                    _isSpanish ? 'Vista previa' : 'Preview',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // â”€â”€ Status + total strip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 6, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _formatStatusLabel(statusStr),
                          style: typo.bodySmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (total != null) ...[
                    Icon(Icons.payments_outlined,
                        size: 13, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      _currencyFormatter.format(total),
                      style: typo.bodyMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

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
            ] else ...[
              // Section label
              Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text(
                    _isSpanish ? 'Crear factura' : 'Create invoice',
                    style: typo.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<_PresupuestoConversionType>(
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                segments: [
                  ButtonSegment<_PresupuestoConversionType>(
                    value: _PresupuestoConversionType.advance,
                    icon: const Icon(Icons.percent_outlined, size: 15),
                    label: Text(_isSpanish ? 'Anticipo' : 'Advance'),
                    enabled: actionState.canCreateAdvance,
                  ),
                  ButtonSegment<_PresupuestoConversionType>(
                    value: _PresupuestoConversionType.finalInvoice,
                    icon: const Icon(Icons.receipt_long_outlined, size: 15),
                    label: Text(_isSpanish ? 'Final' : 'Final'),
                    enabled: actionState.canCreateFinal,
                  ),
                  ButtonSegment<_PresupuestoConversionType>(
                    value: _PresupuestoConversionType.fullFinalInvoice,
                    icon: const Icon(Icons.payments_outlined, size: 15),
                    label: Text(_isSpanish ? 'Completa' : 'Complete'),
                    enabled: actionState.canCreateFullFinal,
                  ),
                ],
                selected: {_conversionType},
                onSelectionChanged: (selected) {
                  setState(() => _conversionType = selected.first);
                },
              ),
              const SizedBox(height: 10),
              if (_submitError != null && _submitError!.trim().isNotEmpty) ...[
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
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _buildAdvanceForm(
    BuildContext context,
    ColorScheme cs,
    AppTypography typo,
  ) {
    final actionState = _selectedActionState;
    final presupuesto = _selectedPresupuesto;
    final vatSummary = presupuesto == null
        ? (_isSpanish
            ? 'Calculado automáticamente'
            : 'Calculated automatically')
        : _presupuestoVatSummaryLabel(presupuesto);
    final vatRates = presupuesto == null
        ? const <double>[]
        : _presupuestoVatRates(presupuesto);
    final vatRate = presupuesto == null ? 21.0 : _advanceVatRate(presupuesto);
    final fixedGross = _parseDouble(_advanceFixedAmountController.text);
    final fixedBase = fixedGross == null || fixedGross <= 0
        ? null
        : double.parse((fixedGross / (1 + vatRate / 100)).toStringAsFixed(2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<_AdvanceAmountMode>(
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
        ),
        const SizedBox(height: 8),
        if (_advanceAmountMode == _AdvanceAmountMode.percent)
          TextFormField(
            controller: _advancePercentController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (value) {
              final percent = _parseDouble(value);
              if (percent == null) return;
              _advanceDescriptionController.text = _isSpanish
                  ? 'Anticipo ${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 2)}% del presupuesto'
                  : 'Advance ${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 2)}% from quote';
            },
            decoration: InputDecoration(
              labelText: _isSpanish ? 'Porcentaje' : 'Percent',
              suffixText: '%',
              isDense: true,
            ),
          )
        else
          TextFormField(
            controller: _advanceFixedAmountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _isSpanish
                  ? 'Importe anticipo con IVA'
                  : 'Advance total incl. VAT',
              suffixText: '€',
              helperText: fixedBase == null
                  ? (_isSpanish
                      ? 'Introduce el total que quieres facturar.'
                      : 'Enter the total amount to invoice.')
                  : (_isSpanish
                      ? 'Base enviada: ${_currencyFormatter.format(fixedBase)} · IVA ${_formatVatRateLabel(vatRate)}'
                      : 'Base sent: ${_currencyFormatter.format(fixedBase)} · VAT ${_formatVatRateLabel(vatRate)}'),
              isDense: true,
            ),
          ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSpanish ? 'IVA detectado' : 'Detected VAT',
                style: typo.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.percent_outlined,
                    label: _isSpanish && vatRates.length > 1
                        ? 'IVA mixto'
                        : (_isSpanish ? 'IVA' : 'VAT'),
                    value: vatSummary,
                    tone: cs.primary,
                  ),
                  _InfoChip(
                    icon: Icons.auto_awesome_outlined,
                    label: _isSpanish
                        ? 'Calculado automáticamente'
                        : 'Calculated automatically',
                    value: _isSpanish
                        ? 'Según los conceptos'
                        : 'From presupuesto concepts',
                    tone: cs.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isSpanish
                    ? 'El IVA del anticipo se calcula automáticamente según los conceptos del presupuesto.'
                    : 'Advance VAT is calculated automatically from the presupuesto concepts.',
                style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _advanceDescriptionController,
          decoration: InputDecoration(
            labelText: _isSpanish ? 'Descripción' : 'Description',
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isSpanish
              ? 'Los importes y el desglose final del IVA se confirman con la respuesta del backend.'
              : 'Final totals and VAT breakdown are confirmed by the backend response.',
          style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: (_submitting || actionState?.canCreateAdvance != true)
                ? null
                : _submitAdvanceInvoice,
            icon: _submitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check_circle_outlined,
                    size: 16),
            label: Text(
              _isSpanish
                  ? 'Crear factura de anticipo'
                  : 'Create advance invoice',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalForm(
    BuildContext context,
    ColorScheme cs,
    AppTypography typo,
    List<AdvanceInvoiceCandidate> candidates,
  ) {
    final actionState = _selectedActionState;
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
        Text(
          _isSpanish
              ? 'El IVA y el desglose final se calculan automáticamente según los conceptos del presupuesto.'
              : 'VAT and the final tax breakdown are calculated automatically from the presupuesto concepts.',
          style: typo.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: (_submitting || actionState?.canCreateFinal != true)
                ? null
                : _submitFinalInvoice,
            icon: _submitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.request_quote_outlined, size: 16),
            label: Text(
              _isSpanish ? 'Crear factura final' : 'Create final invoice',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullFinalForm(
    BuildContext context,
    ColorScheme cs,
    AppTypography typo,
  ) {
    final actionState = _selectedActionState;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.withValues(alpha: 0.24)),
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
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Tooltip(
            message: 'Crear factura final por el importe total, sin anticipo',
            child: FilledButton.icon(
              onPressed:
                  (_submitting || actionState?.canCreateFullFinal != true)
                      ? null
                      : _submitFullFinalInvoice,
              icon: _submitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payments_outlined, size: 16),
              label: const Text('Crear factura completa'),
            ),
          ),
        ),
      ],
    );
  }
}
