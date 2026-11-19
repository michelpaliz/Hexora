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
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _isIssued
                  ? cs.primaryContainer.withValues(alpha: 0.28)
                  : cs.secondaryContainer.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              record.isFinal
                  ? Icons.request_quote_outlined
                  : Icons.description_outlined,
              size: 15,
              color: _isIssued ? cs.primary : cs.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.displayNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.bodyMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withValues(alpha: 0.26),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _typeLabel(isSpanish),
                        style: typo.bodySmall.copyWith(
                          fontSize: 10,
                          color: cs.tertiary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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
                          color: _isIssued ? cs.tertiary : cs.onSurfaceVariant,
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
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

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
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewTabToggle extends StatelessWidget {
  const _PreviewTabToggle({
    required this.selectedIndex,
    required this.isSpanish,
    required this.onChanged,
  });

  final int selectedIndex;
  final bool isSpanish;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    Widget tab(int index, IconData icon, String label) {
      final selected = selectedIndex == index;
      return GestureDetector(
        onTap: () => onChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.4)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: typo.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tab(
            0,
            Icons.picture_as_pdf_outlined,
            isSpanish ? 'Presupuesto' : 'Proposal',
          ),
          tab(
            1,
            Icons.receipt_long_outlined,
            isSpanish ? 'Factura' : 'Invoice',
          ),
        ],
      ),
    );
  }
}

class _SummaryField extends StatelessWidget {
  const _SummaryField({
    required this.label,
    required this.value,
    required this.typo,
    required this.cs,
  });

  final String label;
  final String value;
  final AppTypography typo;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: typo.bodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value.isEmpty ? '—' : value,
          style: typo.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SummaryAmountRow extends StatelessWidget {
  const _SummaryAmountRow({
    required this.label,
    required this.value,
    required this.typo,
    required this.cs,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final AppTypography typo;
  final ColorScheme cs;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              fontSize: emphasized ? 12 : 11,
            ),
          ),
        ),
        Text(
          value,
          style: typo.bodySmall.copyWith(
            color: emphasized ? cs.primary : cs.onSurface,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            fontSize: emphasized ? 14 : 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
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
