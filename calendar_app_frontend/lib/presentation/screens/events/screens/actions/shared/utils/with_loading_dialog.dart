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

  // Retain the route so completion only closes this dialog, even if the user
  // dismisses it or opens another screen while the task is running.
  final dialogRoute = DialogRoute<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    builder: (ctx) => _LoadingDialog(
      message: message,
      blockBackButton: !barrierDismissible,
    ),
  );
  navigator.push(dialogRoute);

  try {
    final result = await task();
    return result;
  } catch (e) {
    debugPrint('withLoadingDialog error: $e');
    return null;
  } finally {
    if (navigator.mounted && dialogRoute.isActive) {
      if (dialogRoute.isCurrent) {
        navigator.pop();
      } else {
        navigator.removeRoute(dialogRoute);
      }
    }
  }
}

class _LoadingDialog extends StatelessWidget {
  final String? message;
  final bool blockBackButton;

  const _LoadingDialog({
    this.message,
    this.blockBackButton = true,
  });

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

    return PopScope(
      canPop: false,
      child: dialog,
    );
  }
}
