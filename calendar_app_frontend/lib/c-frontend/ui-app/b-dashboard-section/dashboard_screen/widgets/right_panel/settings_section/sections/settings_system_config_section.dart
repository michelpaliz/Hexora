import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/auth_user/exceptions/auth_exceptions.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/common/section_header.dart';
import 'package:hexora/c-frontend/ui-app/i-settings-section/dialogs/change_password_dialog.dart';
import 'package:hexora/c-frontend/ui-app/i-settings-section/dialogs/change_username_dialog.dart';
import 'package:hexora/c-frontend/ui-app/i-settings-section/widgets/account_section.dart';
import 'package:hexora/c-frontend/ui-app/i-settings-section/widgets/language_sheet.dart';
import 'package:hexora/c-frontend/ui-app/i-settings-section/widgets/nav_tile.dart';
import 'package:hexora/c-frontend/ui-app/i-settings-section/widgets/preferences_section.dart';
import 'package:hexora/c-frontend/ui-app/i-settings-section/widgets/section_card.dart';
import 'package:hexora/d-local-stateManagement/local/LocaleProvider.dart';
import 'package:hexora/f-themes/app_colors/themes/theme_provider/theme_provider.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
  bool _autoStatementImportLoading = false;

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
        _snack(AppLocalizations.of(context)!.passwordNotMatch);
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
      _snack(AppLocalizations.of(context)!.passwordNotMatch);
    } on ChangePasswordValidationException catch (e) {
      _snack(e.message);
    } on ChangePasswordRequestFailedException catch (e) {
      _snack(e.message);
    } on UserNotSignedInException {
      _snack(AppLocalizations.of(context)!.userNotSignedIn);
    } catch (_) {
      _snack('Failed to change password. Please try again.');
    }
    return false;
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

  void _confirmLogout() {
    final l = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final titleStyle = typography.bodyMedium.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    );
    final contentStyle =
        typography.bodySmall.copyWith(color: cs.onSurfaceVariant);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.logoutConfirmTitle, style: titleStyle),
        content: Text(l.logoutConfirmMessage, style: contentStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.cancel,
              style: typography.buttonText.copyWith(color: cs.primary),
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: cs.error),
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            child: Text(
              l.logout,
              style:
                  typography.buttonText.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.logOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.loginRoute,
      (_) => false,
    );
  }

  void _openLanguageSheet() => showLanguageSheet(context);

  void _snack(String text) {
    final bodyS = AppTypography.of(context).bodySmall;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text, style: bodyS)));
  }

  Future<void> _toggleAutoStatementImport(bool enabled) async {
    if (_autoStatementImportLoading) return;
    setState(() => _autoStatementImportLoading = true);
    try {
      await context.read<AuthProvider>().setAutoStatementImportEnabled(enabled);
    } catch (_) {
      _snack(AppLocalizations.of(context)!.autoStatementImportUpdateFailed);
    } finally {
      if (mounted) {
        setState(() => _autoStatementImportLoading = false);
      }
    }
  }

  String _languageName(BuildContext context) {
    final lp = Provider.of<LocaleProvider>(context, listen: false);
    return lp.locale.languageCode == 'es' ? 'Español (España)' : 'English';
  }

  String _sectionDescription(BuildContext context, String section) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    switch (section) {
      case 'account':
        return isEs
            ? 'Gestiona tu perfil y seguridad.'
            : 'Manage your profile and security.';
      case 'preferences':
        return isEs
            ? 'Personaliza el comportamiento de la aplicación.'
            : 'Customize how the app behaves.';
      case 'security':
        return isEs
            ? 'Controla el acceso a tu sesión.'
            : 'Control access to your session.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sectionTitleStyle = theme.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w900,
      color: cs.onSurface,
      letterSpacing: -0.2,
    );
    final sectionSubtitleStyle = typography.bodySmall.copyWith(
      color: cs.onSurfaceVariant,
      height: 1.25,
      fontWeight: FontWeight.w500,
    );

    return Consumer2<ThemeModeProvider, AuthProvider>(
      builder: (_, themeModeProv, authProvider, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: loc.accountSectionTitle,
            subtitle: _sectionDescription(context, 'account'),
            textStyle: sectionTitleStyle,
            subtitleStyle: sectionSubtitleStyle,
            showDivider: false,
            padding: const EdgeInsets.only(bottom: 12),
          ),
          SectionCard(
            child: AccountSection(
              userName: userName,
              userSubtitle: authProvider.currentUser?.email,
              onEditUsername: () async {
                final successMessage =
                    AppLocalizations.of(context)!.successChangingUsername;
                final newName = await showChangeUsernameDialog(context);
                if (newName == null) return;
                final err = await _changeUsername(newName);
                if (!mounted) return;
                _snack(err ?? successMessage);
              },
              onChangePassword: () async {
                final result = await showChangePasswordDialog(context);
                if (result == null) return;
                await _changePassword(
                    result.current, result.newPass, result.confirm);
              },
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: loc.preferencesSectionTitle,
            subtitle: _sectionDescription(context, 'preferences'),
            textStyle: sectionTitleStyle,
            subtitleStyle: sectionSubtitleStyle,
            showDivider: false,
            padding: const EdgeInsets.only(bottom: 12),
          ),
          SectionCard(
            child: PreferencesSection(
              isDark: themeModeProv.mode == ThemeMode.dark,
              onToggleDark: () => themeModeProv.toggleLightDark(),
              languageName: _languageName(context),
              onChangeLanguage: _openLanguageSheet,
              autoStatementImportEnabled:
                  authProvider.currentUser?.autoStatementImportEnabled ?? false,
              autoStatementImportBusy: _autoStatementImportLoading,
              onToggleAutoStatementImport: _toggleAutoStatementImport,
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: Localizations.localeOf(context).languageCode == 'es'
                ? 'Seguridad'
                : 'Security',
            subtitle: _sectionDescription(context, 'security'),
            textStyle: sectionTitleStyle,
            subtitleStyle: sectionSubtitleStyle,
            showDivider: false,
            padding: const EdgeInsets.only(bottom: 12),
          ),
          SectionCard(
            child: NavTile(
              leading: Icon(Icons.logout_rounded, size: 18, color: cs.error),
              iconBgColor: cs.error.withValues(alpha: 0.10),
              title: loc.logout,
              subtitle: Localizations.localeOf(context).languageCode == 'es'
                  ? 'Salir de esta cuenta en este dispositivo.'
                  : 'Sign out of this account on this device.',
              onTap: _confirmLogout,
              danger: true,
            ),
          ),
        ],
      ),
    );
  }
}
