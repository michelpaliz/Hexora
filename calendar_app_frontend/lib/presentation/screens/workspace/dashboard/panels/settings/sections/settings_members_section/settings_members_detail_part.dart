part of '../settings_members_section.dart';

extension _SettingsMembersDetailPart on _SettingsMembersSectionState {
  Widget _buildDetailPanel(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_selectedMember == null) {
      // Compact empty state on the light-blue canvas, no white container.
      final es = Localizations.localeOf(context).languageCode == 'es';
      return Padding(
        key: const ValueKey('settings-member-empty'),
        padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_search_rounded,
                  size: 18, color: cs.primary),
            ),
            const SizedBox(height: 10),
            Text(
              es ? 'Selecciona un miembro' : 'Select a member',
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              es
                  ? 'Elige un miembro para consultar sus permisos y detalles.'
                  : 'Choose a member to see their permissions and details.',
              textAlign: TextAlign.center,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_loadingUser) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    final user = _selectedUser;
    if (user == null) {
      final invitation = _selectedInvitation;
      if (invitation != null) {
        return _buildInvitationDetailPanel(context, invitation);
      }
      return Container(
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.7),
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
    // The domain map is populated asynchronously. Preserve the roles returned
    // with this group meanwhile, otherwise an owner is incorrectly treated as
    // a regular member and the selector is rendered read-only.
    final rolesMap = <String, String>{
      ...widget.group.userRoles,
      ...gd.userRoles.value,
      ..._confirmedRoleOverrides,
    };
    final roleWire = rolesMap[user.id] ?? _selectedMember!.role;
    final targetRole = GroupRole.fromWire(roleWire);
    final displayedRole = _pendingRole ?? targetRole;
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
      key: const ValueKey('settings-member-detail'),
      constraints: const BoxConstraints(maxHeight: 480),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + name + status badge ──
            Row(
              children: [
                GestureDetector(
                  onTap: () => showHexoraDialog<void>(
                    context: context,
                    barrierColor: Colors.black.withValues(alpha: 0.72),
                    builder: (_) => UserAvatarViewerDialog(user: user),
                  ),
                  child: HexoraUserAvatar(
                    userId: user.id,
                    displayName: displayName,
                    username: user.userName,
                    photoUrl: user.photoUrl,
                    size: 48,
                  ),
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

            const SizedBox(height: 10),

            // ── Contact info ──
            if (user.email.isNotEmpty)
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
            const SizedBox(height: 6),
            _buildMembershipActivity(
              context,
              user: user,
              invitation: inv,
              isAccepted: isAccepted,
            ),

            // ── Membership info (for accepted members) ──

            // ── Role history (lazy) ──

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
                  'Rol en el negocio',
                  style: t.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (_pendingRole != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Cambio sin guardar',
                      style: t.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
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
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildRoleSelector(
                  context,
                  user: user,
                  currentRole: displayedRole,
                  assignableRoles: assignableRoles,
                ),
              )
            else
              _buildRoleReadOnly(context, displayedRole),
            _buildRoleDescriptionFromPermissions(context, displayedRole),
            if (_pendingRole != null) ...[
              const SizedBox(height: 6),
              Text(
                '${roleLabelOf(context, targetRole)} → ${roleLabelOf(context, displayedRole)}',
                style: t.caption.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _changeRole(user, _pendingRole!),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Guardar cambios'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _updateUi(() => _pendingRole = null),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],

            if (canRemove) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.65)),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _confirmRemoveMember(context, user),
                  icon: const Icon(Icons.person_remove_rounded, size: 14),
                  label: Text(
                    'Quitar del negocio',
                    style: t.caption.copyWith(fontWeight: FontWeight.w600),
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
  Widget _buildInvitationDetailPanel(
    BuildContext context,
    Invitation invitation,
  ) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final invitee = invitation.email ?? invitation.userId ?? '—';

    return Container(
      constraints: const BoxConstraints(maxHeight: 480),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                  child: Icon(Icons.mail_outline_rounded, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    invitee,
                    style: t.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(context, false, invitation),
              ],
            ),
            const SizedBox(height: 14),
            _buildCompactInfoRow(
              context,
              icon: Icons.alternate_email_rounded,
              value: invitee,
            ),
            const SizedBox(height: 10),
            _buildInvitationCard(context, invitation),
            const SizedBox(height: 12),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Rol asignado',
                  style: t.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRoleReadOnly(context, invitation.role),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    bool isAccepted,
    Invitation? inv,
  ) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

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
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

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
  Widget _buildMembershipActivity(
    BuildContext context, {
    required User user,
    required Invitation? invitation,
    required bool isAccepted,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        expansionAnimationStyle: HexoraMotion.expansionStyle(context),
        dense: true,
        visualDensity: VisualDensity.compact,
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        initiallyExpanded: _activityExpanded,
        onExpansionChanged: (expanded) =>
            _updateUi(() => _activityExpanded = expanded),
        leading: Icon(Icons.history_rounded, size: 16, color: cs.primary),
        title: Text(
          'Actividad de membresía',
          style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          isAccepted ? 'Miembro activo' : 'Invitación en curso',
          style: t.caption.copyWith(color: cs.onSurfaceVariant),
        ),
        children: [
          if (invitation != null)
            _buildInvitationCard(context, invitation)
          else
            _buildMembershipCard(context, user),
          if (_roleHistoryFuture != null) ...[
            const SizedBox(height: 8),
            _buildRoleHistorySection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildInvitationCard(BuildContext context, Invitation inv) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final es = Localizations.localeOf(context).languageCode == 'es';
    final canManage = inv.status == InvitationStatus.pending ||
        inv.status == InvitationStatus.expired;
    final actionInProgress = _invitationActionId == inv.id;
    final deliveryStatus = inv.meta['deliveryStatus']?.toString();
    final currentUserId = context.read<UserDomain?>()?.user?.id ?? '';
    final actorRole = GroupRole.fromWire(
      currentUserId == widget.group.ownerId
          ? GroupRole.owner.wire
          : widget.group.userRoles[currentUserId],
    );
    final canChangeInvitationRole = inv.status == InvitationStatus.pending &&
        (actorRole.wire == GroupRole.owner.wire ||
            inv.role.rank < actorRole.rank);
    final canShareInvitation = inv.status == InvitationStatus.pending &&
        (actorRole.wire == GroupRole.owner.wire ||
            inv.role.rank < actorRole.rank);

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
                es ? 'Invitación' : 'Invitation',
                style: t.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(inv.role.icon, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '${es ? 'Rol' : 'Role'}: ${roleLabelOf(context, inv.role)}',
                style: t.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildTimelineRow(
            context,
            icon: Icons.send_rounded,
            label: es ? 'Enviada' : 'Sent',
            date: inv.sendingDate,
          ),
          if (inv.invitedByName?.isNotEmpty == true)
            _buildCompactInfoRow(
              context,
              icon: Icons.person_outline_rounded,
              value:
                  '${es ? 'Invitó' : 'Invited by'}: ${inv.invitedByName}',
            ),
          _buildDeliveryStatusRow(
            context,
            deliveryStatus?.isNotEmpty == true ? deliveryStatus! : 'unknown',
            es,
          ),
          if (inv.respondedAt != null)
            _buildTimelineRow(
              context,
              icon: inv.status == InvitationStatus.accepted
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              label: inv.status == InvitationStatus.accepted
                  ? (es ? 'Aceptada' : 'Accepted')
                  : inv.status == InvitationStatus.declined
                      ? (es ? 'Rechazada' : 'Declined')
                      : (es ? 'Respondida' : 'Answered'),
              date: inv.respondedAt!,
            ),
          if (inv.expiresAt != null &&
              (inv.status == InvitationStatus.pending ||
                  inv.status == InvitationStatus.expired)) ...[
            _buildTimelineRow(
              context,
              icon: Icons.timer_outlined,
              label: inv.status == InvitationStatus.expired
                  ? (es ? 'Caducó' : 'Expired')
                  : (es ? 'Expira' : 'Expires'),
              date: inv.expiresAt!,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 4),
              child: Text(
                _formatExactDate(context, inv.expiresAt!),
                style: t.caption.copyWith(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (inv.attempts > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                es
                    ? '${inv.attempts} intentos de envío'
                    : '${inv.attempts} delivery attempts',
                style: t.caption.copyWith(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          if (canManage) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed:
                      actionInProgress ? null : () => _resendInvitation(inv),
                  icon: actionInProgress
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(es ? 'Reenviar' : 'Resend'),
                ),
                if (canChangeInvitationRole)
                  OutlinedButton.icon(
                    onPressed: actionInProgress
                        ? null
                        : () => _changeInvitationRole(inv),
                    icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                    label: Text(es ? 'Cambiar rol' : 'Change role'),
                  ),
                if (canShareInvitation)
                  OutlinedButton.icon(
                    onPressed: actionInProgress
                        ? null
                        : () => _createInvitationShareLink(inv),
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: Text(es ? 'Compartir enlace' : 'Share link'),
                  ),
                OutlinedButton.icon(
                  onPressed:
                      actionInProgress ? null : () => _revokeInvitation(inv),
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: Text(es ? 'Revocar' : 'Revoke'),
                ),
              ],
            ),
          ],
          if (_invitationAuditFuture != null) ...[
            const SizedBox(height: 12),
            _buildInvitationAudit(context),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryStatusRow(
    BuildContext context,
    String status,
    bool es,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final normalized = status.toLowerCase();
    final (icon, color, label) = switch (normalized) {
      'sent' => (
          Icons.mark_email_read_outlined,
          Colors.green,
          es ? 'Correo enviado' : 'Email sent'
        ),
      'in_app_only' => (
          Icons.notifications_active_outlined,
          cs.primary,
          es ? 'Solo notificación en la app' : 'In-app notification only'
        ),
      'unknown' => (
          Icons.help_outline_rounded,
          cs.onSurfaceVariant,
          es ? 'Estado de entrega no registrado' : 'Delivery status not recorded'
        ),
      _ => (
          Icons.error_outline_rounded,
          cs.error,
          es ? 'No se pudo enviar el correo' : 'Email delivery failed'
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationAudit(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final es = Localizations.localeOf(context).languageCode == 'es';
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _invitationAuditFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        final events = snapshot.data ?? const <Map<String, dynamic>>[];
        if (events.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: cs.outlineVariant.withValues(alpha: 0.3)),
            Text(
              es ? 'Historial de la invitación' : 'Invitation history',
              style: t.caption.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...events.map((event) {
              final action = event['action']?.toString() ?? '';
              final actor = event['actorId'];
              final actorMap = actor is Map
                  ? Map<String, dynamic>.from(actor)
                  : const <String, dynamic>{};
              final actorName = actorMap['name']?.toString().trim().isNotEmpty == true
                  ? actorMap['name'].toString()
                  : actorMap['userName']?.toString() ?? '';
              final date = DateTime.tryParse(event['createdAt']?.toString() ?? '');
              final rawMetadata = event['metadata'];
              final metadata = rawMetadata is Map
                  ? Map<String, dynamic>.from(rawMetadata)
                  : const <String, dynamic>{};
              final previousRole = metadata['previousRole']?.toString();
              final nextRole = metadata['nextRole']?.toString();
              final label = switch (action) {
                'created' => es ? 'Creada' : 'Created',
                'resent' => es ? 'Reenviada' : 'Resent',
                'reminded' => es ? 'Recordatorio enviado' : 'Reminder sent',
                'role_changed' when previousRole != null && nextRole != null =>
                  '${es ? 'Rol cambiado' : 'Role changed'}: '
                      '${roleLabelOf(context, GroupRole.fromWire(previousRole))} → '
                      '${roleLabelOf(context, GroupRole.fromWire(nextRole))}',
                'role_changed' => es ? 'Rol cambiado' : 'Role changed',
                'share_link_generated' => es
                    ? 'Enlace para compartir creado'
                    : 'Share link created',
                'accepted' => es ? 'Aceptada' : 'Accepted',
                'declined' => es ? 'Rechazada' : 'Declined',
                'revoked' => es ? 'Revocada' : 'Revoked',
                'expired' => es ? 'Caducada' : 'Expired',
                _ => action,
              };
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        actorName.isEmpty ? label : '$label · $actorName',
                        style: t.caption.copyWith(fontSize: 10),
                      ),
                    ),
                    if (date != null)
                      Text(
                        _formatDate(context, date),
                        style: t.caption.copyWith(fontSize: 10),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
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
            _formatDate(context, date),
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
    final t = AppTypography.of(context);

    final options = [...assignableRoles];
    if (!options.any((r) => r.wire == currentRole.wire)) {
      options.add(currentRole);
    }
    options.sort((a, b) => b.rank.compareTo(a.rank));

    return DropdownButtonFormField<String>(
      key: ValueKey(currentRole.wire),
      initialValue: currentRole.wire,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Cambiar rol',
        prefixIcon: Icon(Icons.manage_accounts_outlined, size: 18),
      ),
      items: [
        for (final role in options)
          DropdownMenuItem<String>(
            value: role.wire,
            child: Row(
              children: [
                Icon(role.icon, size: 16),
                const SizedBox(width: 8),
                Text(
                  roleLabelOf(context, role),
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
      onChanged: (wire) {
        if (wire == null || wire == currentRole.wire) return;
        final role = options.firstWhere((candidate) => candidate.wire == wire);
        _updateUi(() => _pendingRole = role);
      },
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
        final es = Localizations.localeOf(context).languageCode == 'es';

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
                      es ? 'Historial de roles' : 'Role history',
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
    final es = Localizations.localeOf(context).languageCode == 'es';
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
          '${roleLabelOf(context, role)} · ${es ? 'desde' : 'since'} ${_formatDate(context, entry.assignedAt)}',
          style: t.caption.copyWith(
            fontWeight: isLatest ? FontWeight.w800 : FontWeight.w600,
            color: color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.isNegative) {
      // Future date (e.g. expiration)
      final absDiff = date.difference(now);
      if (absDiff.inDays > 0) {
        return es ? 'en ${absDiff.inDays}d' : 'in ${absDiff.inDays}d';
      }
      if (absDiff.inHours > 0) {
        return es ? 'en ${absDiff.inHours}h' : 'in ${absDiff.inHours}h';
      }
      return es
          ? 'en ${absDiff.inMinutes}min'
          : 'in ${absDiff.inMinutes}min';
    }

    if (diff.inDays == 0) {
      if (diff.inHours > 0) {
        return es ? 'hace ${diff.inHours}h' : '${diff.inHours}h ago';
      }
      if (diff.inMinutes > 0) {
        return es ? 'hace ${diff.inMinutes}min' : '${diff.inMinutes}min ago';
      }
      return es ? 'ahora' : 'now';
    }
    if (diff.inDays == 1) return es ? 'ayer' : 'yesterday';
    if (diff.inDays < 7) {
      return es ? 'hace ${diff.inDays}d' : '${diff.inDays}d ago';
    }
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return es ? 'hace $weeks sem' : '${weeks}w ago';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  String _formatExactDate(BuildContext context, DateTime date) {
    final localDate = date.toLocal();
    final material = MaterialLocalizations.of(context);
    final day = material.formatFullDate(localDate);
    final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(localDate));
    return '$day · $time';
  }
}
