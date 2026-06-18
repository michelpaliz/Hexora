import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientListItem extends StatefulWidget {
  final GroupClient client;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  final TextStyle nameStyle;
  final TextStyle metaStyle;

  const ClientListItem({
    super.key,
    required this.client,
    this.onTap,
    this.onDelete,
    required this.nameStyle,
    required this.metaStyle,
  });

  @override
  State<ClientListItem> createState() => _ClientListItemState();
}

class _ClientListItemState extends State<ClientListItem> {
  bool _hovered = false;

  String get _initials {
    final parts = widget.client.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    final l = AppLocalizations.of(context)!;
    final isActive = widget.client.isActive;
    final stripeColor =
        isActive ? cs.secondary : cs.onSurfaceVariant.withValues(alpha: 0.3);

    final monthlyMeta = _buildMonthlyInvoiceMeta(context);

    // Chips shown inline on desktop, below text on mobile
    Widget? monthChip;
    if (widget.client.missingCurrentMonthInvoice == true) {
      monthChip = _MonthStatusChip(
        label: l.clientMissingInvoiceThisMonth,
        background: cs.errorContainer.withValues(alpha: 0.55),
        foreground: cs.onErrorContainer,
        icon: Icons.warning_amber_rounded,
      );
    } else if (widget.client.hasCurrentMonthInvoiceFlagData &&
        widget.client.hasIssuedInvoiceThisMonth) {
      monthChip = _MonthStatusChip(
        label: l.clientInvoiceAllGood,
        background: cs.secondaryContainer.withValues(alpha: 0.55),
        foreground: cs.onSecondaryContainer,
        icon: Icons.check_circle_outline_rounded,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white
              : _hovered
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.18)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? cs.outlineVariant.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.25),
          ),
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: _hovered ? 0.06 : 0.035),
                    blurRadius: _hovered ? 16 : 10,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left status stripe — stretches to card height
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: stripeColor,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12)),
                  ),
                ),
                const SizedBox(width: 10),

                // Avatar with initials
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name + meta (+ chips on mobile)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 9 : 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.client.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: widget.nameStyle.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _MetaRow(
                          phone: widget.client.phone,
                          email: widget.client.email,
                          billing: widget.client.billing,
                          textStyle: widget.metaStyle.copyWith(fontSize: 11),
                          iconColor:
                              cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        if (monthlyMeta != null) ...[
                          const SizedBox(height: 3),
                          monthlyMeta,
                        ],
                        // Chips below text on mobile
                        if (isMobile) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              _StatusChip(active: isActive),
                              if (monthChip != null) monthChip,
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Desktop: chips + delete + chevron
                // Mobile: chevron only
                if (!isMobile)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BillingChip(billing: widget.client.billing),
                      const SizedBox(width: 5),
                      if (monthChip != null) ...[
                        monthChip,
                        const SizedBox(width: 5),
                      ],
                      _StatusChip(active: isActive),
                      if (widget.onDelete != null) ...[
                        const SizedBox(width: 4),
                        AnimatedOpacity(
                          opacity: _hovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.delete_outline,
                                  size: 15, color: cs.error),
                              tooltip: l.remove,
                              onPressed: widget.onDelete,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                    ],
                  ),

                // Chevron — always visible
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: cs.onSurfaceVariant
                        .withValues(alpha: _hovered ? 0.8 : 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildMonthlyInvoiceMeta(BuildContext context) {
    if (!widget.client.hasCurrentMonthInvoiceFlagData) return null;
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final parts = <String>[];
    if (widget.client.currentMonthInvoiceCount != null) {
      parts.add(l.clientInvoiceCountThisMonth(
          widget.client.currentMonthInvoiceCount!));
    }
    if (widget.client.lastCurrentMonthInvoiceAt != null) {
      parts.add(
        l.clientLastInvoiceShort(
          localizations.formatShortDate(
              widget.client.lastCurrentMonthInvoiceAt!.toLocal()),
        ),
      );
    } else if (widget.client.missingCurrentMonthInvoice == true) {
      parts.add(l.clientNoInvoiceIssuedThisMonth);
    }
    if (parts.isEmpty) return null;
    return Row(
      children: [
        Icon(Icons.calendar_month_outlined,
            size: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            parts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.metaStyle.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }
}

// ─── Meta row ─────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final String? phone;
  final String? email;
  final ClientBilling? billing;
  final TextStyle textStyle;
  final Color iconColor;

  const _MetaRow({
    required this.phone,
    required this.email,
    this.billing,
    required this.textStyle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <_MetaPart>[];

    if ((email ?? '').isNotEmpty) {
      parts.add(_MetaPart(Icons.alternate_email_rounded, email!));
    }
    if ((phone ?? '').isNotEmpty) {
      parts.add(_MetaPart(Icons.phone_rounded, phone!));
    }
    final legalName = billing?.legalName;
    if (legalName != null && legalName.isNotEmpty) {
      parts.add(_MetaPart(Icons.receipt_long_outlined, legalName));
    }

    if (parts.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.contact,
        style: textStyle.copyWith(fontStyle: FontStyle.italic),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('·', style: textStyle.copyWith(color: iconColor)),
            ),
          Icon(parts[i].icon, size: 11, color: iconColor),
          const SizedBox(width: 3),
          if (i == parts.length - 1)
            Flexible(
              child: Text(
                parts[i].text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            )
          else
            Text(
              parts[i].text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
        ],
      ],
    );
  }
}

class _MetaPart {
  final IconData icon;
  final String text;
  const _MetaPart(this.icon, this.text);
}

// ─── Billing chip ─────────────────────────────────────────────────────────────

class _BillingChip extends StatelessWidget {
  final ClientBilling? billing;
  const _BillingChip({required this.billing});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final bool isComplete = billing?.isComplete == true;
    final Color color =
        isComplete ? cs.tertiary : cs.onSurfaceVariant.withValues(alpha: 0.6);
    final doc = billing?.documentType ?? 'invoice';
    final docLabel =
        doc == 'receipt' ? l.documentTypeReceipt : l.documentTypeInvoice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete
                ? Icons.check_circle_outline_rounded
                : Icons.pending_outlined,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isComplete ? l.billingComplete : l.billingMissing,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              docLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final color =
        active ? cs.tertiary : cs.onSurfaceVariant.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            active ? l.active : l.inactive,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Month status chip ────────────────────────────────────────────────────────

class _MonthStatusChip extends StatelessWidget {
  const _MonthStatusChip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
