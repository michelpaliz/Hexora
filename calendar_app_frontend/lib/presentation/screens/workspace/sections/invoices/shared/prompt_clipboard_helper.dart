import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool canPresentUiOnContext(BuildContext context) {
  if (!context.mounted) return false;
  final flutterView = View.maybeOf(context);
  if (flutterView == null) return false;
  return WidgetsBinding.instance.platformDispatcher.views
      .any((view) => identical(view, flutterView));
}

void showSafeSnackBar(BuildContext context, SnackBar snackBar) {
  if (!canPresentUiOnContext(context)) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.showSnackBar(snackBar);
}

Future<T?> showSafeDialogOnActiveView<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool? requestFocus,
}) {
  if (!canPresentUiOnContext(context)) {
    return Future<T?>.value(null);
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior: traversalEdgeBehavior,
    requestFocus: requestFocus,
    builder: builder,
  );
}

Future<bool> copyTextWithManualFallbackDialog(
  BuildContext context, {
  required String text,
  required String successMessage,
  String dialogTitle = 'Copiar prompt manualmente',
  String dialogMessage =
      'Tu navegador bloqueo la copia automatica. Selecciona el texto y copialo manualmente.',
}) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return true;
    showSafeSnackBar(context, SnackBar(content: Text(successMessage)));
    return true;
  } catch (_) {
    if (!context.mounted) return false;
    if (!canPresentUiOnContext(context)) return false;

    final controller = TextEditingController(text: text);
    try {
      await showSafeDialogOnActiveView<void>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          return AlertDialog(
            title: Text(dialogTitle),
            content: SizedBox(
              width: 760,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dialogMessage),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: TextField(
                      controller: controller,
                      readOnly: true,
                      autofocus: true,
                      maxLines: null,
                      minLines: 12,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: controller.text.length,
                  );
                },
                child: const Text('Seleccionar todo'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  MaterialLocalizations.of(dialogContext).closeButtonLabel,
                ),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
    return false;
  }
}
