import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/forgot_password.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/login/form/login_form.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/register/ui/form/register_form.dart';
import 'package:hexora/c-frontend/utils/logo/hexora_brand.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'auth_shared_widgets.dart';

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
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_bg.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 32,
                vertical: compact ? 20 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: constraints.maxWidth >= 1000
                            ? const HexoraWordmark(width: 180)
                            : const HexoraBrandIcon(size: 56),
                      ),
                      const SizedBox(height: 24),
                      buildAuthCard(
                        context: context,
                        padding: EdgeInsets.all(compact ? 20 : 28),
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
                                      label: Text(l10n.register),
                                    ),
                                    ButtonSegment(
                                      value: AuthMode.login,
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
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
