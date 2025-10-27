import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class CreateWorkerScreen extends StatefulWidget {
  final Group group;
  const CreateWorkerScreen({super.key, required this.group});

  @override
  State<CreateWorkerScreen> createState() => _CreateWorkerScreenState();
}

class _CreateWorkerScreenState extends State<CreateWorkerScreen> {
  final _formKey = GlobalKey<FormState>();

  late ITimeTrackingRepository _repo;
  late UserDomain _userDomain;

  // Form fields
  bool _linkToExistingUser = false;
  final TextEditingController _displayNameCtrl = TextEditingController();
  final TextEditingController _userIdCtrl = TextEditingController();
  final TextEditingController _roleCtrl = TextEditingController();
  final TextEditingController _rateCtrl = TextEditingController();
  final TextEditingController _currencyCtrl =
      TextEditingController(text: 'USD');
  final TextEditingController _notesCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ITimeTrackingRepository>();
    _userDomain = context.read<UserDomain>();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final token = await _userDomain.getAuthToken();

      Worker newWorker;
      if (_linkToExistingUser && _userIdCtrl.text.trim().isNotEmpty) {
        newWorker = Worker.newLinkedUser(
          groupId: widget.group.id,
          userId: _userIdCtrl.text.trim(),
          defaultHourlyRate:
              double.tryParse(_rateCtrl.text.trim().replaceAll(',', '.')),
          currency: _currencyCtrl.text.trim(),
          roleTag: _roleCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
      } else {
        newWorker = Worker.newExternal(
          groupId: widget.group.id,
          displayName: _displayNameCtrl.text.trim(),
          defaultHourlyRate:
              double.tryParse(_rateCtrl.text.trim().replaceAll(',', '.')),
          currency: _currencyCtrl.text.trim(),
          externalId: null,
          roleTag: _roleCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        );
      }

      await _repo.addWorker(widget.group.id, newWorker, token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.workerCreated)),
      );

      Navigator.pop(context, true); // signal success
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l.createWorkerTitle, style: t.titleLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SwitchListTile(
                title: Text(l.linkExistingUserLabel),
                subtitle: Text(l.linkExistingUserHint),
                value: _linkToExistingUser,
                onChanged: (v) => setState(() => _linkToExistingUser = v),
              ),
              const SizedBox(height: 12),
              if (_linkToExistingUser)
                TextFormField(
                  controller: _userIdCtrl,
                  decoration: InputDecoration(
                    labelText: l.userIdLabel,
                    hintText: l.userIdHint,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l.userIdRequired;
                    }
                    return null;
                  },
                )
              else
                TextFormField(
                  controller: _displayNameCtrl,
                  decoration: InputDecoration(
                    labelText: l.displayNameLabel,
                    hintText: l.displayNameHint,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l.displayNameRequired;
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roleCtrl,
                decoration: InputDecoration(
                  labelText: l.roleLabel,
                  hintText: l.roleHint,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.hourlyRateLabel,
                        hintText: l.hourlyRateHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _currencyCtrl,
                      decoration: InputDecoration(labelText: l.currencyLabel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                label: Text(l.saveWorkerCta),
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
