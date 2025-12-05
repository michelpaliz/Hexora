import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/utils/logo/logo_widget.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadAppView extends StatelessWidget {
  const DownloadAppView({super.key});

  // Both files hosted on your own webserver:
  static const _androidStoreUrl =
      'https://fastezcode.com/downloads/android/hexora-android-latest.apk';

  static const _iosStoreUrl =
      'https://fastezcode.com/downloads/ios/hexora-ios-latest.ipa';

  Future<void> _openStore(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showFailure(context, l10n.downloadAppOpenError);
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showFailure(context, l10n.downloadAppOpenError);
    }
  }

  void _showFailure(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (!kIsWeb) {
      // In native apps, just return to login since the store buttons are web-only.
      return const AuthRedirectScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.downloadMobileApp),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LogoWidget.buildLogoAvatar(size: LogoSize.medium),
                      const SizedBox(height: 18),
                      Text(
                        l10n.downloadAppTitle,
                        style: t.displayMedium.copyWith(color: cs.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.downloadAppSubtitle,
                        style: t.bodyLarge.copyWith(
                          color: cs.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      _DownloadButton(
                        label: l10n.downloadAppAndroid,
                        icon: Icons.android_rounded,
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.white,
                        onPressed: () => _openStore(context, _androidStoreUrl),
                      ),
                      const SizedBox(height: 12),
                      _DownloadButton(
                        label: l10n.downloadAppIos,
                        icon: Icons.apple_rounded,
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        onPressed: () => _openStore(context, _iosStoreUrl),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.loginRoute,
                            (route) => false,
                          );
                        },
                        child: Text(l10n.backToLogin),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthRedirectScreen extends StatelessWidget {
  const AuthRedirectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Immediately send native users back to login/home flow.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.loginRoute,
        (route) => false,
      );
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: t.buttonText.copyWith(color: foregroundColor),
        ),
      ),
    );
  }
}
