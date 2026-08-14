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
import 'package:hexora/c-frontend/ui-app/i-settings-section/widgets/preferences_section.dart';
import 'package:hexora/c-frontend/ui-app/i-settings-section/widgets/section_card.dart';
import 'package:hexora/d-local-stateManagement/local/LocaleProvider.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/app_colors/themes/theme_provider/theme_provider.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late User? currentUser;
  String userName = "";
  static const String _appVersion = '1.0.0';
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

  // ===== Actions =====

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
    final theme = Theme.of(context);
    final typography = AppTypography.of(context);
    final cs = theme.colorScheme;
    final titleStyle = typography.bodyMedium.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    );
    final contentStyle =
        typography.bodySmall.copyWith(color: cs.onSurfaceVariant);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          l.logoutConfirmTitle,
          style: titleStyle,
        ),
        content: Text(
          l.logoutConfirmMessage,
          style: contentStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l.cancel,
              style: typography.buttonText.copyWith(color: cs.primary),
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: cs.error, // keeps destructive feel
            ),
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

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final typography = AppTypography.of(context);
    final bodyM = typography.bodyMedium;
    final bodyS = typography.bodySmall;
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppDarkColors.background : AppColors.background;
    final cs = Theme.of(context).colorScheme;

    return Consumer2<ThemeModeProvider, AuthProvider>(
      builder: (_, themeModeProv, authProvider, __) => Scaffold(
        appBar: AppBar(
          backgroundColor: cs.surface,
          iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
          title: Text(
            loc.settings,
            style: typography.titleLarge.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        backgroundColor: bg,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _ProfileHeroCard(
              userName: userName,
              photoUrl: authProvider.currentUser?.photoUrl,
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: loc.accountSectionTitle,
              textStyle: typography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SectionCard(
              child: AccountSection(
                userName: userName,
                onEditUsername: () async {
                  final newName = await showChangeUsernameDialog(context);
                  if (newName == null) return;
                  final err = await _changeUsername(newName);
                  _snack(err ??
                      AppLocalizations.of(context)!.successChangingUsername);
                },
                onChangePassword: () async {
                  final result = await showChangePasswordDialog(context);
                  if (result == null) return;
                  await _changePassword(
                      result.current, result.newPass, result.confirm);
                },
                onLogout: _confirmLogout,
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: loc.preferencesSectionTitle,
              textStyle: typography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SectionCard(
              child: PreferencesSection(
                isDark: themeModeProv.mode == ThemeMode.dark,
                onToggleDark: () => themeModeProv.toggleLightDark(),
                languageName: _languageName(context),
                onChangeLanguage: _openLanguageSheet,
                autoStatementImportEnabled:
                    authProvider.currentUser?.autoStatementImportEnabled ??
                        false,
                autoStatementImportBusy: _autoStatementImportLoading,
                onToggleAutoStatementImport: _toggleAutoStatementImport,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${loc.appVersionLabel}: $_appVersion',
              style: typography.caption
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _languageName(BuildContext context) {
    final lp = Provider.of<LocaleProvider>(context, listen: false);
    return lp.locale.languageCode == 'es' ? 'Español' : 'English';
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.userName,
    required this.photoUrl,
  });

  final String userName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    final imageUrl = photoUrl?.trim() ?? '';

    Widget fallbackInitial() => Center(
          child: Text(
            initial,
            style: t.titleLarge.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.tertiary],
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl.isEmpty
                  ? fallbackInitial()
                  : Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => fallbackInitial(),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Hexora',
                    style: t.caption.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
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
