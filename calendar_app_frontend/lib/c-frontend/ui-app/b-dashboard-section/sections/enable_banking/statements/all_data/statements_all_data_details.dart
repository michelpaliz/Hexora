import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../statements_controller.dart';
import '../statements_formatters.dart';
import '../statements_shared.dart';

class StatementsAllDataDetails {
  static Future<void> show(
    BuildContext context,
    AppLocalizations l,
    Map<String, dynamic> entry,
    StatementsController controller,
  ) async {
    final batchId =
        (entry['_batchId'] ?? entry['_id'] ?? entry['id'] ?? entry['batchId'])
            ?.toString()
            .trim();
    final date = StatementsShared.entryText(entry, ['date']);
    final valueDate = StatementsShared.entryText(entry, ['valueDate']);
    final desc = StatementsShared.entryText(entry, ['description']);
    final details = StatementsShared.entryText(entry, ['details']);
    final clientLabel = StatementsShared.clientLabel(l, controller, entry);
    String _rawIndex(Map<String, dynamic> entry, int index) {
      final raw = entry['raw'];
      if (raw is List && raw.length > index) {
        final value = raw[index];
        if (value != null) return value.toString();
      }
      return '';
    }

    final rawAmount = _rawIndex(entry, 4);
    final rawBalance = _rawIndex(entry, 5);
    final amount = rawAmount.isNotEmpty
        ? rawAmount
        : StatementsShared.entryText(entry, ['amount']);
    final balance = rawBalance.isNotEmpty
        ? rawBalance
        : StatementsShared.entryText(entry, ['balance']);
    final amountValue = StatementsFormatters.parseAmount(amount);
    final amountIsNegative = (amountValue ?? 0) < 0;
    final amountChipLabel = amountValue == null || amountValue == 0
        ? null
        : amountIsNegative
            ? 'Gasto'
            : 'Ingreso';
    final rawJson = const JsonEncoder.withIndent('  ').convert(entry);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l.close,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) {
        final typography = AppTypography.of(dialogContext);
        final width = MediaQuery.of(dialogContext).size.width;
        final panelWidth = width < 520 ? width : 460.0;
        final cs = Theme.of(dialogContext).colorScheme;

        String formatEuro(String raw) {
          if (raw.trim().isEmpty) return '-';
          final formatted =
              StatementsFormatters.formatAmount(dialogContext, raw);
          if (formatted.isEmpty) return '-';
          return '$formatted €';
        }

        Future<void> copyValue(String value) async {
          if (value.trim().isEmpty) return;
          await Clipboard.setData(ClipboardData(text: value));
          if (!dialogContext.mounted) return;
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(content: Text('Copiado')),
          );
        }

        final detailItems = <_DetailItem>[
          _DetailItem(
            label: 'Fecha operacion',
            value: StatementsFormatters.formatDate(dialogContext, date),
          ),
          _DetailItem(
            label: 'Fecha valor',
            value: StatementsFormatters.formatDate(dialogContext, valueDate),
          ),
          _DetailItem(
            label: l.statementsHeaderDescription,
            value: desc.isEmpty ? '-' : desc,
          ),
          _DetailItem(
            label: l.statementsHeaderDetails,
            value: details.isEmpty ? '-' : details,
          ),
          _DetailItem(
            label: l.statementsHeaderClient,
            value: clientLabel,
          ),
          _DetailItem(
            label: l.statementsHeaderAmount,
            value: formatEuro(amount),
            valueAlign: TextAlign.right,
            valueColor: amountIsNegative ? cs.error : cs.primary,
            trailing: amountChipLabel == null
                ? null
                : _AmountChip(label: amountChipLabel),
          ),
          _DetailItem(
            label: l.statementsHeaderBalance,
            value: formatEuro(balance),
            valueAlign: TextAlign.right,
          ),
        ];
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Theme.of(dialogContext).colorScheme.surface,
            elevation: 12,
            child: SizedBox(
              width: panelWidth,
              height: double.infinity,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Detalle del movimiento',
                              style: typography.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: l.close,
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Lote/ID', style: typography.bodySmall),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Tooltip(
                              message: batchId ?? '-',
                              child: Text(
                                (batchId == null || batchId.isEmpty)
                                    ? '-'
                                    : batchId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: typography.bodyMedium,
                              ),
                            ),
                          ),
                          CopyIconButton(value: batchId ?? ''),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DetailsGrid(items: detailItems),
                      const SizedBox(height: 16),
                      Theme(
                        data: Theme.of(dialogContext).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: EdgeInsets.zero,
                          title: Text(
                            'Datos en bruto',
                            style: typography.bodyMedium,
                          ),
                          children: [
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () => copyValue(rawJson),
                                  child: const Text('Copiar JSON'),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      copyValue(entry['_id']?.toString() ?? ''),
                                  child: const Text('Copiar _id'),
                                ),
                                OutlinedButton(
                                  onPressed: () => copyValue(
                                      entry['signature']?.toString() ?? ''),
                                  child: const Text('Copiar signature'),
                                ),
                                OutlinedButton(
                                  onPressed: () => copyValue(
                                      entry['merchantNormalized']?.toString() ??
                                          ''),
                                  child:
                                      const Text('Copiar merchantNormalized'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                rawJson,
                                style: typography.bodySmall.copyWith(
                                  fontFamily: 'monospace',
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailItem {
  const _DetailItem({
    required this.label,
    required this.value,
    this.valueAlign = TextAlign.left,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String value;
  final TextAlign valueAlign;
  final Color? valueColor;
  final Widget? trailing;
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.items});

  final List<_DetailItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        final columns = isNarrow ? 1 : 2;
        final gap = 16.0;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: 12,
          children: items
              .map((item) => SizedBox(
                    width: itemWidth,
                    child: _DetailCell(item: item),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _DetailCell extends StatelessWidget {
  const _DetailCell({required this.item});

  final _DetailItem item;

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: typography.bodySmall.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: item.valueAlign == TextAlign.right
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: item.valueAlign,
                  style: typography.bodyMedium.copyWith(
                    color: item.valueColor ?? cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (item.trailing != null) ...[
              const SizedBox(width: 8),
              item.trailing!,
            ],
          ],
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        label,
        style: typography.caption.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class CopyIconButton extends StatelessWidget {
  const CopyIconButton({
    super.key,
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    final disabled = value.trim().isEmpty;
    return IconButton(
      tooltip: 'Copiar',
      onPressed: disabled
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copiado')),
              );
            },
      icon: const Icon(Icons.copy, size: 18),
    );
  }
}
