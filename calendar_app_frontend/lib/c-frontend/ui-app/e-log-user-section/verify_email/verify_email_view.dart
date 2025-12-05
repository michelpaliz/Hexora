import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/auth_user/auth/models/verification_result.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/e-log-user-section/verify_email/very_status_card.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final TextEditingController _emailController = TextEditingController();
  VerificationResult? _result;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // --- Logic / Bootstrap ---

  void _bootstrap() {
    // 1. Parse arguments from route settings
    final args = ModalRoute.of(context)?.settings.arguments;
    String? emailArg;
    String? tokenArg;

    if (args is Map) {
      final mapArgs = args.cast<String, dynamic>();
      emailArg = mapArgs['email'] as String?;
      tokenArg = mapArgs['token'] as String?;
    }

    // 2. Parse arguments from URL (Deep link support)
    final tokenFromUrl = Uri.base.queryParameters['token'];
    final emailFromUrl = Uri.base.queryParameters['email'];

    // 3. Determine final values
    _token = (tokenFromUrl?.isNotEmpty ?? false)
        ? tokenFromUrl
        : (tokenArg?.isNotEmpty ?? false)
            ? tokenArg
            : null;

    final email = (emailFromUrl?.isNotEmpty ?? false)
        ? emailFromUrl
        : (emailArg?.isNotEmpty ?? false)
            ? emailArg
            : null;

    if (email != null) {
      _emailController.text = email;
    }

    // 4. Auto-verify if token exists
    if (_token != null && _token!.isNotEmpty) {
      _verify(_token!);
    }
  }

  Future<void> _verify(String token) async {
    setState(() {
      _isVerifying = true;
      _result = null;
    });

    try {
      final authService = context.read<AuthService>();
      final res = await authService.verifyEmailToken(token: token);
      if (!mounted) return;
      setState(() {
        _result = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result =
            VerificationResult(success: false, message: e.toString().trim());
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);

    if (!emailOk) {
      _showSnack(l10n.resendVerificationInvalidEmail);
      return;
    }

    setState(() => _isResending = true);
    try {
      final authService = context.read<AuthService>();
      await authService.resendVerificationEmail(email: email);
      if (!mounted) return;
      _showSnack(l10n.resendVerificationSent(email));
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().trim();
      _showSnack(l10n.resendVerificationFailed(message));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.verifyEmailTitle),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Status Card (Feedback)
                VerifyStatusCard(
                  isVerifying: _isVerifying,
                  result: _result,
                  token: _token,
                  onRetry: () => _token != null ? _verify(_token!) : null,
                ),

                const SizedBox(height: 32),

                // 2. Action Section (Input + Buttons)
                VerifyActionSection(
                  emailController: _emailController,
                  isResending: _isResending,
                  onResend: _resend,
                  onBackToLogin: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.loginRoute,
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}