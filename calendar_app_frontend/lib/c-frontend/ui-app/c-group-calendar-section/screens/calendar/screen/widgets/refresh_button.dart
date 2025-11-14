// lib/.../calendar/utils/refresh_cta.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RefreshCta extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const RefreshCta({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;

    final isDisabled = onPressed == null || isLoading;

    return Semantics(
      button: true,
      label: loc.refresh,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ButtonStyle(
            minimumSize: const MaterialStatePropertyAll(Size.fromHeight(48)),
            padding: const MaterialStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16),
            ),
            shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            side: MaterialStateProperty.resolveWith<BorderSide>(
              (states) => BorderSide(
                color: states.contains(MaterialState.disabled)
                    ? cs.outlineVariant
                    : cs.primary,
                width: 1.2,
              ),
            ),
            foregroundColor: MaterialStateProperty.resolveWith<Color>(
              (states) => states.contains(MaterialState.disabled)
                  ? cs.onSurfaceVariant
                  : cs.primary,
            ),
            overlayColor:
                MaterialStatePropertyAll(cs.primary.withOpacity(0.08)),
            backgroundColor: const MaterialStatePropertyAll(Colors.transparent),
            elevation: const MaterialStatePropertyAll(0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      cs.primary,
                    ),
                  ),
                )
              else
                const Icon(Icons.refresh_rounded, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  loc.refreshButton,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
