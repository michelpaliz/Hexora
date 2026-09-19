import 'package:flutter/material.dart';

class InsightsAsyncIconButton extends StatefulWidget {
  const InsightsAsyncIconButton({
    super.key,
    required this.tooltip,
    required this.semanticLabel,
    required this.errorFallback,
    required this.onPressed,
  });

  final String tooltip;
  final String semanticLabel;
  final String errorFallback;
  final Future<void> Function()? onPressed;

  @override
  State<InsightsAsyncIconButton> createState() =>
      _InsightsAsyncIconButtonState();
}

class _InsightsAsyncIconButtonState extends State<InsightsAsyncIconButton> {
  bool _loading = false;

  Future<void> _run() async {
    final action = widget.onPressed;
    if (action == null || _loading) return;
    setState(() => _loading = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? widget.errorFallback : message),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Tooltip(
        message: widget.tooltip,
        child: IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: widget.onPressed == null || _loading ? null : _run,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.visibility_outlined, size: 18),
        ),
      ),
    );
  }
}
