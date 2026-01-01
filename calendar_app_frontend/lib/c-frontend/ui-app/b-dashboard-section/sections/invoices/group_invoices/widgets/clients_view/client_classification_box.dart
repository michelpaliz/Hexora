import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientClassificationBox extends StatefulWidget {
  final List<String> entityTypes;
  final List<String> propertyKinds;
  final VoidCallback onManage;
  final bool initiallyExpanded;

  const ClientClassificationBox({
    super.key,
    required this.entityTypes,
    required this.propertyKinds,
    required this.onManage,
    this.initiallyExpanded = false,
  });

  @override
  State<ClientClassificationBox> createState() =>
      _ClientClassificationBoxState();
}

class _ClientClassificationBoxState extends State<ClientClassificationBox> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final hasAny =
        widget.entityTypes.isNotEmpty || widget.propertyKinds.isNotEmpty;
    final summaryParts = <String>[
      if (widget.entityTypes.isNotEmpty)
        '${l.clientEntityTypeLabel}: ${widget.entityTypes.length}',
      if (widget.propertyKinds.isNotEmpty)
        '${l.clientPropertyKindLabel}: ${widget.propertyKinds.length}',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.clientClassificationTitle,
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: widget.onManage,
                child: Text(l.clientClassificationManageCta),
              ),
              IconButton(
                tooltip: _expanded
                    ? l.clientClassificationCollapseTooltip
                    : l.clientClassificationExpandTooltip,
                onPressed: hasAny
                    ? () => setState(() => _expanded = !_expanded)
                    : null,
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                ),
              ),
            ],
          ),
          if (!_expanded && summaryParts.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              summaryParts.join(' • '),
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          if (_expanded) ...[
            const SizedBox(height: 8),
            if (widget.entityTypes.isNotEmpty) ...[
              Text(
                l.clientEntityTypeLabel,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              _ChipWrap(values: widget.entityTypes),
            ],
            if (widget.entityTypes.isNotEmpty &&
                widget.propertyKinds.isNotEmpty)
              const SizedBox(height: 10),
            if (widget.propertyKinds.isNotEmpty) ...[
              Text(
                l.clientPropertyKindLabel,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              _ChipWrap(values: widget.propertyKinds),
            ],
          ],
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> values;
  const _ChipWrap({required this.values});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 132),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in values)
                Chip(
                  label: Text(v),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
