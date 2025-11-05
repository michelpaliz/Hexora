// depth_card.dart (or inline in the same file)
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/card_surface.dart';

class DepthCard extends StatelessWidget {
  const DepthCard({
    super.key,
    required this.child,
    this.radius = 14,
    this.borderWidth = 1.2,
    this.ambientOpacity = 0.18,
    this.keyOpacity = 0.10,
    this.ambientBlur = 18,
    this.keyBlur = 10,
    this.keyYOffset = 6,
    this.margin,
    this.minHeight,
    this.padding,
  });

  final Widget child;
  final double radius;
  final double borderWidth;

  /// Shadow tuning
  final double ambientOpacity; // wide soft haze
  final double keyOpacity; // crisper drop
  final double ambientBlur;
  final double keyBlur;
  final double keyYOffset;

  final EdgeInsetsGeometry? margin;
  final double? minHeight;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = CardSurface.bg(context);
    final border = CardSurface.border(context);
    final onBg = CardSurface.onBg(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Layered shadows for thickness
        boxShadow: [
          // Ambient (broad/soft)
          BoxShadow(
            color: Colors.black.withOpacity(ambientOpacity),
            blurRadius: ambientBlur,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
          // Key light (crisper/downward)
          BoxShadow(
            color: Colors.black.withOpacity(keyOpacity),
            blurRadius: keyBlur,
            spreadRadius: 0,
            offset: Offset(0, keyYOffset),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border, width: borderWidth),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight ?? 64),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: IconTheme(
                data: IconThemeData(color: onBg.withOpacity(.7)),
                child: DefaultTextStyle(
                  style:
                      DefaultTextStyle.of(context).style.copyWith(color: onBg),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
