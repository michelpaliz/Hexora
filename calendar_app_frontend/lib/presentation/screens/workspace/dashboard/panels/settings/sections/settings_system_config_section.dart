import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/settings/dialogs/logout_dialog.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/auth/auth_provider.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/auth/exceptions/auth_exceptions.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/settings/dialogs/change_password_dialog.dart';
import 'package:hexora/presentation/screens/settings/dialogs/change_username_dialog.dart';
import 'package:hexora/presentation/screens/settings/widgets/account_section.dart';
import 'package:hexora/presentation/screens/profile/edit/profile_edit_dialog.dart';
import 'package:hexora/presentation/screens/preferences/preference_controls.dart';
import 'package:hexora/presentation/screens/settings/widgets/section_card.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class SettingsSystemConfigSection extends StatefulWidget {
  const SettingsSystemConfigSection({super.key});

  @override
  State<SettingsSystemConfigSection> createState() =>
      _SettingsSystemConfigSectionState();
}

class _SettingsSystemConfigSectionState
    extends State<SettingsSystemConfigSection> {
  late User? currentUser;
  String userName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    currentUser = authProvider.currentUser;
    if (currentUser != null) {
      userName = currentUser!.userName;
    }
  }

  Future<bool> _changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final current = currentPassword.trim();
      final next = newPassword.trim();
      final confirm = confirmPassword.trim();
      if (current.isEmpty || next.isEmpty) {
        _snack('Current password and new password are required.');
        return false;
      }
      if (next.length < 8) {
        _snack('New password must be at least 8 characters');
        return false;
      }
      if (current == next) {
        _snack('New password must be different from current password');
        return false;
      }
      if (next != confirm) {
        _snack(loc.passwordNotMatch);
        return false;
      }

      await authProvider.changePassword(
        current,
        next,
        confirm,
      );

      _snack('Password changed successfully.');
      return true;
    } on CurrentPasswordMismatchException {
      _snack('Current password is incorrect.');
    } on PasswordMismatchException {
      _snack(loc.passwordNotMatch);
    } on ChangePasswordValidationException catch (e) {
      _snack(e.message);
    } on ChangePasswordRequestFailedException catch (e) {
      _snack(e.message);
    } on UserNotSignedInException {
      _snack(loc.userNotSignedIn);
    } catch (_) {
      _snack('Failed to change password. Please try again.');
    }
    return false;
  }

  Future<void> _openChangePassword() async {
    final result = await showChangePasswordDialog(context);
    if (!mounted || result == null) return;
    await _changePassword(result.current, result.newPass, result.confirm);
  }

  Future<String?> _changeUsername(String newUsername) async {
    final loc = AppLocalizations.of(context)!;
    try {
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(newUsername)) {
        return loc.errorUnwantedCharactersUsername;
      }
      if (newUsername.length < 6 || newUsername.length > 10) {
        return loc.errorUsernameLength;
      }
      setState(() => userName = newUsername);
      return null;
    } catch (_) {
      return loc.errorChangingUsername;
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showLogoutDialog(context);
    if (!mounted || confirmed != true) return;
    await _logout();
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    try {
      await auth.logOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.loginRoute,
      (_) => false,
    );
  }

  void _snack(String text) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    final bodyS = AppTypography.of(context).bodySmall;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: cs.inverseSurface,
      content: Text(text, style: bodyS.copyWith(color: cs.onInverseSurface)),
    ));
  }

  /// Width from which the sections split into two columns. Measured on the
  /// space this section receives, so it follows every navigation layout.
  static const double _twoColumnMinWidth = 700;
  static const double _columnGap = 20;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    return Consumer<AuthProvider>(
      // Ink needs a Material above it that is not hidden by the canvas colour.
      builder: (_, authProvider, __) => Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEs ? 'Configuración personal' : 'Personal settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            KeyedSubtree(
              key: const ValueKey('settings-profile-card'),
              child: SectionCard(
                compact: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: AccountSection(
                    userName: userName,
                    userSubtitle: authProvider.currentUser?.email,
                    onEditUsername: () async {
                      final successMessage = loc.successChangingUsername;
                      final newName = await showChangeUsernameDialog(context);
                      if (newName == null) return;
                      final err = await _changeUsername(newName);
                      if (!mounted) return;
                      _snack(err ?? successMessage);
                    },
                    onEditProfile: () => showProfileEditDialog(context),
                    onChangePassword: _openChangePassword,
                    compact: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final navigation = _Section(
                  key: const ValueKey('settings-navigation-column'),
                  title: loc.preferencesNavigation,
                  child: const NavigationPreference(),
                );
                final other = _otherPreferences(loc, isEs);
                if (preferenceLayoutWidth(context, constraints.maxWidth) <
                    _twoColumnMinWidth) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      navigation,
                      const _SectionDivider(),
                      other,
                    ],
                  );
                }
                // Natural heights: neither column stretches to match.
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: navigation),
                    const SizedBox(width: _columnGap),
                    Expanded(child: other),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _otherPreferences(
    AppLocalizations loc,
    bool isEs,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('settings-preferences-column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: loc.preferencesAppearance,
          child: const AppearancePreference(),
        ),
        const _SectionDivider(),
        _Section(
          title: loc.preferencesLanguage,
          trailing: const LanguagePreference(shortLabels: true, onCanvas: true),
        ),
        const _SectionDivider(),
        _Section(
          title: isEs ? 'Seguridad' : 'Security',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ActionRow(
                icon: Icons.lock_outline_rounded,
                color: cs.primary,
                title: loc.changePassword,
                onTap: _openChangePassword,
              ),
              _ActionRow(
                icon: Icons.logout_rounded,
                color: cs.error,
                title: loc.logout,
                titleColor: cs.error,
                onTap: _confirmLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Heading plus content, drawn directly on the workspace canvas.
class _Section extends StatelessWidget {
  const _Section({super.key, required this.title, this.trailing, this.child});

  final String title;

  /// Short control that shares the heading row.
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (child != null) ...[const SizedBox(height: 8), child!],
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(
          height: 1,
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.6),
        ),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color color;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: color.withValues(alpha: 0.05),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? cs.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
