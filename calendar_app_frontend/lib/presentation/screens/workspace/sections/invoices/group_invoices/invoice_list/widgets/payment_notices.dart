part of '../../widgets/group_invoices_invoices_view.dart';

class _UnlinkedInvoicesNotice extends StatelessWidget {
  const _UnlinkedInvoicesNotice({
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final hasError = (error ?? '').trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: (hasError ? cs.error : cs.tertiary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (hasError ? cs.error : cs.tertiary).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          if (loading)
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.tertiary,
              ),
            )
          else
            Icon(
              hasError ? Icons.error_outline_rounded : Icons.link_off_rounded,
              size: 16,
              color: hasError ? cs.error : cs.tertiary,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasError
                  ? error!.trim()
                  : (isSpanish
                      ? 'Facturas emitidas sin vínculo bancario: el pago no está confirmado por extracto.'
                      : 'Issued invoices without a bank link: payment is not confirmed by statement.'),
              style: t.bodySmall.copyWith(
                color: hasError ? cs.error : cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (hasError)
            TextButton(
              onPressed: loading ? null : onRetry,
              child: Text(isSpanish ? 'Reintentar' : 'Retry'),
            ),
        ],
      ),
    );
  }
}

class _PaymentSuggestionStrip extends StatelessWidget {
  const _PaymentSuggestionStrip({
    required this.suggestion,
    required this.loading,
  });

  final InvoicePaymentSuggestion? suggestion;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    if (loading && suggestion == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 42, top: 4),
        child: Row(
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isSpanish
                  ? 'Buscando pagos probables...'
                  : 'Finding likely payments...',
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (suggestion == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 42, top: 4),
        child: Text(
          isSpanish
              ? 'Sin pago sugerido por ahora.'
              : 'No suggested payment yet.',
          style: t.bodySmall.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final alreadyLinked = suggestion!.alreadyLinked;
    final linkedText = [
      if ((suggestion!.linkedInvoiceNumber ?? '').trim().isNotEmpty)
        suggestion!.linkedInvoiceNumber!.trim(),
      if ((suggestion!.linkedInvoiceClientName ?? '').trim().isNotEmpty)
        suggestion!.linkedInvoiceClientName!.trim(),
    ].join(' Â· ');
    final reason = (suggestion!.reason ?? '').trim();
    final confidence = (suggestion!.confidenceLabel ?? '').trim().isNotEmpty
        ? suggestion!.confidenceLabel!.trim()
        : (suggestion!.confidence == null
            ? ''
            : '${(suggestion!.confidence! * 100).round()}%');

    Widget miniChip({
      required IconData icon,
      required String text,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: t.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 42, top: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: (alreadyLinked ? cs.secondary : cs.tertiary)
                .withValues(alpha: 0.24),
          ),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            miniChip(
              icon: Icons.auto_fix_high_rounded,
              text: isSpanish ? 'Pago sugerido' : 'Suggested payment',
              color: cs.tertiary,
            ),
            if ((suggestion!.entryDate ?? '').trim().isNotEmpty)
              Text(
                suggestion!.entryDate!.trim(),
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if ((suggestion!.amountFormatted ?? '').trim().isNotEmpty)
              Text(
                suggestion!.amountFormatted!.trim(),
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            if ((suggestion!.concept ?? '').trim().isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  suggestion!.concept!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (confidence.isNotEmpty)
              miniChip(
                icon: Icons.speed_rounded,
                text: confidence,
                color: cs.primary,
              ),
            if (alreadyLinked)
              miniChip(
                icon: Icons.swap_horiz_rounded,
                text: linkedText.isEmpty
                    ? (isSpanish ? 'Ya vinculado' : 'Already linked')
                    : (isSpanish
                        ? 'Ya vinculado a $linkedText'
                        : 'Already linked to $linkedText'),
                color: cs.secondary,
              ),
            if (reason.isNotEmpty)
              Tooltip(
                message: reason,
                child: miniChip(
                  icon: Icons.info_outline_rounded,
                  text: isSpanish ? 'Por qué' : 'Why',
                  color: cs.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
