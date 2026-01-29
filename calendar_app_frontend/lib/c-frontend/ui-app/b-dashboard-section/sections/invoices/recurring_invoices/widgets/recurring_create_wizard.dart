import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_client_step.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_preview_step.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_schedule_step.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_template_step.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RecurringCreateWizard extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final RecurringInvoicesApi api;
  final VoidCallback onCancel;
  final ValueChanged<Map<String, dynamic>> onCreated;

  const RecurringCreateWizard({
    super.key,
    required this.group,
    required this.clients,
    required this.api,
    required this.onCancel,
    required this.onCreated,
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
  final String _detectedTimezone = detectTimezone();
  final List<DateTime> _exceptions = [];

  bool _loadingPreview = false;
  bool _saving = false;
  List<String> _previewDates = [];

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
    _intervalCtrl.dispose();
    _countCtrl.dispose();
    _billDayCtrl.dispose();
    _weekDayCtrl.dispose();
    _timezoneCtrl.dispose();
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
    final taxRate = line.taxRate ?? 21;
    return _lineSubtotal(line) * (taxRate / 100);
  }

  num get _subtotal => _lines.fold<num>(0, (sum, l) => sum + _lineSubtotal(l));
  num get _tax => _lines.fold<num>(0, (sum, l) => sum + _lineTax(l));
  num get _total => _subtotal + _tax;

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
      'freq': _freq,
      'frequency': _freq,
      'interval': interval,
      'startDate': utcDate,
      'timeOfDay': utcTime,
      'timezone': _timezoneCtrl.text.trim().isEmpty
          ? 'Europe/Madrid'
          : _timezoneCtrl.text.trim(),
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

  List<Map<String, dynamic>> _buildLines() {
    return _lines.map((line) {
      return {
        'position': line.position,
        'description': line.description.text.trim(),
        'quantity': line.quantity ?? 1,
        'unitPrice': line.unitPrice ?? 0,
        'taxRate': line.taxRate ?? 21,
      };
    }).toList();
  }

  Future<void> _loadPreview() async {
    if (_loadingPreview) return;
    setState(() => _loadingPreview = true);
    try {
      final payload = {
        'rule': _buildRule(),
      };
      final result = await widget.api.preview(payload);
      final items = result['dates'];
      final list = <String>[];
      if (items is List) {
        for (final item in items) {
          list.add(item.toString());
        }
      }
      if (mounted) setState(() => _previewDates = list);
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
    final tz = _timezoneCtrl.text.trim();
    final utcStartDate = utcDateString(_startDate, _startTime, tz);
    final utcTimeOfDay = utcTimeString(_startDate, _startTime, tz);
    final payload = {
      'groupId': widget.group.id,
      'clientId': _clientId,
      'name': name,
      'frequency': _freq,
      'interval': int.tryParse(_intervalCtrl.text.trim()) ?? 1,
      'startDate': utcStartDate,
      if (_endType == 'date' && _endDate != null)
        'endDate': utcDateString(_endDate!, _startTime, tz),
      if (_endType == 'count' && int.tryParse(_countCtrl.text.trim()) != null)
        'count': int.tryParse(_countCtrl.text.trim()),
      if (_freq == 'monthly') 'billDay': int.tryParse(_billDayCtrl.text.trim()),
      if (_freq == 'weekly') 'billDay': int.tryParse(_weekDayCtrl.text.trim()),
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
      'rule': _buildRule(),
      'lines': _buildLines(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.recurringInvoicesCreateSuccess)),
      );
      widget.onCreated(created);
    } catch (e) {
      if (!mounted) return;
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
          ),
        ),
        state: _step > 0 ? StepState.complete : StepState.indexed,
        isActive: _step >= 0,
      ),
      Step(
        title: stepTitle(l.recurringInvoicesStepTemplate, 1),
        content: wrapStepContent(
          RecurringWizardTemplateStep(
            lines: _lines,
            onChanged: _onChanged,
            subtotal: _subtotal,
            tax: _tax,
            total: _total,
          ),
        ),
        state: _step > 1 ? StepState.complete : StepState.indexed,
        isActive: _step >= 1,
      ),
      Step(
        title: stepTitle(l.recurringInvoicesStepSchedule, 2),
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
            timezoneLabel: _timezoneLabel(),
            exceptions: _exceptions,
            onFreqChanged: (v) => setState(() => _freq = v),
            onPickStart: _pickStartDate,
            onPickStartTime: _pickStartTime,
            onPickEnd: _pickEndDate,
            onEndTypeChanged: (v) => setState(() => _endType = v),
            onTimezoneChanged: (_) => setState(() {}),
            onPickTimezone: _pickTimezone,
            onAddException: _addException,
            onRemoveException: (d) => setState(() => _exceptions.remove(d)),
          ),
        ),
        state: _step > 2 ? StepState.complete : StepState.indexed,
        isActive: _step >= 2,
      ),
      Step(
        title: stepTitle(l.recurringInvoicesStepPreview, 3),
        content: wrapStepContent(
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
            previewDates: _previewDates,
            onLoadPreview: _loadPreview,
          ),
        ),
        state: _step > 3 ? StepState.complete : StepState.indexed,
        isActive: _step >= 3,
      ),
    ];
    final stepTitleText = steps[_step].title is Text
        ? (steps[_step].title as Text).data ?? ''
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.recurringInvoicesCreateTitle,
                            style: t.titleLarge
                                .copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onCancel,
                          child: Text(
                            l.cancel,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              color: cs.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${l.invoiceClientLabel}: $clientLabel',
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _step = 0),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l.change,
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: Text(
                      '${l.stepLabel} ${_step + 1} ${l.ofLabel} ${steps.length} · $stepTitleText',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: Stepper(
                        type: isWide
                            ? StepperType.horizontal
                            : StepperType.vertical,
                        currentStep: _step,
                        connectorThickness: 2,
                        stepIconHeight: 30,
                        stepIconWidth: 30,
                        stepIconBuilder: (index, state) {
                          final active = _step >= index;
                          final color =
                              active ? cs.onPrimary : cs.onSurfaceVariant;
                          switch (state) {
                            case StepState.complete:
                              return Icon(Icons.check, color: color, size: 18);
                            case StepState.editing:
                              return Icon(Icons.edit, color: color, size: 18);
                            case StepState.error:
                              return Icon(Icons.priority_high,
                                  color: color, size: 18);
                            case StepState.disabled:
                            case StepState.indexed:
                              return Text(
                                '${index + 1}',
                                style: t.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              );
                          }
                        },
                        onStepContinue: () {
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
                        controlsBuilder: (context, details) {
                          final isLast = _step == steps.length - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed:
                                      _saving ? null : details.onStepCancel,
                                  child: Text(l.recurringInvoicesBackCta),
                                ),
                                const Spacer(),
                                FilledButton(
                                  onPressed:
                                      _saving ? null : details.onStepContinue,
                                  child: Text(
                                    isLast
                                        ? (_saving
                                            ? l.recurringInvoicesSavingRule
                                            : l.recurringInvoicesCreateCta)
                                        : l.recurringInvoicesContinueCta,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        steps: steps,
                      ),
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
