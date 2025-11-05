import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_database/auth_provider.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../c-frontend/routes/appRoutes.dart';

//* GLOBAL VARIABLES */

enum DrawerSections { calendar, settings, logOut }

/// We only need section & icon now; title comes from localizations.
final List<Map<String, dynamic>> menuItems = [
  {
    'section': DrawerSections.calendar,
    'icon': Icons.calendar_month,
    'isSelected': false
  },
  {
    'section': DrawerSections.settings,
    'icon': Icons.settings,
    'isSelected': false
  },
  {'section': DrawerSections.logOut, 'icon': Icons.logout, 'isSelected': false},
];

//* UI FOR THE DRAWER LIST */

Widget MyDrawerList(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      for (var item in menuItems)
        menuItem(
          context,
          item['section'] as DrawerSections,
          item['icon'] as IconData,
          item['isSelected'] as bool,
        ),
    ],
  );
}

Widget menuItem(
  BuildContext context,
  DrawerSections section,
  IconData iconData,
  bool selected,
) {
  final t = AppTypography.of(context);
  final cs = Theme.of(context).colorScheme;

  final title = _getTranslatedTitle(context, section);

  // Colors: selected gets container colors; otherwise subtle surface/outline mix.
  final bg =
      selected ? cs.secondaryContainer.withOpacity(0.85) : Colors.transparent;
  final onBg =
      selected ? cs.onSecondaryContainer : ThemeColors.textPrimary(context);
  final iconColor = selected ? cs.onSecondaryContainer : cs.secondary;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        switch (section) {
          case DrawerSections.calendar:
            Navigator.pushNamed(context, AppRoutes.homePage);
            break;
          case DrawerSections.settings:
            Navigator.pushNamed(context, AppRoutes.settings);
            break;
          case DrawerSections.logOut:
            _handleLogout(context);
            break;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : cs.outlineVariant.withOpacity(0.35),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 7),
              child: Icon(iconData, size: 20, color: iconColor),
            ),
            Expanded(
              child: Text(
                title,
                style: t.bodyLarge.copyWith(
                  color: onBg,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (section != DrawerSections.logOut)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: onBg.withOpacity(0.6)),
          ],
        ),
      ),
    ),
  );
}

String _getTranslatedTitle(BuildContext context, DrawerSections section) {
  final loc = AppLocalizations.of(context)!;
  switch (section) {
    case DrawerSections.calendar:
      return loc.calendar;
    case DrawerSections.settings:
      return loc.settings;
    case DrawerSections.logOut:
      return loc.logout;
  }
}

//* LOGOUT HANDLER */
bool _loggingOut = false;

Future<void> _handleLogout(BuildContext context) async {
  if (_loggingOut) return;
  _loggingOut = true;
  try {
    final shouldLogout = await showLogOutDialog(context);
    if (shouldLogout) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logOut();
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.loginRoute, (_) => false);
    }
  } finally {
    _loggingOut = false;
  }
}

Future<bool> showLogOutDialog(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final t = AppTypography.of(context);
  final cs = Theme.of(context).colorScheme;

  final dialogBg = ThemeColors.cardBg(context);
  final onDialog = ThemeColors.textPrimary(context);

  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          loc.logout,
          style: t.titleLarge
              .copyWith(color: onDialog, fontWeight: FontWeight.w700),
        ),
        content: Text(
          loc.logoutMessage,
          style: t.bodyLarge
              .copyWith(color: onDialog.withOpacity(0.9), height: 1.35),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: cs.secondary),
            child: Text(loc.cancel, style: t.buttonText),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: ThemeColors.contrastOn(cs.primary),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(loc.logout, style: t.buttonText),
          ),
        ],
      );
    },
  ).then((v) => v ?? false);
}
