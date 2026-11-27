import 'package:flutter/material.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/auth/models/verification_result.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/auth/shared_utilities/auth_shared_widgets.dart';
import 'package:hexora/presentation/screens/auth/verify_email/very_status_card.dart';
import 'package:hexora/presentation/utils/logo/hexora_brand.dart';
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
  String? _invitationToken;

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
      _invitationToken = mapArgs['invitationToken'] as String?;
    }

    // 2. Parse arguments from URL (Deep link support)
    final tokenFromUrl = Uri.base.queryParameters['token'];
    final emailFromUrl = Uri.base.queryParameters['email'];
    _invitationToken ??= Uri.base.queryParameters['invitationToken'];

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
      await authService.resendVerificationEmail(
        email: email,
        invitationToken: _invitationToken,
      );
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_page/dark_bg_color.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;
              final horizontalPadding = compact ? 16.0 : 32.0;
              final verticalPadding = compact ? 64.0 : 32.0;

              return Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        verticalPadding,
                        horizontalPadding,
                        compact ? 20 : 32,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight -
                                  verticalPadding -
                                  (compact ? 20 : 32))
                              .clamp(0, double.infinity),
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        l10n.verifyEmailTitle,
                                        key: const Key('verify_email_title'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      VerifyStatusCard(
                                        isVerifying: _isVerifying,
                                        result: _result,
                                        token: _token,
                                        onRetry: () => _token != null
                                            ? _verify(_token!)
                                            : null,
                                      ),
                                      const SizedBox(height: 24),
                                      VerifyActionSection(
                                        emailController: _emailController,
                                        isResending: _isResending,
                                        verificationSucceeded:
                                            _result?.success == true,
                                        onResend: _resend,
                                        onBackToLogin: () {
                                          Navigator.of(context)
                                              .pushNamedAndRemoveUntil(
                                            AppRoutes.loginRoute,
                                            (route) => false,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: compact ? 12 : 16,
                    right: compact ? 16 : 24,
                    child: const AuthLanguageSelector(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
