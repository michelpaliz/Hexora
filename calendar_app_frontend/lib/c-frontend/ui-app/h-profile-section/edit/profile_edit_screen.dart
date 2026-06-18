import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/h-profile-section/edit/controller/profile_edit_controller.dart';
import 'package:hexora/c-frontend/ui-app/h-profile-section/edit/controller/profile_update_contract.dart';
import 'package:hexora/c-frontend/utils/user_avatar.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/main_scaffold.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'widgets/labeled_field.dart';
import 'widgets/profile_header.dart';

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
        _formError = 'Please fix the highlighted fields.';
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
      _usernameCtrl.text = ProfileUpdateContract.normalizeUsername(_usernameCtrl.text);
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

    final cardBg = ThemeColors.cardBg(context);
    final cardShadow = ThemeColors.cardShadow(context);
    final onCard = ThemeColors.textPrimary(context);

    return MainScaffold(
      showAppBar: false,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(
            child: SafeArea(top: true, bottom: false, child: SizedBox(height: 8)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ProfileHeader(title: l.profile, subtitle: user.email),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cardShadow,
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: UserAvatar(
                        user: user,
                        fetchReadSas: (_) async => null,
                        radius: 52,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Material(
                        color: cs.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _handleChangePhoto,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: ThemeColors.contrastOn(cs.primary),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cardShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l.details,
                        style: t.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: onCard,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: l.displayName,
                      controller: _displayNameCtrl,
                      errorText: _displayNameError,
                      maxLength: ProfileUpdateContract.maxDisplayNameLength,
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: l.username,
                      controller: _usernameCtrl,
                      errorText: _usernameError,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._-]')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: l.phoneLabel,
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      errorText: _phoneError,
                      maxLength: ProfileUpdateContract.maxPhoneLength,
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: l.location,
                      controller: _locationCtrl,
                      errorText: _locationError,
                      maxLength: ProfileUpdateContract.maxLocationLength,
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Bio',
                      controller: _bioCtrl,
                      maxLines: 4,
                      maxLength: ProfileUpdateContract.maxBioLength,
                      errorText: _bioError,
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: l.email,
                      controller: _emailCtrl,
                      enabled: false,
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formError!,
                          style: t.bodySmall.copyWith(color: cs.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _handleSave,
                    icon: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ThemeColors.contrastOn(cs.primary),
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _saving ? l.saving : l.save,
                      style: t.buttonText.copyWith(
                        color: ThemeColors.contrastOn(cs.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
