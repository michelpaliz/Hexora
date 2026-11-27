import 'package:flutter/material.dart';
import 'package:hexora/services/auth/models/verification_result.dart';
import 'package:hexora/presentation/screens/auth/shared_utilities/auth_shared_widgets.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// A card that displays the current status of the verification process
/// (Loading, Success, Error, or Idle).
class VerifyStatusCard extends StatelessWidget {
  final bool isVerifying;
  final VerificationResult? result;
  final String? token;
  final VoidCallback onRetry;

  const VerifyStatusCard({
    super.key,
    required this.isVerifying,
    required this.result,
    required this.token,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget content;
    Color bgColor;
    Color borderColor;

    if (isVerifying) {
      bgColor = cs.surface;
      borderColor = cs.outlineVariant.withValues(alpha: 0.5);
      content = Row(
        children: [
          const SizedBox.square(
            dimension: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.verifyingEmail,
              style: t.bodyMedium.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      );
    } else if (result != null) {
      final success = result!.success;
      bgColor = success ? Colors.green.shade50 : Colors.red.shade50;
      borderColor = success ? Colors.green.shade200 : Colors.red.shade200;
      final iconColor = success ? Colors.green.shade700 : Colors.red.shade700;
      final textColor = success ? Colors.green.shade900 : Colors.red.shade900;

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.error_rounded,
                color: iconColor,
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  result!.message,
                  style: t.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!success && (token?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: iconColor),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.verifyEmailTryAgain),
              ),
            ),
          ],
        ],
      );
    } else {
      // Idle / Default state
      bgColor = cs.primaryContainer.withValues(alpha: 0.3);
      borderColor = cs.primary.withValues(alpha: 0.2);
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.mark_email_unread_rounded,
              size: 24,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.verifyEmailInfo,
                style: t.bodyMedium.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: content,
    );
  }
}

/// A section containing the Email Input and Action Buttons (Resend / Back).
class VerifyActionSection extends StatelessWidget {
  final TextEditingController emailController;
  final bool isResending;
  final bool verificationSucceeded;
  final VoidCallback onResend;
  final VoidCallback onBackToLogin;

  const VerifyActionSection({
    super.key,
    required this.emailController,
    required this.isResending,
    this.verificationSucceeded = false,
    required this.onResend,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!verificationSucceeded) ...[
          TextFormField(
            key: const Key('verify_email_field'),
            controller: emailController,
            enabled: !isResending,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) {
              if (!isResending) onResend();
            },
            style: t.bodyMedium,
            decoration: authInputDecoration(
              context,
              labelText: l10n.email,
              hintText: l10n.emailHint,
              icon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              key: const Key('resend_verification_button'),
              icon: isResending
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                isResending
                    ? l10n.resendVerificationSending
                    : l10n.resendVerificationButton,
                style: t.buttonText,
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isResending ? null : onResend,
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 44,
          child: TextButton.icon(
            key: const Key('back_to_login_button'),
            onPressed: onBackToLogin,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(
              l10n.backToLogin,
              style: t.bodyMedium.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
