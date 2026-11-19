import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two-pane horizontal layout with a draggable divider. The chosen width is
/// stored per [preferenceKey] so it survives reloads. Double-click the divider
/// to reset; arrow keys resize it when focused. Falls back to a fixed split
/// when there is no room for both minimum widths.
class HexoraResizableSplit extends StatefulWidget {
  const HexoraResizableSplit({
    super.key,
    required this.start,
    required this.end,
    required this.preferenceKey,
    this.initialFraction = 0.38,
    this.minStartWidth = 300,
    this.minEndWidth = 420,
    this.handleWidth = 12,
  });

  final Widget start;
  final Widget end;
  final String preferenceKey;
  final double initialFraction;
  final double minStartWidth;
  final double minEndWidth;
  final double handleWidth;

  @override
  State<HexoraResizableSplit> createState() => _HexoraResizableSplitState();
}

class _HexoraResizableSplitState extends State<HexoraResizableSplit> {
  late double _fraction = widget.initialFraction;
  bool _hovered = false;
  bool _dragging = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(widget.preferenceKey);
      if (!mounted || saved == null) return;
      setState(() => _fraction = saved.clamp(0.15, 0.85));
    } catch (_) {
      // Keep the default split when preferences are unavailable.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(widget.preferenceKey, _fraction);
    } catch (_) {}
  }

  double _clampFraction(double value, double available) {
    final min = widget.minStartWidth / available;
    final max = 1 - widget.minEndWidth / available;
    return value.clamp(min, max).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';

    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth - widget.handleWidth;
      final canResize =
          available >= widget.minStartWidth + widget.minEndWidth;
      final fraction =
          canResize ? _clampFraction(_fraction, available) : widget.initialFraction;
      final startWidth = available * fraction;

      void resizeBy(double dx) {
        setState(() => _fraction =
            _clampFraction((startWidth + dx) / available, available));
      }

      final active = _hovered || _dragging || _focused;
      final handle = Semantics(
        label: es ? 'Redimensionar paneles' : 'Resize panels',
        child: Tooltip(
          message: es
              ? 'Arrastra para redimensionar · doble clic para restablecer'
              : 'Drag to resize · double-click to reset',
          waitDuration: const Duration(milliseconds: 600),
          child: Focus(
            onFocusChange: (v) => setState(() => _focused = v),
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                resizeBy(-24);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                resizeBy(24);
              } else {
                return KeyEventResult.ignored;
              }
              _save();
              return KeyEventResult.handled;
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) => setState(() => _dragging = true),
                onHorizontalDragUpdate: (d) => resizeBy(d.delta.dx),
                onHorizontalDragEnd: (_) {
                  setState(() => _dragging = false);
                  _save();
                },
                onDoubleTap: () {
                  setState(() => _fraction = widget.initialFraction);
                  _save();
                },
                child: SizedBox(
                  width: widget.handleWidth,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: active ? 2 : 1,
                      decoration: BoxDecoration(
                        color: active
                            ? cs.primary.withValues(alpha: 0.7)
                            : cs.outlineVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: startWidth, child: widget.start),
          if (canResize) handle else SizedBox(width: widget.handleWidth),
          Expanded(child: widget.end),
        ],
      );
    });
  }
}
