import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AnimatedUsersList extends StatelessWidget {
  final List<User> users;
  const AnimatedUsersList({Key? key, required this.users}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: users.isEmpty
            ? Center(
                key: const ValueKey('empty'),
                child: Text(
                  l.noUsersSelected,
                  style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            : ListView.builder(
                key: const ValueKey('list'),
                scrollDirection: Axis.horizontal,
                itemCount: users.length,
                itemBuilder: (_, i) => _UserChip(user: users[i]),
              ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final User user;
  const _UserChip({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final ImageProvider<Object> avatarProvider =
        (user.photoUrl != null && user.photoUrl!.isNotEmpty)
            ? NetworkImage(user.photoUrl!) as ImageProvider<Object>
            : const AssetImage('assets/images/default_profile.png')
                as ImageProvider<Object>;

    return Container(
      width: 68,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: avatarProvider, // ✅ correct type
              backgroundColor: cs.surfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.userName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typo.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
