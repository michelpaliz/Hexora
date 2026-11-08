import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:hexora/theme/theme_provider.dart';
import 'package:provider/provider.dart';

/// Full-screen preferences route used from the profile, home and account menus.
///
/// When Preferences is opened from inside the Settings workspace it renders
/// [UserPreferencesView] directly in the content area instead, so the Settings
/// sidebar stays visible. Both paths share the exact same content.
class UserPreferencesScreen extends StatelessWidget {
  const UserPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l.preferencesTitle),
      ),
      body: const SafeArea(child: UserPreferencesView()),
    );
  }
}

/// Embeddable preferences content (no Scaffold or AppBar), so it can be hosted
/// either by [UserPreferencesScreen] or inline inside the Settings shell.
class UserPreferencesView extends StatelessWidget {
  const UserPreferencesView({
    super.key,
    this.maxWidth = 760,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 40),
    this.alignment = Alignment.topCenter,
  });

  /// Maximum content width; callers align it with the surrounding layout.
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  /// Horizontal/vertical anchor of the capped content. The standalone route
  /// centers it; the Settings shell pins it to the left to follow the sidebar.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Align(
      alignment: alignment,
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                icon: Icons.navigation_outlined,
                label: l.preferencesNavigation,
              ),
              const SizedBox(height: 8),
              const _NavigationPreference(),
              const _SectionDivider(),
              _SectionTitle(
                icon: Icons.palette_outlined,
                label: l.preferencesAppearance,
              ),
              const SizedBox(height: 12),
              const _AppearancePreference(),
              const _SectionDivider(),
              _SectionTitle(
                icon: Icons.language_rounded,
                label: l.preferencesLanguage,
              ),
              const SizedBox(height: 12),
              const _LanguagePreference(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Divider(
          height: 1,
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.45),
        ),
      );
}

class _NavigationPreference extends StatelessWidget {
  const _NavigationPreference();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final provider = context.watch<UserPreferencesProvider>();
    final choices = [
      (
        mode: NavigationDisplayMode.automatic,
        title: l.preferencesNavigationAutomatic,
        description: l.preferencesNavigationAutomaticDescription,
      ),
      (
        mode: NavigationDisplayMode.iconsAndText,
        title: l.preferencesNavigationIconsAndText,
        description: l.preferencesNavigationIconsAndTextDescription,
      ),
      (
        mode: NavigationDisplayMode.iconsOnly,
        title: l.preferencesNavigationIconsOnly,
        description: l.preferencesNavigationIconsOnlyDescription,
      ),
    ];

    return Column(
      children: [
        for (final choice in choices)
          _PreferenceChoice(
            title: choice.title,
            description: choice.description,
            selected: provider.navigationDisplayMode == choice.mode,
            enabled: provider.isLoaded,
            onTap: () => provider.setNavigationDisplayMode(choice.mode),
          ),
      ],
    );
  }
}

class _PreferenceChoice extends StatelessWidget {
  const _PreferenceChoice({
    required this.title,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppearancePreference extends StatelessWidget {
  const _AppearancePreference();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final provider = context.watch<ThemeModeProvider>();
    return _CompactSegmentedControl<ThemeMode>(
      selected: provider.mode,
      options: [
        (value: ThemeMode.system, label: l.preferencesAutomatic),
        (value: ThemeMode.light, label: l.preferencesThemeLight),
        (value: ThemeMode.dark, label: l.preferencesThemeDark),
      ],
      onSelected: provider.isLoaded ? provider.setMode : null,
    );
  }
}

class _LanguagePreference extends StatelessWidget {
  const _LanguagePreference();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleProvider>();
    return _CompactSegmentedControl<String>(
      selected: provider.locale.languageCode,
      options: const [
        (value: 'es', label: 'Español'),
        (value: 'en', label: 'English'),
      ],
      onSelected: (languageCode) => provider.setLocale(Locale(languageCode)),
    );
  }
}

class _CompactSegmentedControl<T> extends StatelessWidget {
  const _CompactSegmentedControl({
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final T selected;
  final List<({T value, String label})> options;
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: [
        for (final option in options)
          ButtonSegment<T>(value: option.value, label: Text(option.label)),
      ],
      selected: {selected},
      onSelectionChanged: onSelected == null
          ? null
          : (selection) => onSelected!(selection.first),
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        ),
      ),
    );
  }
}
