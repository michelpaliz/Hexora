import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ServiceListItem extends StatefulWidget {
  final Service service;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  final TextStyle nameStyle;
  final TextStyle metaStyle;

  const ServiceListItem({
    super.key,
    required this.service,
    this.onTap,
    this.onDelete,
    required this.nameStyle,
    required this.metaStyle,
  });

  @override
  State<ServiceListItem> createState() => _ServiceListItemState();
}

class _ServiceListItemState extends State<ServiceListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final l = AppLocalizations.of(context)!;
    final isActive = widget.service.isActive;

    final durationText = widget.service.defaultMinutes != null
        ? '${widget.service.defaultMinutes} ${l.minutesAbbrev}'
        : l.noDefaultDuration;

    final stripeColor =
        isActive ? cs.secondary : cs.onSurfaceVariant.withValues(alpha: 0.3);

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
          child: Row(
            children: [
              // Left status stripe
              Container(
                width: 3,
                height: 54,
                decoration: BoxDecoration(
                  color: stripeColor,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
              ),
              const SizedBox(width: 10),

              // Colored service avatar (rounded square)
              _ServiceAvatar(colorHex: widget.service.color),
              const SizedBox(width: 12),

              // Name + meta
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: widget.nameStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 11,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.6)),
                          const SizedBox(width: 3),
                          Text(
                            durationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: widget.metaStyle.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Right side: status + actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  Icon(Icons.chevron_right,
                      size: 16,
                      color: cs.onSurfaceVariant
                          .withValues(alpha: _hovered ? 0.8 : 0.4)),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Service avatar ───────────────────────────────────────────────────────────

class _ServiceAvatar extends StatelessWidget {
  final String? colorHex;
  const _ServiceAvatar({this.colorHex});

  Color? _hexToColorOrNull(String? hex) {
    if (hex == null || !hex.startsWith('#')) return null;
    var cleaned = hex.substring(1);
    if (cleaned.length == 3) {
      cleaned = cleaned.split('').map((ch) => '$ch$ch').join();
    }
    if (cleaned.length != 6) return null;
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value == null ? null : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bg = _hexToColorOrNull(colorHex) ?? cs.secondaryContainer;
    final Color fg = ThemeColors.contrastOn(bg);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.design_services_outlined, size: 16, color: fg),
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
