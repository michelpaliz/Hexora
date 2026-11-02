import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/shared/widgets/client_search_select.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';

enum DocumentClientMode { existing, manual }

class DocumentManualClientConfig {
  const DocumentManualClientConfig({
    required this.nameController,
    required this.onChanged,
    this.addressController,
    this.cityController,
    this.postalCodeController,
    this.nameLabel = 'Nombre del cliente',
    this.addressLabel = 'Dirección',
    this.cityLabel = 'Ciudad',
    this.postalCodeLabel = 'CP',
    this.helperText,
    this.nameErrorText,
  });

  final TextEditingController nameController;
  final TextEditingController? addressController;
  final TextEditingController? cityController;
  final TextEditingController? postalCodeController;
  final VoidCallback onChanged;
  final String nameLabel;
  final String addressLabel;
  final String cityLabel;
  final String postalCodeLabel;
  final String? helperText;
  final String? nameErrorText;
}

/// Shared presentation for the client step used by document editors.
///
/// Selection state, validation, history loading, and persistence remain owned
/// by the document-specific editor.
class DocumentClientStep extends StatelessWidget {
  const DocumentClientStep({
    super.key,
    required this.clients,
    required this.selectedClientId,
    required this.onClientChanged,
    required this.mode,
    required this.onModeChanged,
    required this.selectedDetails,
    this.manual,
    this.enabled = true,
    this.allowManual = true,
    this.existingLabel = 'Cliente existente',
    this.manualLabel = 'Cliente manual',
    this.selectClientLabel = 'Selecciona cliente',
    this.emptySelectionLabel = 'Selecciona un cliente para continuar',
    this.twoColumnBreakpoint = 980,
    this.clientSearchController,
    this.flat = false,
    this.desktopListWidth,
    this.showSelectionHeading = true,
    this.modeSelectorAlignment = Alignment.center,
    this.adaptivePreview = false,
    this.compactSelectionMaxWidth = 620,
  });

  final List<GroupClient> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onClientChanged;
  final DocumentClientMode mode;
  final ValueChanged<DocumentClientMode> onModeChanged;
  final Widget? selectedDetails;
  final DocumentManualClientConfig? manual;
  final bool enabled;
  final bool allowManual;
  final String existingLabel;
  final String manualLabel;
  final String selectClientLabel;
  final String emptySelectionLabel;
  final double twoColumnBreakpoint;
  final TextEditingController? clientSearchController;
  final bool flat;
  final double? desktopListWidth;
  final bool showSelectionHeading;
  final AlignmentGeometry modeSelectorAlignment;
  final bool adaptivePreview;
  final double compactSelectionMaxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canUseManual = allowManual && manual != null;
        final manualMode = mode == DocumentClientMode.manual && canUseManual;
        final hasSelection = selectedClientId != null;
        final useCompactLayout =
            adaptivePreview && (manualMode || !hasSelection);
        final layoutWidth = useCompactLayout
            ? compactSelectionMaxWidth
                .clamp(0.0, constraints.maxWidth)
                .toDouble()
            : constraints.maxWidth;

        Widget existingContent() {
          final wide = constraints.maxWidth >= twoColumnBreakpoint;
          final listHeight =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 520.0;
          final list = _ExistingClientPanel(
            clients: clients,
            selectedClientId: selectedClientId,
            onClientChanged: onClientChanged,
            enabled: enabled,
            maxListHeight: listHeight,
            searchController: clientSearchController,
            flat: flat,
          );
          // Fade just the preview when the selection changes, so the list on
          // the left stays rock-steady during row changes.
          final detailsBody = _AnimatedClientDetails(
            selectionKey: selectedClientId ?? '__empty__',
            fadeDuration: HexoraMotion.duration(context, HexoraMotion.standard),
            child: _ClientDetailsPanel(
              hasSelection: selectedClientId != null,
              emptyLabel: emptySelectionLabel,
              flat: flat,
              child: selectedDetails,
            ),
          );

          if (wide) {
            final showPreview = !adaptivePreview || hasSelection;
            final requestedListWidth = showPreview ? desktopListWidth : null;
            final availableListWidth = showPreview
                ? (layoutWidth * .48).clamp(0.0, layoutWidth).toDouble()
                : layoutWidth;
            final resolvedListWidth = requestedListWidth == null
                ? availableListWidth
                : requestedListWidth.clamp(0.0, availableListWidth).toDouble();
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: resolvedListWidth, child: list),
                if (showPreview) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: VerticalDivider(
                      width: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: .45),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _PreviewEntrance(child: detailsBody),
                  ),
                ],
              ],
            );
          }

          // Mobile / narrow: the list takes the whole screen. Once a client
          // is picked, the preview folds in as a compact expandable section
          // below the list so it can be dismissed to see more rows.
          if (selectedClientId == null) return list;
          final availableHeight =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 700.0;
          final listSlot = (availableHeight * .62).clamp(280.0, 460.0);
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: listSlot, child: list),
                const SizedBox(height: 10),
                _CompactPreviewSection(
                  emptyLabel: emptySelectionLabel,
                  child: detailsBody,
                ),
              ],
            ),
          );
        }

        final title = manualMode ? manualLabel : selectClientLabel;

        return Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: layoutWidth,
            height:
                constraints.maxHeight.isFinite ? constraints.maxHeight : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ClientModeHeader(
                  title: title,
                  count: manualMode ? null : clients.length,
                  showHeading: showSelectionHeading,
                  selectorAlignment: modeSelectorAlignment,
                  selector: canUseManual
                      ? _ModeSelector(
                          mode: mode,
                          onChanged: onModeChanged,
                          enabled: enabled,
                          existingLabel: existingLabel,
                          manualLabel: manualLabel,
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: canUseManual
                      ? _ClientModeTransition(
                          mode: mode,
                          existing: existingContent(),
                          manual: _ManualClientPanel(
                            config: manual!,
                            enabled: enabled,
                            flat: flat,
                          ),
                        )
                      : existingContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewEntrance extends StatelessWidget {
  const _PreviewEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: HexoraMotion.duration(context, HexoraMotion.standard),
      curve: HexoraMotion.enter,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(10 * (1 - value), 0),
          child: child,
        ),
      ),
    );
  }
}

class _ClientModeHeader extends StatelessWidget {
  const _ClientModeHeader({
    required this.title,
    required this.count,
    required this.selector,
    required this.showHeading,
    required this.selectorAlignment,
  });

  final String title;
  final int? count;
  final Widget? selector;
  final bool showHeading;
  final AlignmentGeometry selectorAlignment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final heading = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
    final secondaryCount = count == null
        ? null
        : Text(
            '$count ${isSpanish ? 'clientes' : 'clients'}',
            key: const ValueKey('document-client-count'),
            style: textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
          );
    if (selector == null) {
      return showHeading ? heading : secondaryCount ?? const SizedBox.shrink();
    }
    if (!showHeading) {
      return Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 6,
        children: [
          Align(alignment: selectorAlignment, child: selector!),
          if (secondaryCount != null) secondaryCount,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading,
        const SizedBox(height: 7),
        Align(alignment: selectorAlignment, child: selector!),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.mode,
    required this.onChanged,
    required this.enabled,
    required this.existingLabel,
    required this.manualLabel,
  });

  final DocumentClientMode mode;
  final ValueChanged<DocumentClientMode> onChanged;
  final bool enabled;
  final String existingLabel;
  final String manualLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration = HexoraMotion.duration(context, HexoraMotion.standard);
    // Soft blue indicator — subtle in both themes, keeps text readable without
    // relying on primaryContainer's heavier tint.
    final indicatorColor = cs.primary.withValues(alpha: isDark ? .22 : .12);

    Widget option({
      required DocumentClientMode value,
      required IconData icon,
      required String label,
    }) {
      final selected = mode == value;
      final foreground = selected
          ? cs.primary
          : cs.onSurfaceVariant;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          enabled: enabled,
          child: InkWell(
            key: ValueKey('document-client-mode-${value.name}'),
            onTap: enabled ? () => onChanged(value) : null,
            borderRadius: BorderRadius.circular(8),
            // Subtle hover / focus / pressed washes — the indicator still
            // signals the selected segment, these only hint at interactivity.
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return cs.primary.withValues(alpha: isDark ? .14 : .09);
              }
              if (states.contains(WidgetState.hovered)) {
                return cs.primary.withValues(alpha: isDark ? .09 : .06);
              }
              if (states.contains(WidgetState.focused)) {
                return cs.primary.withValues(alpha: isDark ? .12 : .08);
              }
              return null;
            }),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: foreground),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: foreground,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320, minWidth: 240),
      child: SizedBox(
        key: const ValueKey('document-client-mode-selector'),
        width: 300,
        height: 36,
        child: Material(
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: cs.outlineVariant.withValues(alpha: .9),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              AnimatedAlign(
                duration: duration,
                curve: HexoraMotion.emphasized,
                alignment: mode == DocumentClientMode.existing
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: .5,
                  heightFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: DecoratedBox(
                      key: const ValueKey('document-client-mode-indicator'),
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  option(
                    value: DocumentClientMode.existing,
                    icon: Icons.group_outlined,
                    label: existingLabel,
                  ),
                  option(
                    value: DocumentClientMode.manual,
                    icon: Icons.edit_outlined,
                    label: manualLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps both client modes mounted so controllers, search state, focus and
/// scroll positions survive mode switches. Only the visible content moves.
class _ClientModeTransition extends StatelessWidget {
  const _ClientModeTransition({
    required this.mode,
    required this.existing,
    required this.manual,
  });

  final DocumentClientMode mode;
  final Widget existing;
  final Widget manual;

  @override
  Widget build(BuildContext context) {
    final duration = HexoraMotion.duration(context, HexoraMotion.standard);
    final existingActive = mode == DocumentClientMode.existing;

    Widget panel({
      required Key key,
      required Key opacityKey,
      required bool active,
      required Offset hiddenOffset,
      required Widget child,
    }) =>
        Positioned.fill(
          key: key,
          child: IgnorePointer(
            ignoring: !active,
            child: ExcludeSemantics(
              excluding: !active,
              child: AnimatedOpacity(
                key: opacityKey,
                duration: duration,
                curve: HexoraMotion.emphasized,
                opacity: active ? 1 : 0,
                child: AnimatedSlide(
                  duration: duration,
                  curve: HexoraMotion.emphasized,
                  offset: active ? Offset.zero : hiddenOffset,
                  child: TickerMode(
                    enabled: active,
                    child: Focus(
                      canRequestFocus: active,
                      descendantsAreFocusable: active,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    final existingPanel = panel(
      key: const ValueKey('existing-client-panel'),
      opacityKey: const ValueKey('existing-client-panel-opacity'),
      active: existingActive,
      hiddenOffset: const Offset(-.02, 0),
      child: existing,
    );
    final manualPanel = panel(
      key: const ValueKey('manual-client-panel'),
      opacityKey: const ValueKey('manual-client-panel-opacity'),
      active: !existingActive,
      hiddenOffset: const Offset(.02, 0),
      child: manual,
    );

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: existingActive
            ? [manualPanel, existingPanel]
            : [existingPanel, manualPanel],
      ),
    );
  }
}

/// Fades the client preview in when the selection changes, while leaving
/// the list to the left unaffected. Honours reduced-motion.
class _AnimatedClientDetails extends StatelessWidget {
  const _AnimatedClientDetails({
    required this.selectionKey,
    required this.fadeDuration,
    required this.child,
  });

  final String selectionKey;
  final Duration fadeDuration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: fadeDuration,
      switchInCurve: HexoraMotion.enter,
      switchOutCurve: HexoraMotion.exit,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.015, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: HexoraMotion.enter,
            reverseCurve: HexoraMotion.exit,
          )),
          transformHitTests: false,
          child: child,
        ),
      ),
      // Replace just when the selection changes, not on every rebuild.
      child: KeyedSubtree(key: ValueKey(selectionKey), child: child),
    );
  }
}

/// Compact expandable preview used on mobile. Keeps vertical space tight
/// but still allows seeing the full details on demand.
class _CompactPreviewSection extends StatelessWidget {
  const _CompactPreviewSection({
    required this.emptyLabel,
    required this.child,
  });

  final String emptyLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // ExpansionTile paints the divider by default; drop it to avoid a
        // doubled border above/below the preview body.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(
            Icons.person_outline_rounded,
            size: 18,
            color: cs.primary,
          ),
          title: Text(
            isSpanish ? 'Vista del cliente' : 'Client preview',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _ExistingClientPanel extends StatelessWidget {
  const _ExistingClientPanel({
    required this.clients,
    required this.selectedClientId,
    required this.onClientChanged,
    required this.enabled,
    required this.maxListHeight,
    this.searchController,
    required this.flat,
  });

  final List<GroupClient> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onClientChanged;
  final bool enabled;
  final double maxListHeight;
  final TextEditingController? searchController;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: IgnorePointer(
            ignoring: !enabled,
            child: Padding(
              padding: EdgeInsets.fromLTRB(flat ? 0 : 10, 0, flat ? 0 : 10, 10),
              // compact + compactToolbar give us ~50 px rows, the
              // `_CompactClientIdentity` title (name + one secondary line)
              // and a full-width search input flush with the list.
              child: ClientSearchSelect(
                clients: clients,
                selectedClientId: selectedClientId,
                onClientChanged: onClientChanged,
                useDefaultPropertyKind: false,
                showAdvancedFilters: false,
                compact: true,
                compactToolbar: true,
                flatRows: flat,
                searchDesktopHeight: 42,
                searchController: searchController,
                maxListHeight: maxListHeight,
              ),
            ),
          ),
        ),
      ],
    );
    if (flat) return content;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .38)),
      ),
      child: content,
    );
  }
}

class _ClientDetailsPanel extends StatelessWidget {
  const _ClientDetailsPanel({
    required this.hasSelection,
    required this.emptyLabel,
    required this.child,
    required this.flat,
  });

  final bool hasSelection;
  final String emptyLabel;
  final Widget? child;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = hasSelection && child != null
        ? Align(alignment: AlignmentDirectional.topStart, child: child)
        : Align(
            alignment: AlignmentDirectional.topStart,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Text(
                emptyLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ),
          );
    if (flat) return content;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: .45),
        ),
      ),
      child: content,
    );
  }
}

class _ManualClientPanel extends StatelessWidget {
  const _ManualClientPanel({
    required this.config,
    required this.enabled,
    required this.flat,
  });

  final DocumentManualClientConfig config;
  final bool enabled;
  final bool flat;

  InputDecoration _decoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      prefixIcon: Icon(icon, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      filled: true,
      fillColor: cs.surfaceContainer,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: .45),
        ),
      ),
    );
  }

  Widget _field(BuildContext context, TextEditingController controller,
          String label, IconData icon,
          {String? errorText}) =>
      TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(fontSize: 13),
        onChanged: (_) => config.onChanged(),
        decoration: _decoration(context, label, icon).copyWith(
          errorText: errorText,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final optional = <Widget>[
      if (config.addressController != null)
        _field(
          context,
          config.addressController!,
          config.addressLabel,
          Icons.location_on_outlined,
        ),
      if (config.cityController != null)
        _field(
          context,
          config.cityController!,
          config.cityLabel,
          Icons.location_city_outlined,
        ),
      if (config.postalCodeController != null)
        _field(
          context,
          config.postalCodeController!,
          config.postalCodeLabel,
          Icons.markunread_mailbox_outlined,
        ),
    ];
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          context,
          config.nameController,
          config.nameLabel,
          Icons.person_outline_rounded,
          errorText: config.nameErrorText,
        ),
        if (optional.isNotEmpty) ...[
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 700) {
              return Column(
                children: [
                  for (var i = 0; i < optional.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    optional[i],
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < optional.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: optional[i]),
                ],
              ],
            );
          }),
        ],
        if ((config.helperText ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            config.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
        ],
      ],
    );
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: flat
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: form,
                )
              : Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: .38),
                    ),
                  ),
                  child: form,
                ),
        ),
      ),
    );
  }
}
