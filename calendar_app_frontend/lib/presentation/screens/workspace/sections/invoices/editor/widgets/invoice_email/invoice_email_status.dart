part of '../invoice_email_widgets.dart';

class EmailStatusBadge extends StatelessWidget {
  final String status;
  const EmailStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final normalized = status.toLowerCase();
    Color bg = cs.surfaceContainerHighest;
    Color fg = cs.onSurfaceVariant;
    if (normalized.contains('sent') ||
        normalized.contains('delivered') ||
        normalized.contains('success')) {
      bg = cs.primaryContainer;
      fg = cs.onPrimaryContainer;
    } else if (normalized.contains('fail') ||
        normalized.contains('error') ||
        normalized.contains('bounce')) {
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: t.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class EmailLogRow extends StatelessWidget {
  final Map<String, dynamic> log;
  final String dateLabel;
  final bool canResend;
  final bool resending;
  final VoidCallback onResend;
  final VoidCallback onViewDetails;

  const EmailLogRow({
    super.key,
    required this.log,
    required this.dateLabel,
    required this.canResend,
    required this.resending,
    required this.onResend,
    required this.onViewDetails,
  });

  String _formatRecipients(dynamic v) {
    if (v == null) return '-';
    if (v is List) {
      return v.whereType<String>().join(', ');
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final status = (log['status'] ?? log['state'] ?? 'unknown').toString();
    final to = _formatRecipients(log['to'] ?? log['toEmail']);
    final cc = _formatRecipients(log['cc'] ?? log['ccEmail']);
    final subject = (log['subject'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EmailStatusBadge(status: status),
              const Spacer(),
              Text(
                dateLabel,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${l.invoiceEmailLogToLabel}: $to',
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          if (cc != '-' && cc.trim().isNotEmpty)
            Text(
              '${l.invoiceEmailLogCcLabel}: $cc',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          const SizedBox(height: 4),
          Text(
            subject,
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: onViewDetails,
                child: Text(l.invoiceEmailViewDetailsCta),
              ),
              const Spacer(),
              if (canResend)
                TextButton.icon(
                  onPressed: resending ? null : onResend,
                  icon: resending
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    resending
                        ? l.invoiceEmailResendingLabel
                        : l.invoiceEmailResendCta,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
