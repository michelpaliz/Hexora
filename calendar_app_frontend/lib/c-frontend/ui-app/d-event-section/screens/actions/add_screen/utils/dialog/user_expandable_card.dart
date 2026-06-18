import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'dialog_button_widget.dart';

class UserExpandableCard extends StatefulWidget {
  final List<User> usersAvailable;
  final ValueChanged<List<User>> onSelectedUsersChanged;
  final List<User>? initiallySelected;
  final String? excludeUserId;

  const UserExpandableCard({
    Key? key,
    required this.usersAvailable,
    required this.onSelectedUsersChanged,
    this.initiallySelected,
    this.excludeUserId,
  }) : super(key: key);

  @override
  _UserExpandableCardState createState() => _UserExpandableCardState();
}

class _UserExpandableCardState extends State<UserExpandableCard> {
  late List<User> _selectedUsers;
  bool _isExpanded = false;

  List<User> get _filteredUsers {
    if (widget.excludeUserId == null) return widget.usersAvailable;
    return widget.usersAvailable
        .where((u) => u.id != widget.excludeUserId)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final initSel = (widget.initiallySelected ?? [])
        .where((u) => u.id != widget.excludeUserId)
        .toList();
    _selectedUsers = initSel;
  }

  void _toggleExpansion() => setState(() => _isExpanded = !_isExpanded);

  void _onUsersSelected(List<User> selectedUsers) {
    final cleaned =
        selectedUsers.where((u) => u.id != widget.excludeUserId).toList();
    setState(() {
      _selectedUsers = cleaned;
      _isExpanded = false;
    });
    widget.onSelectedUsersChanged(cleaned);
  }

  void _removeUser(User user) {
    final updated = _selectedUsers.where((u) => u.id != user.id).toList();
    setState(() => _selectedUsers = updated);
    widget.onSelectedUsersChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final canInvite = _filteredUsers.isNotEmpty;
    final hasSelected = _selectedUsers.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────
          InkWell(
            onTap: canInvite ? _toggleExpansion : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: cs.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.group_outlined,
                        size: 16, color: cs.secondary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.userExpandableCardTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (hasSelected) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: cs.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${_selectedUsers.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: canInvite
                          ? cs.onSurfaceVariant
                          : cs.onSurfaceVariant.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded: add button ───────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _isExpanded && canInvite
                ? Column(
                    children: [
                      Divider(
                          height: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.18)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: DialogButtonWidget(
                          selectedUsers: _selectedUsers,
                          usersAvailable: _filteredUsers,
                          onUsersSelected: _onUsersSelected,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // ── Divider ───────────────────────────────────────────────────
          Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.15)),

          // ── Selected users / empty state ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: hasSelected
                ? _buildSelectedChips(cs)
                : _buildEmptyState(loc, cs),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc, ColorScheme cs) {
    return Row(
      children: [
        Icon(
          Icons.person_add_outlined,
          size: 14,
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 7),
        Text(
          loc.noUsersSelected,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedChips(ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedUsers
          .map((user) => _UserChip(
                user: user,
                cs: cs,
                onRemove: () => _removeUser(user),
              ))
          .toList(),
    );
  }
}

// ── User chip ─────────────────────────────────────────────────────────────────

class _UserChip extends StatelessWidget {
  final User user;
  final ColorScheme cs;
  final VoidCallback onRemove;

  const _UserChip({
    required this.user,
    required this.cs,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.userName);

    return Container(
      padding: const EdgeInsets.only(left: 4, right: 2, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 11,
            backgroundColor: cs.secondary.withValues(alpha: 0.25),
            backgroundImage: (user.photoUrl?.isNotEmpty ?? false)
                ? AvatarUtils.profileImageProvider(user.photoUrl)
                : null,
            child: (user.photoUrl?.isNotEmpty ?? false)
                ? null
                : Text(
                    initials,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: cs.secondary,
                    ),
                  ),
          ),

          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 90),
            child: Text(
              user.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Remove button
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
