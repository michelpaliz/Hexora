import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/shared/currency_options.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/create_time_entry_screen.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkersFormPanel extends StatelessWidget {
  final Group group;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;
  final Worker? selectedWorker;
  final void Function(bool created, Worker savedWorker) onSaved;
  final TabController tabController;
  final bool enableAddHoursTab;

  const WorkersFormPanel({
    super.key,
    required this.group,
    required this.repo,
    required this.getToken,
    required this.selectedWorker,
    required this.onSaved,
    required this.tabController,
    this.enableAddHoursTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? cs.surface : cs.surfaceContainerHighest;

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: (isDark
                        ? cs.surfaceContainerHigh
                        : cs.surfaceContainerHighest)
                    .withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                dividerColor: Colors.transparent,
                labelColor: cs.onPrimary,
                unselectedLabelColor: cs.onSurface,
                labelStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                indicator: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                tabs: [
                  Tab(text: l.editWorker),
                  Tab(text: l.createWorkerCta),
                  if (enableAddHoursTab) Tab(text: l.addTimeEntryCta),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  selectedWorker == null
                      ? Center(
                          child: Text(
                            l.workerRequired,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _WorkerEditorForm(
                          key: ValueKey('edit-${selectedWorker!.id}'),
                          group: group,
                          repo: repo,
                          getToken: getToken,
                          worker: selectedWorker!,
                          isCreate: false,
                          onSaved: onSaved,
                        ),
                  _WorkerEditorForm(
                    key: const ValueKey('create-worker'),
                    group: group,
                    repo: repo,
                    getToken: getToken,
                    worker: Worker.newExternal(groupId: group.id),
                    isCreate: true,
                    onSaved: onSaved,
                  ),
                  if (enableAddHoursTab)
                    selectedWorker == null
                        ? Center(
                            child: Text(
                              l.workerRequired,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : CreateTimeEntryScreen(
                            group: group,
                            workers: [selectedWorker!],
                            embedded: true,
                          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerEditorForm extends StatefulWidget {
  final Group group;
  final Worker worker;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;
  final bool isCreate;
  final void Function(bool created, Worker savedWorker) onSaved;

  const _WorkerEditorForm({
    super.key,
    required this.group,
    required this.worker,
    required this.repo,
    required this.getToken,
    required this.isCreate,
    required this.onSaved,
  });

  @override
  State<_WorkerEditorForm> createState() => _WorkerEditorFormState();
}

class _WorkerEditorFormState extends State<_WorkerEditorForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _roleTagCtrl;
  late TextEditingController _notesCtrl;
  String _currency = defaultWorkerCurrency;
  late WorkerStatus _status;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _seedFromWorker(widget.worker);
  }

  @override
  void didUpdateWidget(covariant _WorkerEditorForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worker.id != widget.worker.id ||
        oldWidget.isCreate != widget.isCreate) {
      _seedFromWorker(widget.worker);
    }
  }

  void _seedFromWorker(Worker w) {
    if (_initialized) {
      _nameCtrl.dispose();
      _rateCtrl.dispose();
      _roleTagCtrl.dispose();
      _notesCtrl.dispose();
    }
    _nameCtrl = TextEditingController(text: w.displayName ?? '');
    _rateCtrl = TextEditingController(
      text: (w.defaultHourlyRate ?? '').toString(),
    );
    _roleTagCtrl = TextEditingController(text: w.roleTag ?? '');
    _notesCtrl = TextEditingController(text: w.notes ?? '');
    _currency = (w.currency ?? defaultWorkerCurrency);
    _status = w.status;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    _roleTagCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final token = await widget.getToken();

      final updatedWorker = widget.worker.copyWith(
        displayName:
            _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        defaultHourlyRate: double.tryParse(_rateCtrl.text.replaceAll(',', '.')),
        currency: _currency,
        roleTag:
            _roleTagCtrl.text.trim().isEmpty ? null : _roleTagCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status: _status,
      );

      final saved = widget.isCreate
          ? await widget.repo.addWorker(widget.group.id, updatedWorker, token)
          : await widget.repo.updateWorker(
              widget.group.id, widget.worker.id, updatedWorker, token);

      if (!mounted) return;
      widget.onSaved(widget.isCreate, saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final inputTextStyle = t.bodyMedium;
    final labelTextStyle =
        t.bodySmall.copyWith(color: cs.onSurface.withOpacity(0.7));

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.isCreate ? l.createWorkerCta : l.editWorker,
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _SectionCard(
                    title: l.workerLabel,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          style: inputTextStyle,
                          decoration: InputDecoration(
                            labelText: l.workerNameLabel,
                            labelStyle: labelTextStyle,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _roleTagCtrl,
                          style: inputTextStyle,
                          decoration: InputDecoration(
                            labelText: l.roleLabel,
                            labelStyle: labelTextStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: l.totalHours,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _rateCtrl,
                          style: inputTextStyle,
                          decoration: InputDecoration(
                            labelText: l.hourlyRateLabel,
                            labelStyle: labelTextStyle,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = double.tryParse(v.replaceAll(',', '.'));
                            if (n == null || n < 0) return l.invalidRate;
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: l.currencyLabel,
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            style: inputTextStyle,
                            items: workerCurrencyOptions
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setState(
                                () => _currency = v ?? defaultWorkerCurrency),
                            decoration: InputDecoration(
                              labelText: l.currencyLabel,
                              labelStyle: labelTextStyle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<WorkerStatus>(
                            initialValue: _status,
                            style: inputTextStyle,
                            items: [
                              DropdownMenuItem(
                                value: WorkerStatus.active,
                                child: Text(l.statusActive),
                              ),
                              DropdownMenuItem(
                                value: WorkerStatus.archived,
                                child: Text(l.statusInactive),
                              ),
                            ],
                            onChanged: (v) => setState(
                                () => _status = v ?? WorkerStatus.active),
                            decoration: InputDecoration(
                              labelText: l.statusLabel,
                              labelStyle: labelTextStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: l.notesLabel,
                    child: TextFormField(
                      controller: _notesCtrl,
                      style: inputTextStyle,
                      decoration: InputDecoration(
                        labelText: l.notesLabel,
                        labelStyle: labelTextStyle,
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                          widget.isCreate ? l.createWorkerCta : l.saveChanges),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? cs.surfaceContainerHigh.withOpacity(0.75)
        : cs.surfaceContainerHighest.withOpacity(0.45);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
