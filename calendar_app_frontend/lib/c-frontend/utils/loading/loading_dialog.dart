import 'package:flutter/material.dart';

class LoadingDialog {
  static Future<void> show(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
    Color? barrierColor,
    Color? progressIndicatorColor,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Future.microtask(() {
      return showDialog<void>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor ?? Colors.black54,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => barrierDismissible,
            child: AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressIndicatorColor ?? theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    child: Text(
                      message ?? 'Please wait...',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
