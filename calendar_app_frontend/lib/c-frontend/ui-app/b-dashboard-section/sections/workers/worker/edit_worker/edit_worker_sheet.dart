import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/shared/currency_options.dart';

class EditWorkerSheet extends StatefulWidget {
  final Group group;
  final Worker worker;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;

  const EditWorkerSheet({
    super.key,
    required this.group,
    required this.worker,
    required this.repo,
    required this.getToken,
  });

  @override
  State<EditWorkerSheet> createState() => _EditWorkerSheetState();
}

class _EditWorkerSheetState extends State<EditWorkerSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _roleTagCtrl;
  late TextEditingController _notesCtrl;
  String _currency = defaultWorkerCurrency;
  late WorkerStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final w = widget.worker;
    _nameCtrl = TextEditingController(text: w.displayName ?? '');
    _rateCtrl = TextEditingController(
      text: (w.defaultHourlyRate ?? '').toString(),
    );
    _roleTagCtrl = TextEditingController(text: w.roleTag ?? '');
    _notesCtrl = TextEditingController(text: w.notes ?? '');
    _currency = (w.currency ?? defaultWorkerCurrency);
    _status = w.status;
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

      await widget.repo.updateWorker(
        widget.group.id,
        widget.worker.id,
        updatedWorker,
        token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.workerUpdated)),
      );
      Navigator.of(context).pop(true);
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Form(
        key: _formKey,
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
              child: Text(
                l.editWorker,
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: l.workerNameLabel),
            ),
            TextFormField(
              controller: _rateCtrl,
              decoration: InputDecoration(labelText: l.hourlyRateLabel),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n < 0) return l.invalidRate;
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    items: workerCurrencyOptions
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _currency = v ?? defaultWorkerCurrency),
                    decoration: InputDecoration(labelText: l.currencyLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<WorkerStatus>(
                    value: _status,
                    items: [
                      DropdownMenuItem(
                          value: WorkerStatus.active,
                          child: Text(l.statusActive)),
                      DropdownMenuItem(
                          value: WorkerStatus.archived,
                          child: Text(l.statusInactive)),
                    ],
                    onChanged: (v) =>
                        setState(() => _status = v ?? WorkerStatus.active),
                    decoration: InputDecoration(labelText: l.statusLabel),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _roleTagCtrl,
              decoration: InputDecoration(labelText: l.roleLabel),
            ),
            TextFormField(
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
      ),
    );
  }
}
