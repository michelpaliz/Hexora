import 'package:flutter/material.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/presentation/shared/widgets/secondary_sidebar_header.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:provider/provider.dart';

/// Whether a nested document workflow should avoid adding another expanded
/// navigation column beside the user's workspace menu.
bool documentWizardUsesCompactNavigation(BuildContext context) {
  UserPreferencesProvider? preferences;
  try {
    preferences = context.watch<UserPreferencesProvider>();
  } on ProviderNotFoundException {
    // Standalone routes and focused widget tests may not provide workspace
    // preferences.
  }
  return preferences?.navigationLayout == NavigationLayout.unified ||
      preferences?.navigationDisplayMode == NavigationDisplayMode.iconsOnly;
}

class DocumentWizardSection {
  const DocumentWizardSection({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class DocumentWizardStep {
  const DocumentWizardStep({
    required this.label,
    required this.icon,
    this.sections = const [],
  });

  final String label;
  final IconData icon;
  final List<DocumentWizardSection> sections;
}

class DocumentWizardRail extends StatelessWidget {
  const DocumentWizardRail({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.selectedSectionId,
    required this.groupExpanded,
    required this.collapsed,
    required this.onStepSelected,
    required this.onSectionSelected,
    required this.onToggleGroup,
    required this.onToggleCollapsed,
    this.keyPrefix = 'document-wizard',
    this.useInvoiceLegacyKeys = false,
    this.expandedWidth = 176,
    this.header,
    this.footer,
    this.allowCollapse = true,
    this.title,
    this.backgroundColor,
    this.afterStepBuilder,
  });

  final List<DocumentWizardStep> steps;
  final int currentStep;
  final String? selectedSectionId;
  final bool groupExpanded;
  final bool collapsed;
  final ValueChanged<int> onStepSelected;
  final ValueChanged<String> onSectionSelected;
  final VoidCallback onToggleGroup;
  final VoidCallback onToggleCollapsed;
  final String keyPrefix;
  final bool useInvoiceLegacyKeys;
  final double expandedWidth;
  final Widget? header;
  final Widget? footer;
  final bool allowCollapse;
  final String? title;
  final Color? backgroundColor;
  final Widget? Function(int index)? afterStepBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final preferenceForcesCompact =
        documentWizardUsesCompactNavigation(context);
    final effectiveCollapsed = collapsed || preferenceForcesCompact;
    var railTitle = title ?? steps[currentStep].label;
    if (title == null) {
      for (final section in steps[currentStep].sections) {
        if (section.id == selectedSectionId) {
          railTitle = section.label;
          break;
        }
      }
    }

    Widget mainStep(int index) {
      final step = steps[index];
      final active = currentStep == index;
      final complete = index < currentStep;
      final future = index > currentStep;
      final color =
          active || complete ? colors.primary : colors.onSurfaceVariant;
      final row = Semantics(
        button: true,
        selected: active,
        label: '${index + 1}. ${step.label}',
        child: InkWell(
          key: Key(useInvoiceLegacyKeys
              ? 'invoice-flow-step-$index'
              : '$keyPrefix-step-$index'),
          onTap: () => onStepSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 36,
            padding: EdgeInsets.only(
              left: effectiveCollapsed ? 13 : 10,
              right: effectiveCollapsed ? 13 : 4,
            ),
            decoration: BoxDecoration(
              color: active ? colors.primary.withValues(alpha: .09) : null,
              border: Border(
                left: BorderSide(
                  width: 2,
                  color: active ? colors.primary : Colors.transparent,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  complete ? Icons.check_rounded : step.icon,
                  size: 16,
                  color: future ? color.withValues(alpha: .52) : color,
                ),
                if (!effectiveCollapsed) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: future ? color.withValues(alpha: .62) : color,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (step.sections.isNotEmpty)
                    IconButton(
                      tooltip: groupExpanded
                          ? (isEs ? 'Contraer secciones' : 'Collapse sections')
                          : (isEs ? 'Mostrar secciones' : 'Show sections'),
                      onPressed: onToggleGroup,
                      icon: Icon(
                        groupExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: HexoraIconTokens.standard,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );

      if (!effectiveCollapsed || step.sections.isEmpty) return row;
      return MenuAnchor(
        alignmentOffset: const Offset(48, -36),
        menuChildren: [
          for (final section in step.sections)
            MenuItemButton(
              key: Key(useInvoiceLegacyKeys
                  ? 'invoice-collapsed-line-mode-${section.id}'
                  : '$keyPrefix-collapsed-section-${section.id}'),
              onPressed: () => onSectionSelected(section.id),
              child: SizedBox(
                width: 132,
                child: Row(
                  children: [
                    Icon(section.icon, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(section.label)),
                    if (section.id == selectedSectionId)
                      Icon(Icons.check_rounded,
                          size: 16, color: colors.primary),
                  ],
                ),
              ),
            ),
        ],
        builder: (context, controller, child) => Tooltip(
          message: useInvoiceLegacyKeys
              ? 'M\u00e9todo de l\u00edneas'
              : (isEs ? 'Mostrar secciones' : 'Show sections'),
          child: InkWell(
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            child: AbsorbPointer(child: row),
          ),
        ),
      );
    }

    List<Widget> extrasAfterStep(int index) {
      if (effectiveCollapsed) return const <Widget>[];
      final extra = afterStepBuilder?.call(index);
      return extra == null ? const <Widget>[] : <Widget>[extra];
    }

    return AnimatedContainer(
      key:
          Key(useInvoiceLegacyKeys ? 'invoice-wizard-rail' : '$keyPrefix-rail'),
      duration: const Duration(milliseconds: 180),
      width: effectiveCollapsed ? 52 : expandedWidth,
      color: backgroundColor ?? colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (allowCollapse && effectiveCollapsed && !preferenceForcesCompact)
            Align(
              alignment: Alignment.center,
              child: IconButton(
                key: Key(useInvoiceLegacyKeys
                    ? 'invoice-wizard-rail-toggle'
                    : '$keyPrefix-rail-toggle'),
                tooltip: effectiveCollapsed
                    ? (isEs ? 'Expandir navegación' : 'Expand navigation')
                    : (isEs ? 'Contraer navegación' : 'Collapse navigation'),
                onPressed: onToggleCollapsed,
                icon: Icon(
                  effectiveCollapsed
                      ? Icons.keyboard_double_arrow_right_rounded
                      : Icons.keyboard_double_arrow_left_rounded,
                  size: HexoraIconTokens.standard,
                ),
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 32,
                ),
              ),
            ),
          if (allowCollapse && !effectiveCollapsed)
            SecondarySidebarHeader(
              title: railTitle,
              onCollapse: onToggleCollapsed,
              toggleKey: Key(useInvoiceLegacyKeys
                  ? 'invoice-wizard-rail-toggle'
                  : '$keyPrefix-rail-toggle'),
            ),
          if (!effectiveCollapsed && header != null) header!,
          for (var index = 0; index < steps.length; index++) ...[
            mainStep(index),
            ...extrasAfterStep(index),
            if (!effectiveCollapsed &&
                currentStep == index &&
                groupExpanded &&
                steps[index].sections.isNotEmpty)
              for (final section in steps[index].sections)
                Semantics(
                  button: true,
                  selected: section.id == selectedSectionId,
                  child: InkWell(
                    key: Key(useInvoiceLegacyKeys
                        ? 'invoice-line-mode-${section.id}'
                        : '$keyPrefix-section-${section.id}'),
                    onTap: () => onSectionSelected(section.id),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.only(left: 36, right: 10),
                      decoration: BoxDecoration(
                        color: section.id == selectedSectionId
                            ? colors.primary.withValues(alpha: .07)
                            : colors.surfaceContainerHighest
                                .withValues(alpha: .22),
                        border: Border(
                          left: BorderSide(
                            width: 2,
                            color: section.id == selectedSectionId
                                ? colors.primary
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            section.icon,
                            size: 14,
                            color: section.id == selectedSectionId
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              section.label,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 10.5,
                                color: section.id == selectedSectionId
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                                fontWeight: section.id == selectedSectionId
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
          if (!effectiveCollapsed && footer != null)
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: footer!,
              ),
            ),
        ],
      ),
    );
  }
}

class DocumentWizardMobileSelector extends StatelessWidget {
  const DocumentWizardMobileSelector({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.selectedSectionId,
    required this.onStepSelected,
    required this.onSectionSelected,
    this.keyPrefix = 'document-wizard',
    this.useInvoiceLegacyKeys = false,
    this.canSelectStep,
  });

  final List<DocumentWizardStep> steps;
  final int currentStep;
  final String? selectedSectionId;
  final ValueChanged<int> onStepSelected;
  final ValueChanged<String> onSectionSelected;
  final String keyPrefix;
  final bool useInvoiceLegacyKeys;
  final bool Function(int)? canSelectStep;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final current = steps[currentStep];
    DocumentWizardSection? selectedSection;
    for (final section in current.sections) {
      if (section.id == selectedSectionId) {
        selectedSection = section;
        break;
      }
    }
    final label = selectedSection == null
        ? current.label
        : '${current.label} · ${selectedSection.label}';
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    return PopupMenuButton<String>(
      key: Key(useInvoiceLegacyKeys
          ? 'invoice-wizard-mobile-selector'
          : '$keyPrefix-mobile-selector'),
      tooltip: isEs ? 'Cambiar paso' : 'Change step',
      onSelected: (value) {
        if (value.startsWith('step:')) {
          onStepSelected(int.parse(value.substring(5)));
        } else if (value.startsWith('section:')) {
          onSectionSelected(value.substring(8));
        }
      },
      itemBuilder: (context) => [
        for (var index = 0; index < steps.length; index++) ...[
          PopupMenuItem(
              value: 'step:$index',
              enabled: canSelectStep?.call(index) ?? true,
              child: Text(steps[index].label)),
          for (final section in steps[index].sections)
            PopupMenuItem(
              value: 'section:${section.id}',
              enabled: canSelectStep?.call(index) ?? true,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Row(
                  children: [
                    Expanded(child: Text(section.label)),
                    if (currentStep == index && selectedSectionId == section.id)
                      Icon(Icons.check_rounded,
                          size: 16, color: colors.primary),
                  ],
                ),
              ),
            ),
        ],
      ],
      child: Container(
        height: 38,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(Icons.list_alt_rounded, size: 16, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
