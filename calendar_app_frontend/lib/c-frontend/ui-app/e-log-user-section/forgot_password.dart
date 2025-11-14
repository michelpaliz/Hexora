import 'package:hexora/c-frontend/utils/view-item-styles/text_field/static/text_field_widget.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/text_field/static/textfield_styles.dart'
    show TextFieldStyles;
import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ForgotPasswordForm extends StatefulWidget {
  final VoidCallback? onBackToLogin;
  const ForgotPasswordForm({super.key, this.onBackToLogin});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_recompute);
    _recompute();
  }

  @override
  void dispose() {
    _email.removeListener(_recompute);
    _email.dispose();
    super.dispose();
  }

  void _recompute() {
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_email.text.trim());
    setState(() => _canSubmit = ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.forgotPassword,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.forgotPasswordSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 28),
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
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _canSubmit
                  ? () async {
                      if (!_formKey.currentState!.validate()) return;
                      // TODO: call your reset endpoint
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.resetLinkSent)));
                      widget.onBackToLogin?.call();
                    }
                  : null,
              child: Text(l10n.sendResetLink),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.onBackToLogin,
            child: Text(l10n.login),
          ),
        ],
      ),
    );
  }
}
