import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

typedef LegalLinkAction = Future<bool> Function(Uri uri);

/// Displays localized Terms and Privacy Policy links during registration.
class LegalLinks extends StatefulWidget {
  const LegalLinks({
    super.key,
    this.termsUrl,
    this.privacyUrl,
    this.onTermsTap,
    this.onPrivacyTap,
  });

  final String? termsUrl;
  final String? privacyUrl;

  /// Optional action used instead of launching the Terms URL.
  final LegalLinkAction? onTermsTap;

  /// Optional action used instead of launching the Privacy Policy URL.
  final LegalLinkAction? onPrivacyTap;

  @override
  State<LegalLinks> createState() => _LegalLinksState();
}

class _LegalLinksState extends State<LegalLinks> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _openTerms;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final termsUri = _publicHttpUrl(widget.termsUrl);
    final privacyUri = _publicHttpUrl(widget.privacyUrl);
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurface.withOpacity(0.7),
        );

    if (termsUri == null && privacyUri == null) {
      return Text(
        l10n.termsAndPrivacyUnavailable,
        style: textStyle,
        textAlign: TextAlign.center,
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: textStyle,
        children: [
          TextSpan(text: l10n.termsAndPrivacyPrefix),
          _legalLink(
            label: l10n.terms,
            uri: termsUri,
            recognizer: _termsRecognizer,
          ),
          TextSpan(text: l10n.andSeparator),
          _legalLink(
            label: l10n.privacyPolicy,
            uri: privacyUri,
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
    );
  }

  void _openTerms() {
    final uri = _publicHttpUrl(widget.termsUrl);
    if (uri != null) _openLink(uri, widget.onTermsTap);
  }

  void _openPrivacy() {
    final uri = _publicHttpUrl(widget.privacyUrl);
    if (uri != null) _openLink(uri, widget.onPrivacyTap);
  }

  Future<void> _openLink(Uri uri, LegalLinkAction? action) async {
    final opened = await (action?.call(uri) ??
        launchUrl(uri, mode: LaunchMode.externalApplication));
    if (opened || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.termsAndPrivacyUnavailable)),
    );
  }
}

Uri? _publicHttpUrl(String? value) {
  final rawUrl = value?.trim();
  if (rawUrl == null || rawUrl.isEmpty) return null;

  final uri = Uri.tryParse(rawUrl);
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  return uri;
}

TextSpan _legalLink({
  required String label,
  required Uri? uri,
  required TapGestureRecognizer recognizer,
}) {
  if (uri == null) return TextSpan(text: label);

  return TextSpan(
    text: label,
    semanticsLabel: label,
    style: const TextStyle(decoration: TextDecoration.underline),
    recognizer: recognizer,
    mouseCursor: SystemMouseCursors.click,
  );
}
