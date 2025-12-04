import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/sections/actions_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/sections/notes_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/sections/time_entry_header_strip.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/sections/time_pickers_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/sections/time_summary_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/sections/worker_selection_section.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CreateTimeEntryScreen extends StatefulWidget {
  const CreateTimeEntryScreen({
    super.key,
    required this.group,
    required this.workers,
  }) : assert(workers.length > 0);

  final Group group;
  final List<Worker> workers;

  @override
  State<CreateTimeEntryScreen> createState() => _CreateTimeEntryScreenState();
}

class _CreateTimeEntryScreenState extends State<CreateTimeEntryScreen> {
  late Set<String> _selectedWorkerIds;
  late DateTime _start;
  late DateTime _end;
  late TextEditingController _notesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedWorkerIds = {widget.workers.first.id};
    final now = DateTime.now();
    _end = now;
    _start = now.subtract(const Duration(hours: 1));
    _notesCtrl = TextEditingController();
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
      helpText: isStart ? l.startTime : l.endTime,
    );
    if (pickedTime == null) return;

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
        if (_end.isBefore(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      } else {
        _end = localDateTime;
      }
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (_selectedWorkerIds.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.workerRequiredError)));
      return;
    }
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invalidTimeRange)));
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<ITimeTrackingRepository>();
      final token = await context.read<UserDomain>().getAuthToken();
      final selected = widget.workers
          .where((w) => _selectedWorkerIds.contains(w.id))
          .toList();

      for (final w in selected) {
        final entry = TimeEntry.newEntry(
          workerId: w.id,
          start: _start.toUtc(),
          end: _end.toUtc(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
        await repo.createTimeEntry(widget.group.id, entry, token);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.timeEntryCreated)));
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
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);
    final timeFormat = DateFormat.Hm(locale);
    final selectedWorkers =
        widget.workers.where((w) => _selectedWorkerIds.contains(w.id)).toList();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
        title: Text(l.addTimeEntryCta,
            style: t.titleLarge.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TimeEntryHeaderStrip(l: l, t: t),
            const SizedBox(height: 16),
            WorkerSelectionSection(
              workers: widget.workers,
              selectedIds: _selectedWorkerIds,
              onSelectAll: () => setState(
                () => _selectedWorkerIds =
                    widget.workers.map((w) => w.id).toSet(),
              ),
              onClear: () => setState(() => _selectedWorkerIds.clear()),
              onToggle: (id, selected) => setState(() {
                if (selected) {
                  _selectedWorkerIds.add(id);
                } else {
                  _selectedWorkerIds.remove(id);
                }
              }),
            ),
            const SizedBox(height: 18),
            TimeSummarySection(
              start: _start,
              end: _end,
              dateFormat: dateFormat,
              timeFormat: timeFormat,
              selectedCount: selectedWorkers.length,
            ),
            const SizedBox(height: 16),
            TimePickersSection(
              l: l,
              t: t,
              start: _start,
              end: _end,
              dateFormat: dateFormat,
              timeFormat: timeFormat,
              onPickStart: () => _pickDateTime(true),
              onPickEnd: () => _pickDateTime(false),
            ),
            const SizedBox(height: 16),
            NotesSection(
              controller: _notesCtrl,
              l: l,
              t: t,
            ),
            const SizedBox(height: 20),
            ActionsSection(
              l: l,
              saving: _saving,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}
