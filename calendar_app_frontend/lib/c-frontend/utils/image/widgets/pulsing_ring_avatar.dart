import 'dart:math' as math;

import 'package:flutter/material.dart';

class PulsingRingAvatar extends StatefulWidget {
  final ImageProvider<Object> image;
  final double radius;
  final bool isOnline;
  final Color onlineColor;
  final Color offlineBorderColor;
  final Color backgroundColor;

  const PulsingRingAvatar({
    super.key,
    required this.image,
    required this.radius,
    required this.isOnline,
    required this.onlineColor,
    required this.offlineBorderColor,
    required this.backgroundColor,
  });

  @override
  State<PulsingRingAvatar> createState() => _PulsingRingAvatarState();
}

class _PulsingRingAvatarState extends State<PulsingRingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _t; // 0..1

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _t = CurvedAnimation(parent: _ctl, curve: Curves.easeInOut);

    if (widget.isOnline) _ctl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PulsingRingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline && !_ctl.isAnimating) {
      _ctl.repeat(reverse: true);
    } else if (!widget.isOnline && _ctl.isAnimating) {
      _ctl.stop();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseSize = (widget.radius + 4) * 2; // ring container size
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _t,
        builder: (_, __) {
          // animate ring width (2..4) + glow depending on online
          final ringWidth =
              widget.isOnline ? 2.0 + math.sin(_t.value * math.pi) * 2.0 : 1.5;
          final ringOpacity = widget.isOnline ? (0.5 + 0.5 * _t.value) : 0.6;
          final glow = widget.isOnline ? (6.0 + 6.0 * _t.value) : 0.0;

          final borderColor = widget.isOnline
              ? widget.onlineColor.withOpacity(ringOpacity)
              : widget.offlineBorderColor;

          return Container(
            width: baseSize,
            height: baseSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.isOnline
                  ? [
                      BoxShadow(
                        color: widget.onlineColor.withOpacity(0.35),
                        blurRadius: glow,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Container(
              padding: EdgeInsets.all(ringWidth), // ring thickness
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: ringWidth),
              ),
              child: CircleAvatar(
                radius: widget.radius,
                backgroundImage: widget.image,
                backgroundColor: widget.backgroundColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
