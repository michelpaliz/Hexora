import 'package:flutter/material.dart';

// ─── Typed snack helpers ──────────────────────────────────────────────────────

void showSuccessSnack(
  BuildContext context,
  String message, {
  String? title,
  String? actionLabel,
  SnackBarAction? action,
}) =>
    _emit(
      context,
      message,
      _SnackKind.success,
      title: title,
      actionLabel: actionLabel,
      action: action,
    );

void showErrorSnack(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) =>
    _emit(context, message, _SnackKind.error, action: action);

void showInfoSnack(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) =>
    _emit(context, message, _SnackKind.info, action: action);

// ─── Internal ─────────────────────────────────────────────────────────────────

enum _SnackKind { success, error, info }

void _emit(
  BuildContext context,
  String message,
  _SnackKind kind, {
  String? title,
  String? actionLabel,
  SnackBarAction? action,
}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      _build(
        context,
        message,
        kind,
        title: title,
        actionLabel: actionLabel,
        action: action,
      ),
    );
}

SnackBar _build(
  BuildContext context,
  String message,
  _SnackKind kind, {
  String? title,
  String? actionLabel,
  SnackBarAction? action,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final (Color bg, Color fg, IconData icon) = switch (kind) {
    _SnackKind.success => (
        isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
        cs.onSurface,
        Icons.check_circle_rounded,
      ),
    _SnackKind.error => (
        cs.error,
        cs.onError,
        Icons.cancel_rounded,
      ),
    _SnackKind.info => (
        isDark ? cs.primaryContainer : cs.primary,
        isDark ? cs.onPrimaryContainer : cs.onPrimary,
        Icons.info_rounded,
      ),
  };

  final hasTitle = title != null && title.trim().isNotEmpty;
  final screenWidth = MediaQuery.sizeOf(context).width;
  final snackWidth = screenWidth < 472 ? screenWidth - 32 : 440.0;
  final resolvedAction = action ??
      (actionLabel == null || actionLabel.trim().isEmpty
          ? null
          : SnackBarAction(
              label: actionLabel,
              textColor: bg,
              onPressed: () {
                ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
              },
            ));

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    width: kind == _SnackKind.success ? snackWidth : null,
    backgroundColor: kind == _SnackKind.success ? cs.surface : bg,
    elevation: kind == _SnackKind.success ? 10 : 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kind == _SnackKind.success ? 18 : 12),
      side: kind == _SnackKind.success
          ? BorderSide(color: bg.withValues(alpha: isDark ? 0.32 : 0.18))
          : BorderSide.none,
    ),
    padding: kind == _SnackKind.success
        ? const EdgeInsets.fromLTRB(14, 12, 8, 12)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    action: resolvedAction,
    content: Row(
      children: [
        Container(
          width: kind == _SnackKind.success ? 36 : 18,
          height: kind == _SnackKind.success ? 36 : 18,
          decoration: kind == _SnackKind.success
              ? BoxDecoration(
                  color: bg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child:
              Icon(icon, color: kind == _SnackKind.success ? bg : fg, size: 18),
        ),
        SizedBox(width: kind == _SnackKind.success ? 12 : 10),
        Expanded(
          child: hasTitle
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kind == _SnackKind.success
                            ? cs.onSurfaceVariant
                            : fg,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Text(
                  message,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ],
    ),
  );
}
