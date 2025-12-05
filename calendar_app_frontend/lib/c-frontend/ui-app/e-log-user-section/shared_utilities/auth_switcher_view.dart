import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/forgot_password.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/login/form/login_form.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/register/ui/form/register_form.dart';
import 'package:hexora/c-frontend/utils/logo/logo_widget.dart';
import 'package:hexora/f-themes/shapes/solid/auth_header.dart';
import 'package:hexora/l10n/app_localizations.dart';

enum AuthMode { register, login, forgot }

class AuthSwitcherView extends StatefulWidget {
  final bool showRegister; // keep external control if you want
  const AuthSwitcherView({Key? key, this.showRegister = true})
      : super(key: key);

  @override
  State<AuthSwitcherView> createState() => _AuthSwitcherViewState();
}

class _AuthSwitcherViewState extends State<AuthSwitcherView> {
  late AuthMode _mode;

  static const double _headerHeight = 280;

  Color _authCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(255, 11, 76, 120)
        : Colors.white;
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.showRegister ? AuthMode.register : AuthMode.login;
  }

  void _switchToRegister() => setState(() => _mode = AuthMode.register);
  void _switchToLogin() => setState(() => _mode = AuthMode.login);
  void _switchToForgot() => setState(() => _mode = AuthMode.forgot);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topInset = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxFormWidth = screenWidth < 600 ? screenWidth : 700.0;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 12, 158, 194),
      body: Stack(
        children: [
          const BlueAuthHeader(height: _headerHeight),

          // Logo
          Positioned(
            top: topInset + _headerHeight * 0.10,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: LogoWidget.buildLogoAvatar(size: LogoSize.medium),
            ),
          ),

          // Card with animated swap
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              topInset + _headerHeight * 0.75,
              16,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxFormWidth),
                child: Card(
                  margin: const EdgeInsets.only(top: 24),
                  elevation: 6,
                  color: _authCardColor(context),
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented switcher (hide on Forgot)
                        if (_mode != AuthMode.forgot)
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _switchToRegister,
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          _mode == AuthMode.register
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.register,
                                      style: TextStyle(
                                        color: _mode == AuthMode.register
                                            ? Colors.white
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _switchToLogin,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _mode == AuthMode.login
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.login,
                                      style: TextStyle(
                                        color: _mode == AuthMode.login
                                            ? Colors.white
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Animated content
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            final offsetTween = Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).chain(CurveTween(curve: Curves.easeInOut));
                            return SlideTransition(
                              position: animation.drive(offsetTween),
                              child: FadeTransition(
                                  opacity: animation, child: child),
                            );
                          },
                          child: () {
                            switch (_mode) {
                              case AuthMode.register:
                                return Column(
                                  key: const ValueKey("register"),
                                  children: [
                                    const RegisterForm(),
                                    const SizedBox(height: 12),
                                    Text.rich(
                                      TextSpan(
                                        text: "${l10n.alreadyHaveAccount} ",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        children: [
                                          TextSpan(
                                            text: l10n.login,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = _switchToLogin,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                );
                              case AuthMode.login:
                                return Column(
                                  key: const ValueKey("login"),
                                  children: [
                                    LoginForm(
                                        onForgotPassword: _switchToForgot),
                                    const SizedBox(height: 12),
                                    Text.rich(
                                      TextSpan(
                                        text: "${l10n.dontHaveAccount} ",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        children: [
                                          TextSpan(
                                            text: l10n.register,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = _switchToRegister,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                );
                              case AuthMode.forgot:
                                return ForgotPasswordForm(
                                  key: const ValueKey("forgot"),
                                  onBackToLogin: _switchToLogin,
                                );
                            }
                          }(),
                        ),
                        if (kIsWeb) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRoutes.downloadApp),
                            icon: const Icon(Icons.download_rounded),
                            label: Text(l10n.downloadMobileApp),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
