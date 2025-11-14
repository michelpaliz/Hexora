// lib/c-frontend/home/widgets/change_view_row.dart
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Compact info affordance:
/// - Default: small info icon with tooltip (no clutter).
/// - Tap: expands to a dismissible banner with the full message.
/// - Dismiss: hides until widget rebuild (wire to storage if you want persistence).
class InfoRow extends StatefulWidget {
  const InfoRow({super.key});

  @override
  State<InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<InfoRow> {
  bool _expanded = false;
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final bg = ThemeColors.cardBg(context);
    final onBg = ThemeColors.textPrimary(context);
    final shadow = ThemeColors.cardShadow(context);

    final user = context.read<UserDomain?>()?.user;
    final message = user != null ? l.welcomeGroupView(user.name) : l.groups;

    // Compact: icon-only with tooltip
    if (!_expanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Align(
          alignment: Alignment.centerRight,
          child: Tooltip(
            message: message,
            triggerMode: TooltipTriggerMode.longPress,
            child: InkResponse(
              onTap: () => setState(() => _expanded = true),
              radius: 20,
              child: Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: onBg.withOpacity(0.85),
              ),
            ),
          ),
        ),
      );
    }

    // Expanded: subtle banner with message + close
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
                color: shadow, blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: onBg.withOpacity(0.9), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: t.bodySmall
                    .copyWith(color: onBg.withOpacity(0.95), height: 1.3),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => setState(() => _expanded = false),
              icon: Icon(Icons.close_rounded,
                  color: onBg.withOpacity(0.85), size: 18),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}
