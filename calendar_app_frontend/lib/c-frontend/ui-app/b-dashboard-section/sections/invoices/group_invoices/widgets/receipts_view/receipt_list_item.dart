import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ReceiptListItem extends StatefulWidget {
  final Receipt receipt;
  final GroupClient client;
  final VoidCallback? onTap;
  final Future<void> Function()? onPreview;
  final VoidCallback? onEdit;
  final VoidCallback? onIssue;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;

  const ReceiptListItem({
    super.key,
    required this.receipt,
    required this.client,
    this.onTap,
    this.onPreview,
    this.onEdit,
    this.onIssue,
    this.onDelete,
    this.onDownload,
  });

  @override
  State<ReceiptListItem> createState() => _ReceiptListItemState();
}

class _ReceiptListItemState extends State<ReceiptListItem> {
  bool _hovered = false;
  bool _previewing = false;

  Future<void> _runPreview() async {
    final onPreview = widget.onPreview;
    if (onPreview == null || _previewing) return;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    setState(() => _previewing = true);
    final notice = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(minutes: 1),
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEs
                  ? 'Preparando vista previa del PDF...'
                  : 'Preparing PDF preview...',
            ),
          ],
        ),
      ),
    );
    try {
      await onPreview();
    } finally {
      notice.close();
      if (mounted) setState(() => _previewing = false);
    }
  }

  void _showMobileActions(
    BuildContext context,
    AppLocalizations l,
    ColorScheme cs,
    AppTypography t,
    String number,
    String dateLabel,
    String totalLabel,
    bool issued,
    IconData iconData,
    Color iconColor,
    Color iconBg,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              // Receipt header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(iconData, color: iconColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.client.name,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$number · $dateLabel',
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      totalLabel,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
              if (widget.onPreview != null)
                ListTile(
                  enabled: !_previewing,
                  leading: _previewing
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                      : Icon(Icons.preview_outlined, color: cs.primary),
                  title: Text(
                    _previewing
                        ? (l.localeName.toLowerCase().startsWith('es')
                            ? 'Preparando vista previa...'
                            : 'Preparing preview...')
                        : l.preview,
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _runPreview();
                  },
                ),
              if (widget.onEdit != null)
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: cs.primary),
                  title: Text(l.edit),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    widget.onEdit!();
                  },
                ),
              if (widget.onDownload != null)
                ListTile(
                  leading:
                      Icon(Icons.download_outlined, color: cs.onSurfaceVariant),
                  title: Text(l.download),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    widget.onDownload!();
                  },
                ),
              if (widget.onIssue != null)
                ListTile(
                  leading: Icon(Icons.publish_outlined, color: cs.tertiary),
                  title: Text(
                    l.receiptIssueCta,
                    style: TextStyle(color: cs.tertiary),
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    widget.onIssue!();
                  },
                ),
              if (widget.onDelete != null) ...[
                Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.25)),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: cs.error),
                  title: Text(l.delete, style: TextStyle(color: cs.error)),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    widget.onDelete!();
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isMobile = MediaQuery.sizeOf(context).width < 640;

    final date = widget.receipt.registeredAt ?? widget.receipt.issueDate;
    final dateLabel = date != null
        ? DateFormat.yMMMd(l.localeName).add_Hm().format(date.toLocal())
        : l.receiptDateUnknown;
    final shortDateLabel = date != null
        ? DateFormat.yMMMd(l.localeName).format(date.toLocal())
        : l.receiptDateUnknown;

    final total = widget.receipt.total ??
        widget.receipt.lines.fold<num>(
          0,
          (sum, line) =>
              sum + ((line.total ?? (line.quantity * line.unitPrice))),
        );
    final money = NumberFormat.currency(locale: l.localeName, symbol: 'EUR');
    final totalLabel = money.format(total);

    final number = (widget.receipt.receiptNumber?.trim().isNotEmpty == true)
        ? widget.receipt.receiptNumber!.trim()
        : l.receiptDraftNumberPlaceholder;

    final status = (widget.receipt.status ?? 'draft').toLowerCase();
    final issued = status.contains('issue');

    final iconBg = issued
        ? cs.primary.withValues(alpha: 0.10)
        : cs.tertiary.withValues(alpha: 0.10);
    final iconColor = issued ? cs.primary : cs.tertiary;
    final iconData =
        issued ? Icons.task_alt_outlined : Icons.description_outlined;

    final lineCount = widget.receipt.lines.length;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 12,
            vertical: isMobile ? 10 : 10,
          ),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white
                : _hovered
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
                    : cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? cs.outlineVariant.withValues(alpha: 0.55)
                  : cs.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: isLight
                ? [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: _hovered ? 0.06 : 0.035),
                      blurRadius: _hovered ? 16 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status icon box
              Container(
                width: isMobile ? 30 : 32,
                height: isMobile ? 30 : 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(iconData, color: iconColor, size: isMobile ? 15 : 16),
              ),
              const SizedBox(width: 9),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1: mobile shows name + amount inline; desktop name only
                    if (isMobile)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.client.name,
                              style: t.bodyMedium.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            totalLabel,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        widget.client.name,
                        style: t.bodyMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),

                    if (isMobile) ...[
                      // Mobile line 2: number · short date | lines chip
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$number · $shortDateLabel',
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _LinesChip(
                            count: lineCount,
                            cs: cs,
                            t: t,
                            label: l.receiptLinesTitle,
                          ),
                        ],
                      ),
                    ] else ...[
                      // Desktop line 2: number · date (line count shown as chip in right panel)
                      Text(
                        '$number · $dateLabel',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Right side
              if (isMobile) ...[
                // Status icon + ⋮ menu button
                Icon(
                  issued ? Icons.task_alt_rounded : Icons.edit_note_rounded,
                  size: 14,
                  color: issued
                      ? cs.primary
                      : cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 2),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showMobileActions(
                    context,
                    l,
                    cs,
                    t,
                    number,
                    shortDateLabel,
                    totalLabel,
                    issued,
                    iconData,
                    iconColor,
                    iconBg,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ] else ...[
                // Desktop: amount + lines chip + status pill + actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      totalLabel,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _LinesChip(
                      count: lineCount,
                      cs: cs,
                      t: t,
                      label: l.receiptLinesTitle,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 14,
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 8),
                    // Status pill with icon + label
                    Tooltip(
                      message: issued ? l.statusIssued : l.statusDraft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconData, size: 12, color: iconColor),
                            const SizedBox(width: 4),
                            Text(
                              issued ? l.statusIssued : l.statusDraft,
                              style: t.caption.copyWith(
                                color: iconColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 14,
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 4),
                    // Action buttons — more visible at rest
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 130),
                      opacity: _hovered ? 1.0 : 0.45,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onPreview != null)
                            _ActionBtn(
                              icon: Icons.visibility_outlined,
                              tooltip: _previewing
                                  ? (l.localeName.toLowerCase().startsWith('es')
                                      ? 'Preparando vista previa...'
                                      : 'Preparing preview...')
                                  : l.preview,
                              color: cs.primary,
                              loading: _previewing,
                              onTap: _runPreview,
                            ),
                          if (widget.onEdit != null)
                            _ActionBtn(
                              icon: Icons.edit_outlined,
                              tooltip: l.edit,
                              color: cs.primary,
                              onTap: widget.onEdit!,
                            ),
                          if (widget.onDownload != null)
                            _ActionBtn(
                              icon: Icons.download_rounded,
                              tooltip: l.download,
                              color: cs.onSurfaceVariant,
                              onTap: widget.onDownload!,
                            ),
                          if (widget.onIssue != null)
                            _ActionBtn(
                              icon: Icons.publish_outlined,
                              tooltip: l.receiptIssueCta,
                              color: cs.tertiary,
                              onTap: widget.onIssue!,
                            ),
                          if ((widget.onPreview != null ||
                                  widget.onEdit != null ||
                                  widget.onIssue != null ||
                                  widget.onDownload != null) &&
                              widget.onDelete != null)
                            Container(
                              width: 1,
                              height: 14,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                          if (widget.onDelete != null)
                            _ActionBtn(
                              icon: Icons.delete_outline_rounded,
                              tooltip: l.delete,
                              color: cs.error,
                              onTap: widget.onDelete!,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Lines count chip ───────────────────────────────────────────────────────────

class _LinesChip extends StatelessWidget {
  final int count;
  final ColorScheme cs;
  final AppTypography t;
  final String label;

  const _LinesChip({
    required this.count,
    required this.cs,
    required this.t,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final chipLabel = isEs
        ? '$count línea${count == 1 ? '' : 's'}'
        : '$count line${count == 1 ? '' : 's'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Text(
        chipLabel,
        style: t.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ── Desktop action button ──────────────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: widget.loading
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.loading ? null : widget.onTap,
          borderRadius: BorderRadius.circular(7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: _hovered ? 0.16 : 0.07),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _hovered
                    ? widget.color.withValues(alpha: 0.30)
                    : Colors.transparent,
              ),
            ),
            child: widget.loading
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.color,
                    ),
                  )
                : Icon(
                    widget.icon,
                    size: 14,
                    color:
                        widget.color.withValues(alpha: _hovered ? 1.0 : 0.75),
                  ),
          ),
        ),
      ),
    );
  }
}
