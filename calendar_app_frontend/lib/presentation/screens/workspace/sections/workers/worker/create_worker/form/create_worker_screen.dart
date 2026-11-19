import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/shared/currency_options.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/client_editor_theme.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/client_form_fields.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/input_border.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
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

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _userIdCtrl.dispose();
    _roleCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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
          members.add(await _userDomain.userRepository
              .getUserById(widget.group.ownerId));
        } catch (_) {
          // The member list can still be used if the owner profile is unavailable.
        }
      }
      if (mounted) setState(() => _members = members);
    } catch (_) {
      if (mounted) {
        setState(() => _membersError = 'No se pudieron cargar los miembros.');
      }
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
      body: Theme(
        data: clientEditorThemeOf(context),
        child: Builder(
          builder: (context) {
            final text = Theme.of(context).textTheme;
            return Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      children: [
                        _LinkUserToggle(
                          title: l.linkExistingUserLabel,
                          subtitle: l.linkExistingUserHint,
                          value: _linkToExistingUser,
                          onChanged: (v) {
                            setState(() => _linkToExistingUser = v);
                            if (v && _members.isEmpty) _loadMembers();
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_linkToExistingUser)
                          _buildMemberField(context, l, text)
                        else
                          TextFormField(
                            controller: _displayNameCtrl,
                            style: text.bodyLarge,
                            decoration: buildInputDecoration(
                              context,
                              label: l.displayNameLabel,
                              hintText: l.displayNameHint,
                              prefixIcon: const Icon(Icons.person_outline),
                              isRequired: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return l.displayNameRequired;
                              }
                              return null;
                            },
                          ),
                        if (_linkToExistingUser) ...[
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _operationalRole,
                            isExpanded: true,
                            style: text.bodyLarge,
                            decoration: buildInputDecoration(
                              context,
                              label: 'Rol de trabajador',
                              prefixIcon:
                                  const Icon(Icons.admin_panel_settings_outlined),
                              isFilled: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'worker', child: Text('Trabajador')),
                              DropdownMenuItem(
                                  value: 'supervisor',
                                  child: Text('Supervisor')),
                            ],
                            onChanged: (value) => setState(
                                () => _operationalRole = value ?? 'worker'),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'El rol de empresa del miembro, como Co-Administrador, se conserva.',
                            style: text.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _roleCtrl,
                          style: text.bodyLarge,
                          decoration: buildInputDecoration(
                            context,
                            label: l.roleLabel,
                            hintText: l.roleHint,
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClientFormFields(
                          first: TextFormField(
                            controller: _rateCtrl,
                            style: text.bodyLarge,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: buildInputDecoration(
                              context,
                              label: l.hourlyRateLabel,
                              hintText: l.hourlyRateHint,
                              prefixIcon: const Icon(Icons.payments_outlined),
                            ),
                          ),
                          second: DropdownButtonFormField<String>(
                            initialValue: _selectedCurrency,
                            isExpanded: true,
                            style: text.bodyLarge,
                            decoration: buildInputDecoration(
                              context,
                              label: l.currencyLabel,
                              prefixIcon:
                                  const Icon(Icons.currency_exchange_outlined),
                              isFilled: true,
                            ),
                            items: workerCurrencyOptions
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedCurrency = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _notesCtrl,
                          style: text.bodyLarge,
                          maxLines: 3,
                          decoration: buildInputDecoration(
                            context,
                            label: l.notesLabel,
                            hintText: l.notesHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _FooterBar(
                  saving: _saving,
                  cancelLabel: l.cancel,
                  saveLabel: _saving ? l.savingLabel : l.saveWorkerCta,
                  onCancel: () => Navigator.of(context).pop(false),
                  onSubmit: _submit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMemberField(
    BuildContext context,
    AppLocalizations l,
    TextTheme text,
  ) {
    if (_loadingMembers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_membersError != null) {
      return TextButton(onPressed: _loadMembers, child: Text(_membersError!));
    }
    return DropdownButtonFormField<String>(
      initialValue: _userIdCtrl.text.isEmpty ? null : _userIdCtrl.text,
      isExpanded: true,
      style: text.bodyLarge,
      decoration: buildInputDecoration(
        context,
        label: 'Miembro de la empresa',
        prefixIcon: const Icon(Icons.group_outlined),
        isRequired: true,
      ),
      items: _members
          .map((member) => DropdownMenuItem(
                value: member.id,
                child: Text(member.displayName ?? member.name),
              ))
          .toList(),
      onChanged: (value) => _userIdCtrl.text = value ?? '',
      validator: (value) => value == null ? l.userIdRequired : null,
    );
  }
}

/// Compact toggle for linking to an existing company member, without a card.
class _LinkUserToggle extends StatelessWidget {
  const _LinkUserToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(Icons.link_rounded,
            size: 18, color: value ? cs.primary : cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style:
                      text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Bottom bar with Cancel + primary Save, right-aligned, matching other forms.
class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.saving,
    required this.cancelLabel,
    required this.saveLabel,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool saving;
  final String cancelLabel;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 6,
        children: [
          HexoraButton(
            onPressed: saving ? null : onCancel,
            label: cancelLabel,
            variant: HexoraButtonVariant.secondary,
          ),
          HexoraButton(
            icon: Icons.save_outlined,
            label: saveLabel,
            loading: saving,
            onPressed: saving ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}
