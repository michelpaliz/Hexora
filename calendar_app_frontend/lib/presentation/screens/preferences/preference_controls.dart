import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/presentation/shared/widgets/hexora_segmented_control.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/theme/theme_provider.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';

/// Preference controls shared by the standalone preferences screen and the
/// Settings dashboard. Each one adapts to the width it is given (never to the
/// browser width) and draws no outer container.

void _showSaved(ScaffoldMessengerState? messenger, {required bool isEs}) {
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(isEs ? 'Configuración guardada.' : 'Settings saved.'),
      ),
    );
}

bool _isEs(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'es';

/// Width available for laying controls out, discounting enlarged text.
double preferenceLayoutWidth(BuildContext context, double width) =>
    width / math.max(1, MediaQuery.textScalerOf(context).scale(14) / 14);

/// Selectable surface: white by default, light blue with a blue border when
/// selected. The border is painted on top so selecting never moves content.
class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(10);
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: AnimatedContainer(
        duration: HexoraMotion.duration(context, HexoraMotion.navigation),
        curve: HexoraMotion.enter,
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(
                  cs.primary.withValues(alpha: .10),
                  cs.surface,
                )
              : cs.surface,
          borderRadius: radius,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            hoverColor: cs.primary.withValues(alpha: .04),
            child: Padding(padding: const EdgeInsets.all(8), child: child),
          ),
        ),
      ),
    );
  }
}

class _RadioIcon extends StatelessWidget {
  const _RadioIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Icon(
      selected
          ? Icons.radio_button_checked_rounded
          : Icons.radio_button_unchecked_rounded,
      size: 18,
      color: selected ? cs.primary : cs.onSurfaceVariant,
    );
  }
}

// ── Navigation ───────────────────────────────────────────────────────────────

class NavigationPreference extends StatelessWidget {
  const NavigationPreference({super.key});

  /// Below this width the two layout cards stack.
  static const double horizontalCardsMinWidth = 400;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final provider = context.watch<UserPreferencesProvider>();
    final isEs = _isEs(context);
    final subheading = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );
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

    Widget layoutCard(
      NavigationLayout layout,
      String title,
      String description, {
      required bool stacked,
    }) =>
        _NavigationLayoutCard(
          key: ValueKey('navigation-layout-${layout.name}'),
          layout: layout,
          title: title,
          description: description,
          stacked: stacked,
          selected: provider.navigationLayout == layout,
          onTap: provider.isLoaded
              ? () => _setLayout(context, provider, layout)
              : null,
        );

    Widget headerPositionCard(
      GlobalHeaderPosition position,
      String title,
      String description, {
      required bool stacked,
    }) =>
        _HeaderPositionCard(
          key: ValueKey('global-header-position-${position.name}'),
          position: position,
          title: title,
          description: description,
          stacked: stacked,
          selected: provider.globalHeaderPosition == position,
          onTap: provider.isLoaded
              ? () => _setHeaderPosition(context, provider, position)
              : null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(isEs ? 'Diseño de navegación' : 'Navigation layout',
            style: subheading),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                preferenceLayoutWidth(context, constraints.maxWidth) <
                    horizontalCardsMinWidth;
            final split = layoutCard(
              NavigationLayout.split,
              isEs ? 'Menús separados' : 'Split menus',
              isEs
                  ? 'Menú principal y submenú independientes.'
                  : 'Independent primary menu and submenu.',
              stacked: stacked,
            );
            final unified = layoutCard(
              NavigationLayout.unified,
              isEs ? 'Menú unificado' : 'Unified menu',
              isEs
                  ? 'El módulo activo y su menú en una sola barra.'
                  : 'The active module and its menu in one sidebar.',
              stacked: stacked,
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [split, const SizedBox(height: 8), unified],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: split),
                  const SizedBox(width: 10),
                  Expanded(child: unified),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .6)),
        const SizedBox(height: 12),
        Text(
          isEs ? 'Posición de la barra principal' : 'Main bar position',
          style: subheading,
        ),
        const SizedBox(height: 3),
        Text(
          isEs
              ? 'Elige dónde mostrar los controles generales de Hexora.'
              : 'Choose where Hexora displays its global controls.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                preferenceLayoutWidth(context, constraints.maxWidth) <
                    horizontalCardsMinWidth;
            final top = headerPositionCard(
              GlobalHeaderPosition.top,
              isEs ? 'Superior' : 'Top',
              isEs ? 'Diseño tradicional.' : 'Traditional layout.',
              stacked: stacked,
            );
            final bottom = headerPositionCard(
              GlobalHeaderPosition.bottom,
              isEs ? 'Inferior' : 'Bottom',
              isEs
                  ? 'Estilo aplicación de escritorio.'
                  : 'Desktop application style.',
              stacked: stacked,
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [top, const SizedBox(height: 8), bottom],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: top),
                  const SizedBox(width: 10),
                  Expanded(child: bottom),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 5),
        Text(
          isEs
              ? 'La posición de las pestañas y los menús laterales no cambiará.'
              : 'Workspace tabs and side menus stay in their current position.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .6)),
        const SizedBox(height: 12),
        Text(isEs ? 'Visualización de elementos' : 'Item display',
            style: subheading),
        const SizedBox(height: 2),
        for (final choice in choices)
          _PreferenceChoice(
            key: ValueKey('navigation-display-${choice.mode.name}'),
            title: choice.title,
            description: choice.description,
            selected: provider.navigationDisplayMode == choice.mode,
            onTap: provider.isLoaded
                ? () async {
                    if (provider.navigationDisplayMode == choice.mode) return;
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    await provider.setNavigationDisplayMode(choice.mode);
                    _showSaved(messenger, isEs: isEs);
                  }
                : null,
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
    final isEs = _isEs(context);
    await provider.setNavigationLayout(layout);
    _showSaved(messenger, isEs: isEs);
  }

  Future<void> _setHeaderPosition(
    BuildContext context,
    UserPreferencesProvider provider,
    GlobalHeaderPosition position,
  ) async {
    if (provider.globalHeaderPosition == position) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final isEs = _isEs(context);
    await provider.setGlobalHeaderPosition(position);
    _showSaved(messenger, isEs: isEs);
  }
}

class _NavigationLayoutCard extends StatelessWidget {
  const _NavigationLayoutCard({
    super.key,
    required this.layout,
    required this.title,
    required this.description,
    required this.stacked,
    required this.selected,
    required this.onTap,
  });

  final NavigationLayout layout;
  final String title;
  final String description;

  /// Stacked cards span the column, so the preview moves beside the text to
  /// keep them short.
  final bool stacked;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleText = Text(
      title,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    final descriptionText = Text(
      description,
      style: theme.textTheme.bodySmall?.copyWith(
        color: cs.onSurfaceVariant,
        height: 1.25,
      ),
    );
    final radio = _RadioIcon(selected: selected);

    return _SelectableCard(
      selected: selected,
      onTap: onTap,
      child: stacked
          ? Row(
              children: [
                SizedBox(
                  width: 104,
                  child: _NavigationLayoutPreview(layout: layout),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleText,
                      const SizedBox(height: 2),
                      descriptionText,
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                radio,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NavigationLayoutPreview(layout: layout),
                const SizedBox(height: 8),
                Row(children: [Expanded(child: titleText), radio]),
                const SizedBox(height: 2),
                descriptionText,
              ],
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
    Widget rail(int flex, {bool nested = false}) => Expanded(
          flex: flex,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                cs.primary.withValues(alpha: nested ? .08 : .05),
                cs.surface,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 4; i++)
                  Container(
                    height: 5,
                    margin: EdgeInsets.only(left: nested && i > 0 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i == 1
                          ? cs.primary.withValues(alpha: .28)
                          : cs.onSurfaceVariant.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
        );

    return ExcludeSemantics(
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (layout == NavigationLayout.split) ...[
              rail(20),
              const SizedBox(width: 3),
              rail(26, nested: true),
            ] else
              rail(38, nested: true),
            const SizedBox(width: 4),
            Expanded(
              flex: 50,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: .55),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPositionCard extends StatelessWidget {
  const _HeaderPositionCard({
    super.key,
    required this.position,
    required this.title,
    required this.description,
    required this.stacked,
    required this.selected,
    required this.onTap,
  });

  final GlobalHeaderPosition position;
  final String title;
  final String description;
  final bool stacked;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleText = Text(
      title,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    final descriptionText = Text(
      description,
      style: theme.textTheme.bodySmall?.copyWith(
        color: cs.onSurfaceVariant,
        height: 1.25,
      ),
    );
    final radio = _RadioIcon(selected: selected);

    return _SelectableCard(
      selected: selected,
      onTap: onTap,
      child: stacked
          ? Row(
              children: [
                SizedBox(
                  width: 104,
                  child: _HeaderPositionPreview(position: position),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleText,
                      const SizedBox(height: 2),
                      descriptionText,
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                radio,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderPositionPreview(position: position),
                const SizedBox(height: 8),
                Row(children: [Expanded(child: titleText), radio]),
                const SizedBox(height: 2),
                descriptionText,
              ],
            ),
    );
  }
}

class _HeaderPositionPreview extends StatelessWidget {
  const _HeaderPositionPreview({required this.position});

  final GlobalHeaderPosition position;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final header = Container(
      height: 8,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(3),
      ),
    );
    final workspace = Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 17,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: .55),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return ExcludeSemantics(
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: position == GlobalHeaderPosition.top
              ? [header, const SizedBox(height: 3), workspace]
              : [workspace, const SizedBox(height: 3), header],
        ),
      ),
    );
  }
}

class _PreferenceChoice extends StatelessWidget {
  const _PreferenceChoice({
    super.key,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: cs.primary.withValues(alpha: .045),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Row(
                children: [
                  _RadioIcon(selected: selected),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Appearance ───────────────────────────────────────────────────────────────

enum _AppearanceChoice { automatic, light, lightBlue, dark }

class AppearancePreference extends StatelessWidget {
  const AppearancePreference({super.key});

  /// From this width the four themes share one row; below it they form 2 × 2.
  static const double singleRowMinWidth = 520;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final provider = context.watch<ThemeModeProvider>();
    final isEs = _isEs(context);
    final selected = switch (provider.mode) {
      ThemeMode.system => _AppearanceChoice.automatic,
      ThemeMode.dark => _AppearanceChoice.dark,
      ThemeMode.light => provider.lightVariant == LightThemeVariant.blue
          ? _AppearanceChoice.lightBlue
          : _AppearanceChoice.light,
    };
    final labels = {
      _AppearanceChoice.automatic: l.preferencesAutomatic,
      _AppearanceChoice.light: l.preferencesThemeLight,
      _AppearanceChoice.lightBlue: isEs ? 'Claro azul' : 'Blue light',
      _AppearanceChoice.dark: l.preferencesThemeDark,
    };

    Future<void> select(_AppearanceChoice choice) async {
      if (selected == choice) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
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
      _showSaved(messenger, isEs: isEs);
    }

    Widget tile(_AppearanceChoice choice) => Expanded(
          child: _SelectableCard(
            key: ValueKey('appearance-${choice.name}'),
            selected: selected == choice,
            onTap: provider.isLoaded ? () => select(choice) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ThemePreview(
                  choice: choice,
                  lightVariant: provider.lightVariant,
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        labels[choice]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    _RadioIcon(selected: selected == choice),
                  ],
                ),
              ],
            ),
          ),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = preferenceLayoutWidth(context, constraints.maxWidth) >=
                singleRowMinWidth
            ? 4
            : 2;
        const values = _AppearanceChoice.values;
        return Column(
          children: [
            for (var start = 0; start < values.length; start += perRow) ...[
              if (start > 0) const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = start; i < start + perRow; i++) ...[
                    if (i > start) const SizedBox(width: 8),
                    tile(values[i]),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Miniature workspace painted with each theme's real colours. Automatic shows
/// the light theme it would use next to the dark one.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.choice, required this.lightVariant});

  final _AppearanceChoice choice;
  final LightThemeVariant lightVariant;

  @override
  Widget build(BuildContext context) {
    final light = _ThemeSwatch(
      scheme: AppTheme.light.colorScheme,
      canvas: AppColors.workspaceCanvas,
      navigation: AppTheme.light.colorScheme.surface,
    );
    final blue = _ThemeSwatch(
      scheme: AppTheme.blueLight.colorScheme,
      canvas: AppColors.workspaceCanvas,
      navigation: AppColors.dashboardTopBar,
    );
    final dark = _ThemeSwatch(
      scheme: AppTheme.dark.colorScheme,
      canvas: AppTheme.dark.scaffoldBackgroundColor,
      navigation: AppDarkColors.sidebar,
    );
    final Widget content = switch (choice) {
      _AppearanceChoice.light => light,
      _AppearanceChoice.lightBlue => blue,
      _AppearanceChoice.dark => dark,
      _AppearanceChoice.automatic => Row(
          children: [
            Expanded(
                child: lightVariant == LightThemeVariant.blue ? blue : light),
            Expanded(child: dark),
          ],
        ),
    };
    return ExcludeSemantics(
      child: Container(
        height: 46,
        clipBehavior: Clip.antiAlias,
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(7)),
        child: content,
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.scheme,
    required this.canvas,
    required this.navigation,
  });

  final ColorScheme scheme;
  final Color canvas;
  final Color navigation;

  @override
  Widget build(BuildContext context) {
    Widget bar(Color color, double widthFactor) => FractionallySizedBox(
          widthFactor: widthFactor,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
    return ColoredBox(
      color: canvas,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 1, child: ColoredBox(color: navigation)),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    bar(scheme.primary, .55),
                    const SizedBox(height: 4),
                    bar(scheme.onSurface.withValues(alpha: .3), .9),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language ─────────────────────────────────────────────────────────────────

class LanguagePreference extends StatelessWidget {
  const LanguagePreference({
    super.key,
    this.shortLabels = false,
    this.onCanvas = false,
  });

  /// Uses ES / EN instead of the full language names.
  final bool shortLabels;

  /// Placed directly on the canvas: a surface track keeps it visible.
  final bool onCanvas;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocaleProvider>();
    return HexoraSegmentedControl<String>(
      backgroundColor: onCanvas ? Theme.of(context).colorScheme.surface : null,
      selected: provider.locale.languageCode,
      segments: [
        HexoraSegment(
          key: const ValueKey('language-es'),
          value: 'es',
          label: shortLabels ? 'ES' : 'Español',
        ),
        HexoraSegment(
          key: const ValueKey('language-en'),
          value: 'en',
          label: shortLabels ? 'EN' : 'English',
        ),
      ],
      onChanged: (languageCode) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        provider.setLocale(Locale(languageCode));
        _showSaved(messenger, isEs: languageCode == 'es');
      },
    );
  }
}
