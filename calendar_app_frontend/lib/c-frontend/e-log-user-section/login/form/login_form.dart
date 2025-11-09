import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/c-frontend/a-home-section/home_page.dart';
import 'package:hexora/c-frontend/e-log-user-section/register/ui/form/button_style_helper.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/text_field/static/text_field_widget.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/text_field/static/textfield_styles.dart'
    show TextFieldStyles;
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context); // ✅ grab themed text styles

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
          const SizedBox(height: 24),

          // Submit
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

                        // Navigate to home after login
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Login failed: $e')),
                        );
                      }
                    }
                  : null,
              child: Text(l10n.login, style: t.buttonText), // ✅ use themed text
            ),
          ),

          const SizedBox(height: 14),

          // Forgot password → switches the card
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              child: Text(l10n.forgotPassword,
                  style: t.bodyMedium.copyWith(color: cs.primary)),
            ),
          ),
        ],
      ),
    );
  }
}
