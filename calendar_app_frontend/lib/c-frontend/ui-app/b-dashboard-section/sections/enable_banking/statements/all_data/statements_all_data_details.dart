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

    String rawIndex(int index) {
      final raw = entry['raw'];
      if (raw is List && raw.length > index) {
        final value = raw[index];
        if (value != null) return value.toString();
      }
      return '';
    }

    final rawAmount = rawIndex(4);
    final rawBalance = rawIndex(5);
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
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      pageBuilder: (dialogContext, _, __) {
        final t = AppTypography.of(dialogContext);
        final width = MediaQuery.of(dialogContext).size.width;
        final panelWidth = width < 520 ? width : 460.0;
        final cs = Theme.of(dialogContext).colorScheme;
        final isLight =
            Theme.of(dialogContext).brightness == Brightness.light;
        final accentColor = amountIsNegative ? cs.error : cs.primary;

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

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: panelWidth,
              height: double.infinity,
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isLight ? 0.14 : 0.38),
                    blurRadius: 48,
                    offset: const Offset(-6, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                      decoration: BoxDecoration(
                        color: accentColor
                            .withValues(alpha: isLight ? 0.05 : 0.08),
                        border: Border(
                          bottom: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.45),
                          ),
                          left: BorderSide(color: accentColor, width: 3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              amountIsNegative
                                  ? Icons.arrow_circle_down_rounded
                                  : Icons.arrow_circle_up_rounded,
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detalle del movimiento',
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        formatEuro(amount),
                                        style: t.titleLarge.copyWith(
                                          color: accentColor,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (amountChipLabel != null) ...[
                                      const SizedBox(width: 8),
                                      _AmountChip(
                                        label: amountChipLabel,
                                        isExpense: amountIsNegative,
                                      ),
                                    ],
                                  ],
                                ),
                                if (desc.isNotEmpty)
                                  Text(
                                    desc,
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: l.close,
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
                            icon: Icon(Icons.close,
                                color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),

                    // ── Scrollable body ──────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Lote/ID
                            _SectionCard(
                              cs: cs,
                              isLight: isLight,
                              child: Row(
                                children: [
                                  Icon(Icons.tag_rounded,
                                      size: 14,
                                      color: cs.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Lote/ID',
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Tooltip(
                                      message: batchId ?? '-',
                                      child: Text(
                                        (batchId == null ||
                                                batchId.isEmpty)
                                            ? '-'
                                            : batchId,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.bodySmall.copyWith(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                  CopyIconButton(value: batchId ?? ''),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Dates
                            _SectionCard(
                              cs: cs,
                              isLight: isLight,
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _DetailCell(
                                        item: _DetailItem(
                                          label: 'Fecha operación',
                                          value:
                                              StatementsFormatters.formatDate(
                                                  dialogContext, date),
                                          icon: Icons.calendar_today_outlined,
                                        ),
                                      ),
                                    ),
                                    VerticalDivider(
                                      width: 24,
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.4),
                                    ),
                                    Expanded(
                                      child: _DetailCell(
                                        item: _DetailItem(
                                          label: 'Fecha valor',
                                          value:
                                              StatementsFormatters.formatDate(
                                                  dialogContext, valueDate),
                                          icon: Icons.event_outlined,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Description + Details
                            _SectionCard(
                              cs: cs,
                              isLight: isLight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailCell(
                                    item: _DetailItem(
                                      label:
                                          l.statementsHeaderDescription,
                                      value:
                                          desc.isEmpty ? '-' : desc,
                                      icon: Icons.text_snippet_outlined,
                                    ),
                                  ),
                                  if (details.isNotEmpty) ...[
                                    Divider(
                                      height: 20,
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.4),
                                    ),
                                    _DetailCell(
                                      item: _DetailItem(
                                        label: l.statementsHeaderDetails,
                                        value: details,
                                        icon: Icons.info_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Client + Balance
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _SectionCard(
                                    cs: cs,
                                    isLight: isLight,
                                    child: _DetailCell(
                                      item: _DetailItem(
                                        label: l.statementsHeaderClient,
                                        value: clientLabel,
                                        icon:
                                            Icons.person_outline_rounded,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _SectionCard(
                                    cs: cs,
                                    isLight: isLight,
                                    child: _DetailCell(
                                      item: _DetailItem(
                                        label: l.statementsHeaderBalance,
                                        value: formatEuro(balance),
                                        icon: Icons
                                            .account_balance_wallet_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Datos en bruto
                            _RawDataSection(
                              rawJson: rawJson,
                              entry: entry,
                              copyValue: copyValue,
                              cs: cs,
                              t: t,
                              isLight: isLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    required this.cs,
    required this.isLight,
  });

  final Widget child;
  final ColorScheme cs;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight
            ? cs.surfaceContainerHighest.withValues(alpha: 0.32)
            : cs.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

// ── Detail cell ───────────────────────────────────────────────────────────────

class _DetailItem {
  const _DetailItem({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;
}

class _DetailCell extends StatelessWidget {
  const _DetailCell({required this.item});

  final _DetailItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (item.icon != null) ...[
              Icon(item.icon,
                  size: 11,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.65)),
              const SizedBox(width: 4),
            ],
            Text(
              item.label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: t.bodyMedium.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Amount chip ───────────────────────────────────────────────────────────────

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.label, required this.isExpense});

  final String label;
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final color = isExpense ? cs.error : cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: t.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── Raw data section ──────────────────────────────────────────────────────────

class _RawDataSection extends StatelessWidget {
  const _RawDataSection({
    required this.rawJson,
    required this.entry,
    required this.copyValue,
    required this.cs,
    required this.t,
    required this.isLight,
  });

  final String rawJson;
  final Map<String, dynamic> entry;
  final Future<void> Function(String) copyValue;
  final ColorScheme cs;
  final AppTypography t;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: isLight
              ? cs.surfaceContainerHighest.withValues(alpha: 0.32)
              : cs.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding:
              const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(Icons.data_object_rounded,
              size: 16, color: cs.onSurfaceVariant),
          title: Text(
            'Datos en bruto',
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _CopyChip(
                  label: 'JSON',
                  icon: Icons.code_rounded,
                  onTap: () => copyValue(rawJson),
                ),
                _CopyChip(
                  label: 'ID',
                  icon: Icons.fingerprint_rounded,
                  onTap: () =>
                      copyValue(entry['_id']?.toString() ?? ''),
                ),
                _CopyChip(
                  label: 'Signature',
                  icon: Icons.key_rounded,
                  onTap: () =>
                      copyValue(entry['signature']?.toString() ?? ''),
                ),
                _CopyChip(
                  label: 'Merchant',
                  icon: Icons.store_outlined,
                  onTap: () => copyValue(
                      entry['merchantNormalized']?.toString() ?? ''),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight
                    ? const Color(0xFF1E1E2E)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                rawJson,
                style: t.bodySmall.copyWith(
                  fontFamily: 'monospace',
                  height: 1.4,
                  fontSize: 11,
                  color: isLight
                      ? const Color(0xFFCDD6F4)
                      : cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Copy chip button ──────────────────────────────────────────────────────────

class _CopyChip extends StatelessWidget {
  const _CopyChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: cs.primary.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: cs.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: t.caption.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Copy icon button (public — used by other files) ───────────────────────────

class CopyIconButton extends StatelessWidget {
  const CopyIconButton({super.key, required this.value});

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
      icon: const Icon(Icons.copy, size: 16),
    );
  }
}
