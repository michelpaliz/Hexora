import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/auth/auth_provider.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/blob_storage/blob_server.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/shared/widgets/avatars/hexora_user_avatar.dart';
import 'package:hexora/presentation/screens/settings/dialogs/logout_dialog.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/theme_provider.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// Circular avatar button.  Tap → shows a profile card popup anchored
/// to the top-right of the screen (near the nav bar).
class UserProfilePopup extends StatefulWidget {
  const UserProfilePopup({super.key, required this.user, this.onSettings});

  final User? user;
  final VoidCallback? onSettings;

  @override
  State<UserProfilePopup> createState() => _UserProfilePopupState();
}

class _UserProfilePopupState extends State<UserProfilePopup> {
  OverlayEntry? _popupEntry;

  @override
  void dispose() {
    _dismissPopup();
    super.dispose();
  }

  void _dismissPopup() {
    _popupEntry?.remove();
    _popupEntry = null;
  }

  void _togglePopup(User user) {
    if (_popupEntry != null) {
      _dismissPopup();
      return;
    }
    final renderBox = context.findRenderObject() as RenderBox?;
    final anchor = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final anchorSize = renderBox?.size ?? Size.zero;
    final overlay = Overlay.of(context, rootOverlay: true);
    _popupEntry = OverlayEntry(
      builder: (overlayContext) => PositionedDirectional(
        top: anchor.dy + anchorSize.height + 8,
        end: 16,
        child: TapRegion(
          onTapOutside: (_) => _dismissPopup(),
          child: Focus(
            autofocus: true,
            onKeyEvent: (_, event) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                _dismissPopup();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Material(
              color: Colors.transparent,
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: _UserProfileCard(
                initialUser: user,
                onSettings: widget.onSettings,
                onClose: _dismissPopup,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_popupEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final liveUser = context.watch<UserDomain>().user;
    final u = liveUser ?? widget.user;
    if (u == null) return const SizedBox(width: 32, height: 32);

    return Tooltip(
      message: u.displayName?.isNotEmpty == true ? u.displayName! : u.name,
      child: GestureDetector(
        onTap: () => _togglePopup(u),
        child: HexoraUserAvatar(
          userId: u.id,
          displayName: u.displayName ?? u.name,
          username: u.userName,
          photoUrl: u.photoUrl,
          size: 32,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile card shown inside the dialog
// ─────────────────────────────────────────────────────────────────────────────

class _UserProfileCard extends StatefulWidget {
  const _UserProfileCard({
    required this.initialUser,
    required this.onClose,
    this.onSettings,
  });
  final User initialUser;
  final VoidCallback? onSettings;
  final VoidCallback onClose;

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
      if (resp.statusCode != 200) {
        throw StateError(
            'Photo save failed (${resp.statusCode}): ${resp.body}');
      }
      final json = jsonDecode(resp.body) as Map<String, dynamic>;

      if (!mounted) return;

      final updated = _user.copyWith(
        photoUrl: json['photoUrl'] ?? result.photoUrl,
        photoBlobName: json['photoBlobName'] ?? result.blobName,
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
  Widget build(BuildContext context) => buildCompact(context);

  // ignore: unused_element
  Widget _buildLegacyProfileCard(BuildContext context) {
    final themeModeProvider = context.watch<ThemeModeProvider>();
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
            child: Stack(
              children: [
                Column(
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
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.5),
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
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: IconButton(
                    tooltip: 'Cerrar',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                    color: subColor,
                  ),
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
                Tooltip(
                  message: isDark ? 'Light mode' : 'Dark mode',
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: themeModeProvider.toggleLightDark,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: activeColor,
                        side: BorderSide(
                          color: activeColor.withValues(alpha: 0.4),
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.settings_outlined, size: 14),
                    label: Text(
                        Localizations.localeOf(context).languageCode == 'es'
                            ? 'Configuración'
                            : 'Settings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activeColor,
                      side:
                          BorderSide(color: activeColor.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle:
                          t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      widget.onClose();
                      if (widget.onSettings != null) {
                        widget.onSettings!();
                      } else {
                        Navigator.of(context).pushNamed(AppRoutes.settings);
                      }
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
// The popup intentionally keeps profile editing in account settings.
extension _CompactProfileCard on _UserProfileCardState {
  Widget buildCompact(BuildContext context) {
    final theme = context.watch<ThemeModeProvider>();
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _user.displayName?.trim().isNotEmpty == true
        ? _user.displayName!.trim()
        : _user.name;
    return Container(
      width: 304,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .35)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          HexoraUserAvatar(
            userId: _user.id,
            displayName: name,
            username: _user.userName,
            photoUrl: _user.photoUrl,
            size: 48,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('@${_user.userName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(color: cs.onSurfaceVariant)),
              ])),
          IconButton(
              tooltip: 'Cerrar',
              visualDensity: VisualDensity.compact,
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded, size: 18)),
        ]),
        if (_user.email.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.email_outlined, size: 15, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
                child: Text(_user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(color: cs.onSurfaceVariant))),
            if (_user.emailVerified)
              Tooltip(
                  message: 'Correo electrónico verificado',
                  child: Icon(Icons.verified_rounded,
                      size: 16, color: Colors.green.shade600)),
          ]),
        ],
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
                height: 1, color: cs.outlineVariant.withValues(alpha: .45))),
        _compactMenuRow(context,
            icon: Icons.settings_outlined, label: 'Configuración', onTap: () {
          widget.onClose();
          if (widget.onSettings != null) {
            widget.onSettings!();
          } else {
            Navigator.of(context).pushNamed(AppRoutes.settings);
          }
        }),
        _compactMenuRow(context,
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            label: 'Modo oscuro',
            trailing: Switch(
                value: isDark,
                onChanged: (_) =>
                    theme.setMode(isDark ? ThemeMode.light : ThemeMode.dark)),
            onTap: () =>
                theme.setMode(isDark ? ThemeMode.light : ThemeMode.dark)),
        _compactMenuRow(context,
            icon: Icons.logout_rounded,
            label: 'Cerrar sesión',
            danger: true,
            onTap: () => _compactLogout(context)),
      ]),
    );
  }

  Widget _compactMenuRow(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Widget? trailing,
      bool danger = false}) {
    final cs = Theme.of(context).colorScheme;
    final color = danger ? cs.error : cs.onSurface;
    return SizedBox(
        height: 40,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(label, style: TextStyle(color: color))),
                    trailing ??
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: cs.onSurfaceVariant),
                  ])),
            )));
  }

  Future<void> _compactLogout(BuildContext context) async {
    // This card lives in a root OverlayEntry. Dismiss it before presenting the
    // confirmation dialog so the overlay cannot sit above and intercept the
    // dialog's taps.
    final navigator = Navigator.of(context, rootNavigator: true);
    final auth = context.read<AuthService>();
    widget.onClose();
    await Future<void>.delayed(Duration.zero);
    if (!navigator.mounted) return;

    final confirmed = await showLogoutDialog(navigator.context);
    if (confirmed != true || !navigator.mounted) return;
    try {
      await auth.logOut();
    } catch (_) {
      if (navigator.mounted) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          const SnackBar(content: Text('No se pudo cerrar la sesión.')),
        );
      }
      return;
    }
    if (!navigator.mounted) return;
    navigator.pushNamedAndRemoveUntil(AppRoutes.loginRoute, (_) => false);
  }
}

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
    final textColor =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final activeColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final cardBg = isDark ? AppDarkColors.surface : Colors.white;

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
                            : const Icon(Icons.camera_alt_rounded,
                                size: 20, color: Colors.white),
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
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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
