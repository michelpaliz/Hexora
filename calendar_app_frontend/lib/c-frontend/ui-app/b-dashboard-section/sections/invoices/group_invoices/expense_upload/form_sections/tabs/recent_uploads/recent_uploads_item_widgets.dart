part of '../recent_uploads_tab.dart';

// OCR extraction confidence badge derived from field completeness (0–4 score).
class _OcrBadge extends StatelessWidget {
  final int score;
  const _OcrBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isLight = cs.brightness == Brightness.light;

    final Color color;
    final IconData icon;
    final String label;

    if (score >= 4) {
      color = isLight ? const Color(0xFF2E7D32) : const Color(0xFF81C784);
      icon = Icons.check_circle_outline_rounded;
      label = 'Extraído';
    } else if (score >= 3) {
      color = isLight ? const Color(0xFFE65100) : const Color(0xFFFFB74D);
      icon = Icons.warning_amber_rounded;
      label = 'Revisar';
    } else {
      color = cs.error;
      icon = Icons.error_outline_rounded;
      label = 'Incompleto';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.09),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: t.bodySmall.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Structured line-items card from a newline- or semicolon-delimited summary.
class _LineItemsCard extends StatelessWidget {
  final String linesSummary;
  final ColorScheme cs;
  final AppTypography t;
  final AppLocalizations l;

  const _LineItemsCard({
    required this.linesSummary,
    required this.cs,
    required this.t,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    // Try newline split first, fall back to semicolons
    final raw = linesSummary.trim();
    final lines = raw.contains('\n')
        ? raw.split('\n')
        : raw.contains(';')
            ? raw.split(';')
            : [raw];
    final nonEmpty = lines.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
            child: Row(
              children: [
                Icon(Icons.format_list_numbered,
                    size: 11, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  l.expenseUploadLinesTitle,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                    fontSize: 9,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
          for (int i = 0; i < nonEmpty.length; i++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: t.bodySmall.copyWith(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      nonEmpty[i],
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < nonEmpty.length - 1)
              Divider(
                  height: 1,
                  indent: 8,
                  endIndent: 8,
                  color: cs.outlineVariant.withValues(alpha: 0.22)),
          ],
        ],
      ),
    );
  }
}

// Collapsible section wrapping secondary _InfoBox chips.
class _ExpandableMetaSection extends StatefulWidget {
  final List<Widget> fields;
  final ColorScheme cs;
  final AppTypography t;

  const _ExpandableMetaSection({
    required this.fields,
    required this.cs,
    required this.t,
  });

  @override
  State<_ExpandableMetaSection> createState() => _ExpandableMetaSectionState();
}

class _ExpandableMetaSectionState extends State<_ExpandableMetaSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final t = widget.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle row
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _expanded ? 'Ocultar detalles' : 'Más detalles',
                  style: t.bodySmall.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: widget.fields,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final Color? color;
  final IconData? icon;

  const _StatusPill({
    required this.label,
    required this.cs,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final tone = color ?? cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: tone.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10.5, color: tone),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: tone,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseIdPill extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme cs;

  const _ExpenseIdPill({
    required this.label,
    required this.selected,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final isLight = cs.brightness == Brightness.light;
    final bg = selected
        ? (isLight
            ? const Color(0xFFEAF7EF)
            : Colors.green.shade700.withValues(alpha: 0.16))
        : (isLight
            ? const Color(0xFFF2F8F4)
            : Colors.green.shade600.withValues(alpha: 0.11));
    final border = isLight
        ? const Color(0xFFC5DEC9)
        : (selected
            ? Colors.green.shade300.withValues(alpha: 0.38)
            : Colors.green.shade400.withValues(alpha: 0.24));
    final fg = isLight ? const Color(0xFF3E7F52) : Colors.green.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _VatZeroPill extends StatelessWidget {
  final ColorScheme cs;

  const _VatZeroPill({required this.cs});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.tertiary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'IVA 0',
        style: t.bodySmall.copyWith(
          color: cs.onTertiaryContainer,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _DuplicateInvoicePill extends StatelessWidget {
  final ColorScheme cs;

  const _DuplicateInvoicePill({required this.cs});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.error.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'Dup',
        style: t.bodySmall.copyWith(
          color: cs.onErrorContainer,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _PotentialDuplicatePill extends StatelessWidget {
  final ColorScheme cs;

  const _PotentialDuplicatePill({required this.cs});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final isLight = cs.brightness == Brightness.light;
    final bg = isLight
        ? const Color(0xFFFFF2CC)
        : Colors.amber.shade700.withValues(alpha: 0.18);
    final border = isLight
        ? const Color(0xFFF4C152)
        : Colors.amber.shade400.withValues(alpha: 0.45);
    final fg = isLight ? const Color(0xFF9A5B00) : Colors.amber.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        'Pos dup',
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _ExpenseTypePill extends StatelessWidget {
  final ExpenseDocumentType type;
  final ColorScheme cs;

  const _ExpenseTypePill({
    required this.type,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    late final Color bg;
    late final Color border;
    late final Color fg;
    late final String label;

    switch (type) {
      case ExpenseDocumentType.advance:
        label = 'Anticipo';
        bg = cs.tertiaryContainer.withValues(alpha: 0.72);
        border = cs.tertiary.withValues(alpha: 0.35);
        fg = cs.onTertiaryContainer;
        break;
      case ExpenseDocumentType.finalExpense:
        label = 'Factura final';
        bg = cs.secondaryContainer.withValues(alpha: 0.78);
        border = cs.secondary.withValues(alpha: 0.35);
        fg = cs.onSecondaryContainer;
        break;
      case ExpenseDocumentType.standard:
        label = 'Estandar';
        bg = cs.surfaceContainerHighest.withValues(alpha: 0.5);
        border = cs.outlineVariant.withValues(alpha: 0.25);
        fg = cs.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _FileTypeIconWidget extends StatelessWidget {
  final String fileName;
  final ColorScheme cs;

  const _FileTypeIconWidget({required this.fileName, required this.cs});

  @override
  Widget build(BuildContext context) {
    final lower = fileName.toLowerCase();
    final isPdf = lower.endsWith('.pdf');
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.jpe');

    final icon = isPdf
        ? Icons.picture_as_pdf_outlined
        : isImage
            ? Icons.image_outlined
            : Icons.attach_file_rounded;
    final isLight = cs.brightness == Brightness.light;
    final color = isPdf
        ? const Color(0xFFEF4444)
        : isImage
            ? const Color(0xFF0F766E)
            : cs.onSurfaceVariant.withValues(alpha: 0.65);
    final bg = isPdf
        ? const Color(0xFFFFEBEE)
        : isImage
            ? const Color(0xFFE0F2F1)
            : cs.surfaceContainerHighest
                .withValues(alpha: isLight ? 0.55 : 0.28);
    final border = isPdf
        ? const Color(0xFFFFCDD2)
        : isImage
            ? const Color(0xFFB2DFDB)
            : cs.outlineVariant.withValues(alpha: 0.28);

    return Tooltip(
      message: fileName,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: border),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

class _ExpenseRowIconAction extends StatelessWidget {
  final String tooltip;
  final Widget icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ExpenseRowIconAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: 0.07)
                : cs.surfaceContainerHighest.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.13)
                  : cs.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: IconTheme(
            data: IconThemeData(
              color: enabled
                  ? color.withValues(alpha: 0.82)
                  : cs.onSurfaceVariant.withValues(alpha: 0.32),
              size: 16,
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme cs;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 9, color: cs.onSurfaceVariant),
              const SizedBox(width: 2),
              Text(
                label,
                style: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
