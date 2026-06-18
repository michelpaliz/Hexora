part of '../settings_members_section.dart';

extension _SettingsMembersDetailPart on _SettingsMembersSectionState {
  Widget _buildDetailPanel(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    if (_selectedMember == null) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 380),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_search_rounded,
                size: 36,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 10),
              Text(
                'Selecciona un miembro',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadingUser) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 380),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    final user = _selectedUser;
    if (user == null) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 380),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            'No se pudo cargar el usuario',
            style: t.bodySmall.copyWith(color: cs.error),
          ),
        ),
      );
    }

    final gd = context.watch<GroupDomain>();
    final currentUserId = context.read<UserDomain?>()?.user?.id ?? '';
    final rolesMap = gd.userRoles.value;
    final roleWire = rolesMap[user.id] ?? _selectedMember!.role;
    final targetRole = GroupRole.fromWire(roleWire);
    final currentRole = GroupRole.fromWire(rolesMap[currentUserId] ?? '');
    final isOwner = user.id == widget.group.ownerId;
    final isSelf = user.id == currentUserId;
    final isAccepted = _selectedMember!.statusToken == 'Accepted';
    final inv = _selectedInvitation;

    final canEditRole = RolePolicy.canEditRole(
      actorId: currentUserId,
      targetId: user.id,
      ownerId: widget.group.ownerId,
      roleOf: (id) => GroupRole.fromWire(rolesMap[id] ?? ''),
    );

    final assignableRoles = RolePolicy.assignableRoles(
      actorId: currentUserId,
      targetId: user.id,
      ownerId: widget.group.ownerId,
      roleOf: (id) => GroupRole.fromWire(rolesMap[id] ?? ''),
      availableRoles: GroupRole.defaults,
    );

    final canRemove = !isOwner &&
        !isSelf &&
        (currentRole == GroupRole.owner ||
            currentRole == GroupRole.admin ||
            currentRole == GroupRole.coAdmin);

    final displayName = user.name.isNotEmpty ? user.name : user.userName;

    return Container(
      constraints: const BoxConstraints(maxHeight: 380),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + name + status badge ──
            Row(
              children: [
                GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.72),
                    builder: (_) => UserAvatarViewerDialog(user: user),
                  ),
                  child: AvatarUtils.profileAvatar(context, user.photoUrl,
                      radius: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: t.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.userName.isNotEmpty)
                        Text(
                          '@${user.userName}',
                          style: t.caption.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(context, isAccepted, inv),
              ],
            ),

            const SizedBox(height: 14),

            // ── Contact info ──
            _buildCompactInfoRow(
              context,
              icon: Icons.alternate_email_rounded,
              value: user.email,
            ),
            if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
              _buildCompactInfoRow(
                context,
                icon: Icons.phone_rounded,
                value: user.phoneNumber!,
              ),
            if (user.location != null && user.location!.isNotEmpty)
              _buildCompactInfoRow(
                context,
                icon: Icons.location_on_outlined,
                value: user.location!,
              ),
            if (user.bio != null && user.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  user.bio!,
                  style: t.caption.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // ── Invitation timeline (for pending/notAccepted) ──
            if (inv != null) ...[
              const SizedBox(height: 10),
              _buildInvitationCard(context, inv),
            ],

            // ── Membership info (for accepted members) ──
            if (isAccepted && inv == null) ...[
              const SizedBox(height: 10),
              _buildMembershipCard(context, user),
            ],

            // ── Role history (lazy) ──
            if (_roleHistoryFuture != null) ...[
              const SizedBox(height: 10),
              _buildRoleHistorySection(context),
            ],

            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),

            // ── Role section ──
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  l.roleLabel,
                  style: t.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (isOwner) ...[
                  const Spacer(),
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 14,
                    color: cs.primary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Owner',
                    style: t.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (canEditRole && assignableRoles.isNotEmpty)
              _buildRoleSelector(
                context,
                user: user,
                currentRole: targetRole,
                assignableRoles: assignableRoles,
              )
            else
              _buildRoleReadOnly(context, targetRole),
            _buildRoleDescriptionFromPermissions(context, targetRole),

            if (canRemove) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmRemoveMember(context, user),
                  icon: Icon(
                    Icons.person_remove_rounded,
                    size: 14,
                    color: cs.error,
                  ),
                  label: Text(
                    l.remove,
                    style: t.caption.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: cs.error.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Status badge ──
  Widget _buildStatusBadge(
    BuildContext context,
    bool isAccepted,
    Invitation? inv,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final String label;
    final Color color;
    final IconData icon;

    if (isAccepted) {
      label = 'Activo';
      color = Colors.green;
      icon = Icons.check_circle_outline_rounded;
    } else if (inv != null && inv.status == InvitationStatus.pending) {
      label = 'Pendiente';
      color = Colors.orange;
      icon = Icons.hourglass_empty_rounded;
    } else if (inv != null && inv.status == InvitationStatus.declined) {
      label = 'Rechazado';
      color = cs.error;
      icon = Icons.cancel_outlined;
    } else if (inv != null && inv.status == InvitationStatus.expired) {
      label = 'Expirado';
      color = cs.onSurfaceVariant;
      icon = Icons.timer_off_outlined;
    } else if (inv != null && inv.status == InvitationStatus.revoked) {
      label = 'Revocado';
      color = cs.error;
      icon = Icons.block_rounded;
    } else {
      label = 'Desconocido';
      color = cs.onSurfaceVariant;
      icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Compact info row ──
  Widget _buildCompactInfoRow(
    BuildContext context, {
    required IconData icon,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: t.caption.copyWith(color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Invitation timeline card ──
  Widget _buildInvitationCard(BuildContext context, Invitation inv) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mail_outline_rounded,
                size: 13,
                color: cs.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Invitación',
                style: t.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTimelineRow(
            context,
            icon: Icons.send_rounded,
            label: 'Enviada',
            date: inv.sendingDate,
          ),
          if (inv.respondedAt != null)
            _buildTimelineRow(
              context,
              icon: inv.status == InvitationStatus.accepted
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              label: inv.status == InvitationStatus.accepted
                  ? 'Aceptada'
                  : inv.status == InvitationStatus.declined
                      ? 'Rechazada'
                      : 'Respondida',
              date: inv.respondedAt!,
            ),
          if (inv.expiresAt != null && inv.status == InvitationStatus.pending)
            _buildTimelineRow(
              context,
              icon: Icons.timer_outlined,
              label: 'Expira',
              date: inv.expiresAt!,
            ),
          if (inv.attempts > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${inv.attempts} intentos de envío',
                style: t.caption.copyWith(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DateTime date,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            _formatDate(date),
            style: t.caption.copyWith(
              fontSize: 10,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ── Membership card (accepted users) ──
  Widget _buildMembershipCard(BuildContext context, User user) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    // Try to find an accepted invitation for join date
    final acceptedInv =
        widget.membersVM.invitations.cast<Invitation?>().firstWhere(
              (i) =>
                  (i!.userId == user.id || i.email == user.email) &&
                  i.status == InvitationStatus.accepted,
              orElse: () => null,
            );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.group_rounded,
                size: 13,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                'Membresía',
                style: t.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (acceptedInv?.respondedAt != null)
            _buildTimelineRow(
              context,
              icon: Icons.login_rounded,
              label: 'Se unió',
              date: acceptedInv!.respondedAt!,
            ),
          if (acceptedInv?.sendingDate != null)
            _buildTimelineRow(
              context,
              icon: Icons.send_rounded,
              label: 'Invitado',
              date: acceptedInv!.sendingDate,
            ),
          if (acceptedInv == null)
            Row(
              children: [
                Icon(Icons.info_outline, size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Miembro desde la creación del grupo',
                  style: t.caption.copyWith(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Role read-only display ──
  Widget _buildRoleReadOnly(BuildContext context, GroupRole role) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: role.roleChipColor(cs).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: role.roleChipColor(cs).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            role.icon,
            size: 16,
            color: role.roleChipColor(cs),
          ),
          const SizedBox(width: 8),
          Text(
            roleLabelOf(context, role),
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: role.roleChipColor(cs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(
    BuildContext context, {
    required User user,
    required GroupRole currentRole,
    required List<GroupRole> assignableRoles,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final options = [...assignableRoles];
    if (!options.any((r) => r.wire == currentRole.wire)) {
      options.add(currentRole);
    }
    options.sort((a, b) => b.rank.compareTo(a.rank));

    return Column(
      children: [
        for (final role in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: role.wire == currentRole.wire
                  ? null
                  : () => _changeRole(user, role),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: role.wire == currentRole.wire
                      ? role.roleChipColor(cs).withValues(alpha: 0.1)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: role.wire == currentRole.wire
                        ? role.roleChipColor(cs).withValues(alpha: 0.3)
                        : cs.outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      role.icon,
                      size: 14,
                      color: role.wire == currentRole.wire
                          ? role.roleChipColor(cs)
                          : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        roleLabelOf(context, role),
                        style: t.caption.copyWith(
                          fontWeight: role.wire == currentRole.wire
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: role.wire == currentRole.wire
                              ? role.roleChipColor(cs)
                              : cs.onSurface,
                        ),
                      ),
                    ),
                    if (role.wire == currentRole.wire)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: role.roleChipColor(cs),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Role history section ──
  Widget _buildRoleHistorySection(BuildContext context) {
    return FutureBuilder<List<RoleHistoryEntry>>(
      future: _roleHistoryFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // silent load — no spinner
        }
        final entries = snap.data;
        if (entries == null || entries.isEmpty) return const SizedBox.shrink();

        final cs = Theme.of(context).colorScheme;
        final t = AppTypography.of(context);

        // Newest first
        final sorted = [...entries]
          ..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));

        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.18),
              ),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 13,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Historial de roles',
                      style: t.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                for (int i = 0; i < sorted.length; i++)
                  _buildHistoryRow(context, sorted[i], isLatest: i == 0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryRow(
    BuildContext context,
    RoleHistoryEntry entry, {
    required bool isLatest,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final role = GroupRole.fromWire(entry.role);
    final color = isLatest ? role.roleChipColor(cs) : cs.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isLatest ? Icons.circle : Icons.circle_outlined,
          size: 7,
          color: color.withValues(alpha: isLatest ? 1.0 : 0.55),
        ),
        const SizedBox(width: 6),
        Text(
          '${roleLabelOf(context, role)} · desde ${_formatDate(entry.assignedAt)}',
          style: t.caption.copyWith(
            fontWeight: isLatest ? FontWeight.w800 : FontWeight.w600,
            color: color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.isNegative) {
      // Future date (e.g. expiration)
      final absDiff = date.difference(now);
      if (absDiff.inDays > 0) return 'en ${absDiff.inDays}d';
      if (absDiff.inHours > 0) return 'en ${absDiff.inHours}h';
      return 'en ${absDiff.inMinutes}min';
    }

    if (diff.inDays == 0) {
      if (diff.inHours > 0) return 'hace ${diff.inHours}h';
      if (diff.inMinutes > 0) return 'hace ${diff.inMinutes}min';
      return 'ahora';
    }
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    if (diff.inDays < 30) return 'hace ${(diff.inDays / 7).floor()} sem';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}
