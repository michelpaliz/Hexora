import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/shared/currency_options.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

class EditWorkerSheet extends StatefulWidget {
  const EditWorkerSheet({
    super.key,
    required this.group,
    required this.worker,
    required this.repo,
    required this.getToken,
    this.scrollController,
  });

  final Group group;
  final Worker worker;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;
  final ScrollController? scrollController;

  @override
  State<EditWorkerSheet> createState() => _EditWorkerSheetState();
}

class _EditWorkerSheetState extends State<EditWorkerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _roleTagCtrl;
  late final TextEditingController _notesCtrl;
  String _currency = defaultWorkerCurrency;
  late WorkerStatus _status;
  late String _operationalRole;
  bool _saving = false;
  bool _discarding = false;

  @override
  void initState() {
    super.initState();
    final worker = widget.worker;
    _nameCtrl = TextEditingController(text: worker.displayName ?? '');
    _rateCtrl = TextEditingController(
      text: (worker.defaultHourlyRate ?? '').toString(),
    );
    _roleTagCtrl = TextEditingController(text: worker.roleTag ?? '');
    _notesCtrl = TextEditingController(text: worker.notes ?? '');
    _currency = worker.currency ?? defaultWorkerCurrency;
    _status = worker.status;
    _operationalRole = worker.operationalRole;
  }

  bool get _hasChanges {
    final worker = widget.worker;
    return _nameCtrl.text.trim() != (worker.displayName ?? '').trim() ||
        _rateCtrl.text.trim() != (worker.defaultHourlyRate ?? '').toString() ||
        _roleTagCtrl.text.trim() != (worker.roleTag ?? '').trim() ||
        _notesCtrl.text.trim() != (worker.notes ?? '').trim() ||
        _currency != (worker.currency ?? defaultWorkerCurrency) ||
        _status != worker.status ||
        _operationalRole != worker.operationalRole;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    _roleTagCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmDiscard() async {
    if (!_hasChanges || _saving || _discarding) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar cambios'),
        content:
            const Text('Tienes cambios sin guardar. ¿Quieres descartarlos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _discarding = true);
      Navigator.of(context).pop();
    }
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
        operationalRole: _operationalRole,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status: _status,
      );
      final savedWorker = await widget.repo.updateWorker(
        widget.group.id,
        widget.worker.id,
        updatedWorker,
        token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.workerUpdated)),
      );
      Navigator.of(context).pop(savedWorker);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeWorker() async {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final name = (widget.worker.displayName ?? '').trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isSpanish ? 'Eliminar trabajador' : 'Remove worker'),
        content: Text(
          isSpanish
              ? '¿Quieres eliminar a ${name.isEmpty ? 'este trabajador' : name} de la lista activa? Sus horas y visitas anteriores se conservarán.'
              : 'Remove ${name.isEmpty ? 'this worker' : name} from the active list? Previous hours and visits will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isSpanish ? 'Eliminar' : 'Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final token = await widget.getToken();
      final savedWorker = await widget.repo.updateWorker(
        widget.group.id,
        widget.worker.id,
        widget.worker.copyWith(status: WorkerStatus.archived),
        token,
      );
      if (!mounted) return;
      Navigator.of(context).pop(savedWorker);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !_hasChanges || _saving || _discarding,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: SafeArea(
        top: false,
        child: Column(children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l.editWorker,
                style:
                    typography.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: widget.scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _decoration(l.workerNameLabel),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _rateCtrl,
                        decoration: _decoration(l.hourlyRateLabel),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return null;
                          final amount =
                              double.tryParse(value.replaceAll(',', '.'));
                          return amount == null || amount < 0
                              ? l.invalidRate
                              : null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _currency,
                            decoration: _decoration(l.currencyLabel),
                            items: workerCurrencyOptions
                                .map((currency) => DropdownMenuItem(
                                    value: currency, child: Text(currency)))
                                .toList(),
                            onChanged: (value) => setState(() =>
                                _currency = value ?? defaultWorkerCurrency),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<WorkerStatus>(
                            isExpanded: true,
                            initialValue: _status,
                            decoration: _decoration(l.statusLabel),
                            items: [
                              DropdownMenuItem(
                                  value: WorkerStatus.active,
                                  child: Text(l.statusActive)),
                              DropdownMenuItem(
                                  value: WorkerStatus.archived,
                                  child: Text(l.statusInactive)),
                            ],
                            onChanged: (value) => setState(
                                () => _status = value ?? WorkerStatus.active),
                          ),
                        ),
                      ]),
                      if (widget.worker.userId != null &&
                          widget.worker.account == null) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _operationalRole,
                          decoration: _decoration('Rol de trabajador'),
                          items: const [
                            DropdownMenuItem(
                                value: 'worker', child: Text('Trabajador')),
                            DropdownMenuItem(
                                value: 'supervisor', child: Text('Supervisor')),
                          ],
                          onChanged: (value) => setState(
                              () => _operationalRole = value ?? 'worker'),
                        ),
                      ],
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _roleTagCtrl,
                        decoration: _decoration(l.roleLabel),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _notesCtrl,
                        decoration: _decoration(l.notesLabel),
                        minLines: 2,
                        maxLines: 3,
                      ),
                    ]),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
            child: Row(
              children: [
                if (widget.worker.status == WorkerStatus.active) ...[
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: _saving ? null : _removeWorker,
                        icon:
                            const Icon(Icons.person_remove_outlined, size: 18),
                        label: Text(
                          Localizations.localeOf(context).languageCode == 'es'
                              ? 'Eliminar trabajador'
                              : 'Remove worker',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(l.saveChanges),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
