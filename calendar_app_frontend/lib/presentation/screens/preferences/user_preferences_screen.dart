import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:hexora/theme/theme_provider.dart';
import 'package:provider/provider.dart';

void _showPreferenceSuccess(BuildContext context) {
  final isEs = Localizations.localeOf(context).languageCode == 'es';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(isEs ? 'Configuración guardada.' : 'Settings saved.'),
      ),
    );
}

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
    this.scrollable = true,
    this.showLanguage = true,
  });

  /// Maximum content width; callers align it with the surrounding layout.
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  /// Horizontal/vertical anchor of the capped content. The standalone route
  /// centers it; the Settings shell pins it to the left to follow the sidebar.
  final AlignmentGeometry alignment;

  /// Settings hosts this view inside its own scroll area. Avoid nesting a
  /// second scroll view there while preserving the standalone route behavior.
  final bool scrollable;

  /// System settings owns the language control when embedded, so it can keep
  /// the related account preferences together in one compact card.
  final bool showLanguage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreferencesGroup(
          icon: Icons.navigation_outlined,
          label: l.preferencesNavigation,
          child: const _NavigationPreference(),
        ),
        const SizedBox(height: 12),
        _PreferencesGroup(
          icon: Icons.palette_outlined,
          label: l.preferencesAppearance,
          child: const _AppearancePreference(),
        ),
        if (showLanguage) ...[
          const SizedBox(height: 12),
          _PreferencesGroup(
            icon: Icons.language_rounded,
            label: l.preferencesLanguage,
            child: const _LanguagePreference(),
          ),
        ],
      ],
    );

    final constrained = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: content,
    );
    if (!scrollable) return constrained;

    return Align(
      alignment: alignment,
      child: SingleChildScrollView(
        padding: padding,
        child: constrained,
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

class _PreferencesGroup extends StatelessWidget {
  const _PreferencesGroup({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(icon: icon, label: label),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _NavigationPreference extends StatelessWidget {
  const _NavigationPreference();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final provider = context.watch<UserPreferencesProvider>();
    final isEs = Localizations.localeOf(context).languageCode == 'es';
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEs ? 'Diseño de navegación' : 'Navigation layout',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          isEs
              ? 'Personaliza cómo se organizan los menús de tu espacio de trabajo.'
              : 'Choose how your workspace menus are organized.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _NavigationLayoutCard(
                layout: NavigationLayout.split,
                title: isEs ? 'Menús separados' : 'Split menus',
                description: isEs
                    ? 'Menú principal y submenú independientes.'
                    : 'Independent primary menu and submenu.',
                selected: provider.navigationLayout == NavigationLayout.split,
                enabled: provider.isLoaded,
                onTap: () => _setLayout(
                  context,
                  provider,
                  NavigationLayout.split,
                ),
              ),
              _NavigationLayoutCard(
                layout: NavigationLayout.unified,
                title: isEs ? 'Menú unificado' : 'Unified menu',
                description: isEs
                    ? 'El módulo activo y su menú en una sola barra.'
                    : 'The active module and its menu in one sidebar.',
                selected: provider.navigationLayout == NavigationLayout.unified,
                enabled: provider.isLoaded,
                onTap: () => _setLayout(
                  context,
                  provider,
                  NavigationLayout.unified,
                ),
              ),
            ];
            if (constraints.maxWidth < 520) {
              return Column(
                children: [
                  cards.first,
                  const SizedBox(height: 8),
                  cards.last,
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards.first),
                  const SizedBox(width: 10),
                  Expanded(child: cards.last),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Divider(color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 4),
        Text(
          isEs ? 'Visualización de elementos' : 'Item display',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        for (final choice in choices)
          _PreferenceChoice(
            title: choice.title,
            description: choice.description,
            selected: provider.navigationDisplayMode == choice.mode,
            enabled: provider.isLoaded,
            onTap: () async {
              if (provider.navigationDisplayMode == choice.mode) return;
              await provider.setNavigationDisplayMode(choice.mode);
              if (context.mounted) _showPreferenceSuccess(context);
            },
          ),
      ],
    );
  }

  Future<void> _setLayout(
    BuildContext context,
    UserPreferencesProvider provider,
    NavigationLayout layout,
  ) async {
    if (provider.navigationLayout == layout) return;
    // Switching layout can reparent the Settings workspace immediately. Keep
    // stable references before notifying listeners so no ancestor lookup is
    // attempted through a deactivated BuildContext afterward.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    await provider.setNavigationLayout(layout);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(isEs ? 'Configuración guardada.' : 'Settings saved.'),
        ),
      );
  }
}

class _NavigationLayoutCard extends StatelessWidget {
  const _NavigationLayoutCard({
    required this.layout,
    required this.title,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final NavigationLayout layout;
  final String title;
  final String description;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    cs.primary.withValues(alpha: .10),
                    cs.surface,
                  )
                : cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NavigationLayoutPreview(layout: layout),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.25,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationLayoutPreview extends StatelessWidget {
  const _NavigationLayoutPreview({required this.layout});

  final NavigationLayout layout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget rail(double width, {bool nested = false}) => Container(
          width: width,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              cs.primary.withValues(alpha: nested ? .08 : .05),
              cs.surface,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  height: i == 1 ? 6 : 5,
                  margin: EdgeInsets.only(
                    left: nested && i > 0 ? 8 : 0,
                    bottom: i == 3 ? 0 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: i == 1
                        ? cs.primary.withValues(alpha: .28)
                        : cs.onSurfaceVariant.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        );

    return Container(
      height: 58,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (layout == NavigationLayout.split) ...[
            rail(38),
            const SizedBox(width: 4),
            rail(48, nested: true),
          ] else
            rail(72, nested: true),
          const SizedBox(width: 5),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: .55),
                ),
              ),
            ),
          ),
        ],
      ),
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

enum _AppearanceChoice { automatic, light, lightBlue, dark }

class _AppearancePreference extends StatelessWidget {
  const _AppearancePreference();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final provider = context.watch<ThemeModeProvider>();
    final selected = switch (provider.mode) {
      ThemeMode.system => _AppearanceChoice.automatic,
      ThemeMode.dark => _AppearanceChoice.dark,
      ThemeMode.light => provider.lightVariant == LightThemeVariant.blue
          ? _AppearanceChoice.lightBlue
          : _AppearanceChoice.light,
    };
    return _CompactSegmentedControl<_AppearanceChoice>(
      selected: selected,
      options: [
        (value: _AppearanceChoice.automatic, label: l.preferencesAutomatic),
        (value: _AppearanceChoice.light, label: l.preferencesThemeLight),
        (
          value: _AppearanceChoice.lightBlue,
          label: Localizations.localeOf(context).languageCode == 'es'
              ? 'Claro azul'
              : 'Blue light',
        ),
        (value: _AppearanceChoice.dark, label: l.preferencesThemeDark),
      ],
      onSelected: provider.isLoaded
          ? (choice) async {
              if (selected == choice) return;
              switch (choice) {
                case _AppearanceChoice.automatic:
                  await provider.setMode(ThemeMode.system);
                case _AppearanceChoice.light:
                  await provider.setLightVariant(LightThemeVariant.neutral);
                  await provider.setMode(ThemeMode.light);
                case _AppearanceChoice.lightBlue:
                  await provider.setLightVariant(LightThemeVariant.blue);
                  await provider.setMode(ThemeMode.light);
                case _AppearanceChoice.dark:
                  await provider.setMode(ThemeMode.dark);
              }
              if (context.mounted) _showPreferenceSuccess(context);
            }
          : null,
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
      onSelected: (languageCode) {
        if (provider.locale.languageCode == languageCode) return;
        provider.setLocale(Locale(languageCode));
        if (context.mounted) _showPreferenceSuccess(context);
      },
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
