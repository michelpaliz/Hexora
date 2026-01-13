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
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            side: WidgetStateProperty.resolveWith<BorderSide>(
              (states) => BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? cs.outlineVariant
                    : cs.primary,
                width: 1.2,
              ),
            ),
            foregroundColor: WidgetStateProperty.resolveWith<Color>(
              (states) => states.contains(WidgetState.disabled)
                  ? cs.onSurfaceVariant
                  : cs.primary,
            ),
            overlayColor:
                WidgetStatePropertyAll(cs.primary.withOpacity(0.08)),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(0),
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
