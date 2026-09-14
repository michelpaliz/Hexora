part of 'presupuesto_invoice_conversion_view.dart';

class _LinkedInvoiceCard extends StatelessWidget {
  const _LinkedInvoiceCard({
    required this.record,
    required this.isSpanish,
    this.onOpen,
  });

  final PresupuestoLinkedInvoiceRecord record;
  final bool isSpanish;
  final VoidCallback? onOpen;

  String _typeLabel(bool isSpanish) {
    if (record.isAdvance) return isSpanish ? 'Anticipo' : 'Advance';
    if (record.isFinal) return isSpanish ? 'Final' : 'Final';
    return isSpanish ? 'Estándar' : 'Standard';
  }

  String _statusLabel(bool isSpanish) {
    if (_isIssued) return isSpanish ? 'Emitida' : 'Issued';
    return isSpanish ? 'Borrador' : 'Draft';
  }

  bool get _isIssued {
    final normalized = record.status.trim().toLowerCase();
    return normalized.contains('issued') ||
        normalized.contains('accept') ||
        normalized.contains('approved');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _isIssued
                  ? cs.primaryContainer.withValues(alpha: 0.28)
                  : cs.secondaryContainer.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              record.isFinal
                  ? Icons.request_quote_outlined
                  : Icons.description_outlined,
              size: 18,
              color: _isIssued ? cs.primary : cs.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      record.displayNumber,
                      style: typo.bodyLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withValues(alpha: 0.26),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _typeLabel(isSpanish),
                        style: typo.bodySmall.copyWith(
                          color: cs.tertiary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${isSpanish ? 'ID' : 'ID'}: ${record.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.bodyMedium.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _isIssued
                            ? cs.tertiaryContainer.withValues(alpha: 0.4)
                            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _statusLabel(isSpanish),
                        style: typo.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _isIssued
                              ? cs.tertiary
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onOpen != null)
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSpanish ? 'Abrir' : 'Open',
                      style: typo.bodySmall.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: typo.bodySmall.copyWith(
              color: tone,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: typo.bodySmall.copyWith(
          fontWeight: FontWeight.w800,
          color: foreground,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _CenteredInfoState extends StatelessWidget {
  const _CenteredInfoState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 36,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: typo.bodyLarge.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: typo.bodyMedium.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: typo.bodySmall.copyWith(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
