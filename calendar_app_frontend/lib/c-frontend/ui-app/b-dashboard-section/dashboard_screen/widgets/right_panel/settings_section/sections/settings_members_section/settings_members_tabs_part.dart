part of '../settings_members_section.dart';

extension _SettingsMembersTabsPart on _SettingsMembersSectionState {
  Widget _buildTabChips(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final tabs = [
      _TabDef(
        label: l.membersTitle,
        count: widget.membersVM.totalAccepted,
        icon: Icons.people_rounded,
      ),
      _TabDef(
        label: l.statusPending,
        count: widget.membersVM.totalPending,
        icon: Icons.hourglass_empty_rounded,
      ),
      _TabDef(
        label: l.statusNotAccepted,
        count: widget.membersVM.totalNotAccepted,
        icon: Icons.cancel_outlined,
      ),
      _TabDef(
        label: l.tabAddUsers,
        count: null,
        icon: Icons.person_add_rounded,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _buildChip(context, tabs[i], i),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, _TabDef tab, int index) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final selected = _selectedTab == index;

    return InkWell(
      onTap: () => _updateUi(() {
        _selectedTab = index;
        if (index == 3) {
          _selectedMember = null;
          _selectedUser = null;
        }
      }),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer
              : cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.3)
                : cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: 13,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              tab.label,
              style: t.caption.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
            if (tab.count != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary.withValues(alpha: 0.15)
                      : cs.outlineVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${tab.count}',
                  style: t.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
