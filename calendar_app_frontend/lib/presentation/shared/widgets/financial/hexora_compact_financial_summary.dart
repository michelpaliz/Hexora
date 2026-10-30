import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

class HexoraFinancialMetric {
  const HexoraFinancialMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;
}

class HexoraFinancialAlert {
  const HexoraFinancialAlert({
    required this.label,
    required this.tooltip,
    this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
}

class HexoraCompactFinancialSummary extends StatefulWidget {
  const HexoraCompactFinancialSummary({
    super.key,
    required this.metrics,
    this.alert,
    this.loading = false,
    this.loadingLabel = 'Calculando totales…',
    this.dense = false,
    this.inline = false,
  });

  final List<HexoraFinancialMetric> metrics;
  final HexoraFinancialAlert? alert;
  final bool loading;
  final String loadingLabel;
  final bool dense;
  final bool inline;

  @override
  State<HexoraCompactFinancialSummary> createState() =>
      _HexoraCompactFinancialSummaryState();
}

class _HexoraCompactFinancialSummaryState
    extends State<HexoraCompactFinancialSummary> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent signal) {
    if (signal is! PointerScrollEvent || !_horizontalController.hasClients) {
      return;
    }
    final delta = signal.scrollDelta.dx.abs() > signal.scrollDelta.dy.abs()
        ? signal.scrollDelta.dx
        : signal.scrollDelta.dy;
    final position = _horizontalController.position;
    _horizontalController.jumpTo(
      (_horizontalController.offset + delta)
          .clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    if (widget.loading) {
      if (widget.inline) {
        return SizedBox(
          height: 34,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 7),
              Text(
                widget.loadingLabel,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );
      }
      return Container(
        constraints: BoxConstraints(minHeight: widget.dense ? 40 : 60),
        padding: EdgeInsets.symmetric(
          horizontal: widget.dense ? 8 : 12,
          vertical: widget.dense ? 2 : 8,
        ),
        decoration: _decoration(cs, dense: widget.dense),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              widget.loadingLabel,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final children = <Widget>[
          for (final metric in widget.metrics) _metric(context, metric),
          if (widget.alert != null) _alert(context, widget.alert!),
        ];
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final wide = constraints.maxWidth >= 700 && textScale <= 1.4;

        if (widget.inline) {
          return SizedBox(
            height: 34,
            child: ClipRect(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: const {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < children.length; index++) ...[
                        children[index],
                        if (index != children.length - 1)
                          const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          constraints: BoxConstraints(minHeight: widget.dense ? 40 : 60),
          padding: EdgeInsets.symmetric(
            horizontal: widget.dense ? 6 : 10,
            vertical: widget.dense ? 1 : 8,
          ),
          decoration: _decoration(cs, dense: widget.dense),
          child: wide
              ? IntrinsicHeight(
                  child: Row(
                    children: [
                      for (var index = 0; index < children.length; index++) ...[
                        Expanded(
                          flex: index == 2 ? 12 : 10,
                          child: children[index],
                        ),
                        if (index != children.length - 1)
                          VerticalDivider(
                            width: 12,
                            thickness: 1,
                            color: cs.outlineVariant.withValues(alpha: .45),
                          ),
                      ],
                    ],
                  ),
                )
              : Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  notificationPredicate: (notification) =>
                      notification.metrics.axis == Axis.horizontal,
                  child: Listener(
                    onPointerSignal: _handlePointerSignal,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: const {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 5),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              for (var index = 0;
                                  index < children.length;
                                  index++) ...[
                                SizedBox(
                                  width: index == 2 ? 180 : 160,
                                  child: children[index],
                                ),
                                if (index != children.length - 1)
                                  const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  BoxDecoration _decoration(ColorScheme cs, {required bool dense}) =>
      BoxDecoration(
        color:
            dense ? cs.surfaceContainerLow.withValues(alpha: .55) : cs.surface,
        borderRadius: BorderRadius.circular(dense ? 6 : 10),
        border: dense
            ? null
            : Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
      );

  Widget _metric(BuildContext context, HexoraFinancialMetric metric) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Semantics(
      label: '${metric.label}: ${metric.value}',
      child: Container(
        constraints: BoxConstraints(minHeight: widget.inline ? 32 : 38),
        padding: EdgeInsets.symmetric(
          horizontal: widget.inline ? 6 : 10,
          vertical: widget.inline ? 1 : 3,
        ),
        decoration: BoxDecoration(
          color: metric.emphasized && !widget.inline
              ? cs.primaryContainer.withValues(alpha: .32)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.label.toUpperCase(),
              style: t.caption.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: widget.inline ? 9.5 : 11,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: widget.inline ? 2 : 3),
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  metric.value,
                  softWrap: false,
                  style: t.bodySmall.copyWith(
                    color: metric.valueColor ??
                        (metric.emphasized ? cs.primary : cs.onSurface),
                    fontSize: widget.inline
                        ? (metric.emphasized ? 14.5 : 13.5)
                        : (metric.emphasized ? 17 : 16),
                    height: 1,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alert(BuildContext context, HexoraFinancialAlert alert) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final warning = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFB85C00)
        : cs.secondary;
    return Tooltip(
      message: alert.tooltip,
      child: Semantics(
        button: alert.onPressed != null,
        label: alert.label,
        child: InkWell(
          onTap: alert.onPressed,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            constraints: BoxConstraints(minHeight: widget.inline ? 32 : 38),
            padding: EdgeInsets.symmetric(
              horizontal: widget.inline ? 7 : 10,
              vertical: widget.inline ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: warning.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: widget.inline ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: warning),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    alert.label,
                    softWrap: false,
                    style: t.bodySmall.copyWith(
                      color: warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (alert.onPressed != null) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.chevron_right_rounded, size: 16, color: warning),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
