import 'package:hexora/theme/shapes/solid/auth_header.dart';
import 'package:hexora/presentation/utils/logo/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:provider/provider.dart';

/// Shared constants
const double kAuthHeaderHeight = 280;

class AuthLanguageSelector extends StatelessWidget {
  const AuthLanguageSelector({super.key, this.neutralSurface = false});

  final bool neutralSurface;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final selected = locale.locale.languageCode;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final colors = Theme.of(context).colorScheme;

    Widget option(String code) {
      final active = selected == code.toLowerCase();
      return Semantics(
        button: true,
        selected: active,
        label: code == 'ES' ? 'Español' : 'English',
        child: InkWell(
          key: ValueKey('auth-language-${code.toLowerCase()}'),
          onTap: active
              ? null
              : () => locale.setLocale(Locale(code.toLowerCase())),
          borderRadius: BorderRadius.circular(7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? (neutralSurface
                      ? colors.primaryContainer
                      : AppColors.white.withValues(alpha: 0.18))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              code,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: neutralSurface
                        ? (active
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant)
                        : AppColors.navigationForeground,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: isEs ? 'Cambiar idioma' : 'Change language',
      child: Material(
        key: const ValueKey('auth-language-selector'),
        color: neutralSurface
            ? colors.surface
            : AppColors.dashboardTopBar.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 7, right: 3),
                child: Icon(
                  Icons.language_rounded,
                  size: 17,
                  color: neutralSurface
                      ? colors.onSurfaceVariant
                      : AppColors.navigationForeground,
                ),
              ),
              option('ES'),
              option('EN'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared card builder
Widget buildAuthCard({
  Key? key,
  bool softShadow = false,
  required BuildContext context,
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(28),
}) {
  return Card(
    key: key,
    margin: EdgeInsets.zero,
    elevation: softShadow ? 8 : 0,
    shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
    color: Theme.of(context).colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(softShadow ? 24 : 20),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: padding,
      child: child,
    ),
  );
}

/// Auth-only field styling; other application forms keep their own theme.
InputDecoration authInputDecoration(
  BuildContext context, {
  required String labelText,
  required String hintText,
  required IconData icon,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
    filled: true,
    fillColor: cs.surfaceContainerLowest,
    prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: border(cs.outlineVariant),
    enabledBorder: border(cs.outlineVariant),
    focusedBorder: border(cs.primary, 2),
    errorBorder: border(cs.error),
    focusedErrorBorder: border(cs.error, 2),
    errorMaxLines: 3,
  );
}

/// Shared header with background + logo
Widget buildAuthHeader(BuildContext context) {
  final topInset = MediaQuery.of(context).padding.top;

  return Stack(
    children: [
      const BlueAuthHeader(height: kAuthHeaderHeight),
      Positioned(
        top: topInset + kAuthHeaderHeight * 0.10,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.center,
          child: LogoWidget.buildLogoAvatar(size: LogoSize.medium),
        ),
      ),
    ],
  );
}
