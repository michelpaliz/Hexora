import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'nav_tile.dart';
import 'switch_tile.dart';

class PreferencesSection extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleDark;
  final String languageName;
  final VoidCallback onChangeLanguage;
  final bool autoStatementImportEnabled;
  final bool autoStatementImportBusy;
  final ValueChanged<bool> onToggleAutoStatementImport;

  const PreferencesSection({
    super.key,
    required this.isDark,
    required this.onToggleDark,
    required this.languageName,
    required this.onChangeLanguage,
    required this.autoStatementImportEnabled,
    required this.autoStatementImportBusy,
    required this.onToggleAutoStatementImport,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    // Amber-ish for dark mode toggle
    const darkModeColor = Color(0xFFF59E0B);

    return Column(
      children: [
        SwitchTile(
          leading: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 18,
            color: darkModeColor,
          ),
          iconBgColor: darkModeColor.withValues(alpha: 0.12),
          title: l.darkMode,
          value: isDark,
          onChanged: (_) => onToggleDark(),
        ),
        Divider(
            height: 0,
            indent: 63,
            color: cs.outlineVariant.withValues(alpha: 0.4)),
        SwitchTile(
          leading: Icon(Icons.sync_rounded, size: 18, color: cs.secondary),
          iconBgColor: cs.secondary.withValues(alpha: 0.12),
          title: l.autoStatementImportTitle,
          subtitle: l.autoStatementImportHelper,
          value: autoStatementImportEnabled,
          enabled: !autoStatementImportBusy,
          onChanged: onToggleAutoStatementImport,
        ),
        Divider(
            height: 0,
            indent: 63,
            color: cs.outlineVariant.withValues(alpha: 0.4)),
        NavTile(
          leading: Icon(Icons.language_rounded, size: 18, color: cs.tertiary),
          iconBgColor: cs.tertiary.withValues(alpha: 0.12),
          title: isSpanish ? 'Idioma' : 'Language',
          subtitle: languageName,
          onTap: onChangeLanguage,
        ),
      ],
    );
  }
}
