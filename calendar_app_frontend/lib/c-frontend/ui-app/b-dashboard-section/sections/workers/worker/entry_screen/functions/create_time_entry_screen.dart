import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/shared/currency_options.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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

  static const String _allCurrenciesKey = '__all__';

  final GlobalKey<FormFieldState<List<Worker>>> _workerFieldKey =
      GlobalKey<FormFieldState<List<Worker>>>();

  late List<Worker> _selectedWorkers;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(hours: 1));
  final TextEditingController _notesCtrl = TextEditingController();
  String? _currencyFilter;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _selectedDay = DateTime.now().day;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ITimeTrackingRepository>();
    _userDomain = context.read<UserDomain>();
    _selectedYear = _start.year;
    _selectedMonth = _start.month;
    _selectedDay = _start.day;
    _selectedWorkers =
        widget.workers.isNotEmpty ? [widget.workers.first] : <Worker>[];

    final defaultCurrencyWorkers = _workersMatching(defaultWorkerCurrency);
    if (defaultCurrencyWorkers.isNotEmpty) {
      _currencyFilter = defaultWorkerCurrency;
      _selectedWorkers = [defaultCurrencyWorkers.first];
    } else if (widget.workers.isNotEmpty) {
      _currencyFilter = widget.workers.first.currency?.toUpperCase();
      final fallback = _workersMatching(_currencyFilter);
      if (fallback.isNotEmpty) {
        _selectedWorkers = [fallback.first];
      }
    } else {
      _currencyFilter = defaultWorkerCurrency;
    }
    _ensureSelectionMatchesFilter();
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
      _selectedYear = _start.year;
      _selectedMonth = _start.month;
      _selectedDay = _start.day;
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
      if (!_end.isAfter(_start)) {
        _end = _start.add(const Duration(hours: 1));
      }
    });
  }

  List<Worker> get _filteredWorkers => _workersMatching(_currencyFilter);

  List<Worker> _workersMatching(String? currency) {
    if (currency == null) return widget.workers;
    return widget.workers.where((w) => _workerCurrency(w) == currency).toList();
  }

  List<String> get _availableCurrencies {
    final set = <String>{};
    for (final worker in widget.workers) {
      final c = worker.currency;
      if (c != null && c.isNotEmpty) {
        set.add(c.toUpperCase());
      }
    }
    set.addAll(workerCurrencyOptions);
    final list = set.toList()..sort();
    return list;
  }

  String _workerCurrency(Worker worker) {
    final value = worker.currency;
    if (value == null || value.isEmpty) return defaultWorkerCurrency;
    return value.toUpperCase();
  }

  void _setSelectedWorkers(List<Worker> workers) {
    setState(() {
      _selectedWorkers = workers;
    });
    _workerFieldKey.currentState?.didChange(_selectedWorkers);
  }

  void _ensureSelectionMatchesFilter() {
    final filtered = _filteredWorkers;
    if (_selectedWorkers.isEmpty && filtered.isNotEmpty) {
      _selectedWorkers = [filtered.first];
      return;
    }
    _selectedWorkers = _selectedWorkers
        .where((w) => filtered.any((fw) => fw.id == w.id))
        .toList();
    if (_selectedWorkers.isEmpty && filtered.isNotEmpty) {
      _selectedWorkers = [filtered.first];
    }
  }

  void _removeWorker(Worker worker) {
    final updated = _selectedWorkers.where((w) => w.id != worker.id).toList();
    _setSelectedWorkers(updated);
  }

  Future<void> _showWorkerPicker() async {
    final available = _filteredWorkers;
    if (available.isEmpty) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.noWorkersYetTitle)),
        );
      }
      return;
    }

    final currentIds = _selectedWorkers.map((w) => w.id).toSet();
    final chosen = await showDialog<List<Worker>>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context)!;
        final tempSelected = currentIds.toSet();
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(l.dialogShowUsers),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView(
                  children: available.map((worker) {
                    final checked = tempSelected.contains(worker.id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (value) {
                        setStateDialog(() {
                          if (value == true) {
                            tempSelected.add(worker.id);
                          } else {
                            tempSelected.remove(worker.id);
                          }
                        });
                      },
                      title: Text(_workerDisplayName(worker, l)),
                      subtitle: Text(_workerCurrency(worker)),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: tempSelected.isEmpty
                      ? null
                      : () {
                          final selection = available
                              .where((w) => tempSelected.contains(w.id))
                              .toList();
                          Navigator.of(context).pop(selection);
                        },
                  child: Text(l.confirm),
                ),
              ],
            );
          },
        );
      },
    );

    if (chosen != null && chosen.isNotEmpty) {
      _setSelectedWorkers(chosen);
    }
  }

  void _onCurrencyChanged(String? currency) {
    final normalized = currency?.toUpperCase();
    final filtered = _workersMatching(normalized);
    setState(() {
      _currencyFilter = normalized;
      _selectedWorkers = _selectedWorkers
          .where((w) => filtered.any((fw) => fw.id == w.id))
          .toList();
      if (_selectedWorkers.isEmpty && filtered.isNotEmpty) {
        _selectedWorkers = [filtered.first];
      }
    });
    _workerFieldKey.currentState?.didChange(_selectedWorkers);
  }

  void _applyDateSelections({int? month, int? day}) {
    final duration = _end.difference(_start);
    final startHour = _start.hour;
    final startMinute = _start.minute;
    final nextYear = _selectedYear;
    final nextMonth = month ?? _selectedMonth;
    final maxDay = DateUtils.getDaysInMonth(nextYear, nextMonth);
    var targetDay = day ?? _selectedDay;
    if (targetDay > maxDay) targetDay = maxDay;
    if (targetDay < 1) targetDay = 1;

    setState(() {
      _selectedMonth = nextMonth;
      _selectedDay = targetDay;
      final newStart = DateTime(
        _selectedYear,
        _selectedMonth,
        _selectedDay,
        startHour,
        startMinute,
      );
      var newEnd = duration.isNegative
          ? newStart.add(const Duration(hours: 1))
          : newStart.add(duration);
      if (!newEnd.isAfter(newStart)) {
        newEnd = newStart.add(const Duration(hours: 1));
      }
      _start = newStart;
      _end = newEnd;
    });
  }

  String _workerDisplayName(Worker worker, AppLocalizations l) =>
      worker.displayName ?? worker.userId ?? l.unknownWorker;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWorkers.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.workerRequired)));
      return;
    }
    if (!_end.isAfter(_start)) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.endDateMustBeAfterStartDate)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final token = await _userDomain.getAuthToken();
      final trimmedNotes = _notesCtrl.text.trim();
      for (final worker in _selectedWorkers) {
        final entry = TimeEntry.newEntry(
          workerId: worker.id,
          start: _start,
          end: _end,
          notes: trimmedNotes.isEmpty ? null : trimmedNotes,
        );
        await _repo.createTimeEntry(widget.group.id, entry, token);
      }

      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      final message = _selectedWorkers.length == 1
          ? l.timeEntryCreated
          : '${l.timeEntryCreated} (${_selectedWorkers.length})';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
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
              Text(l.pickMonth, style: t.bodyMedium),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(12, (index) {
                    final monthIndex = index + 1;
                    final date = DateTime(_selectedYear, monthIndex, 1);
                    final label = DateFormat.MMM().format(date);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _selectedMonth == monthIndex,
                        onSelected: (_) =>
                            _applyDateSelections(month: monthIndex),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.selectDay),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  DateUtils.getDaysInMonth(_selectedYear, _selectedMonth),
                  (index) {
                    final day = index + 1;
                    return ChoiceChip(
                      label: Text(day.toString()),
                      selected: _selectedDay == day,
                      onSelected: (_) => _applyDateSelections(day: day),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: (_currencyFilter ?? _allCurrenciesKey),
                decoration: InputDecoration(labelText: l.currencyLabel),
                items: [
                  DropdownMenuItem(
                    value: _allCurrenciesKey,
                    child: Text(l.all),
                  ),
                  ..._availableCurrencies.map(
                    (code) => DropdownMenuItem(
                      value: code,
                      child: Text(code),
                    ),
                  ),
                ],
                onChanged: (value) => _onCurrencyChanged(
                  value == _allCurrenciesKey ? null : value,
                ),
              ),
              const SizedBox(height: 12),
              FormField<List<Worker>>(
                key: _workerFieldKey,
                validator: (_) =>
                    _selectedWorkers.isEmpty ? l.workerRequired : null,
                builder: (state) {
                  final hasWorkers = _filteredWorkers.isNotEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: l.workerLabel,
                          errorText: state.errorText,
                        ),
                        child: _selectedWorkers.isEmpty
                            ? Text(
                                l.dialogShowUsers,
                                style: t.bodyMedium.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedWorkers
                                    .map(
                                      (worker) => InputChip(
                                        label:
                                            Text(_workerDisplayName(worker, l)),
                                        onDeleted: () => _removeWorker(worker),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: hasWorkers ? _showWorkerPicker : null,
                          icon: const Icon(Icons.group_add_outlined),
                          label: Text(l.dialogShowUsers),
                        ),
                      ),
                      if (!hasWorkers)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l.noWorkersYetSubtitle,
                            style: t.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  );
                },
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
