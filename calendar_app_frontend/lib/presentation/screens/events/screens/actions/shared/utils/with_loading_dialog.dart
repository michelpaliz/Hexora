import 'package:flutter/material.dart';

/// Shows a blocking loading dialog while [task] runs.
/// Returns the result of [task]. If [task] throws, returns null.
///
/// Usage:
/// final ok = await withLoadingDialog<bool>(
///   context,
///   () => logic.addEvent(context),
///   message: AppLocalizations.of(context)!.createEventMessage,
/// );
Future<T?> withLoadingDialog<T>(
  BuildContext context,
  Future<T> Function() task, {
  String? message,
  bool barrierDismissible = false,
  bool useRootNavigator = true,
}) async {
  if (!context.mounted) {
    // If context is gone, just run the task without a dialog.
    try {
      return await task();
    } catch (_) {
      return null;
    }
  }

  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);

  // Show the loading dialog (don't await it).
  showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: (ctx) => _LoadingDialog(
      message: message,
      blockBackButton: !barrierDismissible,
    ),
  );

  try {
    final result = await task();
    return result;
  } catch (e) {
    debugPrint('withLoadingDialog error: $e');
    return null;
  } finally {
    if (context.mounted) {
      // Close the dialog if it's still open.
      // maybePop avoids exceptions if the dialog was already dismissed.
      await navigator.maybePop();
    }
  }
}

class _LoadingDialog extends StatelessWidget {
  final String? message;
  final bool blockBackButton;

  const _LoadingDialog({
    Key? key,
    this.message,
    this.blockBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 4),
        const CircularProgressIndicator(),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            message ?? 'Loading…',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );

    final dialog = AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      content: content,
    );

    // Optionally block the system back button.
    if (!blockBackButton) return dialog;

    return WillPopScope(
      onWillPop: () async => false,
      child: dialog,
    );
  }
}
