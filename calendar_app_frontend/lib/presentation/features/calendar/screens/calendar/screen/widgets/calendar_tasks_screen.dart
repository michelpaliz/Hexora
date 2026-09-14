import 'package:flutter/material.dart';
import 'package:hexora/models/event/model/event.dart';
import 'package:hexora/models/group/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/data/group_management/event/repository/i_event_repository.dart';
import 'package:hexora/data/user/domain/user_domain.dart';
import 'package:hexora/theme/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarTasksScreen extends StatefulWidget {
  const CalendarTasksScreen({
    super.key,
    required this.group,
  });

  final Group group;

  @override
  State<CalendarTasksScreen> createState() => _CalendarTasksScreenState();
}

class _CalendarTasksScreenState extends State<CalendarTasksScreen> {
  static const _pendingStatuses = <String>{
    'pending',
    'open',
    'active',
  };

  final Set<String> _updatingIds = <String>{};
  List<Event> _tasks = <Event>[];
  List<User> _groupUsers = <User>[];
  bool _loading = true;
  bool _loadingUsers = false;
  bool _creating = false;
  bool _mineOnly = false;
  String _statusFilter = 'pending';

  String _formatDueDate(BuildContext context, DateTime dueAt) => DateFormat(
        'EEE, d MMM · HH:mm',
        Localizations.localeOf(context).toString(),
      ).format(dueAt);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        _loadTasks(),
        _loadUsers(),
      ]);
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final users = await context.read<UserDomain>().getUsersForGroup(widget.group);
      if (!mounted) return;
      setState(() {
        _groupUsers = users;
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() => _loadingUsers = false);
      }
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final tasks = await context.read<IEventRepository>().getTasks(
            groupId: widget.group.id,
            status: _statusFilter == 'all' ? 'all' : _statusFilter,
            mine: _mineOnly,
          );
      if (!mounted) return;
      setState(() {
        _tasks = [...tasks]..sort((a, b) => a.startDate.compareTo(b.startDate));
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.calendarTasksLoadError,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _matchesStatus(Event task) {
    if (_statusFilter == 'all') return true;
    if (_statusFilter == 'done') return task.isCompleted;
    return !task.isCompleted ||
        (task.status != null && _pendingStatuses.contains(task.status));
  }

  Future<void> _toggleDone(Event task, bool nextValue) async {
    final index = _tasks.indexWhere((e) => e.id == task.id);
    if (index == -1) return;
    final previous = _tasks[index];
    final updated = previous.copyWith(
      isDone: nextValue,
      completedAt: nextValue ? DateTime.now() : null,
      status: nextValue ? 'done' : 'pending',
    );

    setState(() {
      _updatingIds.add(task.id);
      _tasks[index] = updated;
      if (!_matchesStatus(updated)) {
        _tasks.removeAt(index);
      }
    });

    try {
      await context
          .read<IEventRepository>()
          .markEventAsDone(task.id, isDone: nextValue);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (index <= _tasks.length) {
          if (_matchesStatus(previous)) {
            final existingIndex = _tasks.indexWhere((e) => e.id == previous.id);
            if (existingIndex == -1) {
              _tasks.insert(index.clamp(0, _tasks.length), previous);
            } else {
              _tasks[existingIndex] = previous;
            }
          } else {
            final existingIndex = _tasks.indexWhere((e) => e.id == previous.id);
            if (existingIndex != -1) {
              _tasks.removeAt(existingIndex);
            }
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.calendarTasksUpdateError,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingIds.remove(task.id));
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final selectedRecipients = <String>{};
    DateTime dueAt = DateTime.now();
    int reminderTime = 0;
    bool notifyOwner = true;
    final reminders = <int, String>{
      0: AppLocalizations.of(context)!.calendarTasksReminderAtDueTime,
      10: AppLocalizations.of(context)!.calendarTasksReminder10Minutes,
      30: AppLocalizations.of(context)!.calendarTasksReminder30Minutes,
      60: AppLocalizations.of(context)!.calendarTasksReminder1Hour,
    };

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final typo = AppTypography.of(dialogContext);
        final l = AppLocalizations.of(dialogContext)!;
        return StatefulBuilder(
          builder: (context, setLocal) {
            Future<void> pickDateTime() async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: dueAt,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (pickedDate == null || !context.mounted) return;
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(dueAt),
              );
              if (pickedTime == null) return;
              setLocal(() {
                dueAt = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }

            final canSubmit = titleCtrl.text.trim().isNotEmpty && !_creating;

            return AlertDialog(
              backgroundColor: cs.surface,
              title: Text(l.calendarTasksNew),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        autofocus: true,
                        onChanged: (_) => setLocal(() {}),
                        decoration: InputDecoration(
                          labelText: l.calendarTasksTitleLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l.calendarTasksNoteLabel,
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: pickDateTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule_rounded, color: cs.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.calendarTasksDue,
                                      style: typo.bodySmall.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDueDate(dialogContext, dueAt),
                                      style: typo.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit_calendar_rounded),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: reminderTime,
                        items: reminders.entries
                            .map(
                              (entry) => DropdownMenuItem<int>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setLocal(() => reminderTime = value ?? 0),
                        decoration: InputDecoration(
                          labelText: l.calendarTasksReminder,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: notifyOwner,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l.calendarTasksNotifyOwner,
                        ),
                        onChanged: (value) =>
                            setLocal(() => notifyOwner = value),
                      ),
                      if (_groupUsers.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          l.calendarTasksAssignUsers,
                          style: typo.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _groupUsers.map((user) {
                            final selected = selectedRecipients.contains(user.id);
                            final label = (user.displayName?.trim().isNotEmpty ?? false)
                                ? user.displayName!.trim()
                                : user.name;
                            return FilterChip(
                              label: Text(label),
                              selected: selected,
                              onSelected: (value) {
                                setLocal(() {
                                  if (value) {
                                    selectedRecipients.add(user.id);
                                  } else {
                                    selectedRecipients.remove(user.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ] else if (_loadingUsers) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(minHeight: 2),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _creating
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: Text(l.cancel),
                ),
                FilledButton.icon(
                  onPressed: canSubmit
                      ? () async {
                          setState(() => _creating = true);
                          try {
                            await context.read<IEventRepository>().createTask(
                                  groupId: widget.group.id,
                                  title: titleCtrl.text.trim(),
                                  note: noteCtrl.text.trim().isEmpty
                                      ? null
                                      : noteCtrl.text.trim(),
                                  dueAt: dueAt,
                                  reminderTime: reminderTime,
                                  recipients: selectedRecipients.toList(),
                                  notifyOwner: notifyOwner,
                                );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop(true);
                          } catch (error) {
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l.calendarTasksCreateError,
                                ),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _creating = false);
                            }
                          }
                        }
                      : null,
                  icon: _creating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_task_rounded),
                  label: Text(l.calendarTasksCreate),
                ),
              ],
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    noteCtrl.dispose();

    if (created == true && mounted) {
      await _loadTasks();
    }
  }

  Color _statusColor(BuildContext context, Event task) {
    final cs = Theme.of(context).colorScheme;
    if (task.isCompleted) return Colors.greenAccent;
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.tasks,
                      style: typo.bodyLarge.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.calendarTasksSubtitle,
                      style: typo.bodyMedium.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip('pending', l.calendarTasksPendingPlural),
                        _buildFilterChip('done', l.calendarTasksDonePlural),
                        _buildFilterChip('all', l.all),
                        FilterChip(
                          label: Text(l.calendarTasksMine),
                          selected: _mineOnly,
                          onSelected: (value) async {
                            setState(() => _mineOnly = value);
                            await _loadTasks();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _creating ? null : _showCreateDialog,
                icon: const Icon(Icons.add_rounded),
                label: Text(l.calendarTasksNew),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? Center(
                        child: Text(
                          l.calendarTasksEmpty,
                          style: typo.bodyMedium.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: _tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          final updating = _updatingIds.contains(task.id);
                          final due = task.startDate;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(
                                alpha: task.isCompleted ? 0.12 : 0.2,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _statusColor(context, task).withValues(
                                  alpha: task.isCompleted ? 0.22 : 0.36,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: task.isCompleted,
                                  onChanged: updating
                                      ? null
                                      : (value) => _toggleDone(
                                            task,
                                            value ?? false,
                                          ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: typo.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w800,
                                          decoration: task.isCompleted
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                      ),
                                      if (task.note?.trim().isNotEmpty ?? false) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          task.note!.trim(),
                                          style: typo.bodyMedium.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 180,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatDueDate(context, due),
                                        style: typo.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.end,
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(context, task)
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          task.isCompleted
                                              ? l.calendarTasksDone
                                              : l.calendarTasksPending,
                                          style: typo.bodySmall.copyWith(
                                            color: _statusColor(context, task),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _statusFilter == value,
      onSelected: (selected) async {
        if (!selected) return;
        setState(() => _statusFilter = value);
        await _loadTasks();
      },
    );
  }
}
