import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/profile/edit/controller/profile_edit_controller.dart';
import 'package:hexora/presentation/screens/profile/edit/controller/profile_update_contract.dart';
import 'package:hexora/presentation/shared/widgets/avatars/hexora_user_avatar.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'widgets/labeled_field.dart';

Future<void> showProfileEditDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ProfileEditDialog(),
  );
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog();

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _controller = ProfileEditController();

  bool _saving = false;
  bool _seeded = false;
  bool _dirty = false;

  String? _displayNameError;
  String? _usernameError;
  String? _phoneError;
  String? _locationError;
  String? _bioError;
  String? _formError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final user = context.read<UserDomain>().user;
    if (user != null) {
      _displayNameCtrl.text = user.displayName ?? '';
      _usernameCtrl.text = user.userName;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phoneNumber ?? '';
      _locationCtrl.text = user.location ?? '';
      _bioCtrl.text = user.bio ?? '';
      for (final controller in [
        _displayNameCtrl,
        _usernameCtrl,
        _phoneCtrl,
        _locationCtrl,
        _bioCtrl,
      ]) {
        controller.addListener(_markDirty);
      }
      _seeded = true;
    }
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  Future<void> _requestClose() async {
    if (!_dirty || _saving) {
      if (!_saving) Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Descartar cambios'),
            content: const Text(
                'Tienes cambios sin guardar. ¿Quieres descartarlos?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Seguir editando')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Descartar')),
            ],
          ),
        ) ??
        false;
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _clearValidation() {
    _displayNameError = null;
    _usernameError = null;
    _phoneError = null;
    _locationError = null;
    _bioError = null;
    _formError = null;
  }

  Future<void> _handleChangePhoto() async {
    await _controller.changePhoto(context);
    if (mounted) setState(() {});
  }

  Future<void> _handleSave() async {
    if (_saving) return;

    final localValidation = ProfileUpdateContract.validate(
      ProfileUpdateInput(
        displayName: _displayNameCtrl.text,
        userName: _usernameCtrl.text,
        phoneNumber: _phoneCtrl.text,
        location: _locationCtrl.text,
        bio: _bioCtrl.text,
      ),
    );

    if (!localValidation.isValid) {
      setState(() {
        _displayNameError = localValidation.displayNameError;
        _usernameError = localValidation.userNameError;
        _phoneError = localValidation.phoneError;
        _locationError = localValidation.locationError;
        _bioError = localValidation.bioError;
        _formError = AppLocalizations.of(context)!.localeName.startsWith('es')
            ? 'Revisa los campos indicados.'
            : 'Please fix the highlighted fields.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _clearValidation();
    });

    final result = await _controller.saveProfile(
      context: context,
      displayName: _displayNameCtrl.text,
      username: _usernameCtrl.text,
      phoneNumber: _phoneCtrl.text,
      location: _locationCtrl.text,
      bio: _bioCtrl.text,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      if (result.validation != null) {
        _displayNameError = result.validation!.displayNameError;
        _usernameError = result.validation!.userNameError;
        _phoneError = result.validation!.phoneError;
        _locationError = result.validation!.locationError;
        _bioError = result.validation!.bioError;
      }
      _formError = result.success ? null : result.message;
      _usernameCtrl.text =
          ProfileUpdateContract.normalizeUsername(_usernameCtrl.text);
    });

    if (result.success) {
      _dirty = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Profile saved')),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _responsivePair(BuildContext context, Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(children: [first, const SizedBox(height: 12), second]);
        }
        return Row(children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second)
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final user = context.watch<UserDomain>().user;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final spanish = l.localeName.startsWith('es');

    Widget section(String title, List<Widget> fields) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title,
                  style: t.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 14),
              ...fields,
            ],
          ),
        );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      spanish ? 'Editar perfil' : 'Edit profile',
                      style: t.titleLarge.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: _saving ? null : _requestClose,
                  ),
                ],
              ),
            ),

            // Scrollable form
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                shrinkWrap: true,
                children: [
                  Row(children: [
                    HexoraUserAvatar(
                      userId: user.id,
                      displayName: user.displayName ?? user.name,
                      username: user.userName,
                      photoUrl: user.photoUrl,
                      size: 64,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _saving ? null : _handleChangePhoto,
                          icon:
                              const Icon(Icons.add_a_photo_outlined, size: 18),
                          label:
                              Text(spanish ? 'Cambiar foto' : 'Change photo'),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  section(
                    spanish ? 'Información personal' : 'Personal information',
                    [
                      _responsivePair(
                        context,
                        LabeledField(
                            label: l.displayName,
                            controller: _displayNameCtrl,
                            enabled: !_saving,
                            errorText: _displayNameError,
                            maxLength:
                                ProfileUpdateContract.maxDisplayNameLength),
                        LabeledField(
                            label: l.username,
                            controller: _usernameCtrl,
                            enabled: !_saving,
                            errorText: _usernameError,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9._-]'))
                            ]),
                      ),
                      const SizedBox(height: 12),
                      LabeledField(
                        label: spanish ? 'Biografía' : 'Bio',
                        controller: _bioCtrl,
                        enabled: !_saving,
                        maxLines: 2,
                        maxLength: ProfileUpdateContract.maxBioLength,
                        errorText: _bioError,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  section(
                    spanish ? 'Contacto y ubicación' : 'Contact and location',
                    [
                      _responsivePair(
                        context,
                        LabeledField(
                            label: l.phoneLabel,
                            controller: _phoneCtrl,
                            enabled: !_saving,
                            keyboardType: TextInputType.phone,
                            errorText: _phoneError,
                            maxLength: ProfileUpdateContract.maxPhoneLength),
                        LabeledField(
                            label: l.location,
                            controller: _locationCtrl,
                            enabled: !_saving,
                            errorText: _locationError,
                            maxLength: ProfileUpdateContract.maxLocationLength),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 16, color: cs.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                              child:
                                  Text(_emailCtrl.text, style: t.bodyMedium)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        spanish
                            ? 'El correo de tu cuenta no se puede editar aquí.'
                            : 'Your account email cannot be edited here.',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (_formError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _formError!,
                        style: TextStyle(color: cs.error, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _saving ? null : _requestClose,
                    child: Text(spanish ? 'Cancelar' : 'Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving || !_dirty ? null : _handleSave,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(
                      _saving ? l.saving : (spanish ? 'Guardar' : 'Save'),
                    ),
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
