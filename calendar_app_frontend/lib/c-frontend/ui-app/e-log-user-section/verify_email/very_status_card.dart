import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/models/verification_result.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
      borderColor = cs.outlineVariant.withOpacity(0.5);
      content = Column(
        children: [
          const SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.verifyingEmail,
            style: t.bodyLarge.copyWith(color: cs.onSurface),
            textAlign: TextAlign.center,
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
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: iconColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            result!.message,
            textAlign: TextAlign.center,
            style: t.bodyLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!success && (token?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: iconColor,
                side: BorderSide(color: iconColor),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.verifyEmailTryAgain),
            ),
          ],
        ],
      );
    } else {
      // Idle / Default state
      bgColor = cs.primaryContainer.withOpacity(0.3);
      borderColor = cs.primary.withOpacity(0.2);
      content = Column(
        children: [
          Icon(Icons.mark_email_read_outlined, size: 64, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            l10n.verifyEmailInfo,
            textAlign: TextAlign.center,
            style: t.bodyMedium.copyWith(color: cs.onSurface),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
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
  final VoidCallback onResend;
  final VoidCallback onBackToLogin;

  const VerifyActionSection({
    super.key,
    required this.emailController,
    required this.isResending,
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
        // Input Field
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: t.bodyLarge,
          decoration: InputDecoration(
            labelText: l10n.email,
            hintText: l10n.emailHint,
            prefixIcon: Icon(Icons.email_outlined, color: cs.primary),
            filled: true,
            fillColor: cs.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            // Resend Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  icon: isResending
                      ? SizedBox(
                          width: 18,
                          height: 18,
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
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isResending ? null : onResend,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Back Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: onBackToLogin,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: Text(
                    l10n.backToLogin,
                    style: t.bodyLarge.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
