import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/shared/currency_options.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
  final TextEditingController _notesCtrl = TextEditingController();
  List<User> _members = const [];
  bool _loadingMembers = false;
  String? _membersError;
  String _operationalRole = 'worker';
  String _selectedCurrency = defaultWorkerCurrency;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ITimeTrackingRepository>();
    _userDomain = context.read<UserDomain>();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _membersError = null;
    });
    try {
      final members = await _userDomain.getUsersForGroup(widget.group);
      if (!members.any((member) => member.id == widget.group.ownerId)) {
        try {
          members.add(await _userDomain.userRepository.getUserById(widget.group.ownerId));
        } catch (_) {
          // The member list can still be used if the owner profile is unavailable.
        }
      }
      if (mounted) setState(() => _members = members);
    } catch (_) {
      if (mounted) setState(() => _membersError = 'No se pudieron cargar los miembros.');
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_linkToExistingUser && _userIdCtrl.text.trim().isEmpty) return;

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
          currency: _selectedCurrency,
          roleTag: _roleCtrl.text.trim(),
          operationalRole: _operationalRole,
          notes: _notesCtrl.text.trim(),
        );
      } else {
        newWorker = Worker.newExternal(
          groupId: widget.group.id,
          displayName: _displayNameCtrl.text.trim(),
          defaultHourlyRate:
              double.tryParse(_rateCtrl.text.trim().replaceAll(',', '.')),
          currency: _selectedCurrency,
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
        title: Text(
          l.createWorkerTitle,
          style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _HeaderStrip(l: l, t: t),
              const SizedBox(height: 14),
              _ModeCard(
                l: l,
                t: t,
                value: _linkToExistingUser,
                onChanged: (v) {
                  setState(() => _linkToExistingUser = v);
                  if (v && _members.isEmpty) _loadMembers();
                },
              ),
              const SizedBox(height: 12),
              _IdentityCard(
                l: l,
                t: t,
                linkToExistingUser: _linkToExistingUser,
                userIdCtrl: _userIdCtrl,
                displayNameCtrl: _displayNameCtrl,
                members: _members,
                loadingMembers: _loadingMembers,
                membersError: _membersError,
                onRetryMembers: _loadMembers,
              ),
              if (_linkToExistingUser) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _operationalRole,
                  decoration: const InputDecoration(labelText: 'Rol de trabajador'),
                  items: const [
                    DropdownMenuItem(value: 'worker', child: Text('Trabajador')),
                    DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                  ],
                  onChanged: (value) => setState(() => _operationalRole = value ?? 'worker'),
                ),
                const SizedBox(height: 4),
                const Text('El rol de empresa del miembro, como Co-Administrador, se conserva.'),
              ],
              const SizedBox(height: 12),
              _RoleCard(
                l: l,
                t: t,
                roleCtrl: _roleCtrl,
                rateCtrl: _rateCtrl,
                selectedCurrency: _selectedCurrency,
                onCurrencyChanged: (v) => setState(() => _selectedCurrency = v),
              ),
              const SizedBox(height: 12),
              _NotesCard(
                l: l,
                t: t,
                notesCtrl: _notesCtrl,
              ),
              const SizedBox(height: 20),
              _Actions(
                l: l,
                saving: _saving,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderStrip extends StatelessWidget {
  const _HeaderStrip({required this.l, required this.t});
  final AppLocalizations l;
  final AppTypography t;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.badge_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.createWorkerTitle,
                  style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  l.addWorkerSubtitle,
                  style: t.caption.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.l,
    required this.t,
    required this.value,
    required this.onChanged,
  });

  final AppLocalizations l;
  final AppTypography t;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(
          l.linkExistingUserLabel,
          style: t.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: ThemeColors.textPrimary(context),
          ),
        ),
        subtitle: Text(
          l.linkExistingUserHint,
          style: t.bodySmall.copyWith(
            color: ThemeColors.textSecondary(context),
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.l,
    required this.t,
    required this.linkToExistingUser,
    required this.userIdCtrl,
    required this.displayNameCtrl,
    required this.members,
    required this.loadingMembers,
    required this.membersError,
    required this.onRetryMembers,
  });

  final AppLocalizations l;
  final AppTypography t;
  final bool linkToExistingUser;
  final TextEditingController userIdCtrl;
  final TextEditingController displayNameCtrl;
  final List<User> members;
  final bool loadingMembers;
  final String? membersError;
  final VoidCallback onRetryMembers;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.detailsSectionTitle,
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            if (linkToExistingUser)
              if (loadingMembers)
                const Center(child: CircularProgressIndicator())
              else if (membersError != null)
                TextButton(onPressed: onRetryMembers, child: Text(membersError!))
              else
                DropdownButtonFormField<String>(
                  initialValue: userIdCtrl.text.isEmpty ? null : userIdCtrl.text,
                  decoration: const InputDecoration(labelText: 'Miembro de la empresa'),
                  items: members.map((member) => DropdownMenuItem(
                    value: member.id,
                    child: Text(member.displayName ?? member.name),
                  )).toList(),
                  onChanged: (value) => userIdCtrl.text = value ?? '',
                  validator: (value) => value == null ? l.userIdRequired : null,
                )
            else
              TextFormField(
                controller: displayNameCtrl,
                decoration: InputDecoration(
                  labelText: l.displayNameLabel,
                  hintText: l.displayNameHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: t.bodyMedium,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l.displayNameRequired;
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.l,
    required this.t,
    required this.roleCtrl,
    required this.rateCtrl,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  final AppLocalizations l;
  final AppTypography t;
  final TextEditingController roleCtrl;
  final TextEditingController rateCtrl;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.roleLabel,
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: roleCtrl,
              decoration: InputDecoration(
                hintText: l.roleHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: t.bodyMedium,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final stacked = constraints.maxWidth < 400;
              return Flex(
                direction: stacked ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: stacked
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.center,
                children: [
                  Flexible(
                    flex: stacked ? 0 : 1,
                    fit: stacked ? FlexFit.loose : FlexFit.tight,
                    child: TextFormField(
                      controller: rateCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l.hourlyRateLabel,
                        hintText: l.hourlyRateHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: t.bodyMedium,
                    ),
                  ),
                  SizedBox(width: stacked ? 0 : 12, height: stacked ? 12 : 0),
                  SizedBox(
                    width: stacked ? double.infinity : 150,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedCurrency,
                      decoration: InputDecoration(
                        labelText: l.currencyLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: workerCurrencyOptions
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) onCurrencyChanged(value);
                      },
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.l,
    required this.t,
    required this.notesCtrl,
  });

  final AppLocalizations l;
  final AppTypography t;
  final TextEditingController notesCtrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.notesLabel,
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l.notesHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              style: t.bodyMedium.copyWith(
                color: ThemeColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.l,
    required this.saving,
    required this.onSubmit,
  });

  final AppLocalizations l;
  final bool saving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: saving ? null : () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: saving ? null : onSubmit,
            icon: saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(saving ? l.savingLabel : l.saveWorkerCta),
          ),
        ),
      ],
    );
  }
}
