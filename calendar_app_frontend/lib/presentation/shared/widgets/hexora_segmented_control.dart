import 'package:flutter/material.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';

class HexoraSegment<T> {
  const HexoraSegment({
    required this.value,
    required this.label,
    this.icon,
    this.key,
  });

  final T value;
  final String label;
  final IconData? icon;
  final Key? key;
}

/// Compact segmented control: a subtle neutral track with 3px padding, where
/// the selected option is an independent rounded pill in soft light blue.
///
/// Labels reserve their semibold width, so changing the selection never
/// shifts the surrounding layout.
class HexoraSegmentedControl<T> extends StatelessWidget {
  const HexoraSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 34,
    this.backgroundColor,
    this.expandSegments = false,
  });

  final List<HexoraSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;
  final bool expandSegments;

  /// Track colour; defaults to the neutral [trackColor]. Use a surface colour
  /// when the control sits directly on the workspace canvas.
  final Color? backgroundColor;

  static const double trackPadding = 3;

  static Color trackColor(ColorScheme cs) => Color.alphaBlend(
        cs.onSurface
            .withValues(alpha: cs.brightness == Brightness.dark ? 0.07 : 0.045),
        cs.surface,
      );

  static Color selectedColor(ColorScheme cs) => Color.alphaBlend(
        cs.primary
            .withValues(alpha: cs.brightness == Brightness.dark ? 0.24 : 0.13),
        cs.surface,
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(trackPadding),
        decoration: BoxDecoration(
          color: backgroundColor ?? trackColor(cs),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              if (expandSegments)
                Expanded(
                  child: _SegmentButton<T>(
                    segment: segments[i],
                    selected: segments[i].value == selected,
                    compact: true,
                    onTap: () {
                      if (segments[i].value != selected) {
                        onChanged(segments[i].value);
                      }
                    },
                  ),
                )
              else
                _SegmentButton<T>(
                  segment: segments[i],
                  selected: segments[i].value == selected,
                  onTap: () {
                    if (segments[i].value != selected) {
                      onChanged(segments[i].value);
                    }
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.segment,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final HexoraSegment<T> segment;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final duration = HexoraMotion.duration(context, HexoraMotion.navigation);
    final foreground = selected ? cs.primary : cs.onSurfaceVariant;
    final base = theme.textTheme.bodySmall?.copyWith(fontSize: 13, height: 1);
    final radius = BorderRadius.circular(7);

    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        key: segment.key,
        duration: duration,
        curve: HexoraMotion.enter,
        decoration: BoxDecoration(
          color: selected ? HexoraSegmentedControl.selectedColor(cs) : null,
          borderRadius: radius,
          boxShadow: selected && cs.brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            hoverColor: selected
                ? Colors.transparent
                : cs.onSurface.withValues(alpha: 0.05),
            splashColor: cs.primary.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (segment.icon != null) ...[
                    TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: foreground),
                      duration: duration,
                      curve: HexoraMotion.enter,
                      builder: (_, color, __) =>
                          Icon(segment.icon, size: 16, color: color),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (compact)
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: duration,
                        curve: HexoraMotion.enter,
                        style: (base ?? const TextStyle()).copyWith(
                          color: foreground,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        child: Text(
                          segment.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    // The invisible semibold copy reserves the widest label
                    // so the weight change does not move neighbouring tabs.
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: 0,
                          child: ExcludeSemantics(
                            child: Text(
                              segment.label,
                              maxLines: 1,
                              style:
                                  base?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        AnimatedDefaultTextStyle(
                          duration: duration,
                          curve: HexoraMotion.enter,
                          style: (base ?? const TextStyle()).copyWith(
                            color: foreground,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          child: Text(segment.label, maxLines: 1),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
