import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/profile_edit_dialog.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// Circular avatar button.  Tap → shows a profile card popup anchored
/// to the top-right of the screen (near the nav bar).
class UserProfilePopup extends StatelessWidget {
  const UserProfilePopup({super.key, required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final liveUser = context.watch<UserDomain>().user;
    final u = liveUser ?? user;
    if (u == null) return const SizedBox(width: 32, height: 32);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;

    return Tooltip(
      message: u.displayName?.isNotEmpty == true ? u.displayName! : u.name,
      child: GestureDetector(
        onTap: () => _openPopup(context, u),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: textColor.withValues(alpha: 0.12),
          backgroundImage:
              u.photoUrl?.trim().isNotEmpty == true
                  ? NetworkImage(u.photoUrl!.trim())
                  : null,
          child: u.photoUrl?.trim().isNotEmpty != true
              ? Text(
                  u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  void _openPopup(BuildContext context, User u) {
    showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (_) => Dialog(
        alignment: Alignment.topRight,
        insetPadding:
            const EdgeInsets.only(top: 56, right: 14, bottom: 0, left: 0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: _UserProfileCard(initialUser: u),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile card shown inside the dialog
// ─────────────────────────────────────────────────────────────────────────────

class _UserProfileCard extends StatefulWidget {
  const _UserProfileCard({required this.initialUser});
  final User initialUser;

  @override
  State<_UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<_UserProfileCard> {
  late User _user;
  bool _uploading = false;
  VoidCallback? _userSub;
  UserDomain? _userDomain;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    final domain = context.read<UserDomain>();
    _userDomain = domain;
    _userSub = () {
      final next = domain.currentUserNotifier.value;
      if (!mounted || next == null) return;
      if (next.id == _user.id) {
        setState(() => _user = next);
      }
    };
    domain.currentUserNotifier.addListener(_userSub!);
  }

  @override
  void dispose() {
    final sub = _userSub;
    final domain = _userDomain;
    if (sub != null && domain != null) {
      domain.currentUserNotifier.removeListener(sub);
    }
    super.dispose();
  }

  void _openImageViewer() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => UserAvatarViewerDialog(
        user: _user,
        uploading: _uploading,
        onChangePhoto: () {
          Navigator.of(ctx).pop();
          _pickAndUpload();
        },
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
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

      final updated = _user.copyWith(
        photoUrl: json?['photoUrl'] ?? result.photoUrl,
        photoBlobName: json?['photoBlobName'] ?? result.blobName,
      );

      setState(() {
        _user = updated;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final textColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final subColor = textColor.withValues(alpha: 0.55);
    final cardBg = ThemeColors.cardBg(context);
    final activeColor = isDark ? AppDarkColors.primary : AppColors.primary;

    final displayName = (_user.displayName?.trim().isNotEmpty == true)
        ? _user.displayName!
        : _user.name;

    return Container(
      width: 288,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Avatar section ───────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _openImageViewer,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: textColor.withValues(alpha: 0.12),
                        backgroundImage:
                            _user.photoUrl?.trim().isNotEmpty == true
                                ? NetworkImage(_user.photoUrl!.trim())
                                : null,
                        child: _user.photoUrl?.trim().isNotEmpty != true
                            ? Text(
                                _user.name.isNotEmpty
                                    ? _user.name[0].toUpperCase()
                                    : '?',
                                style: t.titleLarge.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      // Camera overlay
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: _uploading
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: activeColor,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt_outlined,
                                  size: 12,
                                  color: activeColor,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: t.bodyLarge.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@${_user.userName}',
                  style: t.bodySmall.copyWith(color: subColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // ── Info rows ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.email_outlined,
                  text: _user.email,
                  trailing: _user.emailVerified
                      ? Tooltip(
                          message: 'Verified',
                          child: Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: Colors.green.shade500,
                          ),
                        )
                      : null,
                  textColor: textColor,
                  subColor: subColor,
                ),
                if (_user.phoneNumber?.trim().isNotEmpty == true)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    text: _user.phoneNumber!.trim(),
                    textColor: textColor,
                    subColor: subColor,
                  ),
                if (_user.location?.trim().isNotEmpty == true)
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: _user.location!.trim(),
                    textColor: textColor,
                    subColor: subColor,
                  ),
                if (_user.bio?.trim().isNotEmpty == true)
                  _InfoRow(
                    icon: Icons.info_outline_rounded,
                    text: _user.bio!.trim(),
                    textColor: textColor,
                    subColor: subColor,
                    maxLines: 2,
                  ),
              ],
            ),
          ),
          // ── Footer ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Divider(
              height: 1,
              thickness: 0.6,
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeColor,
                      side: BorderSide(
                          color: activeColor.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: t.bodySmall
                          .copyWith(fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog<void>(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          insetPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxWidth: 480, maxHeight: 820),
                            child: ProfileEditDialog(user: _user),
                          ),
                        ),
                      );
                    },
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

// ─────────────────────────────────────────────────────────────────────────────
// Full-size avatar viewer dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Public reusable avatar viewer dialog.
/// Pass [onChangePhoto] to show a "Change photo" button (e.g. for own profile).
/// Omit it for read-only viewing (e.g. viewing another member's avatar).
class UserAvatarViewerDialog extends StatelessWidget {
  const UserAvatarViewerDialog({
    super.key,
    required this.user,
    this.uploading = false,
    this.onChangePhoto,
  });

  final User user;
  final bool uploading;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppTypography.of(context);
    final textColor = isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final activeColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    final hasPhoto = user.photoUrl?.trim().isNotEmpty == true;
    final displayName = (user.displayName?.trim().isNotEmpty == true)
        ? user.displayName!
        : user.name;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button row
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.white.withValues(alpha: 0.12),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Avatar card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Large avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 72,
                      backgroundColor: activeColor.withValues(alpha: 0.14),
                      backgroundImage:
                          hasPhoto ? NetworkImage(user.photoUrl!.trim()) : null,
                      child: !hasPhoto
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: t.displayLarge.copyWith(
                                color: activeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name
                  Text(
                    displayName,
                    style: t.bodyLarge.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.userName}',
                    style: t.bodySmall.copyWith(
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (onChangePhoto != null) ...[
                  const SizedBox(height: 24),

                  // Change photo button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: uploading ? null : onChangePhoto,
                      icon: uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                      label: Text(
                        uploading ? 'Uploading...' : 'Change photo',
                        style: t.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info row: icon + text
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.textColor,
    required this.subColor,
    this.trailing,
    this.maxLines = 1,
  });

  final IconData icon;
  final String text;
  final Color textColor;
  final Color subColor;
  final Widget? trailing;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: subColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: t.bodySmall.copyWith(color: textColor),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}
