import 'package:flutter/services.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/show_notifications.dart';
import 'package:hexora/presentation/screens/profile/edit/profile_edit_dialog.dart';
import 'package:hexora/presentation/screens/profile/view/widgets/profile_details_card.dart';
import 'package:hexora/presentation/shared/widgets/weather/weather_summary_card.dart';
import 'package:hexora/services/notification/domain/notification_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/home/widgets/home_section_nav.dart';
import 'package:hexora/presentation/screens/home/widgets/see_all_groups_button.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/create_edit/models/create_group_data.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/show-groups/group_screen/group_list_section.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/show-groups/motivational_phrase/quotes/quotes_en.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/show-groups/motivational_phrase/quotes/quotes_es.dart';
import 'package:hexora/presentation/screens/settings/dialogs/change_password_dialog.dart';
import 'package:hexora/presentation/screens/settings/dialogs/change_username_dialog.dart';
import 'package:hexora/presentation/screens/settings/dialogs/logout_dialog.dart';
import 'package:hexora/presentation/screens/settings/widgets/account_section.dart';
import 'package:hexora/presentation/screens/settings/widgets/contact_section.dart';
import 'package:hexora/presentation/screens/settings/widgets/language_sheet.dart';
import 'package:hexora/presentation/screens/settings/widgets/preferences_section.dart';
import 'package:hexora/presentation/screens/settings/widgets/section_card.dart';
import 'package:hexora/presentation/shared/widgets/user_profile_popup.dart';
import 'package:hexora/services/auth/auth_provider.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/auth/exceptions/auth_exceptions.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:hexora/theme/theme_provider.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/section_header.dart';

enum _HomeView { groups, settings, notifications, profile }

class HomeSliverContent extends StatefulWidget {
  final User user;
  final bool isWide;
  final double bottomSafePadding;
  final GlobalKey summaryKey;
  final GlobalKey phraseKey;
  final GlobalKey groupsKey;
  final ScrollController controller;
  final bool showSectionNavBar;
  final List<HomeSectionNavItem>? sectionItems;
  final String? activeSection;
  final ValueChanged<String>? onSectionSelected;

  const HomeSliverContent({
    super.key,
    required this.user,
    required this.isWide,
    required this.bottomSafePadding,
    required this.summaryKey,
    required this.phraseKey,
    required this.groupsKey,
    required this.controller,
    this.showSectionNavBar = false,
    this.sectionItems,
    this.activeSection,
    this.onSectionSelected,
  });

  @override
  State<HomeSliverContent> createState() => _HomeSliverContentState();
}

class _HomeSliverContentState extends State<HomeSliverContent> {
  bool _autoStatementImportLoading = false;
  late String _userName;
  _HomeView _activeView = _HomeView.groups;

  @override
  void initState() {
    super.initState();
    _userName = widget.user.userName;
  }

  @override
  void didUpdateWidget(covariant HomeSliverContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.userName != widget.user.userName) {
      _userName = widget.user.userName;
    }
  }

  Future<void> _openCreateGroup(BuildContext context) async {
    if (kIsWeb) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 900),
            child: const CreateGroupData(),
          ),
        ),
      );
      return;
    }
    await Navigator.pushNamed(context, AppRoutes.createGroupData);
  }

  // ── Settings actions ──────────────────────────────────────────────────

  bool get _isSpanish =>
      Localizations.localeOf(context).languageCode == 'es';

  void _snack(String text) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: cs.inverseSurface,
      content: Text(text,
          style: TextStyle(color: cs.onInverseSurface, fontSize: 13)),
    ));
  }

  Future<bool> _changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
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
      await authProvider.changePassword(current, next, confirm);
      _snack('Password changed successfully.');
      return true;
    } on CurrentPasswordMismatchException {
      _snack('Current password is incorrect.');
    } on PasswordMismatchException {
      _snack(loc.passwordNotMatch);
    } on ChangePasswordValidationException catch (e) {
      _snack(e.message);
    } on UserNotSignedInException {
      _snack(loc.userNotSignedIn);
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
      setState(() => _userName = newUsername);
      return null;
    } catch (_) {
      return loc.errorChangingUsername;
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showLogoutDialog(context);
    if (!mounted || confirmed != true) return;
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

  Future<void> _toggleAutoStatementImport(bool enabled) async {
    final loc = AppLocalizations.of(context)!;
    if (_autoStatementImportLoading) return;
    setState(() => _autoStatementImportLoading = true);
    try {
      await context.read<AuthProvider>().setAutoStatementImportEnabled(enabled);
    } catch (_) {
      _snack(loc.autoStatementImportUpdateFailed);
    } finally {
      if (mounted) setState(() => _autoStatementImportLoading = false);
    }
  }

  Future<void> _email(String address) async {
    final uri = Uri(scheme: 'mailto', path: address);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !mounted) return;
    _snack(_isSpanish
        ? 'No se pudo abrir la aplicación de correo.'
        : 'Could not open the email application.');
  }

  String _languageName() {
    final lp = context.read<LocaleProvider>();
    return lp.locale.languageCode == 'es' ? 'Español' : 'English';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Consumer2<ThemeModeProvider, AuthProvider>(
      builder: (context, themeModeProv, authProvider, _) {
        final photoUrl = authProvider.currentUser?.photoUrl;
        final autoImportEnabled =
            authProvider.currentUser?.autoStatementImportEnabled ?? false;

        return CustomScrollView(
          controller: widget.controller,
          slivers: [
            if (widget.showSectionNavBar && widget.sectionItems != null)
              SliverToBoxAdapter(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: HomeSectionNav(
                    items: widget.sectionItems!,
                    selectedId: widget.activeSection ?? '',
                    onSelect: widget.onSectionSelected ?? (_) {},
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    axis: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  ),
                ),
              ),
            // ── Full header: only on dashboard / groups ──────────────
            if (_activeView == _HomeView.groups) ...[
              SliverToBoxAdapter(
                key: widget.summaryKey,
                child: _HeroGreeting(
                  user: widget.user,
                  compact: !widget.isWide,
                  settingsActive: false,
                  notificationsActive: false,
                  onSettings: () => setState(
                      () => _activeView = _HomeView.settings),
                  onNotifications: () => setState(
                      () => _activeView = _HomeView.notifications),
                ),
              ),
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: WeatherSummaryCard(location: widget.user.location),
              )),
              SliverToBoxAdapter(
                key: widget.phraseKey,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: _DailyPhraseCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],

            // ── Compact header: secondary views ─────────────────────
            if (_activeView == _HomeView.settings)
              SliverToBoxAdapter(
                child: _CompactPageHeader(
                  icon: Icons.settings_outlined,
                  title: loc.settings,
                  subtitle: _isSpanish
                      ? 'Cuenta, preferencias y contacto'
                      : 'Account, preferences & contact',
                  onBack: () => setState(
                      () => _activeView = _HomeView.groups),
                ),
              ),

            if (_activeView == _HomeView.notifications)
              SliverToBoxAdapter(
                child: _CompactPageHeader(
                  icon: Icons.notifications_outlined,
                  title: loc.notifications,
                  subtitle: _isSpanish
                      ? 'Revisa tus avisos y alertas'
                      : 'Review your alerts and updates',
                  onBack: () => setState(
                      () => _activeView = _HomeView.groups),
                ),
              ),

            if (_activeView == _HomeView.profile)
              SliverToBoxAdapter(
                child: _CompactPageHeader(
                  icon: Icons.person_outlined,
                  title: _isSpanish ? 'Mi perfil' : 'My profile',
                  subtitle: '@${widget.user.userName}',
                  onBack: () => setState(
                      () => _activeView = _HomeView.settings),
                  trailing: OutlinedButton.icon(
                    onPressed: () => setState(
                        () => _activeView = _HomeView.settings),
                    icon: const Icon(Icons.settings_outlined, size: 16),
                    label: Text(
                        _isSpanish ? 'Configuración' : 'Settings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(
                          color:
                              cs.outlineVariant.withValues(alpha: 0.8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),

            // ── Groups view (default) ────────────────────────────────
            if (_activeView == _HomeView.groups) ...[
              SliverToBoxAdapter(
                key: widget.groupsKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                    title: loc.groupSectionTitle,
                    markerHeight: widget.isWide ? 30 : 24,
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                    trailing: widget.isWide
                        ? Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _openCreateGroup(context),
                                icon:
                                    const Icon(Icons.add_rounded, size: 18),
                                label: Text(loc.createGroup),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: cs.primary,
                                  side: BorderSide(
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SeeAllGroupsButton(
                                  compact: true, outlined: true),
                            ],
                          )
                        : const SeeAllGroupsButton(
                            compact: true, outlined: true),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 6)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 6, bottom: 12),
                  child: GroupListSection(maxItems: 5, fullPage: false),
                ),
              ),
            ],

            // ── Settings view ────────────────────────────────────────
            if (_activeView == _HomeView.settings) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _InlineProfileCard(
                    userName: _userName,
                    photoUrl: photoUrl,
                    onTap: () => setState(
                        () => _activeView = _HomeView.profile),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Account
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                    title: loc.accountSectionTitle,
                    markerHeight: widget.isWide ? 30 : 24,
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionCard(
                    child: AccountSection(
                      userName: _userName,
                      onEditUsername: () async {
                        final successMessage = loc.successChangingUsername;
                        final newName =
                            await showChangeUsernameDialog(context);
                        if (newName == null) return;
                        final err = await _changeUsername(newName);
                        _snack(err ?? successMessage);
                      },
                      onEditProfile: () =>
                          showProfileEditDialog(context),
                      onChangePassword: () async {
                        final result =
                            await showChangePasswordDialog(context);
                        if (result == null) return;
                        await _changePassword(
                            result.current, result.newPass, result.confirm);
                      },
                      onLogout: _confirmLogout,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Preferences
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                    title: loc.preferencesSectionTitle,
                    markerHeight: widget.isWide ? 30 : 24,
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionCard(
                    child: PreferencesSection(
                      isDark: themeModeProv.mode == ThemeMode.dark,
                      onToggleDark: () => themeModeProv.toggleLightDark(),
                      languageName: _languageName(),
                      onChangeLanguage: () => showLanguageSheet(context),
                      autoStatementImportEnabled: autoImportEnabled,
                      autoStatementImportBusy: _autoStatementImportLoading,
                      onToggleAutoStatementImport:
                          _toggleAutoStatementImport,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Contact
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                    title: _isSpanish
                        ? 'Contactar con Hexora'
                        : 'Contact Hexora',
                    markerHeight: widget.isWide ? 30 : 24,
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionCard(
                    child: ContactSection(
                      isSpanish: _isSpanish,
                      onEmail: _email,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${loc.appVersionLabel}: 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ],

            // ── Notifications view ───────────────────────────────────
            if (_activeView == _HomeView.notifications)
              SliverFillRemaining(
                child: ShowNotifications(
                  user: widget.user,
                  showBottomNav: false,
                ),
              ),

            // ── Profile view ────────────────────────────────────────
            if (_activeView == _HomeView.profile) ...[
              // Compact profile summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _InlineProfileCard(
                    userName: widget.user.name.isNotEmpty
                        ? widget.user.name
                        : widget.user.userName,
                    photoUrl: photoUrl,
                    onTap: () => setState(
                        () => _activeView = _HomeView.settings),
                    subtitle: '@${widget.user.userName}  ·  '
                        '${widget.user.email}',
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ProfileDetailsCard(
                    email: widget.user.email,
                    username: '@${widget.user.userName}',
                    userId: widget.user.id,
                    groupsCount: widget.user.groupIds.length,
                    calendarsCount: widget.user.sharedCalendars.length,
                    notificationsCount: context
                        .read<NotificationDomain>()
                        .notifications
                        .length,
                    onCopyEmail: () {
                      Clipboard.setData(
                          ClipboardData(text: widget.user.email));
                      _snack(loc.copiedToClipboard);
                    },
                    onCopyId: () {
                      Clipboard.setData(
                          ClipboardData(text: widget.user.id));
                      _snack(loc.copiedToClipboard);
                    },
                    onTapUsername: () => setState(
                        () => _activeView = _HomeView.settings),
                    onTapTeams: () => Navigator.pushNamed(
                        context, AppRoutes.showGroups),
                    onTapCalendars: () => Navigator.pushNamed(
                        context, AppRoutes.agenda),
                    onTapNotifications: () => setState(
                        () => _activeView = _HomeView.notifications),
                  ),
                ),
              ),
            ],

            SliverToBoxAdapter(
                child: SizedBox(
                    height: widget.isWide ? 24 : widget.bottomSafePadding)),
          ],
        );
      },
    );
  }
}

// ── Desktop-only hero greeting ────────────────────────────────────────────────

class _HeroGreeting extends StatelessWidget {
  const _HeroGreeting({
    required this.user,
    this.compact = false,
    this.onNotifications,
    this.onSettings,
    this.settingsActive = false,
    this.notificationsActive = false,
  });

  final bool compact;
  final User user;
  final VoidCallback? onNotifications;
  final VoidCallback? onSettings;
  final bool settingsActive;
  final bool notificationsActive;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final hour = DateTime.now().hour;
    final String greeting;
    final IconData greetingIcon;
    if (hour >= 6 && hour < 12) {
      greeting = isEs ? 'Buenos días' : 'Good morning';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour >= 12 && hour < 20) {
      greeting = isEs ? 'Buenas tardes' : 'Good afternoon';
      greetingIcon = Icons.wb_twilight_rounded;
    } else {
      greeting = isEs ? 'Buenas noches' : 'Good evening';
      greetingIcon = Icons.nightlight_round;
    }

    final displayName = user.name.isNotEmpty ? user.name : user.userName;
    final name = displayName.isEmpty
        ? 'Usuario'
        : displayName[0].toUpperCase() + displayName.substring(1);
    final initial = displayName.isEmpty ? 'U' : displayName[0].toUpperCase();
    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    final now = DateTime.now();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final rawDate = DateFormat('EEEE, d MMMM y', localeTag).format(now);
    final dateStr = rawDate.isEmpty
        ? rawDate
        : rawDate[0].toUpperCase() + rawDate.substring(1);

    if (compact) {
      final shortDate = DateFormat.MMMMEEEEd(localeTag).format(now);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primaryContainer,
                Color.alphaBlend(cs.primary.withValues(alpha: 0.04), cs.surface)
              ],
            ),
            border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(greeting,
                      style: t.bodyMedium.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(name,
                      style: t.titleLarge.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: cs.onPrimaryContainer),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(shortDate,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                ])),
            const SizedBox(width: 12),
            ExcludeSemantics(
                child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.65),
                  shape: BoxShape.circle),
              child: Icon(greetingIcon, color: cs.primary, size: 28),
            )),
          ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar — tappable; shows photo dialog or navigates to profile
          GestureDetector(
            onTap: hasPhoto
                ? () => showDialog<void>(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.72),
                      builder: (_) => UserAvatarViewerDialog(user: user),
                    )
                : () => Navigator.pushNamed(context, AppRoutes.profileDetails),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasPhoto
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cs.primary, cs.tertiary],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: hasPhoto
                  ? ClipOval(
                      child: Image.network(
                        user.photoUrl!,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: t.titleLarge.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(greetingIcon,
                        size: 18, color: cs.primary.withValues(alpha: 0.85)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$greeting, $name',
                        style: t.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 25,
                          color: cs.onSurface,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    dateStr,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Navigation icons
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(notificationsActive
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded),
            tooltip: loc.notifications,
            color: notificationsActive ? cs.primary : cs.onSurfaceVariant,
            onPressed: onNotifications ??
                () => Navigator.pushNamed(
                    context, AppRoutes.showNotifications),
          ),
          IconButton(
            icon: Icon(settingsActive
                ? Icons.settings_rounded
                : Icons.settings_outlined),
            tooltip: loc.settings,
            color: settingsActive ? cs.primary : cs.onSurfaceVariant,
            onPressed: onSettings ??
                () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

class _DailyPhraseCard extends StatelessWidget {
  const _DailyPhraseCard();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayKey = now.year * 10000 + now.month * 100 + now.day;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final quotes = isEs ? quotesEs : quotesEn;
    final (quote, author) = quotes[dayKey % quotes.length];
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.format_quote_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '”$quote” — ${author.replaceFirst(RegExp(r'^[\s—–-]+'), '')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineProfileCard extends StatelessWidget {
  const _InlineProfileCard({
    required this.userName,
    required this.photoUrl,
    required this.onTap,
    this.subtitle,
  });

  final String userName;
  final String? photoUrl;
  final VoidCallback onTap;
  final String? subtitle;

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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                color: cs.primary,
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
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: t.caption.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant, size: 22),
          ],
        ),
      ),
    );
  }
}

class _CompactPageHeader extends StatelessWidget {
  const _CompactPageHeader({
    required this.icon,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            color: cs.onSurfaceVariant,
            onPressed: onBack,
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.titleLarge.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
