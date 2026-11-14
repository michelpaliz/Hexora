import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.showClientCount = true,
    this.searchDriven = false,
    this.searchDrivenDetails,
    this.modeSelectorTrailing,
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
  final bool showClientCount;
  final bool searchDriven;
  final Widget? searchDrivenDetails;

  /// Optional controls aligned to the right of the mode selector, so a
  /// document-type toggle (e.g. Factura / Recibo) and the client-source toggle
  /// (Existente / Manual) share one compact toolbar row instead of stacking.
  final Widget? modeSelectorTrailing;

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
            showVisibleCount: !showClientCount,
            searchDriven: searchDriven,
            searchDrivenDetails: searchDrivenDetails,
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
                ? (layoutWidth * .40).clamp(0.0, layoutWidth).toDouble()
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
                    padding: const EdgeInsets.symmetric(horizontal: 14),
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
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _PreviewEntrance(child: detailsBody),
                    ),
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
                  child: searchDriven
                      ? SizedBox(
                          height: (availableHeight * .56)
                              .clamp(320.0, 520.0)
                              .toDouble(),
                          child: detailsBody,
                        )
                      : detailsBody,
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
                  count: manualMode || !showClientCount ? null : clients.length,
                  showHeading: showSelectionHeading,
                  selectorAlignment: modeSelectorAlignment,
                  trailing: modeSelectorTrailing,
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
    this.trailing,
  });

  final String title;
  final int? count;
  final Widget? selector;
  final bool showHeading;
  final AlignmentGeometry selectorAlignment;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    // Shared toolbar: the client-source selector (and the inline count) sit on
    // the left, the document-type toggle on the right. Stacks only when the
    // row cannot fit both groups.
    if (selector != null && trailing != null && !showHeading) {
      final countChip = count == null
          ? null
          : Container(
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
            );
      final leftGroup = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          selector!,
          if (countChip != null) ...[
            const SizedBox(width: 8),
            countChip,
          ],
        ],
      );
      return LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 560;
          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftGroup,
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: trailing!,
                ),
              ],
            );
          }
          return Row(
            children: [
              Flexible(child: leftGroup),
              const SizedBox(width: 10),
              trailing!,
            ],
          );
        },
      );
    }
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
      final foreground = selected ? cs.primary : cs.onSurfaceVariant;
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
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
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
      constraints: const BoxConstraints(maxWidth: 400, minWidth: 240),
      child: SizedBox(
        key: const ValueKey('document-client-mode-selector'),
        width: 380,
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
    required this.showVisibleCount,
    required this.searchDriven,
    this.searchDrivenDetails,
  });

  final List<GroupClient> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onClientChanged;
  final bool enabled;
  final double maxListHeight;
  final TextEditingController? searchController;
  final bool flat;
  final bool showVisibleCount;
  final bool searchDriven;
  final Widget? searchDrivenDetails;

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
              padding: EdgeInsets.fromLTRB(
                searchDriven ? 12 : 0,
                0,
                searchDriven ? 12 : 0,
                6,
              ),
              // compact + compactToolbar give us ~50 px rows, the
              // `_CompactClientIdentity` title (name + one secondary line)
              // and a full-width search input flush with the list.
              child: searchDriven
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DialogClientSelect(
                          clients: clients,
                          selectedClientId: selectedClientId,
                          onClientChanged: onClientChanged,
                          enabled: enabled,
                        ),
                        if (searchDrivenDetails != null) ...[
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: searchDrivenDetails,
                            ),
                          ),
                        ],
                      ],
                    )
                  : ClientSearchSelect(
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
                      showVisibleCount: showVisibleCount,
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

class _DialogClientSelect extends StatelessWidget {
  const _DialogClientSelect({
    required this.clients,
    required this.selectedClientId,
    required this.onClientChanged,
    required this.enabled,
  });

  final List<GroupClient> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onClientChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = clients.cast<GroupClient?>().firstWhere(
          (client) => client?.id == selectedClientId,
          orElse: () => null,
        );

    Future<void> openSelector() async {
      if (!enabled) return;
      final result = await showDialog<GroupClient>(
        context: context,
        builder: (_) => _ClientSelectionDialog(
          clients: clients,
          selectedClientId: selectedClientId,
        ),
      );
      if (result != null && result.id != selectedClientId) {
        onClientChanged(result.id);
      }
    }

    return Semantics(
      button: true,
      label: selected == null ? 'Buscar cliente' : 'Cambiar cliente',
      child: InkWell(
        onTap: openSelector,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search, size: 19),
            suffixIcon: Icon(
              Icons.unfold_more_rounded,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          ),
          child: Text(
            selected?.name ?? 'Buscar cliente...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected == null ? cs.onSurfaceVariant : cs.onSurface,
              fontWeight: selected == null ? FontWeight.w400 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientSelectionDialog extends StatefulWidget {
  const _ClientSelectionDialog({
    required this.clients,
    required this.selectedClientId,
  });

  final List<GroupClient> clients;
  final String? selectedClientId;

  @override
  State<_ClientSelectionDialog> createState() => _ClientSelectionDialogState();
}

class _ClientSelectionDialogState extends State<_ClientSelectionDialog> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  int _highlightedIndex = 0;

  List<GroupClient> get _matches {
    final query = _searchController.text.trim().toLowerCase();
    return widget.clients
        .where((client) {
          if (client.isActive == false) return false;
          final searchable = [
            client.name,
            client.email ?? '',
            client.billing?.email ?? '',
            client.billing?.legalName ?? '',
            client.billing?.taxId ?? '',
          ].join(' ').toLowerCase();
          return query.isEmpty || searchable.contains(query);
        })
        .take(80)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _moveHighlight(int delta) {
    final matches = _matches;
    if (matches.isEmpty) return;
    setState(() {
      _highlightedIndex =
          (_highlightedIndex + delta).clamp(0, matches.length - 1);
    });
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_highlightedIndex * 57.0)
          .clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  void _selectHighlighted() {
    final matches = _matches;
    if (matches.isEmpty) return;
    Navigator.of(context).pop(matches[_highlightedIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final media = MediaQuery.sizeOf(context);
    final compact = media.width < 700;
    final matches = _matches;
    if (_highlightedIndex >= matches.length) {
      _highlightedIndex = matches.isEmpty ? 0 : matches.length - 1;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveHighlight(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveHighlight(-1),
        const SingleActivator(LogicalKeyboardKey.enter): _selectHighlighted,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Dialog(
        insetPadding: compact
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        shape: compact
            ? const RoundedRectangleBorder()
            : Theme.of(context).dialogTheme.shape,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: compact ? media.height : 620,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Seleccionar cliente',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() => _highlightedIndex = 0),
                  onSubmitted: (_) => _selectHighlighted(),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Nombre, razón social, NIF/CIF o email',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
              Divider(height: 1, color: cs.outlineVariant),
              Expanded(
                child: matches.isEmpty
                    ? Center(
                        child: Text(
                          'No se encontraron clientes',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: matches.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 58,
                          color: cs.outlineVariant.withValues(alpha: .45),
                        ),
                        itemBuilder: (context, index) {
                          final client = matches[index];
                          final email =
                              (client.billing?.email ?? client.email ?? '')
                                  .trim();
                          final taxId = (client.billing?.taxId ?? '').trim();
                          final selected = client.id == widget.selectedClientId;
                          final highlighted = index == _highlightedIndex;
                          return Material(
                            color: highlighted
                                ? cs.primaryContainer.withValues(alpha: .5)
                                : Colors.transparent,
                            child: InkWell(
                              onHover: (hovering) {
                                if (hovering) {
                                  setState(() => _highlightedIndex = index);
                                }
                              },
                              onTap: () => Navigator.of(context).pop(client),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          cs.primary.withValues(alpha: .12),
                                      child: Text(
                                        client.name.trim().isEmpty
                                            ? '?'
                                            : client.name
                                                .trim()[0]
                                                .toUpperCase(),
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            client.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (email.isNotEmpty ||
                                              taxId.isNotEmpty)
                                            Text(
                                              [email, taxId]
                                                  .where((value) =>
                                                      value.isNotEmpty)
                                                  .join(' · '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        Icons.check_rounded,
                                        color: cs.primary,
                                        size: 19,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
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
        ? LayoutBuilder(
            builder: (context, constraints) {
              final boundedHeight = constraints.maxHeight.isFinite;
              return Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: boundedHeight ? constraints.maxHeight : 0,
                    maxHeight:
                        boundedHeight ? constraints.maxHeight : double.infinity,
                  ),
                  child: child,
                ),
              );
            },
          )
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
          const SizedBox(height: 6),
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
