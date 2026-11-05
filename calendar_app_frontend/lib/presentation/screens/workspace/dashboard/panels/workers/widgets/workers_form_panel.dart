import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/shared/currency_options.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/create_time_entry_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/client_editor_theme.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/client_form_fields.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/input_border.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_active_switch.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/widgets/hexora_section_tabs.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkersFormPanel extends StatelessWidget {
  final Group group;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;
  final Worker? selectedWorker;
  final List<Worker> allWorkers;
  final void Function(bool created, Worker savedWorker) onSaved;
  final TabController tabController;
  final bool enableAddHoursTab;
  final VoidCallback? onTimeEntryChanged;

  const WorkersFormPanel({
    super.key,
    required this.group,
    required this.repo,
    required this.getToken,
    required this.selectedWorker,
    required this.allWorkers,
    required this.onSaved,
    required this.tabController,
    this.enableAddHoursTab = false,
    this.onTimeEntryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // Neutral surface, no colored card wrapper around the whole form.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          HexoraSectionTabs(
            controller: tabController,
            compact: true,
            tabs: [
              Tab(text: l.editWorker),
              Tab(text: l.createWorkerCta),
              if (enableAddHoursTab) Tab(text: l.addTimeEntryCta),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                selectedWorker == null
                    ? _RequiredPlaceholder(l: l, t: t, cs: cs)
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
                      ? _RequiredPlaceholder(l: l, t: t, cs: cs)
                      : CreateTimeEntryScreen(
                          key: ValueKey('add-hours-${selectedWorker!.id}'),
                          group: group,
                          workers: allWorkers.isNotEmpty
                              ? allWorkers
                              : [selectedWorker!],
                          initialSelectedIds: {selectedWorker!.id},
                          embedded: true,
                          onCreated: onTimeEntryChanged,
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequiredPlaceholder extends StatelessWidget {
  const _RequiredPlaceholder({
    required this.l,
    required this.t,
    required this.cs,
  });

  final AppLocalizations l;
  final AppTypography t;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        l.workerRequired,
        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
        textAlign: TextAlign.center,
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

    // Reuse the Clientes form theme so label typography, floating-label
    // behaviour, hint and error styles match across modules.
    return Theme(
      data: clientEditorThemeOf(context),
      child: Builder(
        builder: (context) {
          final text = Theme.of(context).textTheme;
          final isSpanish =
              Localizations.localeOf(context).languageCode == 'es';
          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 2, bottom: 8),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClientFormFields(
                    firstFlex: 3,
                    secondFlex: 2,
                    gap: 12,
                    first: TextFormField(
                      controller: _nameCtrl,
                      style: text.bodyLarge,
                      decoration: buildInputDecoration(
                        context,
                        label: l.workerNameLabel,
                        prefixIcon: const Icon(Icons.person_outline),
                        isFilled: _nameCtrl.text.trim().isNotEmpty,
                      ),
                    ),
                    second: TextFormField(
                      controller: _roleTagCtrl,
                      style: text.bodyLarge,
                      decoration: buildInputDecoration(
                        context,
                        label: l.roleLabel,
                        prefixIcon: const Icon(Icons.badge_outlined),
                        isFilled: _roleTagCtrl.text.trim().isNotEmpty,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClientFormFields(
                    gap: 12,
                    first: TextFormField(
                      controller: _rateCtrl,
                      style: text.bodyLarge,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: buildInputDecoration(
                        context,
                        label: l.hourlyRateLabel,
                        prefixIcon: const Icon(Icons.payments_outlined),
                        isFilled: _rateCtrl.text.trim().isNotEmpty,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n < 0) return l.invalidRate;
                        return null;
                      },
                    ),
                    second: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      isExpanded: true,
                      style: text.bodyLarge,
                      items: workerCurrencyOptions
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(
                          () => _currency = v ?? defaultWorkerCurrency),
                      decoration: buildInputDecoration(
                        context,
                        label: l.currencyLabel,
                        prefixIcon:
                            const Icon(Icons.currency_exchange_outlined),
                        isFilled: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 150,
                      child: ActiveSwitch(
                        value: _status == WorkerStatus.active,
                        showIcon: false,
                        showDescription: false,
                        compact: true,
                        onChanged: (isActive) => setState(() => _status =
                            isActive
                                ? WorkerStatus.active
                                : WorkerStatus.archived),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesCtrl,
                    style: text.bodyLarge,
                    minLines: 3,
                    maxLines: 6,
                    decoration: buildInputDecoration(
                      context,
                      label: l.notesLabel,
                      hintText: isSpanish
                          ? 'Añadir notas opcionales...'
                          : 'Add optional notes...',
                      isFilled: _notesCtrl.text.trim().isNotEmpty,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: HexoraButton(
                      icon: Icons.save_outlined,
                      label:
                          widget.isCreate ? l.createWorkerCta : l.saveChanges,
                      size: HexoraButtonSize.compact,
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
