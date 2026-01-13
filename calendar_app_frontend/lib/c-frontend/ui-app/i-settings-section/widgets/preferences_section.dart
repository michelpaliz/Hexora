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

    return Column(
      children: [
        // SwitchTile should render title with bodyMedium internally
        SwitchTile(
          leading: const Icon(Icons.dark_mode_outlined),
          title: l.darkMode,
          value: isDark,
          onChanged: (_) => onToggleDark(),
        ),
        const Divider(height: 0),
        SwitchTile(
          leading: const Icon(Icons.sync_rounded),
          title: l.autoStatementImportTitle,
          subtitle: l.autoStatementImportHelper,
          value: autoStatementImportEnabled,
          enabled: !autoStatementImportBusy,
          onChanged: onToggleAutoStatementImport,
        ),
        const Divider(height: 0),
        // NavTile renders: title → bodyMedium, subtitle → bodySmall
        NavTile(
          leading: const Icon(Icons.language_rounded),
          title: l.language,
          subtitle: languageName,
          onTap: onChangeLanguage,
        ),
      ],
    );
  }
}
