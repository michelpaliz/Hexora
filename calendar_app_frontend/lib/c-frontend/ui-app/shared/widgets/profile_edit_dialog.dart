import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/auth_user/exceptions/auth_exceptions.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/h-profile-section/edit/controller/profile_update_contract.dart';
import 'package:hexora/c-frontend/ui-app/h-profile-section/edit/widgets/labeled_field.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({super.key, required this.user});
  final User user;

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _currentPasswordCtrl;
  late final TextEditingController _newPasswordCtrl;
  late final TextEditingController _confirmPasswordCtrl;

  bool _saving = false;
  bool _uploading = false;
  bool _changePassword = false;
  bool _currentObscured = true;
  bool _newObscured = true;
  bool _confirmObscured = true;
  bool _profileFieldsTouched = false;
  late User _localUser;
  String? _displayNameError;
  String? _usernameError;
  String? _phoneError;
  String? _locationError;
  String? _bioError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _localUser = widget.user;
    _nameCtrl = TextEditingController(text: widget.user.displayName ?? '');
    _usernameCtrl = TextEditingController(text: widget.user.userName);
    _bioCtrl = TextEditingController(text: widget.user.bio ?? '');
    _phoneCtrl = TextEditingController(text: widget.user.phoneNumber ?? '');
    _locationCtrl = TextEditingController(text: widget.user.location ?? '');
    for (final c in [
      _nameCtrl,
      _usernameCtrl,
      _bioCtrl,
      _phoneCtrl,
      _locationCtrl,
    ]) {
      c.addListener(() {
        _profileFieldsTouched = true;
        _formError = null;
      });
    }
    _currentPasswordCtrl = TextEditingController();
    _newPasswordCtrl = TextEditingController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _confirmPasswordCtrl = TextEditingController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _wantsPasswordChange => _changePassword;

  Future<void> _pickAndUpload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final auth = context.read<AuthProvider>();
      final token = await auth.getToken();
      if (token == null || !mounted) return;

      final bytes = kIsWeb ? await picked.readAsBytes() : null;
      final result = await uploadImageToAzure(
        scope: 'users',
        file: kIsWeb ? null : File(picked.path),
        bytes: bytes,
        accessToken: token,
      );

      final resp = await AuthenticatedHttpClient.patch(
        Uri.parse('${ApiConstants.baseUrl}/users/me/photo'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'blobName': result.blobName}),
      );

      final json = resp.statusCode == 200
          ? jsonDecode(resp.body) as Map<String, dynamic>
          : null;

      if (!mounted) return;

      final updated = _localUser.copyWith(
        photoUrl: json?['photoUrl'] ?? result.photoUrl,
        photoBlobName: json?['photoBlobName'] ?? result.blobName,
      );

      setState(() {
        _localUser = updated;
        _uploading = false;
      });
      context.read<UserDomain>().setCurrentUser(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    setState(() => _saving = true);

    final validation = ProfileUpdateContract.validate(
      ProfileUpdateInput(
        displayName: _nameCtrl.text,
        userName: _usernameCtrl.text,
        phoneNumber: _phoneCtrl.text,
        location: _locationCtrl.text,
        bio: _bioCtrl.text,
      ),
    );
    if (!validation.isValid) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _displayNameError = validation.displayNameError;
        _usernameError = validation.userNameError;
        _phoneError = validation.phoneError;
        _locationError = validation.locationError;
        _bioError = validation.bioError;
        _formError = 'Please fix the highlighted fields.';
      });
      return;
    }
    setState(() {
      _displayNameError = null;
      _usernameError = null;
      _phoneError = null;
      _locationError = null;
      _bioError = null;
      _formError = null;
    });

    final current = _currentPasswordCtrl.text.trim();
    final next = _newPasswordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();

    if (_wantsPasswordChange) {
      if (current.isEmpty || next.isEmpty) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Current password and new password are required.')),
        );
        return;
      }
      if (next.length < 8) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('New password must be at least 8 characters')),
        );
        return;
      }
      if (current == next) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('New password must be different from current password')),
        );
        return;
      }
      if (next != confirm) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.passwordNotMatch)),
        );
        return;
      }
    }

    final normalizedUsername =
        ProfileUpdateContract.normalizeUsername(_usernameCtrl.text);
    final updated = _localUser.copyWith(
      displayName: ProfileUpdateContract.normalizeOptional(_nameCtrl.text),
      userName: normalizedUsername,
      bio: ProfileUpdateContract.normalizeOptional(_bioCtrl.text),
      phoneNumber: ProfileUpdateContract.normalizeOptional(_phoneCtrl.text),
      location: ProfileUpdateContract.normalizeOptional(_locationCtrl.text),
    );
    _usernameCtrl.text = normalizedUsername;

    final profileChanged = _profileFieldsTouched &&
        ((updated.displayName ?? '') != (_localUser.displayName ?? '') ||
            updated.userName != _localUser.userName ||
            (updated.bio ?? '') != (_localUser.bio ?? '') ||
            (updated.phoneNumber ?? '') != (_localUser.phoneNumber ?? '') ||
            (updated.location ?? '') != (_localUser.location ?? ''));

    var profileOk = true;
    if (profileChanged) {
      profileOk = await _saveProfileFieldsOnly(updated);
    }

    var passwordOk = true;
    if (_wantsPasswordChange) {
      try {
        await authProvider.changePassword(current, next, confirm);
      } on CurrentPasswordMismatchException {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current password is incorrect.')),
        );
        return;
      } on ChangePasswordValidationException catch (e) {
        passwordOk = false;
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
        return;
      } on ChangePasswordRequestFailedException catch (e) {
        passwordOk = false;
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
        return;
      } catch (_) {
        passwordOk = false;
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to change password. Please try again.')),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (passwordOk && _changePassword) {
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _changePassword = false;
      final passwordSuccessMsg = profileChanged && !profileOk
          ? 'Password changed successfully. Profile changes were not saved.'
          : 'Password changed successfully.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(passwordSuccessMsg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(profileOk ? l.profileSaved : l.failedToSaveProfile)),
      );
    }

    final shouldClose =
        (!profileChanged || profileOk) && (!_wantsPasswordChange || passwordOk);
    if (shouldClose) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _saveProfileFieldsOnly(User updated) async {
    final userDomain = context.read<UserDomain>();
    final l = AppLocalizations.of(context)!;

    try {
      var response = await AuthenticatedHttpClient.patch(
        Uri.parse('${ApiConstants.baseUrl}/users/me'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(ProfileUpdateContract.buildPayload(
          ProfileUpdateInput(
            displayName: updated.displayName ?? '',
            userName: updated.userName,
            phoneNumber: updated.phoneNumber ?? '',
            location: updated.location ?? '',
            bio: updated.bio ?? '',
          ),
        )),
      );

      if (response.statusCode == 404) {
        response = await AuthenticatedHttpClient.put(
          Uri.parse('${ApiConstants.baseUrl}/users/${_localUser.id}'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(ProfileUpdateContract.buildPayload(
            ProfileUpdateInput(
              displayName: updated.displayName ?? '',
              userName: updated.userName,
              phoneNumber: updated.phoneNumber ?? '',
              location: updated.location ?? '',
              bio: updated.bio ?? '',
            ),
          )),
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) {
          final saved = raw.containsKey('user') && raw['user'] is Map
              ? raw['user'] as Map<String, dynamic>
              : raw;
          final merged = _localUser.copyWith(
            userName: (saved['userName'] as String?) ?? updated.userName,
            displayName:
                (saved['displayName'] as String?) ?? updated.displayName,
            bio: (saved['bio'] as String?) ?? updated.bio,
            phoneNumber: (saved['phoneNumber'] as String?) ??
                (saved['phone'] as String?) ??
                updated.phoneNumber,
            location: (saved['location'] as String?) ?? updated.location,
          );
          userDomain.updateCurrentUser(merged);
          _localUser = merged;
          return true;
        }
        userDomain.updateCurrentUser(updated);
        _localUser = updated;
        return true;
      }

      final dynamic decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;
      final serverMessage = decoded is Map<String, dynamic>
          ? (decoded['message']?.toString() ?? decoded['error']?.toString())
          : null;
      final message = ProfileUpdateContract.mapErrorMessage(
        statusCode: response.statusCode,
        backendMessage: serverMessage,
      );

      if (!mounted) return false;
      setState(() {
        _formError = message;
        _usernameError = response.statusCode == 409 ||
                (serverMessage ?? '').toLowerCase().contains('username')
            ? message
            : _usernameError;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return false;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _formError = l.failedToSaveProfile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.failedToSaveProfile)),
      );
      return false;
    }
  }

  // 0-4 score
  int get _pwStrength {
    final v = _newPasswordCtrl.text;
    if (v.isEmpty) return 0;
    int s = 0;
    if (v.length >= 8) s++;
    if (v.length >= 12) s++;
    if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v)) s++;
    if (RegExp(r'[0-9]').hasMatch(v)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(v)) s++;
    return s.clamp(0, 4);
  }

  bool get _pwMatch =>
      _newPasswordCtrl.text.isNotEmpty &&
      _newPasswordCtrl.text == _confirmPasswordCtrl.text;

  Widget _pwRow({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool obscured,
    required VoidCallback onToggle,
    Widget? trailing,
    bool isLast = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 15, color: cs.onSurface.withValues(alpha: 0.35)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscured,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: TextStyle(
                      fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 4), trailing],
            IconButton(
              padding: EdgeInsets.zero,
              iconSize: 17,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                obscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
              onPressed: onToggle,
            ),
          ],
        ),
        if (!isLast)
          Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.35)),
      ],
    );
  }

  Widget _strengthBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = _pwStrength;
    final colors = [
      cs.error,
      Colors.orange.shade600,
      Colors.amber.shade600,
      Colors.lightGreen.shade600,
      Colors.green.shade600,
    ];
    final labels = ['', 'Muy débil', 'Débil', 'Buena', 'Fuerte', 'Muy fuerte'];
    final isEs =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'es';
    final labelsEn = ['', 'Very weak', 'Weak', 'Fair', 'Strong', 'Very strong'];
    final label = score == 0 ? '' : (isEs ? labels[score] : labelsEn[score]);
    final color = score == 0 ? cs.outlineVariant : colors[score - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
      child: Row(
        children: [
          ...List.generate(
            4,
            (i) => Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
                decoration: BoxDecoration(
                  color: i < score
                      ? color
                      : cs.outlineVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final cardBg = ThemeColors.cardBg(context);
    final textColor = ThemeColors.textPrimary(context);
    final subColor = textColor.withValues(alpha: 0.55);

    final displayName = (_localUser.displayName?.trim().isNotEmpty == true)
        ? _localUser.displayName!
        : _localUser.name;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardBg,
      margin: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header bar ──────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.manage_accounts_rounded,
                      size: 20, color: cs.primary),
                  const SizedBox(width: 10),
                  Text(
                    l.profile,
                    style: t.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar
                    Center(
                      child: GestureDetector(
                        onTap: _uploading ? null : _pickAndUpload,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor:
                                  textColor.withValues(alpha: 0.12),
                              backgroundImage: _localUser.photoUrl
                                          ?.trim()
                                          .isNotEmpty ==
                                      true
                                  ? NetworkImage(_localUser.photoUrl!.trim())
                                  : null,
                              child:
                                  _localUser.photoUrl?.trim().isNotEmpty != true
                                      ? Text(
                                          _localUser.name.isNotEmpty
                                              ? _localUser.name[0].toUpperCase()
                                              : '?',
                                          style: t.titleLarge.copyWith(
                                            color: textColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cardBg,
                                    width: 2,
                                  ),
                                ),
                                child: _uploading
                                    ? SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: ThemeColors.contrastOn(
                                              cs.primary),
                                        ),
                                      )
                                    : Icon(
                                        Icons.camera_alt_rounded,
                                        size: 13,
                                        color:
                                            ThemeColors.contrastOn(cs.primary),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Display name + email hint below avatar
                    Center(
                      child: Column(
                        children: [
                          Text(
                            displayName,
                            style: t.bodyMedium.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _localUser.email,
                            style: t.bodySmall.copyWith(color: subColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Fields
                    LabeledField(
                      label: l.displayName,
                      controller: _nameCtrl,
                      errorText: _displayNameError,
                      maxLength: ProfileUpdateContract.maxDisplayNameLength,
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: l.username,
                      controller: _usernameCtrl,
                      errorText: _usernameError,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9._-]'),
                        ),
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
                      maxLines: 3,
                      maxLength: ProfileUpdateContract.maxBioLength,
                      errorText: _bioError,
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
                    const SizedBox(height: 12),
                    // ── Change password toggle ───────────────
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _changePassword = !_changePassword;
                          if (!_changePassword) {
                            _currentPasswordCtrl.clear();
                            _newPasswordCtrl.clear();
                            _confirmPasswordCtrl.clear();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _changePassword
                              ? cs.primary.withValues(alpha: 0.06)
                              : cs.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _changePassword
                                ? cs.primary.withValues(alpha: 0.3)
                                : cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: _changePassword
                                  ? cs.primary
                                  : cs.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l.changePassword,
                                style: t.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _changePassword
                                      ? cs.primary
                                      : cs.onSurface.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                            Icon(
                              _changePassword
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: _changePassword
                                  ? cs.primary
                                  : cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _changePassword
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest
                                      .withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _pwRow(
                                      context: context,
                                      controller: _currentPasswordCtrl,
                                      label: l.currentPassword,
                                      obscured: _currentObscured,
                                      onToggle: () => setState(() =>
                                          _currentObscured = !_currentObscured),
                                    ),
                                    _pwRow(
                                      context: context,
                                      controller: _newPasswordCtrl,
                                      label: l.newPassword,
                                      obscured: _newObscured,
                                      onToggle: () => setState(
                                          () => _newObscured = !_newObscured),
                                    ),
                                    if (_newPasswordCtrl.text.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: _strengthBar(context),
                                      ),
                                    _pwRow(
                                      context: context,
                                      controller: _confirmPasswordCtrl,
                                      label: l.confirmPassword,
                                      obscured: _confirmObscured,
                                      isLast: true,
                                      onToggle: () => setState(() =>
                                          _confirmObscured = !_confirmObscured),
                                      trailing: _confirmPasswordCtrl
                                              .text.isNotEmpty
                                          ? Icon(
                                              _pwMatch
                                                  ? Icons.check_circle_rounded
                                                  : Icons.cancel_rounded,
                                              size: 16,
                                              color: _pwMatch
                                                  ? Colors.green.shade600
                                                  : cs.error,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // ── Footer / Save button ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ThemeColors.contrastOn(cs.primary),
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    _saving ? l.saving : l.saveChanges,
                    style: t.buttonText
                        .copyWith(color: ThemeColors.contrastOn(cs.primary)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
