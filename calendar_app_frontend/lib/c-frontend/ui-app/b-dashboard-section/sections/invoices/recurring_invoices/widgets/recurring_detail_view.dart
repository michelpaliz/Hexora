import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurring_invoices_helpers.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_generated_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_rule_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_template_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/series_status_pill.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';

class RecurringDetailView extends StatefulWidget {
  final RecurringInvoicesApi api;
  final Map<String, dynamic> series;
  final Group group;
  final List<GroupClient> clients;
  final bool canManage;
  final bool enableTaxes;
  final VoidCallback onBack;
  final VoidCallback onUpdated;

  const RecurringDetailView({
    super.key,
    required this.api,
    required this.series,
    required this.group,
    required this.clients,
    required this.canManage,
    this.enableTaxes = true,
    required this.onBack,
    required this.onUpdated,
  });

  @override
  State<RecurringDetailView> createState() => _RecurringDetailViewState();
}

class _RecurringDetailViewState extends State<RecurringDetailView> {
  final _invoicesApi = InvoicesApi();

  late String _freq;
  late TextEditingController _intervalCtrl;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late String _endType;
  DateTime? _endDate;
  late TextEditingController _countCtrl;
  late TextEditingController _billDayCtrl;
  late TextEditingController _weekDayCtrl;
  late TextEditingController _timezoneCtrl;
  late String _invoiceDateMode;
  late String _invoiceDateClampPolicy;
  late TextEditingController _invoiceDateDayCtrl;
  late TextEditingController _invoiceDateOffsetDaysCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _discountAmountCtrl;
  late TextEditingController _discountPercentCtrl;
  bool _useDiscountPercent = false;
  final List<DateTime> _exceptions = [];

  late List<LineDraft> _lines;

  bool _savingRule = false;
  bool _savingTemplate = false;
  bool _loadingGenerated = false;
  String? _generatedError;
  List<Invoice> _generated = [];
  bool _generatedRequested = false;
  int? _generatedCount;
  String? _ruleErrorText;

  @override
  void initState() {
    super.initState();
    _hydrateFromSeries();
  }

  @override
  void didUpdateWidget(covariant RecurringDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = seriesId(oldWidget.series);
    final nextId = seriesId(widget.series);
    if (oldId == nextId) return;
    _hydrateFromSeries(disposeExisting: true);
  }

  @override
  void dispose() {
    _disposeFormState();
    super.dispose();
  }

  void _disposeFormState() {
    _intervalCtrl.dispose();
    _countCtrl.dispose();
    _billDayCtrl.dispose();
    _weekDayCtrl.dispose();
    _timezoneCtrl.dispose();
    _invoiceDateDayCtrl.dispose();
    _invoiceDateOffsetDaysCtrl.dispose();
    _notesCtrl.dispose();
    _currencyCtrl.dispose();
    _discountAmountCtrl.dispose();
    _discountPercentCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
  }

  void _hydrateFromSeries({bool disposeExisting = false}) {
    if (disposeExisting) {
      _disposeFormState();
      _exceptions.clear();
    }
    final rule = (widget.series['rule'] as Map?) ?? const {};
    dynamic field(String key) => rule[key] ?? widget.series[key];

    final rawFreq = rule['freq'] ??
        rule['frequency'] ??
        widget.series['freq'] ??
        widget.series['frequency'];
    _freq = normalizeFrequencyFromApi((rawFreq ?? recurringFreqMonthly).toString());
    _intervalCtrl = TextEditingController(
      text: (field('interval') ?? 1).toString(),
    );
    _startDate = parseDate(field('startDate')) ?? DateTime.now();
    final tzName = (field('timezone') ?? detectTimezone()).toString();
    final timeOfDay = parseTimeOfDay(field('timeOfDay'));
    if (timeOfDay != null) {
      // Interpret timeOfDay as LOCAL time (not UTC) to preserve clock time across DST
      final location = tryGetLocation(tzName);
      if (location != null) {
        _startDate = tz.TZDateTime(
          location,
          _startDate.year,
          _startDate.month,
          _startDate.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );
      } else {
        _startDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );
      }
      _startTime = timeOfDay;
    } else {
      _startTime = TimeOfDay.fromDateTime(_startDate);
    }
    _timezoneCtrl = TextEditingController(text: tzName);
    _billDayCtrl = TextEditingController(
      text: (field('billDay') ?? DateTime.now().day).toString(),
    );
    _weekDayCtrl = TextEditingController(
      text: (field('billDay') ?? '').toString(),
    );
    _endDate = parseDate(field('endDate'));
    final count = field('count');
    _countCtrl = TextEditingController(text: count?.toString() ?? '');
    _endType = _endDate != null ? 'date' : (count != null ? 'count' : 'never');
    _invoiceDateMode = recurringInvoiceDateModeFrom(widget.series);
    _invoiceDateClampPolicy =
        recurringInvoiceDateClampPolicyFrom(widget.series);
    _invoiceDateDayCtrl = TextEditingController(
      text: (recurringInvoiceDateDayFrom(widget.series) ?? '').toString(),
    );
    _invoiceDateOffsetDaysCtrl = TextEditingController(
      text: (recurringInvoiceDateOffsetDaysFrom(widget.series) ?? 0).toString(),
    );
    _notesCtrl = TextEditingController(
      text: (widget.series['notes'] ?? '').toString(),
    );
    _currencyCtrl = TextEditingController(
      text: (widget.series['currency'] ?? 'EUR').toString(),
    );
    num? parseNum(dynamic raw) {
      if (raw == null) return null;
      if (raw is num) return raw;
      return num.tryParse(raw.toString().trim().replaceAll(',', '.'));
    }
    final discountAmount = parseNum(widget.series['discountAmount']) ?? 0;
    final discountPercent = parseNum(widget.series['discountPercent']) ?? 0;
    _discountAmountCtrl = TextEditingController(
      text: discountAmount > 0 ? discountAmount.toString() : '',
    );
    _discountPercentCtrl = TextEditingController(
      text: discountPercent > 0 ? discountPercent.toString() : '',
    );
    _useDiscountPercent = discountPercent > 0 && discountAmount <= 0;

    final exceptions = field('exceptions');
    if (exceptions is List) {
      for (final e in exceptions) {
        final d = parseDate(e);
        if (d != null) _exceptions.add(d);
      }
    }

    _lines = buildLineDrafts(
      widget.series,
      defaultTaxRate: widget.enableTaxes ? 21 : 0,
    );
    _generatedError = null;
    _generated = [];
    _generatedRequested = false;
    _generatedCount = null;
    _loadingGenerated = false;
    _ruleErrorText = null;
  }

  Future<void> _loadGenerated() async {
    final series = seriesId(widget.series);
    if (series.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _loadingGenerated = true;
      _generatedError = null;
      _generatedRequested = true;
    });
    try {
      final result = await widget.api.listGeneratedInvoices(series);
      if (!mounted) return;
      setState(() {
        _generated = result.invoices;
        _generatedCount = result.count;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _generatedError = e.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loadingGenerated = false);
    }
  }

  String _fileNameFromHeaders(Map<String, String> headers, Invoice invoice) {
    final raw =
        headers['content-disposition'] ?? headers['Content-Disposition'];
    if (raw != null && raw.isNotEmpty) {
      final utf8Match =
          RegExp(r"filename\\*=UTF-8''([^;]+)", caseSensitive: false)
              .firstMatch(raw);
      if (utf8Match != null) {
        final name = Uri.decodeComponent(utf8Match.group(1)!);
        if (name.trim().isNotEmpty) return name;
      }
      final match = RegExp(r'filename="?([^";]+)"?', caseSensitive: false)
          .firstMatch(raw);
      if (match != null) {
        final name = match.group(1);
        if (name != null && name.trim().isNotEmpty) return name.trim();
      }
    }
    final fallback = invoice.invoiceNumber.trim().isNotEmpty
        ? invoice.invoiceNumber.trim()
        : invoice.id.trim();
    return fallback.endsWith('.pdf') ? fallback : 'invoice-$fallback.pdf';
  }

  Future<void> _downloadInvoicePdf(Invoice invoice) async {
    if (invoice.id.trim().isEmpty) return;
    try {
      final r = await _invoicesApi.downloadPdf(invoice.id);
      final fileName = _fileNameFromHeaders(r.headers, invoice);
      await launchFileDownload(
        r.bodyBytes,
        fileName: fileName,
        mimeType: 'application/pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<Invoice> _loadGeneratedInvoiceDetails(String invoiceId) {
    return _invoicesApi.getById(invoiceId);
  }

  Future<Uint8List> _loadGeneratedInvoicePreviewBytes(String invoiceId) async {
    final response = await _invoicesApi.previewPdf(invoiceId);
    return InvoiceEditorPdf.validatePdf(response);
  }

  void _openInvoice(Invoice invoice) {
    final client = widget.clients.firstWhere(
      (c) => c.id == invoice.clientId,
      orElse: () => GroupClient(
        id: invoice.clientId,
        name: AppLocalizations.of(context)!.unknownClient,
        isActive: true,
      ),
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InvoiceDetailSheet(
        invoice: invoice,
        client: client,
        billingProfile: null,
        group: widget.group,
        onOpenRecurringSeries: null,
      ),
    );
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
      'timezone': _timezoneCtrl.text.trim().isNotEmpty
          ? _timezoneCtrl.text.trim()
          : 'Europe/Madrid',
    };
    final canonicalFreq = canonicalFrequencyForApi(_freq);
    if ((canonicalFreq == recurringFreqMonthly || canonicalFreq == recurringFreqBimensual || canonicalFreq == recurringFreqTrimestral) && billDay != null) {
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

  Future<void> _saveRule() async {
    if (_savingRule) return;
    final id = seriesId(widget.series);
    if (id.isEmpty) return;
    setState(() => _savingRule = true);
    try {
      final l = AppLocalizations.of(context)!;
      final count = int.tryParse(_countCtrl.text.trim());
      final invoiceDay = int.tryParse(_invoiceDateDayCtrl.text.trim());
      final invoiceOffset =
          int.tryParse(_invoiceDateOffsetDaysCtrl.text.trim());
      if (_invoiceDateMode == 'fixed_day') {
        if (invoiceDay == null || invoiceDay < 1 || invoiceDay > 31) {
          setState(() {
            _ruleErrorText = l.localeName.toLowerCase().startsWith('es')
                ? 'Debes indicar un dia de factura valido (1-31).'
                : 'Invoice day is required (1-31).';
            _savingRule = false;
          });
          return;
        }
      }
      if (_invoiceDateMode == 'offset_days') {
        if (invoiceOffset == null ||
            invoiceOffset < -365 ||
            invoiceOffset > 365) {
          setState(() {
            _ruleErrorText = l.localeName.toLowerCase().startsWith('es')
                ? 'Debes indicar un desfase valido (-365..365).'
                : 'Offset is required (-365..365).';
            _savingRule = false;
          });
          return;
        }
      }
      final tzName = _timezoneCtrl.text.trim();
      final payload = <String, dynamic>{
        'rule': _buildRule(),
        'frequency': canonicalFrequencyForApi(_freq),
        'interval': int.tryParse(_intervalCtrl.text.trim()) ?? 1,
        'startDate': utcDateString(_startDate, _startTime, tzName),
        'timeOfDay': utcTimeString(_startDate, _startTime, tzName),
        'timezone': _timezoneCtrl.text.trim().isNotEmpty
            ? _timezoneCtrl.text.trim()
            : 'Europe/Madrid',
        'invoiceDateMode': _invoiceDateMode,
        'invoiceDateClampPolicy': _invoiceDateClampPolicy,
        if (_invoiceDateMode == 'fixed_day') 'invoiceDateDay': invoiceDay,
        if (_invoiceDateMode == 'offset_days')
          'invoiceDateOffsetDays': invoiceOffset,
      };
      if (_endType == 'date' && _endDate != null) {
        payload['endDate'] = utcDateString(_endDate!, _startTime, tzName);
      } else if (_endType == 'count' && count != null) {
        payload['count'] = count;
      }
      if (canonicalFrequencyForApi(_freq) == recurringFreqMonthly || canonicalFrequencyForApi(_freq) == recurringFreqBimensual || canonicalFrequencyForApi(_freq) == recurringFreqTrimestral) {
        payload['billDay'] = int.tryParse(_billDayCtrl.text.trim());
      } else if (canonicalFrequencyForApi(_freq) == recurringFreqWeekly) {
        payload['billDay'] = int.tryParse(_weekDayCtrl.text.trim());
      }
      if (_exceptions.isNotEmpty) {
        payload['exceptions'] = _exceptions
            .map((d) => utcDateString(d, _startTime, tzName))
            .toList();
      }
      await widget.api.update(id, payload);
      widget.onUpdated();
      if (!mounted) return;
      setState(() => _ruleErrorText = null);
      final locale = Localizations.localeOf(context).languageCode;
      final successText = locale.toLowerCase().startsWith('es')
          ? 'Regla guardada'
          : 'Rule saved';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successText)),
      );
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('(400)')) {
        setState(() => _ruleErrorText = e.toString());
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _savingRule = false);
    }
  }

  Future<void> _saveTemplate() async {
    if (_savingTemplate) return;
    final id = seriesId(widget.series);
    if (id.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final discountValidationError = _validateDiscountInputs(l);
    if (discountValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(discountValidationError)),
      );
      return;
    }
    setState(() => _savingTemplate = true);
    final discountPayload = _buildDiscountPayload();
    final payload = {
      'lines': _lines
          .map((line) => {
                'position': line.position,
                'description': line.description.text.trim(),
                'quantity': line.quantity ?? 1,
                'unitPrice': line.unitPrice ?? 0,
                'taxRate': widget.enableTaxes ? (line.taxRate ?? 21) : 0,
              })
          .toList(),
      'totals': {
        'subtotal': _subtotal,
        'taxTotal': _tax,
        'total': _total,
      },
      ...discountPayload,
    };
    if (_notesCtrl.text.trim().isNotEmpty) {
      payload['notes'] = _notesCtrl.text.trim();
    }
    if (_currencyCtrl.text.trim().isNotEmpty) {
      payload['currency'] = _currencyCtrl.text.trim();
    }
    try {
      await widget.api.update(id, payload);
      widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _savingTemplate = false);
    }
  }

  num _lineSubtotal(LineDraft line) {
    final qty = line.quantity ?? 1;
    final price = line.unitPrice ?? 0;
    return qty * price;
  }

  num _lineTax(LineDraft line) {
    if (!widget.enableTaxes) return 0;
    final taxRate = line.taxRate ?? 21;
    return _lineSubtotal(line) * (taxRate / 100);
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
      _lines.fold<num>(0, (sum, l) => sum + _lineSubtotal(l));
  num get _rawTax => _lines.fold<num>(0, (sum, l) => sum + _lineTax(l));

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
    setState(() {
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

  Future<void> _pickTimezone() async {
    final selected = await showTimezonePicker(
      context: context,
      initial: _timezoneCtrl.text.trim().isEmpty
          ? detectTimezone()
          : _timezoneCtrl.text.trim(),
    );
    if (selected == null) return;
    setState(() => _timezoneCtrl.text = selected);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final rule = widget.series['rule'] as Map?;
    final status = (widget.series['status'] ?? 'active').toString();
    final rawClientName =
        (widget.series['clientName'] ?? widget.series['client']?['name'] ?? '')
            .toString()
            .trim();
    final seriesClientId =
        (widget.series['clientId'] ?? widget.series['client']?['id'] ?? '')
            .toString()
            .trim();
    final fallbackClient = widget.clients.where((c) => c.id == seriesClientId);
    final resolvedClientName = rawClientName.isNotEmpty
        ? rawClientName
        : (fallbackClient.isNotEmpty ? fallbackClient.first.name : '-');
    final nextRun = parseDate(widget.series['nextRunAt']);
    final recurrenceLabel = ruleSummary(rule, l);
    final issuePolicySummary = recurringIssueDatePolicySummary({
      ...widget.series,
      'invoiceDateMode': _invoiceDateMode,
      'invoiceDateDay': int.tryParse(_invoiceDateDayCtrl.text.trim()),
      'invoiceDateOffsetDays':
          int.tryParse(_invoiceDateOffsetDaysCtrl.text.trim()),
      'invoiceDateClampPolicy': _invoiceDateClampPolicy,
    }, l);
    final originalIssuePolicySummary = recurringIssueDatePolicySummary(
      widget.series,
      l,
    );
    final nextRunLabel = nextRun == null
        ? '${l.recurringInvoicesNextRunLabel}: -'
        : '${l.recurringInvoicesNextRunLabel}: ${DateFormat.yMMMd(l.localeName).add_Hm().format(nextRun)}';
    final isPaused = status.toLowerCase() == 'paused';
    final timezoneLabel = timezoneLabelFrom(
      _timezoneCtrl.text.trim().isEmpty
          ? detectTimezone()
          : _timezoneCtrl.text.trim(),
    );
    Future<void> handleTogglePause() async {
      await widget.api.update(
        seriesId(widget.series),
        {'status': isPaused ? 'active' : 'paused'},
      );
      widget.onUpdated();
    }

    Future<void> handleCancel() async {
      try {
        await widget.api.cancel(seriesId(widget.series));
        widget.onUpdated();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    Future<void> handleRunNow() async {
      try {
        final result = await widget.api.run();
        if (!mounted) return;
        final created = result['created']?.toString() ?? '0';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              created == '0'
                  ? l.recurringInvoicesNoRunsSnack
                  : l.recurringInvoicesRunCreatedSnack(created),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    Future<void> pickStartDate() async {
      final date = await showDatePicker(
        context: context,
        initialDate: _startDate,
        firstDate: DateTime(_startDate.year - 1),
        lastDate: DateTime(_startDate.year + 5),
      );
      if (date == null) return;
      setState(() {
        _startDate = DateTime(
          date.year,
          date.month,
          date.day,
          _startTime.hour,
          _startTime.minute,
        );
      });
    }

    Future<void> pickStartTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: _startTime,
      );
      if (picked == null) return;
      setState(() {
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

    Future<void> pickEndDate() async {
      final date = await showDatePicker(
        context: context,
        initialDate: _endDate ?? _startDate,
        firstDate: _startDate,
        lastDate: DateTime(_startDate.year + 5),
      );
      if (date == null) return;
      setState(() => _endDate = date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: FolderPanel(
        title: l.recurringInvoicesTitle,
        onBack: widget.onBack,
        showTab: true,
        contentTopPadding: 4,
        actions: [
          SeriesStatusPill(status: status, iconOnly: true),
          Tooltip(
            message: l.recurringInvoicesPreviewCta,
            child: OutlinedButton(
              onPressed: () =>
                  previewSeries(context, widget.series, widget.api),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 36),
              ),
              child: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
          ),
          if (widget.canManage)
            Tooltip(
              message: isPaused
                  ? l.recurringInvoicesResumeCta
                  : l.recurringInvoicesPauseCta,
              child: OutlinedButton(
                onPressed: handleTogglePause,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 36),
                ),
                child: Icon(
                  isPaused
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline,
                  size: 18,
                ),
              ),
            ),
          if (widget.canManage)
            Tooltip(
              message: l.recurringInvoicesCancelCta,
              child: FilledButton(
                onPressed: handleCancel,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 36),
                  foregroundColor: cs.onErrorContainer,
                  backgroundColor: cs.errorContainer,
                ),
                child: const Icon(Icons.cancel_outlined, size: 18),
              ),
            ),
          if (widget.canManage)
            Tooltip(
              message: l.recurringInvoicesRunNowCta,
              child: FilledButton(
                onPressed: handleRunNow,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 36),
                ),
                child: const Icon(Icons.play_arrow_outlined, size: 18),
              ),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RecurringDetailHeader(
                title: resolvedClientName,
                status: status,
                showStatusPill: false,
                onBack: null,
                backTooltip: l.recurringInvoicesBackCta,
                infoTooltip: l.recurringInvoicesChangesNote,
                recurrenceLabel: recurrenceLabel,
                nextRunLabel: nextRunLabel,
                previewLabel: l.recurringInvoicesPreviewCta,
                onPreview: () =>
                    previewSeries(context, widget.series, widget.api),
                canManage: widget.canManage,
                showActionRow: false,
              ),
              const SizedBox(height: 25),
              Expanded(
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: cs.onPrimaryContainer,
                        unselectedLabelColor: cs.onSurfaceVariant,
                        labelStyle: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w800, fontSize: 13),
                        unselectedLabelStyle:
                            t.bodySmall.copyWith(fontSize: 13),
                        indicator: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelPadding: EdgeInsets.zero,
                        dividerColor: cs.outlineVariant.withValues(alpha: 0.4),
                        tabs: [
                          Tab(
                            height: 34,
                            text: l.recurringInvoicesRuleTab,
                          ),
                          Tab(
                            height: 34,
                            text: l.recurringInvoicesTemplateTab,
                          ),
                          Tab(
                            height: 34,
                            text: l.recurringInvoicesGeneratedTab,
                          ),
                          Tab(
                            height: 34,
                            text: l.recurringInvoicesActivityTab,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: TabBarView(
                          children: [
                            RecurringDetailRuleTab(
                              clientName: resolvedClientName,
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
                              invoiceDateOffsetDaysCtrl:
                                  _invoiceDateOffsetDaysCtrl,
                              invoiceDateClampPolicy: _invoiceDateClampPolicy,
                              timezoneLabel: timezoneLabel,
                              exceptions: _exceptions,
                              onFreqChanged: (v) => setState(() => _freq = canonicalFrequencyForApi(v)),
                              onPickStart: pickStartDate,
                              onPickStartTime: pickStartTime,
                              onPickEnd: pickEndDate,
                              onEndTypeChanged: (v) =>
                                  setState(() => _endType = v),
                              onTimezoneChanged: (_) => setState(() {}),
                              onPickTimezone: _pickTimezone,
                              onAddException: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime(_startDate.year - 1),
                                  lastDate: DateTime(_startDate.year + 5),
                                );
                                if (date == null) return;
                                setState(() => _exceptions.add(date));
                              },
                              onRemoveException: (d) =>
                                  setState(() => _exceptions.remove(d)),
                              onInvoiceDateModeChanged: (v) =>
                                  setState(() => _invoiceDateMode = v),
                              onInvoiceDateClampPolicyChanged: (v) => setState(
                                () => _invoiceDateClampPolicy = v,
                              ),
                              canManage: widget.canManage,
                              saving: _savingRule,
                              onSave: _saveRule,
                              errorText: _ruleErrorText,
                              issueDatePolicySummary: issuePolicySummary,
                              originalIssueDatePolicySummary:
                                  originalIssuePolicySummary,
                              originalSeries: widget.series,
                              startReadOnly: true,
                            ),
                            RecurringDetailTemplateTab(
                              currencyCtrl: _currencyCtrl,
                              notesCtrl: _notesCtrl,
                              lines: _lines,
                              onLinesChanged: () => setState(() {}),
                              discountAmountCtrl: _discountAmountCtrl,
                              discountPercentCtrl: _discountPercentCtrl,
                              useDiscountPercent: _useDiscountPercent,
                              onDiscountModeChanged: _setDiscountModePercent,
                              rawSubtotal: _rawSubtotal,
                              discountAmount: _effectiveDiscount,
                              subtotal: _subtotal,
                              tax: _tax,
                              total: _total,
                              amountErrorText: _discountAmountErrorText(l),
                              percentErrorText: _discountPercentErrorText(l),
                              showTax: widget.enableTaxes,
                              canManage: widget.canManage,
                              saving: _savingTemplate,
                              onSave: _saveTemplate,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: RecurringDetailGeneratedTab(
                                loading: _loadingGenerated,
                                error: _generatedError,
                                invoices: _generated,
                                onReload: _loadGenerated,
                                hasRequested: _generatedRequested,
                                count: _generatedCount,
                                onOpenInvoice: _openInvoice,
                                onDownloadPdf: _downloadInvoicePdf,
                                onLoadInvoiceDetails:
                                    _loadGeneratedInvoiceDetails,
                                onLoadInvoicePreviewBytes:
                                    _loadGeneratedInvoicePreviewBytes,
                              ),
                            ),
                            Center(
                              child: Text(
                                l.recurringInvoicesActivityHint,
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
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
  }
}

