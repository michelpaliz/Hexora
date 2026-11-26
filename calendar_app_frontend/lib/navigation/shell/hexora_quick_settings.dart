import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/navigation/shell/hexora_nav_components.dart';
import 'package:hexora/presentation/shared/widgets/hexora_segmented_control.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:hexora/theme/theme_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

enum _QuickAppearance { light, lightBlue, dark, system }

/// Compact shortcut to the existing personal preference providers.
///
/// This widget owns no preference state: every control reads and updates the
/// same providers used by the full Preferences screen.
class HexoraQuickSettingsButton extends StatefulWidget {
  const HexoraQuickSettingsButton({
    super.key,
    required this.headerPosition,
    required this.onOpenAllPreferences,
  });

  final GlobalHeaderPosition headerPosition;
  final VoidCallback onOpenAllPreferences;

  @override
  State<HexoraQuickSettingsButton> createState() =>
      _HexoraQuickSettingsButtonState();
}

class _HexoraQuickSettingsButtonState extends State<HexoraQuickSettingsButton> {
  final MenuController _controller = MenuController();
  bool _open = false;

  void _toggle() {
    _controller.isOpen ? _controller.close() : _controller.open();
  }

  void _openAllPreferences() {
    _controller.close();
    widget.onOpenAllPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    return MenuAnchor(
      controller: _controller,
      alignmentOffset: Offset(
        -296,
        widget.headerPosition == GlobalHeaderPosition.bottom ? -8 : 8,
      ),
      onOpen: () => setState(() => _open = true),
      onClose: () => setState(() => _open = false),
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: const WidgetStatePropertyAll(10),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      menuChildren: [
        _QuickSettingsPanel(onOpenAllPreferences: _openAllPreferences),
      ],
      builder: (context, controller, child) => HexoraNavIconButton(
        key: const ValueKey('quick-settings-button'),
        icon: LucideIcons.slidersHorizontal,
        tooltip: isEs ? 'Ajustes rápidos' : 'Quick settings',
        selected: _open,
        onPressed: _toggle,
      ),
    );
  }
}

class _QuickSettingsPanel extends StatelessWidget {
  const _QuickSettingsPanel({required this.onOpenAllPreferences});

  final VoidCallback onOpenAllPreferences;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final preferences = context.watch<UserPreferencesProvider>();
    final themeMode = context.watch<ThemeModeProvider>();
    final selectedAppearance = switch (themeMode.mode) {
      ThemeMode.light => themeMode.lightVariant == LightThemeVariant.blue
          ? _QuickAppearance.lightBlue
          : _QuickAppearance.light,
      ThemeMode.dark => _QuickAppearance.dark,
      ThemeMode.system => _QuickAppearance.system,
    };

    Future<void> selectAppearance(_QuickAppearance appearance) async {
      if (appearance == selectedAppearance) return;
      switch (appearance) {
        case _QuickAppearance.light:
          await themeMode.setLightVariant(LightThemeVariant.neutral);
          await themeMode.setMode(ThemeMode.light);
        case _QuickAppearance.lightBlue:
          await themeMode.setLightVariant(LightThemeVariant.blue);
          await themeMode.setMode(ThemeMode.light);
        case _QuickAppearance.dark:
          await themeMode.setMode(ThemeMode.dark);
        case _QuickAppearance.system:
          await themeMode.setMode(ThemeMode.system);
      }
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            MenuController.maybeOf(context)?.close(),
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            MenuController.maybeOf(context)?.close();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: FocusTraversalGroup(
          child: SizedBox(
            key: const ValueKey('quick-settings-panel'),
            width: 340,
            child: Material(
              color: cs.surface,
              surfaceTintColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.slidersHorizontal,
                          size: 18,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEs ? 'Ajustes rápidos' : 'Quick settings',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _label(context, isEs ? 'Menú de navegación' : 'Navigation'),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: HexoraSegmentedControl<NavigationLayout>(
                        expandSegments: true,
                        segments: [
                          HexoraSegment(
                            value: NavigationLayout.unified,
                            label: isEs ? 'Unificado' : 'Unified',
                            key: const ValueKey('quick-nav-layout-unified'),
                          ),
                          HexoraSegment(
                            value: NavigationLayout.split,
                            label: isEs ? 'Separado' : 'Split',
                            key: const ValueKey('quick-nav-layout-split'),
                          ),
                        ],
                        selected: preferences.navigationLayout,
                        onChanged: preferences.isLoaded
                            ? preferences.setNavigationLayout
                            : (_) {},
                      ),
                    ),
                    const SizedBox(height: 12),
                    _label(context, isEs ? 'Visualización' : 'Item display'),
                    const SizedBox(height: 6),
                    HexoraSegmentedControl<NavigationDisplayMode>(
                      expandSegments: true,
                      segments: [
                        HexoraSegment(
                          value: NavigationDisplayMode.automatic,
                          label: isEs ? 'Auto' : 'Auto',
                          key: const ValueKey('quick-nav-display-automatic'),
                        ),
                        HexoraSegment(
                          value: NavigationDisplayMode.iconsOnly,
                          label: isEs ? 'Iconos' : 'Icons',
                          key: const ValueKey('quick-nav-display-iconsOnly'),
                        ),
                        HexoraSegment(
                          value: NavigationDisplayMode.iconsAndText,
                          label: isEs ? 'Iconos y texto' : 'Icons & text',
                          key: const ValueKey('quick-nav-display-iconsAndText'),
                        ),
                      ],
                      selected: preferences.navigationDisplayMode,
                      onChanged: preferences.isLoaded
                          ? preferences.setNavigationDisplayMode
                          : (_) {},
                    ),
                    const SizedBox(height: 12),
                    _label(
                      context,
                      isEs ? 'Barra principal' : 'Main bar',
                    ),
                    const SizedBox(height: 6),
                    HexoraSegmentedControl<GlobalHeaderPosition>(
                      expandSegments: true,
                      segments: [
                        HexoraSegment(
                          value: GlobalHeaderPosition.top,
                          label: isEs ? 'Superior' : 'Top',
                          key: const ValueKey('quick-header-top'),
                        ),
                        HexoraSegment(
                          value: GlobalHeaderPosition.bottom,
                          label: isEs ? 'Inferior' : 'Bottom',
                          key: const ValueKey('quick-header-bottom'),
                        ),
                      ],
                      selected: preferences.globalHeaderPosition,
                      onChanged: preferences.isLoaded
                          ? preferences.setGlobalHeaderPosition
                          : (_) {},
                    ),
                    const SizedBox(height: 6),
                    _CompactSwitch(
                      key: const ValueKey('quick-main-bar-visible'),
                      label: isEs ? 'Mostrar barra principal' : 'Show main bar',
                      value: !preferences.topNavCollapsed,
                      onChanged: preferences.isLoaded
                          ? (visible) =>
                              preferences.setTopNavCollapsed(!visible)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Divider(height: 1, color: cs.outlineVariant),
                    const SizedBox(height: 10),
                    _label(context, isEs ? 'Apariencia' : 'Appearance'),
                    const SizedBox(height: 6),
                    _AppearanceGrid(
                      selected: selectedAppearance,
                      enabled: themeMode.isLoaded,
                      isEs: isEs,
                      onChanged: selectAppearance,
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: cs.outlineVariant),
                    TextButton(
                      key: const ValueKey('quick-settings-all-preferences'),
                      onPressed: onOpenAllPreferences,
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEs
                                  ? 'Todas las preferencias'
                                  : 'All preferences',
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 17),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String value) => Text(
        value,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      );
}

class _AppearanceGrid extends StatelessWidget {
  const _AppearanceGrid({
    required this.selected,
    required this.enabled,
    required this.isEs,
    required this.onChanged,
  });

  final _QuickAppearance selected;
  final bool enabled;
  final bool isEs;
  final ValueChanged<_QuickAppearance> onChanged;

  @override
  Widget build(BuildContext context) {
    HexoraSegment<_QuickAppearance> segment(
      _QuickAppearance value,
      String label,
      IconData icon,
      String key,
    ) =>
        HexoraSegment(
          value: value,
          label: label,
          icon: icon,
          key: ValueKey(key),
        );

    Widget row(List<HexoraSegment<_QuickAppearance>> segments) =>
        HexoraSegmentedControl<_QuickAppearance>(
          expandSegments: true,
          segments: segments,
          selected: selected,
          onChanged: enabled ? onChanged : (_) {},
        );

    return Column(
      children: [
        row([
          segment(
            _QuickAppearance.light,
            isEs ? 'Claro' : 'Light',
            LucideIcons.sun,
            'quick-theme-light',
          ),
          segment(
            _QuickAppearance.lightBlue,
            isEs ? 'Claro azul' : 'Blue light',
            LucideIcons.palette,
            'quick-theme-lightBlue',
          ),
        ]),
        const SizedBox(height: 4),
        row([
          segment(
            _QuickAppearance.dark,
            isEs ? 'Oscuro' : 'Dark',
            LucideIcons.moon,
            'quick-theme-dark',
          ),
          segment(
            _QuickAppearance.system,
            isEs ? 'Sistema' : 'System',
            LucideIcons.monitor,
            'quick-theme-system',
          ),
        ]),
      ],
    );
  }
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child:
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      );
}
