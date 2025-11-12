import 'package:flutter/material.dart';

class FabShell extends StatelessWidget {
  const FabShell({super.key, required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [color.withOpacity(0.65), color],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: const DecoratedBox(
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ).foreground(child),
    );
  }
}

extension on Widget {
  /// Convenience to overlay [child] above this widget.
  Widget foreground(Widget child) => Stack(
        alignment: Alignment.center,
        children: [this, child],
      );
}
