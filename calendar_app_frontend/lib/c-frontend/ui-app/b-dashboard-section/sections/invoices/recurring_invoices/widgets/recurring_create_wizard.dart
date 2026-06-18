import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/a-models/invoice/invoice_concept_utils.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurring_invoices_helpers.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_client_step.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_preview_step.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_schedule_step.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_template_step.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/wizard_steps_header.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecurringCreateWizard extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final RecurringInvoicesApi api;
  final VoidCallback onCancel;
  final ValueChanged<Map<String, dynamic>> onCreated;
  final bool enableTaxes;
  final String draftScope;

  const RecurringCreateWizard({
    super.key,
    required this.group,
    required this.clients,
    required this.api,
    required this.onCancel,
    required this.onCreated,
    this.enableTaxes = true,
    this.draftScope = 'invoice',
  });

  @override
  State<RecurringCreateWizard> createState() => _RecurringCreateWizardState();
}

class _RecurringCreateWizardState extends State<RecurringCreateWizard> {
  static const int _draftVersion = 1;

  int _step = 0;
  String? _clientId;
  final List<InvoiceBlockDraft> _templateBlocks = [InvoiceBlockDraft.item()];
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _currencyCtrl =
      TextEditingController(text: 'EUR');
  final TextEditingController _discountAmountCtrl = TextEditingController();
  final TextEditingController _discountPercentCtrl = TextEditingController();
  bool _useDiscountPercent = false;

  String _freq = 'monthly';
  final TextEditingController _intervalCtrl = TextEditingController(text: '1');
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  String _endType = 'never';
  DateTime? _endDate;
  final TextEditingController _countCtrl = TextEditingController();
  final TextEditingController _billDayCtrl = TextEditingController();
  final TextEditingController _weekDayCtrl = TextEditingController();
  final TextEditingController _timezoneCtrl =
      TextEditingController(text: 'Europe/Madrid');
  final TextEditingController _invoiceDateDayCtrl = TextEditingController();
  final TextEditingController _invoiceDateOffsetDaysCtrl =
      TextEditingController(text: '0');
  String _invoiceDateMode = 'execution_day';
  String _invoiceDateClampPolicy = 'end_of_month';
  final String _detectedTimezone = detectTimezone();
  final List<DateTime> _exceptions = [];

  bool _loadingPreview = false;
  bool _saving = false;
  bool _created = false;
  String? _ruleErrorText;
  List<Map<String, String>> _previewRows = [];
  Timer? _draftSaveTimer;
  bool _restoringDraft = false;
  bool _draftDirty = false;
  bool _draftSaving = false;
  bool _skipDraftSaveOnDispose = false;
  bool _draftSaveFailed = false;
  String? _lastSavedDraftJson;

  String get _draftStorageKey =>
      'recurring_${widget.draftScope}_create_draft_v${_draftVersion}_${widget.group.id}';

  @override
  void initState() {
    super.initState();
    if (widget.clients.isNotEmpty) {
      _clientId = widget.clients.first.id;
    }
    _billDayCtrl.text = DateTime.now().day.toString();
    _startTime = TimeOfDay.fromDateTime(_startDate);
    _timezoneCtrl.text = _detectedTimezone;
    _attachDraftListeners();
    _restoreDraft();
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    if (_draftDirty && !_created && !_skipDraftSaveOnDispose) {
      _saveDraftNow();
    }
    for (final block in _templateBlocks) {
      block.dispose();
    }
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _currencyCtrl.dispose();
    _discountAmountCtrl.dispose();
    _discountPercentCtrl.dispose();
    _intervalCtrl.dispose();
    _countCtrl.dispose();
    _billDayCtrl.dispose();
    _weekDayCtrl.dispose();
    _timezoneCtrl.dispose();
    _invoiceDateDayCtrl.dispose();
    _invoiceDateOffsetDaysCtrl.dispose();
    super.dispose();
  }

  void _attachDraftListeners() {
    for (final ctrl in [
      _nameCtrl,
      _notesCtrl,
      _currencyCtrl,
      _discountAmountCtrl,
      _discountPercentCtrl,
      _intervalCtrl,
      _countCtrl,
      _billDayCtrl,
      _weekDayCtrl,
      _timezoneCtrl,
      _invoiceDateDayCtrl,
      _invoiceDateOffsetDaysCtrl,
    ]) {
      ctrl.addListener(_markDraftDirty);
    }
  }

  void _onChanged() {
    _markDraftDirty();
    setState(() {});
  }

  void _setDraftState(VoidCallback change) {
    setState(change);
    _markDraftDirty();
  }

  void _markDraftDirty() {
    if (_restoringDraft || _created) return;
    _draftDirty = true;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(seconds: 2), _saveDraftNow);
  }

  String _draftJson() => jsonEncode(_buildDraftPayload());

  Map<String, dynamic> _buildDraftPayload() {
    return {
      'version': _draftVersion,
      'step': _step,
      'clientId': _clientId,
      'name': _nameCtrl.text,
      'notes': _notesCtrl.text,
      'currency': _currencyCtrl.text,
      'discountAmount': _discountAmountCtrl.text,
      'discountPercent': _discountPercentCtrl.text,
      'useDiscountPercent': _useDiscountPercent,
      'freq': _freq,
      'interval': _intervalCtrl.text,
      'startDate': _startDate.toIso8601String(),
      'startTimeHour': _startTime.hour,
      'startTimeMinute': _startTime.minute,
      'endType': _endType,
      'endDate': _endDate?.toIso8601String(),
      'count': _countCtrl.text,
      'billDay': _billDayCtrl.text,
      'weekDay': _weekDayCtrl.text,
      'timezone': _timezoneCtrl.text,
      'invoiceDateMode': _invoiceDateMode,
      'invoiceDateDay': _invoiceDateDayCtrl.text,
      'invoiceDateOffsetDays': _invoiceDateOffsetDaysCtrl.text,
      'invoiceDateClampPolicy': _invoiceDateClampPolicy,
      'exceptions': _exceptions.map((d) => d.toIso8601String()).toList(),
      'previewRows': _previewRows,
      'blocks': _templateBlocks.map(_blockDraftToJson).toList(),
    };
  }

  Map<String, dynamic> _blockDraftToJson(InvoiceBlockDraft block) {
    return {
      ...block.toBlock().toJson(),
      'qtyText': block.qtyCtrl.text,
      'unitPriceText': block.unitPriceCtrl.text,
      'discountRateText': block.discountRateCtrl.text,
      'taxRateText': block.taxRateCtrl.text,
      'levelText': block.levelCtrl.text,
      'dateValue': block.dateValue,
      'isBillable': block.isBillable,
    };
  }

  InvoiceBlockDraft _blockDraftFromJson(Map<String, dynamic> json) {
    final items = json['items'] is List
        ? (json['items'] as List)
            .whereType<Map>()
            .map(
              (item) => InvoiceChecklistItemDraft(
                initialText: (item['text'] ?? '').toString(),
                checked: item['checked'] == true,
              ),
            )
            .toList()
        : <InvoiceChecklistItemDraft>[];
    return InvoiceBlockDraft(
      type: (json['type'] ?? InvoiceBlockType.item).toString(),
      sku: json['sku']?.toString(),
      conceptItems: json['conceptItems'] is List
          ? (json['conceptItems'] as List)
              .map((item) => item.toString())
              .toList()
          : null,
      conceptTitle: json['conceptTitle']?.toString(),
      serviceDate: cleanInvoiceServiceDate(json['serviceDate']),
      isCompositeConcept: json['isCompositeConcept'] is bool
          ? json['isCompositeConcept'] as bool
          : null,
      description: json['description']?.toString(),
      qty: (json['qtyText'] ?? json['qty'] ?? '1').toString(),
      unit: json['unit']?.toString(),
      unitPrice: (json['unitPriceText'] ?? json['unitPrice'] ?? '').toString(),
      discountRate:
          (json['discountRateText'] ?? json['discountRate'] ?? '0').toString(),
      taxRate: (json['taxRateText'] ?? json['taxRate'] ?? '21').toString(),
      level: (json['levelText'] ?? json['level'] ?? '').toString(),
      isBillable: json['isBillable'] is bool
          ? json['isBillable'] as bool
          : InvoiceBlockDraft.defaultBillableForType(
              (json['type'] ?? InvoiceBlockType.item).toString(),
            ),
      title: json['title']?.toString(),
      dateValue: json['dateValue']?.toString(),
      text: json['text']?.toString(),
      checklistItems: items,
    );
  }

  Future<void> _saveDraftNow() async {
    if (_created) return;
    _draftSaveTimer?.cancel();
    final json = _draftJson();
    if (json == _lastSavedDraftJson) {
      _draftDirty = false;
      _draftSaveFailed = false;
      return;
    }
    _draftSaving = true;
    if (mounted) setState(() {});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftStorageKey, json);
      _lastSavedDraftJson = json;
      _draftDirty = false;
      _draftSaveFailed = false;
    } catch (_) {
      _draftDirty = true;
      _draftSaveFailed = true;
    } finally {
      _draftSaving = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _restoreDraft() async {
    _restoringDraft = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftStorageKey);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final blocks = decoded['blocks'];
      final restoredBlocks = blocks is List
          ? blocks
              .whereType<Map>()
              .map((block) =>
                  _blockDraftFromJson(Map<String, dynamic>.from(block)))
              .toList()
          : <InvoiceBlockDraft>[];
      if (!mounted) return;
      setState(() {
        _step =
            (decoded['step'] is num ? (decoded['step'] as num).toInt() : _step)
                .clamp(0, 4);
        final restoredClientId = decoded['clientId']?.toString();
        if (restoredClientId != null &&
            widget.clients.any((client) => client.id == restoredClientId)) {
          _clientId = restoredClientId;
        }
        _nameCtrl.text = decoded['name']?.toString() ?? '';
        _notesCtrl.text = decoded['notes']?.toString() ?? '';
        _currencyCtrl.text = decoded['currency']?.toString() ?? 'EUR';
        _discountAmountCtrl.text = decoded['discountAmount']?.toString() ?? '';
        _discountPercentCtrl.text =
            decoded['discountPercent']?.toString() ?? '';
        _useDiscountPercent = decoded['useDiscountPercent'] == true;
        _freq = canonicalFrequencyForApi(decoded['freq']?.toString() ?? _freq);
        _intervalCtrl.text = decoded['interval']?.toString() ?? '1';
        _startDate =
            DateTime.tryParse(decoded['startDate']?.toString() ?? '') ??
                _startDate;
        _startTime = TimeOfDay(
          hour: decoded['startTimeHour'] is num
              ? (decoded['startTimeHour'] as num).toInt()
              : _startTime.hour,
          minute: decoded['startTimeMinute'] is num
              ? (decoded['startTimeMinute'] as num).toInt()
              : _startTime.minute,
        );
        _endType = decoded['endType']?.toString() ?? 'never';
        _endDate = DateTime.tryParse(decoded['endDate']?.toString() ?? '');
        _countCtrl.text = decoded['count']?.toString() ?? '';
        _billDayCtrl.text =
            decoded['billDay']?.toString() ?? DateTime.now().day.toString();
        _weekDayCtrl.text = decoded['weekDay']?.toString() ?? '';
        _timezoneCtrl.text =
            decoded['timezone']?.toString() ?? _detectedTimezone;
        _invoiceDateMode =
            decoded['invoiceDateMode']?.toString() ?? 'execution_day';
        _invoiceDateDayCtrl.text = decoded['invoiceDateDay']?.toString() ?? '';
        _invoiceDateOffsetDaysCtrl.text =
            decoded['invoiceDateOffsetDays']?.toString() ?? '0';
        _invoiceDateClampPolicy =
            decoded['invoiceDateClampPolicy']?.toString() ?? 'end_of_month';
        _exceptions
          ..clear()
          ..addAll(
            decoded['exceptions'] is List
                ? (decoded['exceptions'] as List)
                    .map((item) => DateTime.tryParse(item.toString()))
                    .whereType<DateTime>()
                : const <DateTime>[],
          );
        _previewRows = decoded['previewRows'] is List
            ? (decoded['previewRows'] as List)
                .whereType<Map>()
                .map((row) => row.map(
                      (key, value) =>
                          MapEntry(key.toString(), value.toString()),
                    ))
                .toList()
            : [];
        for (final block in _templateBlocks) {
          block.dispose();
        }
        _templateBlocks
          ..clear()
          ..addAll(restoredBlocks.isEmpty
              ? <InvoiceBlockDraft>[InvoiceBlockDraft.item()]
              : restoredBlocks);
      });
      _lastSavedDraftJson = raw;
      _draftDirty = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final l = AppLocalizations.of(context)!;
        final isEs = l.localeName.toLowerCase().startsWith('es');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEs ? 'Recuperamos tu borrador.' : 'We restored your draft.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    } catch (_) {
      // Ignore corrupt local drafts; the user can continue with a clean wizard.
    } finally {
      _restoringDraft = false;
    }
  }

  Future<void> _clearDraft() async {
    _draftSaveTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftStorageKey);
    _lastSavedDraftJson = null;
    _draftDirty = false;
  }

  Widget _draftStatusChip(AppTypography t, ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final text = _draftSaveFailed
        ? (isEs
            ? 'No se pudo guardar. Reintentando...'
            : 'Save failed. Retrying...')
        : _draftSaving
            ? (isEs ? 'Guardando...' : 'Saving...')
            : _draftDirty
                ? (isEs ? 'Cambios pendientes' : 'Pending changes')
                : (isEs ? 'Borrador guardado' : 'Draft saved');
    final icon = _draftSaveFailed
        ? Icons.cloud_off_outlined
        : _draftSaving
            ? Icons.sync_rounded
            : _draftDirty
                ? Icons.edit_note_rounded
                : Icons.cloud_done_outlined;
    final color = _draftSaveFailed
        ? cs.error
        : _draftSaving || _draftDirty
            ? cs.tertiary
            : cs.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: t.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel() async {
    if (!_draftDirty && !_draftSaving) {
      widget.onCancel();
      return;
    }
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Tienes cambios sin guardar' : 'Unsaved changes'),
        content: Text(
          isEs
              ? 'Aun estamos guardando tu borrador. Puedes quedarte, salir sin guardar, o guardar ahora y salir.'
              : 'Your draft is still being saved. You can stay, leave without saving, or save now and leave.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('stay'),
            child: Text(isEs ? 'Quedarme' : 'Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('leave'),
            child: Text(isEs ? 'Salir sin guardar' : 'Leave without saving'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: Text(isEs ? 'Guardar y salir' : 'Save & leave'),
          ),
        ],
      ),
    );
    if (!mounted || result == null || result == 'stay') return;
    if (result == 'leave') {
      _skipDraftSaveOnDispose = true;
      _draftSaveTimer?.cancel();
      _draftDirty = false;
    }
    if (result == 'save') {
      await _saveDraftNow();
      if (!mounted) return;
    }
    widget.onCancel();
  }

  String _timezoneLabel() => timezoneLabelFrom(
        _timezoneCtrl.text.trim().isEmpty
            ? _detectedTimezone
            : _timezoneCtrl.text.trim(),
      );

  num _blockSubtotal(InvoiceBlockDraft block) {
    if (!block.hasBillableContent) return 0;
    final qty = block.qty ?? 1;
    final price = block.unitPrice ?? 0;
    return qty * price;
  }

  num _blockTax(InvoiceBlockDraft block) {
    if (!widget.enableTaxes) return 0;
    if (!block.hasBillableContent) return 0;
    final taxRate = block.taxRate ?? 21;
    return _blockSubtotal(block) * (taxRate / 100);
  }

  num? _tryParseDiscountInput(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (!RegExp(r'^\d+([.,]\d{0,2})?$').hasMatch(value)) return null;
    return num.tryParse(value.replaceAll(',', '.'));
  }

  String? _discountAmountErrorText(AppLocalizations l) {
    if (_useDiscountPercent) return null;
    final raw = _discountAmountCtrl.text.trim();
    if (raw.isEmpty) return null;
    final parsed = _tryParseDiscountInput(raw);
    if (parsed == null) {
      return l.localeName.toLowerCase().startsWith('es')
          ? 'Introduce un importe valido (max 2 decimales).'
          : 'Enter a valid amount (max 2 decimals).';
    }
    if (parsed < 0) {
      return l.localeName.toLowerCase().startsWith('es')
          ? 'El descuento no puede ser negativo.'
          : 'Discount cannot be negative.';
    }
    return null;
  }

  String? _discountPercentErrorText(AppLocalizations l) {
    if (!_useDiscountPercent) return null;
    final raw = _discountPercentCtrl.text.trim();
    if (raw.isEmpty) return null;
    final parsed = _tryParseDiscountInput(raw);
    if (parsed == null) {
      return l.localeName.toLowerCase().startsWith('es')
          ? 'Introduce un porcentaje valido (max 2 decimales).'
          : 'Enter a valid percentage (max 2 decimals).';
    }
    if (parsed < 0 || parsed > 100) {
      return l.localeName.toLowerCase().startsWith('es')
          ? 'El porcentaje debe estar entre 0 y 100.'
          : 'Percentage must be between 0 and 100.';
    }
    return null;
  }

  String? _validateDiscountInputs(AppLocalizations l) {
    return _discountAmountErrorText(l) ?? _discountPercentErrorText(l);
  }

  num get _rawSubtotal =>
      _templateBlocks.fold<num>(0, (sum, b) => sum + _blockSubtotal(b));
  num get _rawTax =>
      _templateBlocks.fold<num>(0, (sum, b) => sum + _blockTax(b));

  num get _discountAmountValue {
    final v = _tryParseDiscountInput(_discountAmountCtrl.text) ?? 0;
    return v < 0 ? 0 : v;
  }

  num get _discountPercentValue {
    final v = _tryParseDiscountInput(_discountPercentCtrl.text) ?? 0;
    if (v < 0) return 0;
    if (v > 100) return 100;
    return v;
  }

  num get _effectiveDiscount {
    if (_rawSubtotal <= 0) return 0;
    if (!_useDiscountPercent && _discountAmountValue > 0) {
      return _discountAmountValue.clamp(0, _rawSubtotal);
    }
    if (_useDiscountPercent && _discountPercentValue > 0) {
      return (_rawSubtotal * _discountPercentValue) / 100;
    }
    return 0;
  }

  num get _subtotal {
    final v = _rawSubtotal - _effectiveDiscount;
    return v < 0 ? 0 : v;
  }

  num get _tax {
    if (_rawSubtotal <= 0) return 0;
    final ratio = _subtotal / _rawSubtotal;
    return _rawTax * ratio;
  }

  num get _total => _subtotal + _tax;

  void _setDiscountModePercent(bool value) {
    _setDraftState(() {
      _useDiscountPercent = value;
      if (value) {
        _discountAmountCtrl.clear();
      } else {
        _discountPercentCtrl.clear();
      }
    });
  }

  Map<String, dynamic> _buildDiscountPayload() {
    if (!_useDiscountPercent && _discountAmountValue > 0) {
      return {
        'discountAmount': _discountAmountValue,
        'discountPercent': 0,
      };
    }
    if (_useDiscountPercent && _discountPercentValue > 0) {
      return {
        'discountAmount': 0,
        'discountPercent': _discountPercentValue,
      };
    }
    return const {
      'discountAmount': 0,
      'discountPercent': 0,
    };
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(_startDate.year - 1),
      lastDate: DateTime(_startDate.year + 5),
    );
    if (date == null) return;
    _setDraftState(() {
      _startDate = DateTime(
        date.year,
        date.month,
        date.day,
        _startTime.hour,
        _startTime.minute,
      );
    });
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked == null) return;
    _setDraftState(() {
      _startTime = picked;
      _startDate = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(_startDate.year + 5),
    );
    if (date == null) return;
    _setDraftState(() => _endDate = date);
  }

  Future<void> _addException() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(_startDate.year - 1),
      lastDate: DateTime(_startDate.year + 5),
    );
    if (date == null) return;
    _setDraftState(() => _exceptions.add(date));
  }

  Future<void> _pickTimezone() async {
    final selected = await showTimezonePicker(
      context: context,
      initial: _timezoneCtrl.text.trim().isEmpty
          ? _detectedTimezone
          : _timezoneCtrl.text.trim(),
    );
    if (selected == null) return;
    _setDraftState(() => _timezoneCtrl.text = selected);
  }

  Map<String, dynamic> _buildRule() {
    final interval = int.tryParse(_intervalCtrl.text.trim()) ?? 1;
    final billDay = int.tryParse(_billDayCtrl.text.trim());
    final weekDay = int.tryParse(_weekDayCtrl.text.trim());
    final count = int.tryParse(_countCtrl.text.trim());
    final tzName = _timezoneCtrl.text.trim();
    final utcDate = utcDateString(_startDate, _startTime, tzName);
    final utcTime = utcTimeString(_startDate, _startTime, tzName);
    final rule = <String, dynamic>{
      'freq': canonicalFrequencyForApi(_freq),
      'frequency': canonicalFrequencyForApi(_freq),
      'interval': interval,
      'startDate': utcDate,
      'timeOfDay': utcTime,
      'timezone': _timezoneCtrl.text.trim().isEmpty
          ? 'Europe/Madrid'
          : _timezoneCtrl.text.trim(),
    };
    final canonicalFreq = canonicalFrequencyForApi(_freq);
    if ((canonicalFreq == recurringFreqMonthly ||
            canonicalFreq == recurringFreqBimensual ||
            canonicalFreq == recurringFreqTrimestral) &&
        billDay != null) {
      rule['billDay'] = billDay;
    } else if (canonicalFreq == recurringFreqWeekly && weekDay != null) {
      rule['billDay'] = weekDay;
    }
    if (_endType == 'date' && _endDate != null) {
      rule['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    } else if (_endType == 'count' && count != null) {
      rule['count'] = count;
    }
    if (_exceptions.isNotEmpty) {
      rule['exceptions'] = _exceptions
          .map((d) => utcDateString(d, _startTime, _timezoneCtrl.text))
          .toList();
    }
    return rule;
  }

  String _issuePolicySummary(AppLocalizations l) {
    final source = <String, dynamic>{
      'invoiceDateMode': _invoiceDateMode,
      'invoiceDateClampPolicy': _invoiceDateClampPolicy,
      'invoiceDateDay': int.tryParse(_invoiceDateDayCtrl.text.trim()),
      'invoiceDateOffsetDays':
          int.tryParse(_invoiceDateOffsetDaysCtrl.text.trim()),
    };
    return recurringIssueDatePolicySummary(source, l);
  }

  String? _validateIssuePolicy(AppLocalizations l) {
    if (_invoiceDateMode == 'fixed_day') {
      final day = int.tryParse(_invoiceDateDayCtrl.text.trim());
      if (day == null || day < 1 || day > 31) {
        return l.localeName.toLowerCase().startsWith('es')
            ? 'Debes indicar un dia de factura valido (1-31).'
            : 'Invoice day is required (1-31).';
      }
    }
    if (_invoiceDateMode == 'offset_days') {
      final offset = int.tryParse(_invoiceDateOffsetDaysCtrl.text.trim());
      if (offset == null || offset < -365 || offset > 365) {
        return l.localeName.toLowerCase().startsWith('es')
            ? 'Debes indicar un desfase valido (-365..365).'
            : 'Offset is required (-365..365).';
      }
    }
    return null;
  }

  String _blockDescription(InvoiceBlockDraft block) {
    final description = block.description.text.trim();
    if (description.isNotEmpty) return description;
    final title = block.title.text.trim();
    if (title.isNotEmpty) return title;
    if (block.checklistItems.isNotEmpty) {
      return block.checklistItems.first.text.text.trim();
    }
    return '';
  }

  List<Map<String, dynamic>> _buildLines() {
    var position = 1;
    return _templateBlocks
        .where((block) => block.hasBillableContent)
        .map((block) {
      final sku = block.sku.text.trim();
      final unit = block.unitCtrl.text.trim();
      final conceptItems = cleanInvoiceConceptItems(
        block.conceptItems,
        staleSku: sku,
      );
      final conceptTitle = invoiceConceptTitleFrom(
        conceptTitle: block.conceptTitle,
        sku: sku,
      );
      return {
        'position': position++,
        'description': _blockDescription(block),
        if (sku.isNotEmpty && isInvoiceUnitCode(sku)) 'sku': sku,
        if (conceptTitle != null) 'conceptTitle': conceptTitle,
        if (conceptItems != null) 'conceptItems': conceptItems,
        if (block.serviceDate != null)
          'serviceDate': cleanInvoiceServiceDate(block.serviceDate),
        if (block.isCompositeConcept != null)
          'isCompositeConcept': block.isCompositeConcept
        else if ((conceptItems?.length ?? 0) > 1)
          'isCompositeConcept': true,
        if (unit.isNotEmpty) 'unit': unit,
        'quantity': block.qty ?? 1,
        'unitPrice': block.unitPrice ?? 0,
        'taxRate': widget.enableTaxes ? (block.taxRate ?? 21) : 0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildBlocks() {
    return _templateBlocks
        .where((block) => block.hasBillableContent)
        .map((block) => block.toBlock().toJson())
        .toList();
  }

  Future<void> _loadPreview() async {
    if (_loadingPreview) return;
    setState(() => _loadingPreview = true);
    try {
      final rule = _buildRule();
      final canonicalFreq = canonicalFrequencyForApi(_freq);
      final payload = {
        'rule': rule,
        // Keep both formats for backend compatibility.
        'frequency': canonicalFreq,
        'freq': canonicalFreq,
        'interval': int.tryParse(_intervalCtrl.text.trim()) ?? 1,
        'startDate': rule['startDate'],
        'timeOfDay': rule['timeOfDay'],
        'timezone': rule['timezone'],
        if ((canonicalFreq == recurringFreqMonthly ||
                canonicalFreq == recurringFreqBimensual ||
                canonicalFreq == recurringFreqTrimestral) &&
            rule['billDay'] != null)
          'billDay': rule['billDay'],
        if (canonicalFreq == recurringFreqWeekly && rule['billDay'] != null)
          'billDay': rule['billDay'],
        if (rule['endDate'] != null) 'endDate': rule['endDate'],
        if (rule['count'] != null) 'count': rule['count'],
        if (rule['exceptions'] != null) 'exceptions': rule['exceptions'],
        'invoiceDateMode': _invoiceDateMode,
        'invoiceDateClampPolicy': _invoiceDateClampPolicy,
        if (_invoiceDateMode == 'fixed_day')
          'invoiceDateDay': int.tryParse(_invoiceDateDayCtrl.text.trim()),
        if (_invoiceDateMode == 'offset_days')
          'invoiceDateOffsetDays':
              int.tryParse(_invoiceDateOffsetDaysCtrl.text.trim()),
      };
      final result = await widget.api.preview(payload);
      final rows = <Map<String, String>>[];
      final items = result['items'];
      if (items is List) {
        for (final item in items) {
          if (item is! Map) continue;
          final row = Map<String, dynamic>.from(item);
          rows.add({
            'executionAt':
                (row['executionAt'] ?? row['execution_at'] ?? '-').toString(),
            'issueDate':
                (row['issueDate'] ?? row['issue_date'] ?? '-').toString(),
            'error': (row['error'] ?? '').toString(),
          });
        }
      } else {
        final dates = result['dates'];
        if (dates is List) {
          for (final item in dates) {
            rows.add({
              'executionAt': item.toString(),
              'issueDate': '-',
              'error': '',
            });
          }
        }
      }
      if (mounted) {
        setState(() {
          _previewRows = rows;
          _ruleErrorText = null;
        });
        _markDraftDirty();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    final l = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.recurringInvoicesNameRequired)));
      return;
    }
    if (_clientId == null || _clientId!.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invoiceClientRequired)));
      return;
    }
    final billableBlocks =
        _templateBlocks.where((block) => block.hasBillableContent).toList();
    if (billableBlocks.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invoiceLinesRequired)));
      return;
    }
    final policyError = _validateIssuePolicy(l);
    if (policyError != null) {
      setState(() => _ruleErrorText = policyError);
      if (_step < 3) _setDraftState(() => _step = 3);
      return;
    }
    final discountValidationError = _validateDiscountInputs(l);
    if (discountValidationError != null) {
      if (_step != 2) _setDraftState(() => _step = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(discountValidationError)),
      );
      return;
    }
    final tz = _timezoneCtrl.text.trim();
    final utcStartDate = utcDateString(_startDate, _startTime, tz);
    final utcTimeOfDay = utcTimeString(_startDate, _startTime, tz);
    final payload = {
      'groupId': widget.group.id,
      'clientId': _clientId,
      'name': name,
      'frequency': canonicalFrequencyForApi(_freq),
      'interval': int.tryParse(_intervalCtrl.text.trim()) ?? 1,
      'startDate': utcStartDate,
      if (_endType == 'date' && _endDate != null)
        'endDate': utcDateString(_endDate!, _startTime, tz),
      if (_endType == 'count' && int.tryParse(_countCtrl.text.trim()) != null)
        'count': int.tryParse(_countCtrl.text.trim()),
      if ((canonicalFrequencyForApi(_freq) == recurringFreqMonthly ||
          canonicalFrequencyForApi(_freq) == recurringFreqBimensual ||
          canonicalFrequencyForApi(_freq) == recurringFreqTrimestral))
        'billDay': int.tryParse(_billDayCtrl.text.trim()),
      if (canonicalFrequencyForApi(_freq) == recurringFreqWeekly)
        'billDay': int.tryParse(_weekDayCtrl.text.trim()),
      'timeOfDay': utcTimeOfDay,
      'timezone': _timezoneCtrl.text.trim().isEmpty
          ? 'Europe/Madrid'
          : _timezoneCtrl.text.trim(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      if (_currencyCtrl.text.trim().isNotEmpty)
        'currency': _currencyCtrl.text.trim(),
      if (_exceptions.isNotEmpty)
        'exceptions': _exceptions
            .map((d) => utcDateString(d, _startTime, _timezoneCtrl.text))
            .toList(),
      'status': 'active',
      'invoiceDateMode': _invoiceDateMode,
      'invoiceDateClampPolicy': _invoiceDateClampPolicy,
      if (_invoiceDateMode == 'fixed_day')
        'invoiceDateDay': int.tryParse(_invoiceDateDayCtrl.text.trim()),
      if (_invoiceDateMode == 'offset_days')
        'invoiceDateOffsetDays':
            int.tryParse(_invoiceDateOffsetDaysCtrl.text.trim()),
      'rule': _buildRule(),
      'lines': _buildLines(),
      'blocks': _buildBlocks(),
      ..._buildDiscountPayload(),
      'totals': {
        'subtotal': _subtotal,
        'taxTotal': _tax,
        'total': _total,
      },
    };
    setState(() => _saving = true);
    try {
      final created = await widget.api.create(payload);
      if (!mounted) return;
      setState(() => _created = true);
      await _clearDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.recurringInvoicesCreateSuccess)),
      );
      widget.onCreated(created);
    } catch (e) {
      if (!mounted) return;
      final err = e.toString();
      if (err.contains('(400)')) {
        setState(() => _ruleErrorText = err);
      }
      final msg = e.toString().trim().isEmpty
          ? l.recurringInvoicesCreateFailed
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final selectedClientName = _clientId == null
        ? null
        : widget.clients
            .firstWhere(
              (c) => c.id == _clientId,
              orElse: () => GroupClient(id: '', name: ''),
            )
            .name
            .trim();
    final clientLabel =
        (selectedClientName == null || selectedClientName.isEmpty)
            ? '-'
            : selectedClientName;

    Widget wrapStepContent(Widget child) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: child,
      );
    }

    Text stepTitle(String value, int index) => Text(
          value,
          style: t.bodyLarge.copyWith(
            fontWeight: _step == index ? FontWeight.w900 : FontWeight.w700,
            color: _step == index ? cs.onSurface : cs.onSurfaceVariant,
          ),
        );

    final steps = [
      Step(
        title: stepTitle(l.recurringInvoicesStepClient, 0),
        content: wrapStepContent(
          RecurringWizardClientStep(
            clients: widget.clients,
            clientId: _clientId,
            onClientChanged: (v) => _setDraftState(() => _clientId = v),
            nameCtrl: _nameCtrl,
            currencyCtrl: _currencyCtrl,
            notesCtrl: _notesCtrl,
            showRuleFields: false,
          ),
        ),
        state: _step > 0 ? StepState.complete : StepState.indexed,
        isActive: _step >= 0,
      ),
      Step(
        title: stepTitle(l.recurringInvoicesNameLabel, 1),
        content: wrapStepContent(
          _RecurringWizardRuleDetailsStep(
            nameCtrl: _nameCtrl,
            currencyCtrl: _currencyCtrl,
            notesCtrl: _notesCtrl,
          ),
        ),
        state: _step > 1 ? StepState.complete : StepState.indexed,
        isActive: _step >= 1,
      ),
      Step(
        title: stepTitle(l.recurringInvoicesStepTemplate, 2),
        content: wrapStepContent(
          RecurringWizardTemplateStep(
            blocks: _templateBlocks,
            onChanged: _onChanged,
            discountAmountCtrl: _discountAmountCtrl,
            discountPercentCtrl: _discountPercentCtrl,
            useDiscountPercent: _useDiscountPercent,
            onDiscountModeChanged: _setDiscountModePercent,
            discountAmount: _effectiveDiscount,
            total: _total,
          ),
        ),
        state: _step > 2 ? StepState.complete : StepState.indexed,
        isActive: _step >= 2,
      ),
      Step(
        title: stepTitle(l.recurringInvoicesStepSchedule, 3),
        content: wrapStepContent(
          RecurringWizardScheduleStep(
            freq: _freq,
            intervalCtrl: _intervalCtrl,
            startDate: _startDate,
            endType: _endType,
            endDate: _endDate,
            countCtrl: _countCtrl,
            billDayCtrl: _billDayCtrl,
            weekDayCtrl: _weekDayCtrl,
            timezoneCtrl: _timezoneCtrl,
            invoiceDateMode: _invoiceDateMode,
            invoiceDateDayCtrl: _invoiceDateDayCtrl,
            invoiceDateOffsetDaysCtrl: _invoiceDateOffsetDaysCtrl,
            invoiceDateClampPolicy: _invoiceDateClampPolicy,
            timezoneLabel: _timezoneLabel(),
            exceptions: _exceptions,
            onFreqChanged: (v) =>
                _setDraftState(() => _freq = canonicalFrequencyForApi(v)),
            onPickStart: _pickStartDate,
            onPickStartTime: _pickStartTime,
            onPickEnd: _pickEndDate,
            onEndTypeChanged: (v) => _setDraftState(() => _endType = v),
            onTimezoneChanged: (_) => _onChanged(),
            onPickTimezone: _pickTimezone,
            onAddException: _addException,
            onRemoveException: (d) =>
                _setDraftState(() => _exceptions.remove(d)),
            onInvoiceDateModeChanged: (v) =>
                _setDraftState(() => _invoiceDateMode = v),
            onInvoiceDateClampPolicyChanged: (v) =>
                _setDraftState(() => _invoiceDateClampPolicy = v),
            errorText: _ruleErrorText,
          ),
        ),
        state: _step > 3 ? StepState.complete : StepState.indexed,
        isActive: _step >= 3,
      ),
      Step(
        title: stepTitle(l.recurringInvoicesStepPreview, 4),
        content: wrapStepContent(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_created)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.tertiary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: cs.onTertiaryContainer,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.recurringInvoicesCreateSuccess,
                          style: t.bodySmall.copyWith(
                            color: cs.onTertiaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_created) const SizedBox(height: 10),
              RecurringWizardPreviewStep(
                freq: _freq,
                intervalCtrl: _intervalCtrl,
                startDate: _startDate,
                endType: _endType,
                endDate: _endDate,
                countCtrl: _countCtrl,
                billDayCtrl: _billDayCtrl,
                weekDayCtrl: _weekDayCtrl,
                timezoneLabel: _timezoneLabel(),
                exceptions: _exceptions,
                loadingPreview: _loadingPreview,
                previewRows: _previewRows,
                onLoadPreview: _loadPreview,
                issueDatePolicySummary: _issuePolicySummary(l),
                partialSubtotal: _rawSubtotal,
                discountAmount: _effectiveDiscount,
                taxableBase: _subtotal,
                tax: _tax,
                total: _total,
                showTax: widget.enableTaxes,
              ),
            ],
          ),
        ),
        state: _step > 4 ? StepState.complete : StepState.indexed,
        isActive: _step >= 4,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: FolderPanel(
              title: l.recurringInvoicesCreateTitle,
              onBack: _handleCancel,
              showTab: true,
              contentTopPadding: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: isWide ? 60 : null,
                                  child: WizardStepsHeader(
                                    steps: steps,
                                    currentStep: _step,
                                    isWide: isWide,
                                    height: isWide ? 60 : null,
                                    onStepContinue: () {
                                      if (_step == 1 &&
                                          _nameCtrl.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l.recurringInvoicesNameRequired,
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      if (_step == 2 &&
                                          !_templateBlocks.any(
                                            (block) => block.hasBillableContent,
                                          )) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l.invoiceLinesRequired,
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      if (_step < steps.length - 1) {
                                        _setDraftState(() => _step += 1);
                                      } else {
                                        _submit();
                                      }
                                    },
                                    onStepCancel: () {
                                      if (_step == 0) {
                                        _handleCancel();
                                      } else {
                                        _setDraftState(() => _step -= 1);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _draftStatusChip(t, cs),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () => _setDraftState(() => _step = 0),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        color: cs.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 220),
                                        child: Text(
                                          '${l.invoiceClientLabel}: $clientLabel',
                                          style: t.bodySmall.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () {
                                        if (_step == 0) {
                                          _handleCancel();
                                        } else {
                                          _setDraftState(() => _step -= 1);
                                        }
                                      },
                                child: Text(l.recurringInvoicesBackCta),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: _saving
                                    ? null
                                    : () {
                                        if (_step == 1 &&
                                            _nameCtrl.text.trim().isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l.recurringInvoicesNameRequired,
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (_step == 2 &&
                                            !_templateBlocks.any(
                                              (block) =>
                                                  block.hasBillableContent,
                                            )) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l.invoiceLinesRequired,
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        if (_step < steps.length - 1) {
                                          _setDraftState(() => _step += 1);
                                        } else {
                                          _submit();
                                        }
                                      },
                                child: Text(
                                  _step == steps.length - 1
                                      ? (_saving
                                          ? l.recurringInvoicesSavingRule
                                          : l.recurringInvoicesCreateCta)
                                      : l.recurringInvoicesContinueCta,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _step == 2
                                ? steps[_step].content
                                : SingleChildScrollView(
                                    child: steps[_step].content,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecurringWizardRuleDetailsStep extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController currencyCtrl;
  final TextEditingController notesCtrl;

  const _RecurringWizardRuleDetailsStep({
    required this.nameCtrl,
    required this.currencyCtrl,
    required this.notesCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final wide = MediaQuery.of(context).size.width >= 900;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    );

    InputDecoration fieldDecoration({required String label, IconData? icon}) {
      return InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        labelStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
        isDense: true,
        filled: true,
        fillColor: cs.surface,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: nameCtrl,
                  style: t.bodyMedium,
                  decoration: fieldDecoration(
                    label: l.recurringInvoicesNameLabel,
                    icon: Icons.edit_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: currencyCtrl,
                  style: t.bodyMedium,
                  decoration: fieldDecoration(
                    label: l.currencyLabel,
                    icon: Icons.currency_exchange_outlined,
                  ),
                ),
              ),
            ],
          )
        else ...[
          TextFormField(
            controller: nameCtrl,
            style: t.bodyMedium,
            decoration: fieldDecoration(
              label: l.recurringInvoicesNameLabel,
              icon: Icons.edit_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: currencyCtrl,
            style: t.bodyMedium,
            decoration: fieldDecoration(
              label: l.currencyLabel,
              icon: Icons.currency_exchange_outlined,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: notesCtrl,
          maxLines: 2,
          style: t.bodyMedium,
          decoration: fieldDecoration(
            label: l.notesLabel,
            icon: Icons.sticky_note_2_outlined,
          ),
        ),
      ],
    );
  }
}
