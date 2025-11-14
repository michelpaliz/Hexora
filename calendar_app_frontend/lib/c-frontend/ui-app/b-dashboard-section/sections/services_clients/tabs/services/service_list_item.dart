import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ServiceListItem extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap;

  /// Typography (injected)
  final TextStyle nameStyle;
  final TextStyle metaStyle;

  const ServiceListItem({
    super.key,
    required this.service,
    this.onTap,
    required this.nameStyle,
    required this.metaStyle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final durationText = service.defaultMinutes != null
        ? '${service.defaultMinutes} ${l.minutesAbbrev}'
        : l.noDefaultDuration;

    return Card(
      color: cs.surface,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.35), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ServiceDot(colorHex: service.color),
              const SizedBox(width: 12),

              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Status + chevron
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusChip(active: service.isActive),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceDot extends StatelessWidget {
  final String? colorHex;
  const _ServiceDot({this.colorHex});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bg = _hexToColorOrNull(colorHex) ?? cs.secondaryContainer;
    final Color fg = ThemeColors.contrastOn(bg);

    return CircleAvatar(
      radius: 20,
      backgroundColor: bg,
      child: Icon(Icons.design_services_outlined, size: 18, color: fg),
    );
  }

  // Supports #rgb and #rrggbb
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
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // Theme-driven containers instead of hard-coded hex
    final Color bg = active ? cs.secondaryContainer : cs.errorContainer;
    final Color fg = active ? cs.onSecondaryContainer : cs.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: cs.outlineVariant.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.chipGlow(context, bg),
            blurRadius: active ? 8 : 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        active ? l.active : l.inactive,
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
