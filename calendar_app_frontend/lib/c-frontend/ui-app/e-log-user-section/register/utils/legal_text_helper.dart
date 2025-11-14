import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// Builds the Terms + Privacy Policy RichText
Widget buildLegalText(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;

  return RichText(
    textAlign: TextAlign.center,
    text: TextSpan(
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.7),
          ),
      children: [
        TextSpan(text: l10n.termsAndPrivacyPrefix), // optional prefix
        TextSpan(
          text: l10n.terms,
          style: const TextStyle(decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              // TODO: implement navigation / url_launcher
              // final uri = Uri.parse("https://fastezcodecom/terms");
              // if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {}
            },
        ),
        TextSpan(text: l10n.andSeparator),
        TextSpan(
          text: l10n.privacyPolicy,
          style: const TextStyle(decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              // TODO: implement navigation / url_launcher
              // final uri = Uri.parse("https://fastezcodecom/privacy");
              // if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {}
            },
        ),
      ],
    ),
  );
}
