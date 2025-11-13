import 'package:flutter/material.dart';
import 'package:hexora/b-backend/user/presence_domain.dart';
import 'package:hexora/c-frontend/utils/image/user_image/widgets/user_status_row.dart';
import 'package:hexora/l10n/app_localizations.dart';

class OnlineUsersPanel extends StatelessWidget {
  final List<UserPresence> onlineUsers;

  const OnlineUsersPanel({super.key, required this.onlineUsers});

  @override
  Widget build(BuildContext context) {
    if (onlineUsers.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.circle,
                    size: 10, color: Colors.greenAccent.shade400),
                const SizedBox(width: 6),
                Text(
                  // add a key like `onlineNow` to l10n if you want
                  '${l.online ?? "Online now"} (${onlineUsers.length})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Horizontal list of online users (reuses your global UI)
          UserStatusRow(userList: onlineUsers),
        ],
      ),
    );
  }
}
