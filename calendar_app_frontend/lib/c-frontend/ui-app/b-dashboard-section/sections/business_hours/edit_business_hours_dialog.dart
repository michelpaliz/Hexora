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

  bool get _hasPartialSelection =>
      (_start == null) != (_end == null); // only one selected
  bool get _hasCompleteSelection => _start != null && _end != null;

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
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    final previewValue = _hasCompleteSelection
        ? '${_format(_start)} – ${_format(_end)}'
        : l.businessHoursUnset;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.sectionBusinessHours, style: textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            l.businessHoursMemberSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      color: cs.primary.withOpacity(0.8)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.sectionBusinessHours,
                        style: textTheme.labelLarge
                            ?.copyWith(color: cs.primary, letterSpacing: 0.1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        previewValue,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _TimeSelectionTile(
              label: l.businessHoursStartLabel,
              value: _format(_start) ?? '--:--',
              onPressed: () => _pickTime(start: true),
            ),
            const SizedBox(height: 10),
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
                prefixIcon: const Icon(Icons.public),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_hasPartialSelection) ...[
              const SizedBox(height: 10),
              Text(
                l.businessHoursPartialError,
                style: textTheme.bodySmall
                    ?.copyWith(color: cs.error, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
      actions: [
        OverflowBar(
          alignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.cancel),
            ),
            OutlinedButton(
              onPressed: () => _submit(clearWindow: true),
              child: Text(l.businessHoursReset),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: Text(l.businessHoursSave),
              onPressed: _hasPartialSelection ? null : () => _submit(),
            ),
          ],
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
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceVariant.withOpacity(0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.schedule_rounded, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
