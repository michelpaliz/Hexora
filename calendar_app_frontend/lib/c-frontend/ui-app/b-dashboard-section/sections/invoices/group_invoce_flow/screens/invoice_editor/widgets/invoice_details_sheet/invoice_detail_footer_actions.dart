import 'package:flutter/material.dart';

class InvoiceDetailFooterActions extends StatelessWidget {
  final String downloadTooltip;
  final String previewTooltip;
  final String primaryTooltip;
  final Widget downloadIcon;
  final Widget previewIcon;
  final Widget primaryIcon;
  final VoidCallback? onDownload;
  final VoidCallback? onPreview;
  final VoidCallback? onPrimary;
  final bool primaryFilled;
  final bool showPrimary;

  const InvoiceDetailFooterActions({
    super.key,
    required this.downloadTooltip,
    required this.previewTooltip,
    required this.primaryTooltip,
    required this.downloadIcon,
    required this.previewIcon,
    required this.primaryIcon,
    required this.onDownload,
    required this.onPreview,
    required this.onPrimary,
    this.primaryFilled = true,
    this.showPrimary = true,
  });

  Widget _iconButton({
    required String tooltip,
    required Widget icon,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    final child = SizedBox(
      width: 44,
      height: 40,
      child: Center(child: icon),
    );
    return Tooltip(
      message: tooltip,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 40),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 40),
              ),
              child: child,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _iconButton(
          tooltip: downloadTooltip,
          onPressed: onDownload,
          icon: downloadIcon,
        ),
        const SizedBox(width: 10),
        _iconButton(
          tooltip: previewTooltip,
          onPressed: onPreview,
          icon: previewIcon,
        ),
        if (showPrimary) ...[
          const SizedBox(width: 10),
          _iconButton(
            tooltip: primaryTooltip,
            onPressed: onPrimary,
            icon: primaryIcon,
            filled: primaryFilled,
          ),
        ],
      ],
    );
  }
}
