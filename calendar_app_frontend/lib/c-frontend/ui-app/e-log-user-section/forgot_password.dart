import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/auth_user/exceptions/auth_exceptions.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 480),
              child: const ForgotPasswordForm(),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordForm extends StatefulWidget {
  final VoidCallback? onBackToLogin;
  const ForgotPasswordForm({super.key, this.onBackToLogin});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _isSubmitting = false;
  bool _submittedSuccessfully = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  String? _validateEmail(String? val, AppLocalizations l10n) {
    final value = val?.trim() ?? '';
    if (value.isEmpty) return l10n.emailRequired;
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
    return ok ? null : l10n.invalidEmail;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSubmitting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    setState(() {
      _isSubmitting = true;
      _apiError = null;
      _submittedSuccessfully = false;
    });

    try {
      await context.read<AuthService>().forgotPassword(_email.text.trim());
      if (!mounted) return;
      setState(() => _submittedSuccessfully = true);
    } on ForgotPasswordRequestFailedException catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiError = l10n.forgotPasswordNetworkError);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            key: const Key('forgot_email_field'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: l10n.email,
              hintText: l10n.emailHint,
              suffixIcon: const Icon(Icons.email),
              border: const OutlineInputBorder(),
              errorMaxLines: 2,
            ),
            validator: (val) => _validateEmail(val, l10n),
          ),
          if (_apiError != null) ...[
            const SizedBox(height: 12),
            Text(
              _apiError!,
              key: const Key('forgot_api_error'),
              style: TextStyle(color: cs.error),
            ),
          ],
          if (_submittedSuccessfully) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('forgot_success_message'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.forgotPasswordNeutralSuccess,
                style: TextStyle(color: cs.onSurface),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              key: const Key('forgot_submit_button'),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.sendResetLink),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.onBackToLogin ??
                () => Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.loginRoute,
                      (route) => false,
                    ),
            child: Text(l10n.backToLogin),
          ),
        ],
      ),
    );
  }
}
