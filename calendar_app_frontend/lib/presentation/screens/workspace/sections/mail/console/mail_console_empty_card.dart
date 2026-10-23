part of '../mail_console_screen.dart';

class _MailReadingEmptyState extends StatelessWidget {
  const _MailReadingEmptyState();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 78,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 54,
                  color: cs.primary.withValues(alpha: 0.28),
                ),
                Positioned(
                  right: 13,
                  top: 8,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 17,
                    color: cs.primary.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.localeName.startsWith('es')
                ? 'Selecciona un correo para leerlo'
                : 'Select an email to read it',
            style: t.titleLarge.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.localeName.startsWith('es')
                ? 'El contenido del correo aparecerá aquí.'
                : 'The email content will appear here.',
            style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Card(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: cs.onSurfaceVariant, size: 30),
                  const SizedBox(height: 8),
                ],
                Text(
                  title,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onAction,
                    child: Text(
                      actionLabel!,
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
