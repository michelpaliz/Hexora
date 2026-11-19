import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'nav_tile.dart';
import 'switch_tile.dart';

class PreferencesSection extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleDark;
  final String languageName;
  final VoidCallback onChangeLanguage;
  final bool showDisplayPreferences;
  final VoidCallback? onOpenPreferences;
  final bool autoStatementImportEnabled;
  final bool autoStatementImportBusy;
  final ValueChanged<bool> onToggleAutoStatementImport;
  final String? autoStatementImportTitle;
  final String? autoStatementImportSubtitle;
  final bool? showDailyQuote;
  final ValueChanged<bool>? onToggleDailyQuote;

  const PreferencesSection({
    super.key,
    required this.isDark,
    required this.onToggleDark,
    required this.languageName,
    required this.onChangeLanguage,
    this.showDisplayPreferences = true,
    this.onOpenPreferences,
    required this.autoStatementImportEnabled,
    required this.autoStatementImportBusy,
    required this.onToggleAutoStatementImport,
    this.autoStatementImportTitle,
    this.autoStatementImportSubtitle,
    this.showDailyQuote,
    this.onToggleDailyQuote,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return Column(
      children: [
        if (onOpenPreferences != null) ...[
          NavTile(
            leading: Icon(Icons.tune_rounded, size: 18, color: cs.primary),
            iconBgColor: cs.primary.withValues(alpha: 0.12),
            title: l.preferencesTitle,
            subtitle: isSpanish
                ? 'Navegación, apariencia e idioma'
                : 'Navigation, appearance and language',
            compact: true,
            onTap: onOpenPreferences!,
          ),
          Divider(
              height: 0,
              indent: 63,
              color: cs.outlineVariant.withValues(alpha: 0.4)),
        ],
        if (showDisplayPreferences) ...[
          SwitchTile(
            leading: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 18,
              color: cs.primary,
            ),
            iconBgColor: cs.primary.withValues(alpha: 0.12),
            title: l.darkMode,
            compact: true,
            value: isDark,
            onChanged: (_) => onToggleDark(),
          ),
          Divider(
              height: 0,
              indent: 63,
              color: cs.outlineVariant.withValues(alpha: 0.4)),
        ],
        SwitchTile(
          leading: Icon(Icons.sync_rounded, size: 18, color: cs.primary),
          iconBgColor: cs.primary.withValues(alpha: 0.12),
          title: autoStatementImportTitle ?? l.autoStatementImportTitle,
          subtitle: autoStatementImportSubtitle ?? l.autoStatementImportHelper,
          compact: true,
          value: autoStatementImportEnabled,
          enabled: !autoStatementImportBusy,
          onChanged: onToggleAutoStatementImport,
        ),
        if (showDisplayPreferences) ...[
          Divider(
              height: 0,
              indent: 63,
              color: cs.outlineVariant.withValues(alpha: 0.4)),
          NavTile(
            leading: Icon(Icons.language_rounded, size: 18, color: cs.primary),
            iconBgColor: cs.primary.withValues(alpha: 0.12),
            title: isSpanish ? 'Idioma' : 'Language',
            subtitle: languageName,
            compact: true,
            onTap: onChangeLanguage,
          ),
        ],
        if (showDailyQuote != null && onToggleDailyQuote != null) ...[
          Divider(
              height: 0,
              indent: 63,
              color: cs.outlineVariant.withValues(alpha: 0.4)),
          SwitchTile(
            leading:
                Icon(Icons.format_quote_rounded, size: 18, color: cs.primary),
            iconBgColor: cs.primary.withValues(alpha: 0.12),
            title: isSpanish ? 'Frase motivacional' : 'Motivational quote',
            subtitle: isSpanish
                ? 'Mostrar una frase diaria en el inicio'
                : 'Show a daily quote on the home page',
            compact: true,
            value: showDailyQuote!,
            onChanged: onToggleDailyQuote!,
          ),
        ],
      ],
    );
  }
}
