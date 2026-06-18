import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_concept_utils.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/b-backend/receipts/recurring_receipts_api.dart';
import 'package:hexora/b-backend/receipts/receipts_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurring_invoices_helpers.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_generated_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_rule_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_template_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/series_status_pill.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class RecurringDetailView extends StatefulWidget {
  final RecurringInvoicesApi api;
  final Map<String, dynamic> series;
  final Group group;
  final List<GroupClient> clients;
  final bool canManage;
  final bool enableTaxes;
  final VoidCallback onBack;
  final FutureOr<void> Function() onUpdated;

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
  final _receiptsApi = ReceiptsApi();

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
  late List<InvoiceBlockDraft> _templateBlocks;

  bool _savingRule = false;
  bool _savingTemplate = false;
  bool _loadingGenerated = false;
  String? _generatedError;
  List<Invoice> _generated = [];
  bool _generatedRequested = false;
  int? _generatedCount;
  String? _ruleErrorText;
  Map<String, dynamic> _initialRuleSnapshot = const <String, dynamic>{};

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
    for (final block in _templateBlocks) {
      block.dispose();
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
    _freq =
        normalizeFrequencyFromApi((rawFreq ?? recurringFreqMonthly).toString());
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
    _templateBlocks = _blocksFromLines(_lines);
    _generatedError = null;
    _generated = [];
    _generatedRequested = false;
    _generatedCount = null;
    _loadingGenerated = false;
    _ruleErrorText = null;
    _initialRuleSnapshot = _buildCurrentRuleSnapshot();
  }

  Map<String, dynamic> _buildCurrentRuleSnapshot() {
    final dateFmt = DateFormat('yyyy-MM-dd');
    return <String, dynamic>{
      'freq': canonicalFrequencyForApi(_freq),
      'interval': _intervalCtrl.text.trim(),
      'startDate': dateFmt.format(_startDate),
      'startHour': _startTime.hour,
      'startMinute': _startTime.minute,
      'endType': _endType,
      'endDate': _endDate == null ? '' : dateFmt.format(_endDate!),
      'count': _countCtrl.text.trim(),
      'billDay': _billDayCtrl.text.trim(),
      'weekDay': _weekDayCtrl.text.trim(),
      'timezone': _timezoneCtrl.text.trim(),
      'invoiceDateMode': _invoiceDateMode,
      'invoiceDateClampPolicy': _invoiceDateClampPolicy,
      'invoiceDateDay': _invoiceDateDayCtrl.text.trim(),
      'invoiceDateOffsetDays': _invoiceDateOffsetDaysCtrl.text.trim(),
      'exceptions': _exceptions.map(dateFmt.format).toList(growable: false),
    };
  }

  bool _hasUnsavedRuleChanges() {
    return !mapEquals(_initialRuleSnapshot, _buildCurrentRuleSnapshot());
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
    final prefix = widget.api is RecurringReceiptsApi ? 'receipt' : 'invoice';
    return fallback.endsWith('.pdf') ? fallback : '$prefix-$fallback.pdf';
  }

  Future<void> _downloadInvoicePdf(Invoice invoice) async {
    if (invoice.id.trim().isEmpty) return;
    try {
      final r = widget.api is RecurringReceiptsApi
          ? await _receiptsApi.downloadPdf(invoice.id)
          : await _invoicesApi.downloadPdf(invoice.id);
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
    if (widget.api is RecurringReceiptsApi) {
      return Future.value(
        _generated.firstWhere(
          (invoice) => invoice.id == invoiceId,
          orElse: () => Invoice(
            id: invoiceId,
            invoiceNumber: '',
            groupId: widget.group.id,
            clientId: '',
          ),
        ),
      );
    }
    return _invoicesApi.getById(invoiceId);
  }

  Future<Uint8List> _loadGeneratedInvoicePreviewBytes(String invoiceId) async {
    final response = widget.api is RecurringReceiptsApi
        ? await _receiptsApi.previewPdf(invoiceId)
        : await _invoicesApi.previewPdf(invoiceId);
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

  Future<bool> _saveRule() async {
    if (_savingRule) return false;
    final id = seriesId(widget.series);
    if (id.isEmpty) return false;
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
          return false;
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
          return false;
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
      if (canonicalFrequencyForApi(_freq) == recurringFreqMonthly ||
          canonicalFrequencyForApi(_freq) == recurringFreqBimensual ||
          canonicalFrequencyForApi(_freq) == recurringFreqTrimestral) {
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
      _initialRuleSnapshot = _buildCurrentRuleSnapshot();
      await widget.onUpdated();
      if (!mounted) return true;
      setState(() => _ruleErrorText = null);
      final locale = Localizations.localeOf(context).languageCode;
      final successText = locale.toLowerCase().startsWith('es')
          ? 'Regla guardada'
          : 'Rule saved';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successText)),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      if (e.toString().contains('(400)')) {
        setState(() => _ruleErrorText = e.toString());
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      return false;
    } finally {
      if (mounted) setState(() => _savingRule = false);
    }
  }

  List<InvoiceBlockDraft> _blocksFromLines(List<LineDraft> lines) {
    final blocks = lines
        .map(
          (line) => InvoiceBlockDraft(
            type: 'item',
            sku: isInvoiceUnitCode(line.sku) ? line.sku : null,
            conceptItems: cleanInvoiceConceptItems(
              line.conceptItems,
              staleSku: line.sku,
            ),
            conceptTitle: invoiceConceptTitleFrom(
              conceptTitle: line.conceptTitle,
              sku: line.sku,
            ),
            serviceDate: cleanInvoiceServiceDate(line.serviceDate),
            isCompositeConcept: line.isCompositeConcept,
            description: line.description.text,
            qty: (line.quantity ?? 1).toString(),
            unitPrice: (line.unitPrice ?? 0).toString(),
            taxRate: (line.taxRate ?? (widget.enableTaxes ? 21 : 0)).toString(),
            isBillable: true,
          ),
        )
        .toList(growable: true);
    if (blocks.isEmpty) {
      blocks.add(InvoiceBlockDraft.item());
    }
    return blocks;
  }

  List<Map<String, dynamic>> _templateLinesPayload() {
    var position = 1;
    return _templateBlocks
        .where((block) => block.hasBillableContent)
        .map((block) {
      final description = block.description.text.trim().isNotEmpty
          ? block.description.text.trim()
          : block.title.text.trim();
      final sku = block.sku.text.trim();
      final conceptItems = cleanInvoiceConceptItems(
        block.conceptItems,
        staleSku: sku,
      );
      final conceptTitle = invoiceConceptTitleFrom(
        conceptTitle: block.conceptTitle,
        sku: sku,
      );
      return <String, dynamic>{
        'position': position++,
        'description': description,
        if (sku.isNotEmpty && isInvoiceUnitCode(sku)) 'sku': sku,
        if (conceptTitle != null) 'conceptTitle': conceptTitle,
        if (conceptItems != null) 'conceptItems': conceptItems,
        if (block.serviceDate != null)
          'serviceDate': cleanInvoiceServiceDate(block.serviceDate),
        if (block.isCompositeConcept != null)
          'isCompositeConcept': block.isCompositeConcept
        else if ((conceptItems?.length ?? 0) > 1)
          'isCompositeConcept': true,
        'quantity': block.qty ?? 1,
        if (block.unitCtrl.text.trim().isNotEmpty)
          'unit': block.unitCtrl.text.trim(),
        'unitPrice': block.unitPrice ?? 0,
        'taxRate': widget.enableTaxes ? (block.taxRate ?? 21) : 0,
      };
    }).toList(growable: false);
  }

  List<Map<String, dynamic>> _templateBlocksPayload() {
    return _templateBlocks
        .where((block) => block.hasBillableContent)
        .map((block) => block.toBlock().toJson())
        .toList(growable: false);
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
      'lines': _templateLinesPayload(),
      'blocks': _templateBlocksPayload(),
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
      await widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _savingTemplate = false);
    }
  }

  num _blockSubtotal(InvoiceBlockDraft block) {
    final qty = block.qty ?? 1;
    final price = block.unitPrice ?? 0;
    return qty * price;
  }

  num _blockTax(InvoiceBlockDraft block) {
    if (!widget.enableTaxes) return 0;
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

  num get _rawSubtotal => _templateBlocks
      .where((block) => block.hasBillableContent)
      .fold<num>(0, (sum, block) => sum + _blockSubtotal(block));
  num get _rawTax => _templateBlocks
      .where((block) => block.hasBillableContent)
      .fold<num>(0, (sum, block) => sum + _blockTax(block));

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
    final status = (widget.series['status'] ?? 'active').toString();
    String pickClientName() {
      final candidates = [
        widget.series['clientName'],
        widget.series['client']?['name'],
        widget.series['billingName'],
        (widget.series['rule'] as Map?)?['clientName'],
      ];
      for (final candidate in candidates) {
        final value = (candidate ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final rawClientName = pickClientName();
    final seriesClientId = (widget.series['clientId'] ??
            widget.series['client']?['id'] ??
            (widget.series['rule'] as Map?)?['clientId'] ??
            '')
        .toString()
        .trim();
    final fallbackClient = widget.clients.where((c) => c.id == seriesClientId);
    final resolvedClientName = rawClientName.isNotEmpty
        ? rawClientName
        : (fallbackClient.isNotEmpty
            ? fallbackClient.first.name
            : l.unknownClient);
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
      await widget.onUpdated();
    }

    Future<void> handleCancel() async {
      final isEs = l.localeName.toLowerCase().startsWith('es');
      final messenger = ScaffoldMessenger.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.cancel_outlined, size: 28),
          title: Text(l.recurringInvoicesCancelCta),
          content: Text(
            isEs
                ? '¿Cancelar esta serie recurrente? Esta acción no se puede deshacer.'
                : 'Cancel this recurring series? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              child: Text(isEs ? 'Sí, cancelar' : 'Yes, cancel'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      try {
        await widget.api.cancel(seriesId(widget.series));
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEs
                  ? 'Recurrencia cancelada correctamente'
                  : 'Recurrence cancelled successfully',
            ),
          ),
        );
        if (mounted) widget.onBack();
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    Future<void> handleRunNow() async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final l = AppLocalizations.of(context)!;
        final isEs = l.localeName.toLowerCase().startsWith('es');
        if (_hasUnsavedRuleChanges()) {
          final shouldSaveAndRun = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(isEs
                      ? 'Guardar antes de ejecutar'
                      : 'Save before running'),
                  content: Text(
                    isEs
                        ? 'Esta regla tiene cambios sin guardar. Guarda la regla antes de ejecutar para usar la configuracion actual.'
                        : 'This rule has unsaved changes. Save the rule before running to use the current configuration.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(isEs ? 'Cancelar' : 'Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(isEs ? 'Guardar y ejecutar' : 'Save and run'),
                    ),
                  ],
                ),
              ) ??
              false;
          if (!shouldSaveAndRun || !mounted) return;
          final saved = await _saveRule();
          if (!saved || !mounted) return;
        }
        final result = await widget.api.run();
        if (!mounted) return;
        final created = result['created']?.toString() ?? '0';
        final isReceiptFlow = widget.api is RecurringReceiptsApi;
        final zeroMessage = isReceiptFlow
            ? (isEs
                ? 'No habia recibos pendientes para generar con la configuracion guardada.'
                : 'No pending receipts to generate with the saved configuration.')
            : l.recurringInvoicesNoRunsSnack;
        final createdMessage = isReceiptFlow
            ? (isEs
                ? 'Recibos generados: $created'
                : 'Receipts created: $created')
            : l.recurringInvoicesRunCreatedSnack(created);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              created == '0' ? zeroMessage : createdMessage,
            ),
          ),
        );
        await widget.onUpdated();
        await _loadGenerated();
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
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
        contentTopPadding: 56,
        actions: [
          _RecurringDetailActionBar(
            status: status,
            onPreview: () => previewSeries(context, widget.series, widget.api),
            previewTooltip: l.recurringInvoicesPreviewCta,
            canManage: widget.canManage,
            isPaused: isPaused,
            onTogglePause: handleTogglePause,
            togglePauseTooltip: isPaused
                ? l.recurringInvoicesResumeCta
                : l.recurringInvoicesPauseCta,
            onCancel: handleCancel,
            cancelTooltip: l.recurringInvoicesCancelCta,
            onRunNow: handleRunNow,
            runNowTooltip: l.recurringInvoicesRunNowCta,
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TabBar(
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
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          dividerColor:
                              cs.outlineVariant.withValues(alpha: 0.4),
                          tabs: [
                            Tab(
                              height: 40,
                              text: l.recurringInvoicesRuleTab,
                            ),
                            Tab(
                              height: 40,
                              text: l.recurringInvoicesTemplateTab,
                            ),
                            Tab(
                              height: 40,
                              text: l.recurringInvoicesGeneratedTab,
                            ),
                            Tab(
                              height: 40,
                              text: l.recurringInvoicesActivityTab,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
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
                              onFreqChanged: (v) => setState(
                                  () => _freq = canonicalFrequencyForApi(v)),
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
                              key: ValueKey(
                                'recurring-template-editor-${seriesId(widget.series)}-${_templateBlocks.length}',
                              ),
                              currencyCtrl: _currencyCtrl,
                              notesCtrl: _notesCtrl,
                              blocks: _templateBlocks,
                              onBlocksChanged: () => setState(() {}),
                              discountAmountCtrl: _discountAmountCtrl,
                              discountPercentCtrl: _discountPercentCtrl,
                              useDiscountPercent: _useDiscountPercent,
                              onDiscountModeChanged: _setDiscountModePercent,
                              discountAmount: _effectiveDiscount,
                              total: _total,
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
                                receiptsMode:
                                    widget.api is RecurringReceiptsApi,
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

class _RecurringDetailActionBar extends StatelessWidget {
  const _RecurringDetailActionBar({
    required this.status,
    required this.onPreview,
    required this.previewTooltip,
    required this.canManage,
    required this.isPaused,
    required this.onTogglePause,
    required this.togglePauseTooltip,
    required this.onCancel,
    required this.cancelTooltip,
    required this.onRunNow,
    required this.runNowTooltip,
  });

  final String status;
  final VoidCallback onPreview;
  final String previewTooltip;
  final bool canManage;
  final bool isPaused;
  final VoidCallback onTogglePause;
  final String togglePauseTooltip;
  final VoidCallback onCancel;
  final String cancelTooltip;
  final VoidCallback onRunNow;
  final String runNowTooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SeriesStatusPill(status: status, iconOnly: true),
          ),
          _RecurringDetailActionButton(
            icon: Icons.calendar_today_outlined,
            tooltip: previewTooltip,
            onPressed: onPreview,
          ),
          if (canManage) ...[
            _RecurringDetailActionButton(
              icon: isPaused ? Icons.play_circle_outline : Icons.pause_outlined,
              tooltip: togglePauseTooltip,
              onPressed: onTogglePause,
            ),
            _RecurringDetailActionButton(
              icon: Icons.close_rounded,
              tooltip: cancelTooltip,
              onPressed: onCancel,
              foreground: cs.error,
              background: cs.errorContainer.withValues(alpha: 0.72),
            ),
            _RecurringDetailActionButton(
              icon: Icons.play_arrow_rounded,
              tooltip: runNowTooltip,
              onPressed: onRunNow,
              foreground: cs.onPrimary,
              background: cs.primary,
              borderColor: cs.primary,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecurringDetailActionButton extends StatelessWidget {
  const _RecurringDetailActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.foreground,
    this.background,
    this.borderColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? foreground;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = foreground ?? cs.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: background ?? cs.surface.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor ??
                    cs.outlineVariant.withValues(
                      alpha: background == null ? 0.55 : 0.0,
                    ),
              ),
            ),
            child: Icon(icon, size: 17, color: fg),
          ),
        ),
      ),
    );
  }
}
