import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

/// Continuous list surface with consistent selection, focus and hover states.
/// The minimum height grows naturally for wrapped content and larger text.
class HexoraListRow extends StatefulWidget {
  const HexoraListRow(
      {super.key,
      required this.child,
      this.selected = false,
      this.onTap,
      this.minHeight = HexoraTableTokens.rowMinHeight,
      this.verticalPadding = HexoraTableTokens.rowPadding,
      this.separatorWidth = HexoraTableTokens.separatorWidth});
  final double separatorWidth;
  final double minHeight;
  final double verticalPadding;
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<HexoraListRow> createState() => _HexoraListRowState();
}

class _HexoraListRowState extends State<HexoraListRow> {
  /// Focus ring only for keyboard navigation. A mouse click also focuses the
  /// row; showing the ring then turned the selected row into a heavy block.
  bool _keyboardFocused = false;
  bool _pointerDown = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ring = cs.primary.withValues(alpha: .6);
    return Semantics(
      selected: widget.selected,
      child: Listener(
        onPointerDown: (_) => _pointerDown = true,
        onPointerUp: (_) => _pointerDown = false,
        onPointerCancel: (_) => _pointerDown = false,
        child: Material(
          color: widget.selected
              ? cs.primary.withValues(alpha: .05)
              : Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            mouseCursor: widget.onTap == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            canRequestFocus: widget.onTap != null,
            onFocusChange: (focused) =>
                setState(() => _keyboardFocused = focused && !_pointerDown),
            hoverColor: cs.primary.withValues(alpha: .04),
            focusColor: _keyboardFocused
                ? cs.primary.withValues(alpha: .12)
                : Colors.transparent,
            child: Container(
              constraints: BoxConstraints(minHeight: widget.minHeight),
              padding: EdgeInsets.symmetric(
                  horizontal: HexoraTableTokens.cellPadding,
                  vertical: widget.verticalPadding),
              foregroundDecoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(
                      width: 2,
                      color: widget.selected
                          ? cs.primary
                          : _keyboardFocused
                              ? ring
                              : Colors.transparent),
                  top: BorderSide(
                      width: 1,
                      color: _keyboardFocused ? ring : Colors.transparent),
                  end: BorderSide(
                      width: 1,
                      color: _keyboardFocused ? ring : Colors.transparent),
                  bottom: BorderSide(
                      width: widget.separatorWidth,
                      color: _keyboardFocused
                          ? ring
                          : cs.outlineVariant.withValues(
                              alpha: HexoraTableTokens.separatorOpacity)),
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
