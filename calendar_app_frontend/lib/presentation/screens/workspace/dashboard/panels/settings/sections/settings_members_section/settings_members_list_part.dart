part of '../settings_members_section.dart';

extension _SettingsMembersListPart on _SettingsMembersSectionState {
  Widget _buildInvitationFilters(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    void updateFilter(VoidCallback update) {
      _updateUi(() {
        update();
        _selectedMember = null;
        _selectedUser = null;
        _selectedInvitation = null;
      });
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            es ? 'Buscar y filtrar invitaciones' : 'Search and filter invitations',
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _invitationSearchController,
                  onChanged: (value) => updateFilter(
                    () => _invitationQuery = value,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: es ? 'Email o destinatario' : 'Email or recipient',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _invitationQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: es ? 'Limpiar búsqueda' : 'Clear search',
                            onPressed: () {
                              _invitationSearchController.clear();
                              updateFilter(() => _invitationQuery = '');
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                  ),
                ),
              ),
              _invitationFilterDropdown(
                context,
                width: 165,
                value: _invitationStatusFilter,
                label: es ? 'Estado' : 'Status',
                items: {
                  'all': es ? 'Todos' : 'All',
                  'pending': es ? 'Pendiente' : 'Pending',
                  'accepted': es ? 'Aceptada' : 'Accepted',
                  'declined': es ? 'Rechazada' : 'Declined',
                  'expired': es ? 'Caducada' : 'Expired',
                  'revoked': es ? 'Revocada' : 'Revoked',
                },
                onChanged: (value) => updateFilter(
                  () => _invitationStatusFilter = value,
                ),
              ),
              _invitationFilterDropdown(
                context,
                width: 205,
                value: _invitationDeliveryFilter,
                label: es ? 'Entrega' : 'Delivery',
                items: {
                  'all': es ? 'Todas' : 'All',
                  'sent': es ? 'Email enviado' : 'Email sent',
                  'failed': es ? 'Email fallido' : 'Email failed',
                  'in_app_only': es ? 'Solo en la app' : 'In-app only',
                  'unknown': es ? 'Sin registrar' : 'Not recorded',
                },
                onChanged: (value) => updateFilter(
                  () => _invitationDeliveryFilter = value,
                ),
              ),
              _invitationFilterDropdown(
                context,
                width: 165,
                value: _invitationRoleFilter,
                label: es ? 'Rol' : 'Role',
                items: {
                  'all': es ? 'Todos' : 'All',
                  'member': roleLabelOf(context, GroupRole.member),
                  'co-admin': roleLabelOf(context, GroupRole.coAdmin),
                  'admin': roleLabelOf(context, GroupRole.admin),
                },
                onChanged: (value) => updateFilter(
                  () => _invitationRoleFilter = value,
                ),
              ),
              TextButton.icon(
                onPressed: _resetInvitationFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: Text(es ? 'Restablecer' : 'Reset'),
              ),
              Text(
                es
                    ? '${_filteredInvitations.length} resultado(s)'
                    : '${_filteredInvitations.length} result(s)',
                style: t.caption.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _invitationFilterDropdown(
    BuildContext context, {
    required double width,
    required String value,
    required String label,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$value'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(isDense: true, labelText: label),
        items: items.entries
            .map((entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
                ))
            .toList(growable: false),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

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
            width: _selectedTab == 4 ? 360 : 240,
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
    final es = Localizations.localeOf(context).languageCode == 'es';
    final filteringInvitations = _selectedTab == 4 &&
        (_invitationQuery.isNotEmpty ||
            _invitationStatusFilter != 'all' ||
            _invitationDeliveryFilter != 'all' ||
            _invitationRoleFilter != 'all');
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 32, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              filteringInvitations
                  ? (es
                      ? 'No hay invitaciones que coincidan con los filtros.'
                      : 'No invitations match these filters.')
                  : _selectedTab == 4
                      ? (es ? 'No hay invitaciones.' : 'No invitations yet.')
                      : (es ? 'No hay miembros.' : 'No members found.'),
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
    final es = Localizations.localeOf(context).languageCode == 'es';
    final currentUserId = context.read<UserDomain?>()?.user?.id ?? '';
    final actorRole = GroupRole.fromWire(
      currentUserId == widget.group.ownerId
          ? GroupRole.owner.wire
          : widget.group.userRoles[currentUserId],
    );

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
          final normalizedRecipient = ref.username.trim().toLowerCase();
          final invitation = _selectedTab == 4
              ? widget.membersVM.invitations.cast<Invitation?>().firstWhere(
                    (item) =>
                        item!.userId == ref.username ||
                        item.email?.trim().toLowerCase() == normalizedRecipient,
                    orElse: () => null,
                  )
              : null;
          final canManageInvitation = invitation != null &&
              (invitation.status == InvitationStatus.pending ||
                  invitation.status == InvitationStatus.expired) &&
              (actorRole == GroupRole.owner ||
                  invitation.role.rank < actorRole.rank);
          final actionInProgress =
              invitation != null && _invitationActionId == invitation.id;

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
                            if (invitation?.invitedByName?.isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  '${es ? 'Invitó' : 'Invited by'}: '
                                  '${invitation!.invitedByName}',
                                  style: t.caption.copyWith(
                                    fontSize: 9,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                MemberRoleChip(
                                  role: GroupRole.fromWire(ref.role),
                                  hideForAdminLike: false,
                                ),
                                if (invitation != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.secondaryContainer
                                          .withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _invitationStatusLabel(
                                        context,
                                        invitation.status,
                                      ),
                                      style: t.caption.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (invitation?.meta['deliveryStatus'] ==
                                    'failed')
                                  Tooltip(
                                    message: Localizations.localeOf(context)
                                                .languageCode ==
                                            'es'
                                        ? 'El email no pudo enviarse'
                                        : 'Email delivery failed',
                                    child: Icon(
                                      Icons.error_outline_rounded,
                                      size: 14,
                                      color: cs.error,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (canManageInvitation)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: es ? 'Reenviar' : 'Resend',
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                iconSize: 18,
                                onPressed: _invitationActionId != null
                                    ? null
                                    : () => _resendInvitation(invitation!),
                                icon: actionInProgress
                                    ? const SizedBox.square(
                                        dimension: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.refresh_rounded),
                              ),
                            ),
                            Tooltip(
                              message: es ? 'Revocar' : 'Revoke',
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                iconSize: 18,
                                color: cs.error,
                                onPressed: _invitationActionId != null
                                    ? null
                                    : () => _revokeInvitation(invitation!),
                                icon: const Icon(Icons.block_rounded),
                              ),
                            ),
                          ],
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

  String _invitationStatusLabel(
    BuildContext context,
    InvitationStatus status,
  ) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    return switch (status) {
      InvitationStatus.pending => es ? 'Pendiente' : 'Pending',
      InvitationStatus.accepted => es ? 'Aceptada' : 'Accepted',
      InvitationStatus.declined => es ? 'Rechazada' : 'Declined',
      InvitationStatus.expired => es ? 'Caducada' : 'Expired',
      InvitationStatus.revoked => es ? 'Revocada' : 'Revoked',
    };
  }
}
