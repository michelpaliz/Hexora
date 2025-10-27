import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CreateTimeEntryScreen extends StatefulWidget {
  final Group group;
  final List<Worker> workers;

  const CreateTimeEntryScreen({
    super.key,
    required this.group,
    required this.workers,
  });

  @override
  State<CreateTimeEntryScreen> createState() => _CreateTimeEntryScreenState();
}

class _CreateTimeEntryScreenState extends State<CreateTimeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late ITimeTrackingRepository _repo;
  late UserDomain _userDomain;

  Worker? _selectedWorker;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(hours: 1));
  final TextEditingController _notesCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ITimeTrackingRepository>();
    _userDomain = context.read<UserDomain>();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null) return;

    setState(() {
      _start = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
      if (_end.isBefore(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
    );
    if (time == null) return;

    setState(() {
      _end = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWorker == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Select a worker first.')));
      return;
    }

    setState(() => _saving = true);

    try {
      final token = await _userDomain.getAuthToken();

      final entry = TimeEntry.newEntry(
        workerId: _selectedWorker!.id,
        start: _start,
        end: _end,
        notes: _notesCtrl.text.trim(),
      );

      await _repo.createTimeEntry(widget.group.id, entry, token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.timeEntryCreated)),
      );
      Navigator.pop(context, true);
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

    final df = DateFormat('yMMMd, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(l.createTimeEntryTitle, style: t.titleLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<Worker>(
                value: _selectedWorker,
                decoration: InputDecoration(labelText: l.workerLabel),
                items: widget.workers.map((w) {
                  final name = w.displayName ?? w.userId ?? 'Unnamed';
                  return DropdownMenuItem(value: w, child: Text(name));
                }).toList(),
                onChanged: (w) => setState(() => _selectedWorker = w),
                validator: (w) => w == null ? l.workerRequired : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('${l.startLabel}: ${df.format(_start)}'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickStart,
              ),
              ListTile(
                title: Text('${l.endLabel}: ${df.format(_end)}'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickEnd,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: l.notesLabel,
                  hintText: l.notesHint,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _saving
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Icon(Icons.save_outlined),
                label: Text(l.saveTimeEntryCta),
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
