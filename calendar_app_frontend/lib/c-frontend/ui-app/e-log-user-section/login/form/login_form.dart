import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/auth_user/exceptions/auth_exceptions.dart';
import 'package:hexora/c-frontend/ui-app/a-home-section/home_page/home_page.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/register/ui/form/button_style_helper.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/text_field/static/text_field_widget.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/text_field/static/textfield_styles.dart'
    show TextFieldStyles;
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback? onForgotPassword;

  const LoginForm({super.key, this.onForgotPassword});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _showPassword = false;
  bool _canSubmit = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_recomputeCanSubmit);
    _password.addListener(_recomputeCanSubmit);
    _recomputeCanSubmit();
  }

  @override
  void dispose() {
    _email.removeListener(_recomputeCanSubmit);
    _password.removeListener(_recomputeCanSubmit);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _recomputeCanSubmit() {
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_email.text.trim());
    final pwOk = _password.text.isNotEmpty;
    final next = emailOk && pwOk;
    if (next != _canSubmit) setState(() => _canSubmit = next);
  }

  void _showSnack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), action: action),
    );
  }

  Future<void> _resendVerification({String? overrideEmail}) async {
    final l10n = AppLocalizations.of(context)!;
    final email = (overrideEmail ?? _email.text).trim();
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    if (!emailOk) {
      _showSnack(l10n.resendVerificationInvalidEmail);
      return;
    }

    setState(() => _isResending = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.resendVerificationEmail(email: email);
      if (!mounted) return;
      _showSnack(l10n.resendVerificationSent(email));
    } catch (e) {
      if (!mounted) return;
      _showSnack(l10n.resendVerificationFailed(e.toString().trim()));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _promptEmailVerification(String email) {
    final l10n = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.mark_email_unread_rounded, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.verifyEmailTitle,
                    style: t.bodyMedium.copyWith(color: cs.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.verifyEmailInfo,
              style: t.bodyMedium.copyWith(
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _isResending
                    ? null
                    : () async {
                        Navigator.of(context).pop(); // close sheet
                        await _resendVerification(overrideEmail: email);
                      },
                child: _isResending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.resendVerificationButton, style: t.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 👋 Welcome
          Text(
            l10n.loginWelcomeTitle,
            style: t.displayMedium.copyWith(color: cs.primary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.loginWelcomeSubtitle,
            style: t.bodyMedium.copyWith(color: cs.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 28),

          // Email
          TextFieldWidget(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: TextFieldStyles.saucyInputDecoration(
              labelText: l10n.email,
              hintText: l10n.emailHint,
              suffixIcon: Icons.email,
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return l10n.emailRequired;
              final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val.trim());
              return ok ? null : l10n.invalidEmail;
            },
          ),
          const SizedBox(height: 16),

          // Password
          TextFieldWidget(
            controller: _password,
            keyboardType: TextInputType.visiblePassword,
            obscureText: !_showPassword,
            decoration: TextFieldStyles.saucyInputDecoration(
              labelText: l10n.password,
              hintText: l10n.passwordHint,
              suffixIcon: Icons.lock,
            ).copyWith(
              suffixIcon: IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility),
                tooltip: _showPassword ? l10n.hidePassword : l10n.showPassword,
              ),
            ),
            validator: (val) =>
                (val == null || val.isEmpty) ? l10n.passwordRequired : null,
          ),

          // 🔹 UX IMPROVEMENT: Forgot Password immediately below input
          // Aligned right, close to where the user just typed the password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
                foregroundColor: cs.primary,
              ),
              child: Text(
                l10n.forgotPassword,
                style: t.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ButtonStyleHelper.resolved(context, enabled: _canSubmit),
              onPressed: _canSubmit
                  ? () async {
                      if (!_formKey.currentState!.validate()) return;
                      final email = _email.text.trim();
                      final password = _password.text;
                      try {
                        await authService.logIn(
                            email: email, password: password);
                        if (!mounted) return;

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        if (e is EmailNotVerifiedAuthException) {
                          _promptEmailVerification(email);
                        } else if (e is WrongPasswordAuthException) {
                          _showSnack(l10n.loginInvalidCredentials);
                        } else {
                          _showSnack('Login failed: $e');
                        }
                      }
                    }
                  : null,
              child: Text(l10n.login, style: t.buttonText),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
