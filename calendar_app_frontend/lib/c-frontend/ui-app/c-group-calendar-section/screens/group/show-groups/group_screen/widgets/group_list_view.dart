// lib/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_list_view.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_screen/widgets/group_card_tile.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupListView extends StatelessWidget {
  const GroupListView({
    super.key,
    required this.groups,
    required this.axis,
    required this.currentUser,
    required this.userDomain,
    required this.groupDomain,
    required this.updateRole,
    this.emptyWidget,
  });

  final List<Group> groups;
  final Axis axis;
  final User currentUser;
  final UserDomain userDomain;
  final GroupDomain groupDomain;
  final void Function(String?) updateRole;
  final Widget? emptyWidget;

  static const double _kHorizontalRowHeight = 160;
  static const double _kCardSpacing = 8.0;
  static const double _kHorizontalPadding = 12.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (groups.isEmpty) {
      return emptyWidget ?? _buildEmptyState(context, l, cs);
    }

    final isHorizontal = axis == Axis.horizontal;

    final list = ListView.separated(
      key: const PageStorageKey('group-list'),
      scrollDirection: axis,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isHorizontal ? _kHorizontalPadding : 0,
        vertical: isHorizontal ? 8 : 4,
      ),
      itemCount: groups.length,
      separatorBuilder: (_, __) => isHorizontal
          ? const SizedBox(width: _kCardSpacing)
          : const SizedBox(height: _kCardSpacing),
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildGroupCard(
          context,
          group,
          isHorizontal,
        );
      },
    );

    // Horizontal: constrain height; vertical: just return the list.
    return isHorizontal
        ? SizedBox(height: _kHorizontalRowHeight, child: list)
        : list;
  }

  Widget _buildGroupCard(
    BuildContext context,
    Group group,
    bool isHorizontal,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: isHorizontal
          ? const BoxConstraints(
              minWidth: 260,
              maxWidth: 300,
            )
          : null,
      child: GroupCardTile(
        group: group,
        currentUser: currentUser,
        userDomain: userDomain,
        groupDomain: groupDomain,
        updateRole: updateRole,
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l,
    ColorScheme cs,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 64,
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l.noGroupsFound,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l.noGroupsDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
