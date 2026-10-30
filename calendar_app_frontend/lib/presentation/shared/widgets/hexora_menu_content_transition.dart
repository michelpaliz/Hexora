import 'package:flutter/material.dart';

/// Applies the shared Hexora transition when a module menu changes content.
///
/// The child remains in its normal position in the tree, so module state and
/// existing navigation behavior are preserved.
class HexoraMenuContentTransition extends StatefulWidget {
  const HexoraMenuContentTransition({
    super.key,
    required this.transitionKey,
    required this.child,
    this.duration = const Duration(milliseconds: 180),
  });

  final Object transitionKey;
  final Widget child;
  final Duration duration;

  @override
  State<HexoraMenuContentTransition> createState() =>
      _HexoraMenuContentTransitionState();
}

class _HexoraMenuContentTransitionState
    extends State<HexoraMenuContentTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.82,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0.012, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void didUpdateWidget(covariant HexoraMenuContentTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.transitionKey != widget.transitionKey) {
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _controller.value != 1) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return ClipRect(
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          transformHitTests: false,
          child: widget.child,
        ),
      ),
    );
  }
}
