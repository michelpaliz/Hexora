import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/profile/edit/controller/profile_edit_controller.dart';
import 'package:hexora/presentation/screens/profile/edit/controller/profile_update_contract.dart';
import 'package:hexora/presentation/shared/widgets/avatars/user_avatar.dart';
import 'package:hexora/navigation/main_scaffold.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'widgets/labeled_field.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _controller = ProfileEditController();

  bool _saving = false;
  bool _seeded = false;

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
      _seeded = true;
    }
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

  void _applyValidation(ProfileUpdateValidationResult validation) {
    setState(() {
      _displayNameError = validation.displayNameError;
      _usernameError = validation.userNameError;
      _phoneError = validation.phoneError;
      _locationError = validation.locationError;
      _bioError = validation.bioError;
    });
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
      _applyValidation(localValidation);
      setState(() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Profile saved')),
      );
      if (mounted) Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final user = context.watch<UserDomain>().user;
    if (user == null) {
      return MainScaffold(
        showAppBar: false,
        body: Center(child: Text(l.noUserLoaded)),
      );
    }

    final spanish = l.localeName.startsWith('es');
    Widget section(String title, List<Widget> fields) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: cs.surface, borderRadius: BorderRadius.circular(18)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title,
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            ...fields,
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: Text(spanish ? 'Editar perfil' : 'Edit profile')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _saving ? null : _handleSave,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check),
          label: Text(_saving
              ? l.saving
              : (spanish ? 'Guardar cambios' : 'Save changes')),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                UserAvatar(
                    user: user, fetchReadSas: (_) async => null, radius: 32),
                const SizedBox(width: 16),
                Expanded(
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _saving ? null : _handleChangePhoto,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label:
                              Text(spanish ? 'Cambiar foto' : 'Change photo'),
                        ))),
              ]),
              const SizedBox(height: 20),
              section(
                  spanish ? 'Información personal' : 'Personal information', [
                LabeledField(
                    label: l.displayName,
                    controller: _displayNameCtrl,
                    enabled: !_saving,
                    errorText: _displayNameError,
                    maxLength: ProfileUpdateContract.maxDisplayNameLength),
                const SizedBox(height: 16),
                LabeledField(
                    label: l.username,
                    controller: _usernameCtrl,
                    enabled: !_saving,
                    errorText: _usernameError,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9._-]'))
                    ]),
                const SizedBox(height: 16),
                LabeledField(
                    label: spanish ? 'Biografía' : 'Bio',
                    controller: _bioCtrl,
                    enabled: !_saving,
                    maxLines: 3,
                    maxLength: ProfileUpdateContract.maxBioLength,
                    errorText: _bioError),
              ]),
              const SizedBox(height: 16),
              section(
                  spanish ? 'Contacto y ubicación' : 'Contact and location', [
                LabeledField(
                    label: l.phoneLabel,
                    controller: _phoneCtrl,
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    errorText: _phoneError,
                    maxLength: ProfileUpdateContract.maxPhoneLength),
                const SizedBox(height: 16),
                LabeledField(
                    label: l.location,
                    controller: _locationCtrl,
                    enabled: !_saving,
                    errorText: _locationError,
                    maxLength: ProfileUpdateContract.maxLocationLength),
                const SizedBox(height: 16),
                LabeledField(
                    label: l.email, controller: _emailCtrl, enabled: false),
                const SizedBox(height: 8),
                Text(
                    spanish
                        ? 'El correo de tu cuenta no se puede editar aquí.'
                        : 'Your account email cannot be edited here.',
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
              ]),
              if (_formError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_formError!, style: TextStyle(color: cs.error)),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
