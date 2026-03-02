import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
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

class RecurringCreateWizard extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final RecurringInvoicesApi api;
  final VoidCallback onCancel;
  final ValueChanged<Map<String, dynamic>> onCreated;
  final bool enableTaxes;

  const RecurringCreateWizard({
    super.key,
    required this.group,
    required this.clients,
    required this.api,
    required this.onCancel,
    required this.onCreated,
    this.enableTaxes = true,
  });

  @override
  State<RecurringCreateWizard> createState() => _RecurringCreateWizardState();
}

class _RecurringCreateWizardState extends State<RecurringCreateWizard> {
  int _step = 0;
  String? _clientId;
  final List<LineDraft> _lines = [LineDraft(position: 1)];
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

  @override
  void initState() {
    super.initState();
    if (widget.clients.isNotEmpty) {
      _clientId = widget.clients.first.id;
    }
    _billDayCtrl.text = DateTime.now().day.toString();
    _startTime = TimeOfDay.fromDateTime(_startDate);
    _timezoneCtrl.text = _detectedTimezone;
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
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

  void _onChanged() => setState(() {});

  String _timezoneLabel() => timezoneLabelFrom(
        _timezoneCtrl.text.trim().isEmpty
            ? _detectedTimezone
            : _timezoneCtrl.text.trim(),
      );

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

  Future<void> _pickStartDate() async {
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

  Future<void> _pickStartTime() async {
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

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(_startDate.year + 5),
    );
    if (date == null) return;
    setState(() => _endDate = date);
  }

  Future<void> _addException() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(_startDate.year - 1),
      lastDate: DateTime(_startDate.year + 5),
    );
    if (date == null) return;
    setState(() => _exceptions.add(date));
  }

  Future<void> _pickTimezone() async {
    final selected = await showTimezonePicker(
      context: context,
      initial: _timezoneCtrl.text.trim().isEmpty
          ? _detectedTimezone
          : _timezoneCtrl.text.trim(),
    );
    if (selected == null) return;
    setState(() => _timezoneCtrl.text = selected);
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

  List<Map<String, dynamic>> _buildLines() {
    return _lines.map((line) {
      return {
        'position': line.position,
        'description': line.description.text.trim(),
        'quantity': line.quantity ?? 1,
        'unitPrice': line.unitPrice ?? 0,
        'taxRate': widget.enableTaxes ? (line.taxRate ?? 21) : 0,
      };
    }).toList();
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
            'issueDate': (row['issueDate'] ?? row['issue_date'] ?? '-')
                .toString(),
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
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invoiceLinesRequired)));
      return;
    }
    final policyError = _validateIssuePolicy(l);
    if (policyError != null) {
      setState(() => _ruleErrorText = policyError);
      if (_step < 3) setState(() => _step = 3);
      return;
    }
    final discountValidationError = _validateDiscountInputs(l);
    if (discountValidationError != null) {
      if (_step != 2) setState(() => _step = 2);
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
      if ((canonicalFrequencyForApi(_freq) == recurringFreqMonthly || canonicalFrequencyForApi(_freq) == recurringFreqBimensual || canonicalFrequencyForApi(_freq) == recurringFreqTrimestral)) 'billDay': int.tryParse(_billDayCtrl.text.trim()),
      if (canonicalFrequencyForApi(_freq) == recurringFreqWeekly) 'billDay': int.tryParse(_weekDayCtrl.text.trim()),
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
            onClientChanged: (v) => setState(() => _clientId = v),
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
            lines: _lines,
            onChanged: _onChanged,
            discountAmountCtrl: _discountAmountCtrl,
            discountPercentCtrl: _discountPercentCtrl,
            useDiscountPercent: _useDiscountPercent,
            onDiscountModeChanged: _setDiscountModePercent,
            subtotal: _subtotal,
            rawSubtotal: _rawSubtotal,
            discountAmount: _effectiveDiscount,
            tax: _tax,
            total: _total,
            amountErrorText: _discountAmountErrorText(l),
            percentErrorText: _discountPercentErrorText(l),
            showTax: widget.enableTaxes,
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
            onFreqChanged: (v) => setState(() => _freq = canonicalFrequencyForApi(v)),
            onPickStart: _pickStartDate,
            onPickStartTime: _pickStartTime,
            onPickEnd: _pickEndDate,
            onEndTypeChanged: (v) => setState(() => _endType = v),
            onTimezoneChanged: (_) => setState(() {}),
            onPickTimezone: _pickTimezone,
            onAddException: _addException,
            onRemoveException: (d) => setState(() => _exceptions.remove(d)),
            onInvoiceDateModeChanged: (v) =>
                setState(() => _invoiceDateMode = v),
            onInvoiceDateClampPolicyChanged: (v) =>
                setState(() => _invoiceDateClampPolicy = v),
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
              onBack: widget.onCancel,
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
                                      if (_step == 2 && _lines.isEmpty) {
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
                                        setState(() => _step += 1);
                                      } else {
                                        _submit();
                                      }
                                    },
                                    onStepCancel: () {
                                      if (_step == 0) {
                                        widget.onCancel();
                                      } else {
                                        setState(() => _step -= 1);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () => setState(() => _step = 0),
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
                                          widget.onCancel();
                                        } else {
                                          setState(() => _step -= 1);
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
                                        if (_step == 2 && _lines.isEmpty) {
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
                                          setState(() => _step += 1);
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
                            child: SingleChildScrollView(
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

