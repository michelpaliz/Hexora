import 'package:flutter/material.dart';

import 'error_message.dart';

// ─── Typed snack helpers ──────────────────────────────────────────────────────
//
// One feedback style across Hexora: a floating card with a coloured icon tile,
// an optional bold title saying *what* happened and a message saying *why* or
// what to do next. Errors can carry technical [details], shown on demand.

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
  String? title,
  String? details,
  SnackBarAction? action,
}) =>
    _emit(context, message, _SnackKind.error,
        title: title, details: details, action: action);

void showInfoSnack(
  BuildContext context,
  String message, {
  String? title,
  SnackBarAction? action,
}) =>
    _emit(context, message, _SnackKind.info, title: title, action: action);

/// Error snack for a caught exception: [title] states what failed ("No se
/// pudo guardar el cliente"), the message explains why in plain language and
/// "Detalles" reveals the technical cause.
void showFailureSnack(
  BuildContext context,
  Object error, {
  required String title,
  SnackBarAction? action,
}) {
  final friendly = describeError(context, error);
  showErrorSnack(context, friendly.message,
      title: title, details: friendly.details, action: action);
}

// ─── Internal ─────────────────────────────────────────────────────────────────

enum _SnackKind { success, error, info }

void _emit(
  BuildContext context,
  String message,
  _SnackKind kind, {
  String? title,
  String? details,
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
        details: details,
        actionLabel: actionLabel,
        action: action,
      ),
    );
}

void _showDetails(
    BuildContext context, String? title, String message, String details) {
  final es = Localizations.maybeLocaleOf(context)?.languageCode == 'es';
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.error_outline_rounded,
          color: Theme.of(dialogContext).colorScheme.error),
      title: Text(title ?? (es ? 'Detalles del error' : 'Error details')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(dialogContext)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                details,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(MaterialLocalizations.of(dialogContext).closeButtonLabel),
        ),
      ],
    ),
  );
}

SnackBar _build(
  BuildContext context,
  String message,
  _SnackKind kind, {
  String? title,
  String? details,
  String? actionLabel,
  SnackBarAction? action,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final es = Localizations.maybeLocaleOf(context)?.languageCode == 'es';

  final (Color accent, IconData icon) = switch (kind) {
    _SnackKind.success => (
        isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
        Icons.check_circle_rounded,
      ),
    _SnackKind.error => (
        isDark ? const Color(0xFFFF8A80) : cs.error,
        Icons.error_rounded,
      ),
    _SnackKind.info => (
        cs.primary,
        Icons.info_rounded,
      ),
  };

  final hasTitle = title != null && title.trim().isNotEmpty;
  final hasDetails = details != null && details.trim().isNotEmpty;
  final dismissLabel = action == null &&
          !hasDetails &&
          actionLabel != null &&
          actionLabel.trim().isNotEmpty
      ? actionLabel.trim()
      : null;
  final screenWidth = MediaQuery.sizeOf(context).width;
  final snackWidth = screenWidth < 512 ? screenWidth - 32 : 480.0;
  final resolvedAction = action ??
      (hasDetails
          ? SnackBarAction(
              label: es ? 'Detalles' : 'Details',
              textColor: accent,
              onPressed: () =>
                  _showDetails(context, title, message, details.trim()),
            )
          : null);

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    width: snackWidth,
    backgroundColor: cs.surface,
    elevation: 10,
    // Errors stay long enough to be read; success/info stay brief.
    duration: kind == _SnackKind.error
        ? const Duration(seconds: 8)
        : const Duration(seconds: 4),
    showCloseIcon: kind == _SnackKind.error,
    closeIconColor: cs.onSurfaceVariant,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: accent.withValues(alpha: isDark ? 0.40 : 0.25)),
    ),
    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
    action: resolvedAction,
    content: Row(
      crossAxisAlignment:
          hasTitle ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasTitle) ...[
                Text(
                  title.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasTitle ? cs.onSurfaceVariant : cs.onSurface,
                  fontSize: hasTitle ? 12.5 : 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (dismissLabel != null) ...[
          const SizedBox(width: 6),
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar(),
            style: TextButton.styleFrom(
              foregroundColor: accent,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(dismissLabel),
          ),
        ],
      ],
    ),
  );
}
