import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/auth/forgot_password.dart';
import 'package:hexora/presentation/screens/auth/login/form/login_form.dart';
import 'package:hexora/presentation/screens/auth/register/ui/form/register_form.dart';
import 'package:hexora/presentation/utils/logo/hexora_brand.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'auth_shared_widgets.dart';
import 'auth_web_presentation.dart';
import 'package:hexora/presentation/shared/widgets/announcements/announcement_panel.dart';

enum AuthMode { register, login, forgot }

class AuthSwitcherView extends StatefulWidget {
  const AuthSwitcherView({super.key, this.showRegister = true});
  final bool showRegister;

  @override
  State<AuthSwitcherView> createState() => _AuthSwitcherViewState();
}

class _AuthSwitcherViewState extends State<AuthSwitcherView> {
  late AuthMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.showRegister ? AuthMode.register : AuthMode.login;
  }

  void _select(AuthMode mode) {
    if (mode == _mode) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: kIsWeb
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: dark
                      ? const [Color(0xFF151C2B), Color(0xFF101521)]
                      : const [
                          Color(0xFFEAF2FF),
                          Color(0xFFF7F9FE),
                          Color(0xFFDCEAFF)
                        ],
                ),
              )
            : const BoxDecoration(
                image: DecorationImage(
                  image:
                      AssetImage('assets/images/home_page/dark_bg_color.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            final showDesktopNews =
                constraints.maxWidth >= 1100 && _mode != AuthMode.forgot;

            Widget newsPanel({required bool desktop}) => Padding(
                  key: ValueKey(
                      desktop ? 'auth-news-desktop' : 'auth-news-inline'),
                  padding: desktop
                      ? const EdgeInsets.only(top: kIsWeb ? 0 : 80)
                      : const EdgeInsets.all(4),
                  child: AnnouncementPanel(
                    onViewAll: kIsWeb
                        ? () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (context) => const SafeArea(
                                  child: SingleChildScrollView(
                                padding: EdgeInsets.all(24),
                                child: AnnouncementPanel(
                                  placement: 'authentication',
                                  publicOnly: true,
                                  limit: 20,
                                  showEmptyState: true,
                                ),
                              )),
                            )
                        : null,
                    placement: 'authentication',
                    publicOnly: true,
                    limit: 3,
                    compact: true,
                    showEmptyState: true,
                  ),
                );

            Widget authContent({required bool showInlineNews}) =>
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: kIsWeb ? 520 : 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Visibility(
                        visible: !(kIsWeb && showDesktopNews),
                        maintainState: true,
                        child: Center(
                          child: kIsWeb
                              ? const HexoraSurfaceWordmark()
                              : constraints.maxWidth >= 1000
                                  ? const HexoraWordmark(width: 180)
                                  : const HexoraBrandIcon(size: 56),
                        ),
                      ),
                      SizedBox(height: kIsWeb && showDesktopNews ? 0 : 24),
                      buildAuthCard(
                        key: const ValueKey('auth-card'),
                        softShadow: kIsWeb,
                        context: context,
                        padding:
                            EdgeInsets.all(compact ? 20 : (kIsWeb ? 32 : 28)),
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_mode != AuthMode.forgot) ...[
                                SegmentedButton<AuthMode>(
                                  key: const ValueKey('auth-mode-switch'),
                                  showSelectedIcon: false,
                                  expandedInsets: EdgeInsets.zero,
                                  segments: [
                                    ButtonSegment(
                                      value: AuthMode.register,
                                      icon: kIsWeb
                                          ? const Icon(
                                              Icons.person_outline_rounded)
                                          : null,
                                      label: Text(l10n.register),
                                    ),
                                    ButtonSegment(
                                      value: AuthMode.login,
                                      icon: kIsWeb
                                          ? const Icon(Icons.login_rounded)
                                          : null,
                                      label: Text(l10n.login),
                                    ),
                                  ],
                                  selected: {_mode},
                                  onSelectionChanged: (modes) =>
                                      _select(modes.single),
                                  style: ButtonStyle(
                                    minimumSize: const WidgetStatePropertyAll(
                                      Size(0, 44),
                                    ),
                                    textStyle: WidgetStatePropertyAll(
                                      Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                              ],
                              AnimatedSwitcher(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 180),
                                child: switch (_mode) {
                                  AuthMode.register => const RegisterForm(
                                      key: ValueKey('register'),
                                    ),
                                  AuthMode.login => LoginForm(
                                      key: const ValueKey('login'),
                                      onForgotPassword: () =>
                                          _select(AuthMode.forgot),
                                    ),
                                  AuthMode.forgot => ForgotPasswordForm(
                                      key: const ValueKey('forgot'),
                                      onBackToLogin: () =>
                                          _select(AuthMode.login),
                                    ),
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showInlineNews &&
                          _mode != AuthMode.forgot &&
                          constraints.maxHeight >= 720) ...[
                        const SizedBox(height: 16),
                        newsPanel(desktop: false),
                      ],
                      if (kIsWeb) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRoutes.downloadApp),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: Text(l10n.downloadMobileApp),
                          ),
                        ),
                      ],
                    ],
                  ),
                );

            final content = SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 32,
                kIsWeb ? 72 : (compact ? 64 : 32),
                compact ? 16 : 32,
                compact ? 20 : 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight -
                          (kIsWeb ? 72 : (compact ? 64 : 32)) -
                          (compact ? 20 : 32))
                      .clamp(0, double.infinity),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: showDesktopNews
                          ? (kIsWeb ? 1120 : 1040)
                          : (kIsWeb ? 520 : 480),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDesktopNews) ...[
                          Expanded(
                              child: kIsWeb
                                  ? AuthWebIntroduction(
                                      news: newsPanel(desktop: true))
                                  : newsPanel(desktop: true)),
                          const SizedBox(width: 48),
                        ],
                        Expanded(
                          key: const ValueKey('auth-content-column'),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: authContent(
                              showInlineNews: !showDesktopNews,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            return Stack(
              children: [
                if (kIsWeb)
                  Positioned.fill(
                      child: IgnorePointer(
                          child: CustomPaint(
                              painter: AuthWebBackdrop(dark: dark)))),
                Positioned.fill(child: content),
                Positioned(
                  top: compact ? 12 : 16,
                  right: compact ? 16 : 24,
                  child: const AuthLanguageSelector(neutralSurface: kIsWeb),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
