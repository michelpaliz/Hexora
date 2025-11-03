// lib/c-frontend/home/widgets/change_view_row.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// Compact info affordance:
/// - Default: small info icon with tooltip (no clutter).
/// - Tap: expands to a dismissible banner with the full message.
/// - Dismiss: hides until widget rebuild (you can wire to storage if you want persistence).
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

    final loc = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;

    final bg = ThemeColors.getSearchBarBackgroundColor(context);
    final txt = ThemeColors.getContrastTextColorForBackground(bg);
    final shadow = ThemeColors.getCardShadowColor(context);

    final user = context.read<UserDomain?>()?.user;
    final message = user != null
        ? loc.welcomeGroupView(user.name) // e.g. “Welcome {username}…”
        : loc.groups; // short fallback

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
                color: txt.withOpacity(0.85),
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
          boxShadow: [
            BoxShadow(color: shadow, blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: txt.withOpacity(0.9), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: t.bodyMedium?.copyWith(color: txt.withOpacity(0.95)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => setState(() {
                // Close back to compact if they tap once; tap close again to dismiss entirely
                if (_expanded) {
                  _expanded = false;
                } else {
                  _dismissed = true;
                }
              }),
              icon: Icon(Icons.close_rounded,
                  color: txt.withOpacity(0.85), size: 18),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}
