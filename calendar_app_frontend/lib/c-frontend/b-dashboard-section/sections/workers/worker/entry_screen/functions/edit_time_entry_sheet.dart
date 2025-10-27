import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/b-backend/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class EditTimeEntrySheet extends StatefulWidget {
  final TimeEntry entry;
  final String groupId;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;

  const EditTimeEntrySheet({
    super.key,
    required this.entry,
    required this.groupId,
    required this.repo,
    required this.getToken,
  });

  @override
  State<EditTimeEntrySheet> createState() => _EditTimeEntrySheetState();
}

class _EditTimeEntrySheetState extends State<EditTimeEntrySheet> {
  late DateTime _start;
  late DateTime _end;
  late TextEditingController _notesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _start = widget.entry.start.toLocal();
    _end = (widget.entry.end ?? DateTime.now()).toLocal();
    _notesCtrl = TextEditingController(text: widget.entry.notes ?? '');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final l = AppLocalizations.of(context)!;
    final initial = isStart ? _start : _end;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: isStart ? l.pickStartTime : l.pickEndTime,
    );
    if (pickedTime == null) return;

    // Combine → Local → Convert to UTC for saving later
    final localDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _start = localDateTime;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = localDateTime;
      }
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final token = await widget.getToken();

      final updatedEntry = widget.entry.copyWith(
        start: _start.toUtc(),
        end: _end.toUtc(),
        notes: _notesCtrl.text.trim(),
      );

      await widget.repo.updateTimeEntry(
        widget.groupId,
        updatedEntry.id,
        updatedEntry,
        token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.timeEntryUpdated)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final dateFormat =
        DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final timeFormat =
        DateFormat.Hm(Localizations.localeOf(context).toString());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(l.editTimeEntry,
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),

          // Start time
          ListTile(
            title: Text(l.startTime),
            subtitle: Text(
              "${dateFormat.format(_start)} ${timeFormat.format(_start)}",
            ),
            onTap: () => _pickDateTime(true),
          ),

          // End time
          ListTile(
            title: Text(l.endTime),
            subtitle: Text(
              "${dateFormat.format(_end)} ${timeFormat.format(_end)}",
            ),
            onTap: () => _pickDateTime(false),
          ),

          TextField(
            controller: _notesCtrl,
            decoration: InputDecoration(labelText: l.notesLabel),
            maxLines: 3,
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(l.saveChanges),
            ),
          ),
        ],
      ),
    );
  }
}
