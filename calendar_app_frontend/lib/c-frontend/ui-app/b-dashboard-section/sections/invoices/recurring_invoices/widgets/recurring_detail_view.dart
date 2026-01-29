import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurring_invoices_helpers.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_generated_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_rule_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_section_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_template_tab.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RecurringDetailView extends StatefulWidget {
  final RecurringInvoicesApi api;
  final Map<String, dynamic> series;
  final Group group;
  final List<GroupClient> clients;
  final bool canManage;
  final VoidCallback onBack;
  final VoidCallback onUpdated;

  const RecurringDetailView({
    super.key,
    required this.api,
    required this.series,
    required this.group,
    required this.clients,
    required this.canManage,
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
  late TextEditingController _notesCtrl;
  late TextEditingController _currencyCtrl;
  final List<DateTime> _exceptions = [];

  late List<LineDraft> _lines;

  bool _savingRule = false;
  bool _savingTemplate = false;
  bool _loadingGenerated = false;
  String? _generatedError;
  List<Invoice> _generated = [];
  bool _generatedRequested = false;
  int? _generatedCount;

  @override
  void initState() {
    super.initState();
    final rule = (widget.series['rule'] as Map?) ?? const {};
    _freq = (rule['freq'] ?? 'monthly').toString();
    _intervalCtrl = TextEditingController(
      text: (rule['interval'] ?? 1).toString(),
    );
    _startDate = parseDate(rule['startDate']) ?? DateTime.now();
    final tzName = (rule['timezone'] ?? detectTimezone()).toString();
    final timeOfDay = parseTimeOfDay(rule['timeOfDay']);
    if (timeOfDay != null) {
      final utcStart = DateTime.utc(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      final localStart = utcToZoned(utcStart, tzName);
      _startDate = localStart;
      _startTime = TimeOfDay.fromDateTime(localStart);
    } else {
      _startTime = TimeOfDay.fromDateTime(_startDate);
    }
    _timezoneCtrl = TextEditingController(text: tzName);
    _billDayCtrl = TextEditingController(
      text: (rule['billDay'] ?? DateTime.now().day).toString(),
    );
    _weekDayCtrl = TextEditingController(
      text: (rule['billDay'] ?? '').toString(),
    );
    _endDate = parseDate(rule['endDate']);
    final count = rule['count'];
    _countCtrl = TextEditingController(text: count?.toString() ?? '');
    _endType = _endDate != null ? 'date' : (count != null ? 'count' : 'never');
    _notesCtrl = TextEditingController(
      text: (widget.series['notes'] ?? '').toString(),
    );
    _currencyCtrl = TextEditingController(
      text: (widget.series['currency'] ?? 'EUR').toString(),
    );

    final exceptions = rule['exceptions'];
    if (exceptions is List) {
      for (final e in exceptions) {
        final d = parseDate(e);
        if (d != null) _exceptions.add(d);
      }
    }

    _lines = buildLineDrafts(widget.series);
  }

  @override
  void dispose() {
    _intervalCtrl.dispose();
    _countCtrl.dispose();
    _billDayCtrl.dispose();
    _weekDayCtrl.dispose();
    _timezoneCtrl.dispose();
    _notesCtrl.dispose();
    _currencyCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
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
    final raw = headers['content-disposition'] ?? headers['Content-Disposition'];
    if (raw != null && raw.isNotEmpty) {
      final utf8Match =
          RegExp(r"filename\\*=UTF-8''([^;]+)", caseSensitive: false)
              .firstMatch(raw);
      if (utf8Match != null) {
        final name = Uri.decodeComponent(utf8Match.group(1)!);
        if (name.trim().isNotEmpty) return name;
      }
      final match =
          RegExp(r'filename="?([^";]+)"?', caseSensitive: false).firstMatch(raw);
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
      'freq': _freq,
      'frequency': _freq,
      'interval': interval,
      'startDate': utcDate,
      'timeOfDay': utcTime,
      'timezone': _timezoneCtrl.text.trim().isNotEmpty
          ? _timezoneCtrl.text.trim()
          : 'Europe/Madrid',
    };
    if (_freq == 'monthly' && billDay != null) {
      rule['billDay'] = billDay;
    } else if (_freq == 'weekly' && weekDay != null) {
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
      final count = int.tryParse(_countCtrl.text.trim());
      final tzName = _timezoneCtrl.text.trim();
      final payload = <String, dynamic>{
        'rule': _buildRule(),
        'frequency': _freq,
        'interval': int.tryParse(_intervalCtrl.text.trim()) ?? 1,
        'startDate': utcDateString(_startDate, _startTime, tzName),
        'timeOfDay': utcTimeString(_startDate, _startTime, tzName),
        'timezone': _timezoneCtrl.text.trim().isNotEmpty
            ? _timezoneCtrl.text.trim()
            : 'Europe/Madrid',
      };
      if (_endType == 'date' && _endDate != null) {
        payload['endDate'] = utcDateString(_endDate!, _startTime, tzName);
      } else if (_endType == 'count' && count != null) {
        payload['count'] = count;
      }
      if (_freq == 'monthly') {
        payload['billDay'] = int.tryParse(_billDayCtrl.text.trim());
      } else if (_freq == 'weekly') {
        payload['billDay'] = int.tryParse(_weekDayCtrl.text.trim());
      }
      if (_exceptions.isNotEmpty) {
        payload['exceptions'] = _exceptions
            .map((d) => utcDateString(d, _startTime, tzName))
            .toList();
      }
      await widget.api.update(id, payload);
      widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
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
    setState(() => _savingTemplate = true);
    final payload = {
      'lines': _lines
          .map((line) => {
                'position': line.position,
                'description': line.description.text.trim(),
                'quantity': line.quantity ?? 1,
                'unitPrice': line.unitPrice ?? 0,
                'taxRate': line.taxRate ?? 21,
              })
          .toList(),
      'totals': {
        'subtotal': _subtotal,
        'taxTotal': _tax,
        'total': _total,
      },
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
    final taxRate = line.taxRate ?? 21;
    return _lineSubtotal(line) * (taxRate / 100);
  }

  num get _subtotal => _lines.fold<num>(0, (sum, l) => sum + _lineSubtotal(l));
  num get _tax => _lines.fold<num>(0, (sum, l) => sum + _lineTax(l));
  num get _total => _subtotal + _tax;

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
    final clientName =
        (widget.series['clientName'] ?? widget.series['client']?['name'] ?? '-')
            .toString();
    final nextRun = parseDate(widget.series['nextRunAt']);
    final recurrenceLabel = ruleSummary(rule, l);
    final nextRunLabel = nextRun == null
        ? '${l.recurringInvoicesNextRunLabel}: -'
        : '${l.recurringInvoicesNextRunLabel}: ${DateFormat.yMMMd(l.localeName).add_Hm().format(nextRun)}';
    final isPaused = status.toLowerCase() == 'paused';
    final timezoneLabel = timezoneLabelFrom(
      _timezoneCtrl.text.trim().isEmpty
          ? detectTimezone()
          : _timezoneCtrl.text.trim(),
    );

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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecurringDetailHeader(
            title: clientName,
            status: status,
            onBack: widget.onBack,
            backTooltip: l.recurringInvoicesBackCta,
            recurrenceLabel: recurrenceLabel,
            nextRunLabel: nextRunLabel,
            previewLabel: l.recurringInvoicesPreviewCta,
            onPreview: () => previewSeries(context, widget.series, widget.api),
            canManage: widget.canManage,
            onTogglePause: widget.canManage
                ? () => widget.api.update(
                      seriesId(widget.series),
                      {'status': isPaused ? 'active' : 'paused'},
                    ).then((_) => widget.onUpdated())
                : null,
            pauseResumeIcon: isPaused
                ? Icons.play_circle_outline
                : Icons.pause_circle_outline,
            pauseResumeLabel: isPaused
                ? l.recurringInvoicesResumeCta
                : l.recurringInvoicesPauseCta,
            onCancel: widget.canManage
                ? () async {
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
                : null,
            cancelLabel: l.recurringInvoicesCancelCta,
            onRunNow: widget.canManage
                ? () async {
                    try {
                      final result = await widget.api.run();
                      if (!mounted) return;
                      final created = result['created']?.toString() ?? '0';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(created == '0'
                              ? l.recurringInvoicesNoRunsSnack
                              : l.recurringInvoicesRunCreatedSnack(created)),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                : null,
            runNowLabel: l.recurringInvoicesRunNowCta,
          ),
          const SizedBox(height: 12),
          RecurringDetailSectionCard(
            child: Text(
              l.recurringInvoicesChangesNote,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    labelColor: cs.onPrimaryContainer,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    labelStyle:
                        t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                    unselectedLabelStyle: t.bodyMedium,
                    indicator: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: cs.outlineVariant.withValues(alpha: 0.5),
                    tabs: [
                      Tab(text: l.recurringInvoicesRuleTab),
                      Tab(text: l.recurringInvoicesTemplateTab),
                      Tab(text: l.recurringInvoicesGeneratedTab),
                      Tab(text: l.recurringInvoicesActivityTab),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        RecurringDetailRuleTab(
                          freq: _freq,
                          intervalCtrl: _intervalCtrl,
                          startDate: _startDate,
                          endType: _endType,
                          endDate: _endDate,
                          countCtrl: _countCtrl,
                          billDayCtrl: _billDayCtrl,
                          weekDayCtrl: _weekDayCtrl,
                          timezoneCtrl: _timezoneCtrl,
                          timezoneLabel: timezoneLabel,
                          exceptions: _exceptions,
                          onFreqChanged: (v) => setState(() => _freq = v),
                          onPickStart: pickStartDate,
                          onPickStartTime: pickStartTime,
                          onPickEnd: pickEndDate,
                          onEndTypeChanged: (v) => setState(() => _endType = v),
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
                          canManage: widget.canManage,
                          saving: _savingRule,
                          onSave: _saveRule,
                        ),
                        RecurringDetailTemplateTab(
                          currencyCtrl: _currencyCtrl,
                          notesCtrl: _notesCtrl,
                          lines: _lines,
                          onLinesChanged: () => setState(() {}),
                          subtotal: _subtotal,
                          tax: _tax,
                          total: _total,
                          canManage: widget.canManage,
                          saving: _savingTemplate,
                          onSave: _saveTemplate,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: RecurringDetailGeneratedTab(
                            loading: _loadingGenerated,
                            error: _generatedError,
                            invoices: _generated,
                            onReload: _loadGenerated,
                            hasRequested: _generatedRequested,
                            count: _generatedCount,
                            onOpenInvoice: _openInvoice,
                            onDownloadPdf: _downloadInvoicePdf,
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
    );
  }
}
