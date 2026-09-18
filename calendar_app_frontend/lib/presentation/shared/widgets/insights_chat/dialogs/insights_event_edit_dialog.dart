import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/service_catalog/service.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/service_catalog/service_api_client.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import '../insights_json_utils.dart';

class InsightsEventEditDialog extends StatefulWidget {
  const InsightsEventEditDialog({
    super.key,
    required this.groupId,
    required this.clientsApi,
    required this.servicesApi,
    required this.initialAssistant,
  });

  final String groupId;
  final ClientsApi clientsApi;
  final ServiceApi servicesApi;
  final Map<String, dynamic> initialAssistant;

  @override
  State<InsightsEventEditDialog> createState() =>
      _InsightsEventEditDialogState();
}

class _InsightsEventEditDialogState extends State<InsightsEventEditDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _locationCtrl;
  late Map<String, dynamic> _assistant;
  late Map<String, dynamic> _preview;
  late Map<String, dynamic> _payload;
  late DateTime _start;
  late DateTime _end;
  late bool _allDay;
  late Set<String> _daysOfWeek;
  List<GroupClient> _clients = const <GroupClient>[];
  List<Service> _services = const <Service>[];
  String? _selectedClientId;
  String? _selectedPrimaryServiceId;
  bool _loadingAssignments = true;
  DateTime? _untilDate;

  @override
  void initState() {
    super.initState();
    _assistant = cloneJsonMap(widget.initialAssistant);
    _preview =
        cloneJsonMap(safeMap(_assistant['preview']) ?? <String, dynamic>{});
    _payload = cloneJsonMap(
        safeMap(_preview['eventPayload']) ?? <String, dynamic>{});
    _titleCtrl = TextEditingController(
      text: _preview['title']?.toString().trim() ?? '',
    );
    _locationCtrl = TextEditingController(
      text: (_preview['localization'] ?? _preview['location'])
              ?.toString()
              .trim() ??
          '',
    );
    _allDay = _preview['allDay'] == true;
    _start =
        DateTime.tryParse(_preview['startDate']?.toString() ?? '')?.toLocal() ??
            DateTime.now();
    _end =
        DateTime.tryParse(_preview['endDate']?.toString() ?? '')?.toLocal() ??
            _start.add(const Duration(hours: 1));
    final rule = safeMap(_preview['recurrenceRule']);
    _untilDate =
        DateTime.tryParse(rule?['untilDate']?.toString() ?? '')?.toLocal();
    _daysOfWeek = ((rule?['daysOfWeek'] as List?) ?? const [])
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet();
    _selectedClientId = _payload['clientId']?.toString().trim();
    _selectedPrimaryServiceId = _payload['primaryServiceId']?.toString().trim();
    unawaited(_loadAssignments());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    if (!mounted) return;
    TimeOfDay pickedTime = TimeOfDay.fromDateTime(_start);
    if (!_allDay) {
      final time = await showTimePicker(
        context: context,
        initialTime: pickedTime,
      );
      if (time == null) return;
      if (!mounted) return;
      pickedTime = time;
    }
    setState(() {
      _start = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _allDay ? 0 : pickedTime.hour,
        _allDay ? 0 : pickedTime.minute,
      );
      if (!_end.isAfter(_start)) {
        _end = _allDay
            ? DateTime(_start.year, _start.month, _start.day, 23, 59)
            : _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    if (!mounted) return;
    TimeOfDay pickedTime = TimeOfDay.fromDateTime(_end);
    if (!_allDay) {
      final time = await showTimePicker(
        context: context,
        initialTime: pickedTime,
      );
      if (time == null) return;
      if (!mounted) return;
      pickedTime = time;
    }
    setState(() {
      _end = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _allDay ? 23 : pickedTime.hour,
        _allDay ? 59 : pickedTime.minute,
      );
    });
  }

  Future<void> _pickUntilDate() async {
    final initial = _untilDate ?? _start;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _start,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _untilDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    });
  }

  Future<void> _loadAssignments() async {
    try {
      final results = await Future.wait([
        widget.clientsApi.list(groupId: widget.groupId, active: true),
        widget.servicesApi.list(groupId: widget.groupId, active: true),
      ]);
      if (!mounted) return;
      setState(() {
        _clients = results[0] as List<GroupClient>;
        _services = results[1] as List<Service>;
        _loadingAssignments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAssignments = false);
    }
  }

  void _save() {
    if ((_selectedClientId?.isEmpty ?? true) ||
        (_selectedPrimaryServiceId?.isEmpty ?? true)) {
      final isEs = Localizations.localeOf(context)
          .languageCode
          .toLowerCase()
          .startsWith('es');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEs
                ? 'Selecciona cliente y servicio para esta visita.'
                : 'Select both client and service for this work visit.',
          ),
        ),
      );
      return;
    }
    final title = _titleCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    _preview['title'] = title;
    _preview['startDate'] = _start.toUtc().toIso8601String();
    _preview['endDate'] = _end.toUtc().toIso8601String();
    _preview['durationMinutes'] =
        _allDay ? 1440 : _end.difference(_start).inMinutes;
    _preview['localization'] = location;
    _payload['title'] = title;
    _payload['startDate'] = _start.toUtc().toIso8601String();
    _payload['endDate'] = _end.toUtc().toIso8601String();
    _payload['durationMinutes'] = _preview['durationMinutes'];
    _payload['localization'] = location;
    if (_payload.containsKey('location')) {
      _payload['location'] = location;
    }
    _payload['type'] = 'work_visit';
    _payload['clientId'] = _selectedClientId;
    _payload['primaryServiceId'] = _selectedPrimaryServiceId;
    _payload['visitServices'] = [
      {
        'serviceId': _selectedPrimaryServiceId,
      },
    ];

    final previewRule = safeMap(_preview['recurrenceRule']);
    final payloadRule = safeMap(_payload['recurrenceRule']);
    if (previewRule != null || payloadRule != null) {
      final nextPreviewRule = cloneJsonMap(previewRule ?? <String, dynamic>{});
      final nextPayloadRule = cloneJsonMap(payloadRule ?? <String, dynamic>{});
      if (_untilDate != null) {
        final iso = _untilDate!.toUtc().toIso8601String();
        nextPreviewRule['untilDate'] = iso;
        nextPayloadRule['untilDate'] = iso;
      }
      if ((nextPreviewRule['recurrenceType']?.toString() ?? '') == 'Weekly' ||
          (nextPayloadRule['recurrenceType']?.toString() ?? '') == 'Weekly') {
        final days = _daysOfWeek.toList(growable: false);
        nextPreviewRule['daysOfWeek'] = days;
        nextPayloadRule['daysOfWeek'] = days;
      }
      _preview['recurrenceRule'] = nextPreviewRule;
      _payload['recurrenceRule'] = nextPayloadRule;
    }

    final missing = ((_preview['missing'] as List?) ?? const [])
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    _preview['missing'] = missing.where((item) {
      final lower = item.toLowerCase();
      if ((_selectedClientId?.isNotEmpty ?? false) &&
          lower.contains('client')) {
        return false;
      }
      if ((_selectedClientId?.isNotEmpty ?? false) &&
          lower.contains('cliente')) {
        return false;
      }
      if ((_selectedPrimaryServiceId?.isNotEmpty ?? false) &&
          lower.contains('service')) {
        return false;
      }
      if ((_selectedPrimaryServiceId?.isNotEmpty ?? false) &&
          lower.contains('servicio')) {
        return false;
      }
      return true;
    }).toList(growable: false);
    _preview['eventPayload'] = _payload;
    _assistant['preview'] = _preview;
    _assistant['cancelled'] = false;
    Navigator.of(context).pop(_assistant);
  }

  String _dateLabel(DateTime date) {
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatMediumDate(date);
    if (_allDay) return dateLabel;
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '$dateLabel · $timeLabel';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    const weekdayOptions = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final recurrenceType =
        safeMap(_preview['recurrenceRule'])?['recurrenceType']?.toString() ??
            '';

    return AlertDialog(
      title: Text(isEs ? 'Editar evento' : 'Edit event'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: isEs ? 'Titulo' : 'Title',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationCtrl,
                decoration: InputDecoration(
                  labelText: isEs ? 'Ubicacion' : 'Location',
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingAssignments)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: (_selectedClientId?.isNotEmpty ?? false)
                      ? _selectedClientId
                      : null,
                  decoration: InputDecoration(
                    labelText: l.clientLabel,
                    helperText: isEs
                        ? 'Obligatorio para visitas de trabajo'
                        : 'Required for work visits',
                  ),
                  items: _clients
                      .map(
                        (client) => DropdownMenuItem<String>(
                          value: client.id,
                          child: Text(client.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setState(() => _selectedClientId = value?.trim()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: (_selectedPrimaryServiceId?.isNotEmpty ?? false)
                      ? _selectedPrimaryServiceId
                      : null,
                  decoration: InputDecoration(
                    labelText: l.servicePrimaryLabel,
                    helperText: isEs
                        ? 'Obligatorio para visitas de trabajo'
                        : 'Required for work visits',
                  ),
                  items: _services
                      .map(
                        (service) => DropdownMenuItem<String>(
                          value: service.id,
                          child: Text(service.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(
                    () => _selectedPrimaryServiceId = value?.trim(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(isEs ? 'Inicio' : 'Start'),
                subtitle: Text(_dateLabel(_start)),
                trailing: const Icon(Icons.edit_calendar_rounded),
                onTap: _pickStart,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(isEs ? 'Fin' : 'End'),
                subtitle: Text(_dateLabel(_end)),
                trailing: const Icon(Icons.schedule_rounded),
                onTap: _pickEnd,
              ),
              if (recurrenceType == 'Weekly') ...[
                const SizedBox(height: 8),
                Text(
                  isEs ? 'Dias de la semana' : 'Days of week',
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final day in weekdayOptions)
                      FilterChip(
                        selected: _daysOfWeek.contains(day),
                        label: Text(day),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _daysOfWeek.add(day);
                            } else {
                              _daysOfWeek.remove(day);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
              if (recurrenceType.isNotEmpty) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isEs ? 'Fin de recurrencia' : 'Recurrence end'),
                  subtitle: Text(
                    _untilDate == null
                        ? (isEs ? 'Sin fecha' : 'No end date')
                        : _dateLabel(_untilDate!),
                  ),
                  trailing: const Icon(Icons.event_repeat_rounded),
                  onTap: _pickUntilDate,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isEs ? 'Cancelar' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEs ? 'Guardar' : 'Save'),
        ),
      ],
    );
  }
}
