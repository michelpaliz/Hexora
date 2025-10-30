import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AnimatedUsersList extends StatelessWidget {
  final List<User> users;
  final Function(User)? onUserTap;
  final bool showRemoveButton;

  const AnimatedUsersList({
    Key? key,
    required this.users,
    this.onUserTap,
    this.showRemoveButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 120),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_alt_rounded,
                    size: 32,
                    color: cs.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.noUsersSelected,
                    style: typo.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _buildUserChip(context, users[i]),
            ),
    );
  }

  Widget _buildUserChip(BuildContext context, User user) {
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onUserTap != null ? () => onUserTap!(user) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: (user.photoUrl?.isNotEmpty ?? false)
                          ? NetworkImage(user.photoUrl!)
                          : const AssetImage(
                                  'assets/images/default_profile.png')
                              as ImageProvider,
                      backgroundColor: cs.surfaceVariant,
                    ),
                  ),

                  // Remove button (if enabled)
                  if (showRemoveButton)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: GestureDetector(
                        onTap:
                            onUserTap != null ? () => onUserTap!(user) : null,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cs.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                user.userName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: typo.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Alternative: Compact horizontal tags style
class CompactUsersList extends StatelessWidget {
  final List<User> users;
  final Function(User)? onRemove;

  const CompactUsersList({
    Key? key,
    required this.users,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            loc.noUsersSelected,
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: users.map((user) => _buildUserTag(context, user)).toList(),
    );
  }

  Widget _buildUserTag(BuildContext context, User user) {
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: (user.photoUrl?.isNotEmpty ?? false)
                ? NetworkImage(user.photoUrl!)
                : const AssetImage('assets/images/default_profile.png')
                    as ImageProvider,
            backgroundColor: cs.surfaceVariant,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              user.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typo.bodySmall.copyWith(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => onRemove!(user),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: cs.onSecondaryContainer.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
