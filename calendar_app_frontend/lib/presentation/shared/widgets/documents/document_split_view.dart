import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the workspace is shared between the document list and its preview.
enum DocumentViewMode { list, split, document }

/// True while the user drags the list/preview divider. Embedded web PDF
/// viewers (iframes) would otherwise swallow the pointer mid-drag, so
/// [PdfInlinePreview] stops taking pointer events while this is set.
final ValueNotifier<bool> documentSplitDragging = ValueNotifier(false);

/// Exposes the effective workspace mode to document rows and lets a preview
/// action request the list-mode drawer without coupling the list to the split
/// view state.
class DocumentWorkspaceScope extends InheritedWidget {
  const DocumentWorkspaceScope({
    super.key,
    required this.mode,
    required this.openPreviewDrawer,
    required super.child,
  });

  final DocumentViewMode mode;
  final VoidCallback openPreviewDrawer;

  static DocumentWorkspaceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DocumentWorkspaceScope>();

  @override
  bool updateShouldNotify(DocumentWorkspaceScope oldWidget) =>
      mode != oldWidget.mode ||
      openPreviewDrawer != oldWidget.openPreviewDrawer;
}

/// One list + preview layout for every document module (invoices, receipts,
/// quotes, contracts).
///
/// * Large desktop (≥ [splitBreakpoint]): split view with a draggable
///   divider; the list or the document can be expanded without leaving the
///   page.
/// * Medium desktop (≥ [drawerBreakpoint]): list first; selecting a document
///   opens the split view.
/// * Tablet and mobile: list only; the selected document slides in over it
///   (full width on phones).
///
/// The chosen mode and divider position are remembered per [storageKey].
class DocumentSplitView extends StatefulWidget {
  const DocumentSplitView({
    super.key,
    required this.storageKey,
    required this.list,
    required this.preview,
    this.selectionKey,
    this.initialListFraction = 0.56,
    this.minListWidth = 380,
    this.minPreviewWidth = 360,
    this.splitBreakpoint = 1280,
    this.drawerBreakpoint = 960,
    this.gap = 8,
    this.modeNotifier,
  });

  final String storageKey;
  final Widget list;

  /// Detail/PDF pane. Shown in split and document modes, and in the overlay
  /// on narrow screens.
  final Widget preview;

  /// Identity of the selected document; null when nothing is selected. A
  /// change reveals the preview where it is hidden by default.
  final Object? selectionKey;

  final double initialListFraction;
  final double minListWidth;
  final double minPreviewWidth;
  final double splitBreakpoint;
  final double drawerBreakpoint;
  final double gap;

  /// Optional external mode controller. When provided the split view syncs
  /// its active mode with this notifier bidirectionally: external changes
  /// update the layout, and user interactions (divider, rail) update the
  /// notifier so callers can react (e.g. to reflect expand state in a header).
  final ValueNotifier<DocumentViewMode?>? modeNotifier;

  @override
  State<DocumentSplitView> createState() => _DocumentSplitViewState();
}

class _DocumentSplitViewState extends State<DocumentSplitView> {
  /// Survive rebuilds and module switches within the session; prefs make
  /// the choice stick across sessions.
  static final Map<String, double> _fractions = {};
  static final Map<String, DocumentViewMode> _modes = {};

  late double _fraction =
      _fractions[widget.storageKey] ?? widget.initialListFraction;

  /// Explicit user choice; null means "default for this width".
  late DocumentViewMode? _userMode = _modes[widget.storageKey];
  bool _overlayOpen = false;
  bool _previewDrawerOpen = false;
  bool _dragging = false;
  FocusNode? _focusBeforeDrawer;
  final FocusNode _drawerFocus = FocusNode(debugLabel: 'documentPreviewDrawer');

  String get _fractionPref => 'documentSplit.${widget.storageKey}.fraction';
  String get _modePref => 'documentSplit.${widget.storageKey}.mode';

  @override
  void initState() {
    super.initState();
    _restore();
    widget.modeNotifier?.addListener(_onExternalMode);
  }

  void _onExternalMode() {
    final m = widget.modeNotifier!.value;
    final normalized =
        m == DocumentViewMode.document ? DocumentViewMode.split : m;
    if (normalized != _userMode) setState(() => _userMode = normalized);
  }

  Future<void> _restore() async {
    if (_fractions.containsKey(widget.storageKey)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final fraction = prefs.getDouble(_fractionPref);
      final modeName = prefs.getString(_modePref);
      if (!mounted) return;
      setState(() {
        if (fraction != null) _fraction = fraction;
        final restored = DocumentViewMode.values
            .where((m) => m.name == modeName)
            .firstOrNull;
        _userMode = restored == DocumentViewMode.document
            ? DocumentViewMode.split
            : restored;
      });
    } catch (_) {
      // Preferences are a convenience; defaults are fine without them.
    }
  }

  Future<void> _persist() async {
    _fractions[widget.storageKey] = _fraction;
    if (_userMode == null) {
      _modes.remove(widget.storageKey);
    } else {
      _modes[widget.storageKey] = _userMode!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fractionPref, _fraction);
      if (_userMode == null) {
        await prefs.remove(_modePref);
      } else {
        await prefs.setString(_modePref, _userMode!.name);
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant DocumentSplitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.modeNotifier != oldWidget.modeNotifier) {
      oldWidget.modeNotifier?.removeListener(_onExternalMode);
      widget.modeNotifier?.addListener(_onExternalMode);
    }
    if (widget.selectionKey != null &&
        widget.selectionKey != oldWidget.selectionKey) {
      _overlayOpen = true;
    }
    if (widget.selectionKey == null) _overlayOpen = false;
    if (widget.selectionKey == null) _previewDrawerOpen = false;
  }

  @override
  void dispose() {
    widget.modeNotifier?.removeListener(_onExternalMode);
    if (_dragging) documentSplitDragging.value = false;
    _drawerFocus.dispose();
    super.dispose();
  }

  void _setMode(DocumentViewMode? mode) {
    setState(() {
      _userMode = mode;
      if (mode != DocumentViewMode.list) _previewDrawerOpen = false;
    });
    widget.modeNotifier?.value = mode;
    _persist();
  }

  bool get _isEs =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  void _openPreviewDrawer() {
    _focusBeforeDrawer = FocusManager.instance.primaryFocus;
    setState(() {
      // Preserve the effective list layout when selection changes. Without an
      // explicit list mode, medium-width workspaces would switch to split as
      // soon as the preview action selected a document.
      _userMode = DocumentViewMode.list;
      _previewDrawerOpen = true;
    });
    widget.modeNotifier?.value = DocumentViewMode.list;
    _persist();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _drawerFocus.requestFocus();
    });
  }

  void _closePreviewDrawer() {
    if (!_previewDrawerOpen) return;
    setState(() => _previewDrawerOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusBeforeDrawer?.canRequestFocus ?? false) {
        _focusBeforeDrawer!.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (width < widget.drawerBreakpoint) return _buildOverlayLayout(width);

      final hasSelection = widget.selectionKey != null;
      final defaultMode = width >= widget.splitBreakpoint || hasSelection
          ? DocumentViewMode.split
          : DocumentViewMode.list;
      var mode = _userMode ?? defaultMode;
      // Not enough room for both panes at their minimum: fall back to one.
      if (mode == DocumentViewMode.document) mode = DocumentViewMode.split;
      if (mode == DocumentViewMode.split &&
          width <
              widget.minListWidth + widget.minPreviewWidth + _dividerWidth) {
        mode = hasSelection ? DocumentViewMode.split : DocumentViewMode.list;
      }
      final workspace = switch (mode) {
        DocumentViewMode.list => _buildListWithPreviewDrawer(width),
        DocumentViewMode.document => widget.preview,
        DocumentViewMode.split => DocumentWorkspaceScope(
            mode: DocumentViewMode.split,
            openPreviewDrawer: _openPreviewDrawer,
            child: _buildSplit(width),
          ),
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeToolbar(
            mode: mode,
            listTooltip: _isEs ? 'Solo lista' : 'List only',
            splitTooltip: _isEs ? 'Vista dividida' : 'Split view',
            onCompact: () => _setMode(DocumentViewMode.list),
            onRestore: () => _setMode(DocumentViewMode.split),
          ),
          SizedBox(height: widget.gap / 2),
          Expanded(child: workspace),
        ],
      );
    });
  }

  static const double _dividerWidth = 24;

  Widget _buildListWithPreviewDrawer(double width) {
    final cs = Theme.of(context).colorScheme;
    final drawerWidth = (width * .38).clamp(420.0, 520.0);
    final hasPreview = widget.selectionKey != null;
    return Stack(clipBehavior: Clip.hardEdge, children: [
      Positioned.fill(
        child: DocumentWorkspaceScope(
          mode: DocumentViewMode.list,
          openPreviewDrawer: _openPreviewDrawer,
          child: widget.list,
        ),
      ),
      if (hasPreview && _previewDrawerOpen)
        PositionedDirectional(
          top: 0,
          bottom: 0,
          end: 0,
          width: drawerWidth,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(widget.selectionKey),
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(drawerWidth * value, 0),
              child: child,
            ),
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape):
                    _closePreviewDrawer,
              },
              child: Focus(
                focusNode: _drawerFocus,
                child: FocusTraversalGroup(
                  child: Material(
                    key: const ValueKey('document-preview-drawer'),
                    color: cs.surface,
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadiusDirectional.only(
                        topStart: Radius.circular(8),
                        bottomStart: Radius.circular(8),
                      ),
                      side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: .55)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.preview,
                  ),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _buildSplit(double width) {
    final available = width - _dividerWidth;
    final minFraction = widget.minListWidth / available;
    final maxFraction = 1 - widget.minPreviewWidth / available;
    final fraction = _fraction.clamp(minFraction, maxFraction);
    final listWidth = available * fraction;
    return Row(children: [
      SizedBox(width: listWidth, child: widget.list),
      _SplitDivider(
        width: _dividerWidth,
        onDragStart: () {
          setState(() => _dragging = true);
          documentSplitDragging.value = true;
        },
        onDragUpdate: (dx) => setState(() {
          _fraction = ((listWidth + dx) / available)
              .clamp(minFraction, maxFraction)
              .toDouble();
        }),
        onDragEnd: () {
          setState(() => _dragging = false);
          documentSplitDragging.value = false;
          _persist();
        },
        onReset: () {
          setState(() => _fraction = widget.initialListFraction);
          _persist();
        },
        dragTooltip: _isEs
            ? 'Arrastra para redimensionar · doble clic para restablecer'
            : 'Drag to resize · double-click to reset',
      ),
      Expanded(child: widget.preview),
    ]);
  }

  Widget _buildOverlayLayout(double width) {
    final cs = Theme.of(context).colorScheme;
    final open = _overlayOpen && widget.selectionKey != null;
    final phone = width < 650;
    final panelWidth = phone ? width : (width * 0.85).clamp(0.0, 640.0);
    return Stack(children: [
      Positioned.fill(
        child: DocumentWorkspaceScope(
          mode: DocumentViewMode.list,
          openPreviewDrawer: _openPreviewDrawer,
          child: widget.list,
        ),
      ),
      if (open) ...[
        if (!phone)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _overlayOpen = false),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.32)),
            ),
          ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: panelWidth,
          child: Material(
            color: cs.surface,
            elevation: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: IconButton(
                      tooltip: phone
                          ? MaterialLocalizations.of(context).backButtonTooltip
                          : MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                      icon: Icon(phone
                          ? Icons.arrow_back_rounded
                          : Icons.close_rounded),
                      onPressed: () => setState(() => _overlayOpen = false),
                    ),
                  ),
                ),
                Expanded(child: widget.preview),
              ],
            ),
          ),
        ),
      ],
    ]);
  }
}

class _ModeToolbar extends StatelessWidget {
  const _ModeToolbar({
    required this.mode,
    required this.listTooltip,
    required this.splitTooltip,
    required this.onCompact,
    required this.onRestore,
  });

  final DocumentViewMode mode;
  final String listTooltip;
  final String splitTooltip;
  final VoidCallback onCompact;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 34,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModeButton(
                icon: Icons.view_sidebar_outlined,
                tooltip: listTooltip,
                active: mode == DocumentViewMode.list,
                onPressed: mode == DocumentViewMode.list ? null : onCompact,
              ),
              _ModeButton(
                icon: Icons.splitscreen_rounded,
                tooltip: splitTooltip,
                active: mode == DocumentViewMode.split,
                onPressed: mode == DocumentViewMode.split ? null : onRestore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      selected: active,
      button: true,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 17,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        style: IconButton.styleFrom(
          minimumSize: const Size(30, 30),
          maximumSize: const Size(30, 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: active ? cs.primary : cs.onSurfaceVariant,
          disabledForegroundColor:
              active ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
          backgroundColor:
              active ? cs.primaryContainer.withValues(alpha: 0.55) : null,
          disabledBackgroundColor:
              active ? cs.primaryContainer.withValues(alpha: 0.55) : null,
        ),
      ),
    );
  }
}

class _SplitDivider extends StatefulWidget {
  const _SplitDivider({
    required this.width,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onReset,
    required this.dragTooltip,
  });

  final double width;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onReset;
  final String dragTooltip;

  @override
  State<_SplitDivider> createState() => _SplitDividerState();
}

class _SplitDividerState extends State<_SplitDivider> {
  bool _hover = false;
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final highlight = _hover || _active;
    return SizedBox(
      width: widget.width,
      child: Column(children: [
        Expanded(
          child: Tooltip(
            message: widget.dragTooltip,
            waitDuration: const Duration(milliseconds: 600),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              onEnter: (_) => setState(() => _hover = true),
              onExit: (_) => setState(() => _hover = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onDoubleTap: widget.onReset,
                onHorizontalDragStart: (_) {
                  setState(() => _active = true);
                  widget.onDragStart();
                },
                onHorizontalDragUpdate: (d) => widget.onDragUpdate(d.delta.dx),
                onHorizontalDragEnd: (_) {
                  setState(() => _active = false);
                  widget.onDragEnd();
                },
                onHorizontalDragCancel: () {
                  setState(() => _active = false);
                  widget.onDragEnd();
                },
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: highlight ? 3 : 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: highlight
                          ? cs.primary.withValues(alpha: 0.7)
                          : cs.outlineVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
