import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/auth_user/exceptions/auth_exceptions.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _token;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  bool _invalidOrExpired = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveToken());
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _resolveToken() {
    if (_token != null) return;
    final fromCtor = widget.initialToken?.trim();
    final fromUrl = Uri.base.queryParameters['token']?.trim();
    final routeName = ModalRoute.of(context)?.settings.name;
    final fromRoute = routeName == null
        ? null
        : Uri.tryParse(routeName)?.queryParameters['token']?.trim();

    final resolved = [
      fromCtor,
      fromUrl,
      fromRoute,
    ].whereType<String>().firstWhere(
          (e) => e.isNotEmpty,
          orElse: () => '',
        );
    setState(() {
      _token = resolved.isEmpty ? null : resolved;
    });
  }

  String? _validateNewPassword(String? value, AppLocalizations l10n) {
    final password = value ?? '';
    if (password.isEmpty) return l10n.passwordRequired;
    if (password.length < 8) return l10n.passwordMinLength;
    return null;
  }

  String? _validateConfirmPassword(String? value, AppLocalizations l10n) {
    final confirm = value ?? '';
    if (confirm.isEmpty) return l10n.confirmPasswordRequired;
    if (confirm != _newPasswordController.text) {
      return l10n.newPasswordConfirmationError;
    }
    return null;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isSubmitting || _token == null || _token!.isEmpty) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _isSubmitting = true;
      _apiError = null;
      _invalidOrExpired = false;
      _isSuccess = false;
    });

    try {
      await context.read<AuthService>().resetPassword(
            token: _token!,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;
      setState(() => _isSuccess = true);
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on ResetPasswordInvalidOrExpiredTokenException catch (e) {
      if (!mounted) return;
      setState(() {
        _invalidOrExpired = true;
        _apiError =
            e.message.isNotEmpty ? e.message : l10n.resetPasswordInvalidToken;
      });
    } on ResetPasswordRequestFailedException catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiError = l10n.resetPasswordGenericError);
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

    final hasToken = _token != null && _token!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resetPassword),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: hasToken
                  ? _isSuccess
                      ? _SuccessState(onGoLogin: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.loginRoute,
                            (route) => false,
                          );
                        })
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.resetPassword,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('reset_new_password_field'),
                                controller: _newPasswordController,
                                obscureText: !_showNewPassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword
                                ],
                                decoration: InputDecoration(
                                  labelText: l10n.newPassword,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() =>
                                        _showNewPassword = !_showNewPassword),
                                    icon: Icon(_showNewPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                  ),
                                ),
                                validator: (value) =>
                                    _validateNewPassword(value, l10n),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('reset_confirm_password_field'),
                                controller: _confirmPasswordController,
                                obscureText: !_showConfirmPassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                autofillHints: const [
                                  AutofillHints.newPassword
                                ],
                                decoration: InputDecoration(
                                  labelText: l10n.confirmPassword,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() =>
                                        _showConfirmPassword =
                                            !_showConfirmPassword),
                                    icon: Icon(_showConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                  ),
                                ),
                                validator: (value) =>
                                    _validateConfirmPassword(value, l10n),
                              ),
                              if (_apiError != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _apiError!,
                                  key: const Key('reset_api_error'),
                                  style: TextStyle(color: cs.error),
                                ),
                              ],
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  key: const Key('reset_submit_button'),
                                  onPressed: _isSubmitting ? null : _submit,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : Text(l10n.resetPasswordSubmit),
                                ),
                              ),
                              if (_invalidOrExpired) ...[
                                const SizedBox(height: 10),
                                TextButton(
                                  key: const Key(
                                      'reset_request_new_link_button'),
                                  onPressed: () => Navigator.of(context)
                                      .pushReplacementNamed(
                                    AppRoutes.forgotPasswordRoute,
                                  ),
                                  child: Text(l10n.resetPasswordRequestNewLink),
                                ),
                              ],
                            ],
                          ),
                        )
                  : _InvalidLinkState(
                      onRequestNewLink: () => Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.forgotPasswordRoute),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InvalidLinkState extends StatelessWidget {
  const _InvalidLinkState({
    required this.onRequestNewLink,
  });

  final VoidCallback onRequestNewLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const Key('reset_invalid_link_state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.resetPasswordInvalidLinkTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(l10n.resetPasswordInvalidLinkBody),
        const SizedBox(height: 16),
        ElevatedButton(
          key: const Key('reset_request_link_button'),
          onPressed: onRequestNewLink,
          child: Text(l10n.resetPasswordRequestNewLink),
        ),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.onGoLogin});

  final VoidCallback onGoLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const Key('reset_success_state'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.resetPasswordSuccessTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(l10n.resetPasswordSuccessBody),
        const SizedBox(height: 18),
        ElevatedButton(
          key: const Key('reset_go_login_button'),
          onPressed: onGoLogin,
          child: Text(l10n.backToLogin),
        ),
      ],
    );
  }
}
