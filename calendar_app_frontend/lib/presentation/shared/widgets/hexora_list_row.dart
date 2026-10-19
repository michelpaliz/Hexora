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
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      selected: widget.selected,
      child: Material(
        color: widget.selected
            ? cs.primary.withValues(alpha: .045)
            : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (focused) => setState(() => _focused = focused),
          hoverColor: cs.primary.withValues(alpha: .04),
          focusColor: cs.primary.withValues(alpha: .12),
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
                        : _focused
                            ? cs.primary.withValues(alpha: .6)
                            : Colors.transparent),
                top: BorderSide(
                    width: 1,
                    color: _focused
                        ? cs.primary.withValues(alpha: .6)
                        : Colors.transparent),
                end: BorderSide(
                    width: 1,
                    color: _focused
                        ? cs.primary.withValues(alpha: .6)
                        : Colors.transparent),
                bottom: BorderSide(
                    width: widget.separatorWidth,
                    color: _focused
                        ? cs.primary.withValues(alpha: .6)
                        : cs.outlineVariant.withValues(
                            alpha: HexoraTableTokens.separatorOpacity)),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
