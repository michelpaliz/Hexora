part of '../settings_members_section.dart';

extension _SettingsMembersListPart on _SettingsMembersSectionState {
  Widget _buildSplitPanel(BuildContext context) {
    final members = _currentMembers;

    if (members.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 380,
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
      constraints: const BoxConstraints(maxHeight: 380),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.25),
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
                onTap: () => _selectMember(ref),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primaryContainer.withValues(alpha: 0.5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: (user?.photoUrl != null &&
                                user!.photoUrl!.isNotEmpty)
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        backgroundColor:
                            cs.primaryContainer.withValues(alpha: 0.4),
                        child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                            ? Text(
                                _initials(displayName),
                                style: t.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                  fontSize: 10,
                                ),
                              )
                            : null,
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
