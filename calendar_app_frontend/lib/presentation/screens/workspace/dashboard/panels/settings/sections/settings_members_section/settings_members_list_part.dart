part of '../settings_members_section.dart';

extension _SettingsMembersListPart on _SettingsMembersSectionState {
  Widget _buildSplitPanel(BuildContext context) {
    final members = _currentMembers;

    if (members.isEmpty) {
      return _buildEmptyState(context);
    }

    // No fixed height: the detail card ends with its content (max 480).
    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 240,
            child: _buildMemberList(context, members),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDetailPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 32, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No hay miembros',
              style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberList(BuildContext context, List<MemberRef> members) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final repo = context.read<IUserRepository>();

    return Container(
      constraints: const BoxConstraints(maxHeight: 480),
      key: const ValueKey('settings-member-list'),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: members.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 12,
          endIndent: 12,
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
        itemBuilder: (context, index) {
          final ref = members[index];
          final isSelected = _selectedMember?.username == ref.username;

          return FutureBuilder<User>(
            future: repo.getUserBySelector(ref.username),
            builder: (context, snap) {
              final user = snap.data;
              final displayName = user != null
                  ? (user.name.isNotEmpty ? user.name : user.userName)
                  : ref.username;

              return InkWell(
                key: ValueKey('settings-member-row-${ref.username}'),
                onTap: () => _selectMember(ref),
                borderRadius: BorderRadius.circular(8),
                hoverColor: cs.primary.withValues(alpha: 0.05),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  // Selected: stronger pale blue with a 3 px blue indicator.
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  foregroundDecoration: isSelected
                      ? BoxDecoration(
                          border: Border(
                            left: BorderSide(color: cs.primary, width: 3),
                          ),
                        )
                      : null,
                  child: Row(
                    children: [
                      HexoraUserAvatar(
                        userId: user?.id ?? ref.username,
                        displayName:
                            user?.displayName ?? user?.name ?? displayName,
                        username: user?.userName ?? ref.username,
                        photoUrl: user?.photoUrl,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: t.bodySmall.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            MemberRoleChip(
                              role: GroupRole.fromWire(ref.role),
                              hideForAdminLike: false,
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: cs.primary,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
