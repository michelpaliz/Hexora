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
  });

  final List<HexoraFinancialMetric> metrics;
  final HexoraFinancialAlert? alert;
  final bool loading;
  final String loadingLabel;

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
      return Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: _decoration(cs),
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

        return Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: _decoration(cs),
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

  BoxDecoration _decoration(ColorScheme cs) => BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
      );

  Widget _metric(BuildContext context, HexoraFinancialMetric metric) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Semantics(
      label: '${metric.label}: ${metric.value}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: metric.emphasized
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
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
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
                    fontSize: metric.emphasized ? 17 : 16,
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
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: warning.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
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
