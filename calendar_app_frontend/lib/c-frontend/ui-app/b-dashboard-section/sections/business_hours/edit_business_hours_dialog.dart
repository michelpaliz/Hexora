import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group_business_hours.dart';
import 'package:hexora/l10n/app_localizations.dart';

Future<GroupBusinessHours?> showBusinessHoursDialog(
  BuildContext context, {
  GroupBusinessHours? initial,
}) {
  return showDialog<GroupBusinessHours>(
    context: context,
    builder: (_) => _BusinessHoursDialog(initial: initial),
  );
}

class _BusinessHoursDialog extends StatefulWidget {
  const _BusinessHoursDialog({required this.initial});

  final GroupBusinessHours? initial;

  @override
  State<_BusinessHoursDialog> createState() => _BusinessHoursDialogState();
}

class _BusinessHoursDialogState extends State<_BusinessHoursDialog> {
  TimeOfDay? _start;
  TimeOfDay? _end;
  late TextEditingController _timezoneCtrl;

  @override
  void initState() {
    super.initState();
    _start = _parse(widget.initial?.start);
    _end = _parse(widget.initial?.end);
    _timezoneCtrl = TextEditingController(
      text: widget.initial?.timezone ?? 'Europe/Madrid',
    );
  }

  @override
  void dispose() {
    _timezoneCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _parse(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String? _format(TimeOfDay? value) {
    if (value == null) return null;
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime({required bool start}) async {
    final l = AppLocalizations.of(context)!;
    final current = start ? _start : _end;
    final initial = current ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: start ? l.businessHoursStartLabel : l.businessHoursEndLabel,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _submit({bool clearWindow = false}) {
    final tz = _timezoneCtrl.text.trim().isEmpty
        ? 'Europe/Madrid'
        : _timezoneCtrl.text.trim();

    final hours = GroupBusinessHours(
      start: clearWindow ? null : _format(_start),
      end: clearWindow ? null : _format(_end),
      timezone: tz,
    );

    Navigator.of(context).pop(hours);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l.sectionBusinessHours),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TimeSelectionTile(
            label: l.businessHoursStartLabel,
            value: _format(_start) ?? '--:--',
            onPressed: () => _pickTime(start: true),
          ),
          const SizedBox(height: 8),
          _TimeSelectionTile(
            label: l.businessHoursEndLabel,
            value: _format(_end) ?? '--:--',
            onPressed: () => _pickTime(start: false),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _timezoneCtrl,
            decoration: InputDecoration(
              labelText: l.businessHoursTimezoneLabel,
              hintText: l.businessHoursTimezoneHint,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => _submit(clearWindow: true),
          child: Text(l.businessHoursReset),
        ),
        FilledButton(
          onPressed: () => _submit(),
          child: Text(l.businessHoursSave),
        ),
      ],
    );
  }
}

class _TimeSelectionTile extends StatelessWidget {
  const _TimeSelectionTile({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.4)),
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.headlineSmall),
              ],
            ),
          ),
          const Icon(Icons.schedule_rounded),
        ],
      ),
    );
  }
}
