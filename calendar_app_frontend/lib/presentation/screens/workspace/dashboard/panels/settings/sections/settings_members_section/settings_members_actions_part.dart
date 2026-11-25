part of '../settings_members_section.dart';

extension _SettingsMembersActionsPart on _SettingsMembersSectionState {
  Future<void> _createInvitationShareLink(Invitation invitation) async {
    if (_invitationActionId != null ||
        invitation.status != InvitationStatus.pending) {
      return;
    }
    final es = Localizations.localeOf(context).languageCode == 'es';
    final messenger = ScaffoldMessenger.of(context);
    _updateUi(() => _invitationActionId = invitation.id);

    Map<String, dynamic>? result;
    try {
      result = await context
          .read<InvitationDomain>()
          .createShareLinkOrThrow(invitation.id);
      _updateUi(() {
        _invitationAuditFuture = context
            .read<InvitationDomain>()
            .listAudit(widget.group.id, invitation.id);
      });
    } catch (error) {
      final forbidden = error is BackendApiException &&
          error.code == 'INVITATION_ROLE_FORBIDDEN';
      final cooldown = error is BackendApiException &&
          error.code == 'INVITATION_SHARE_LINK_COOLDOWN';
      messenger.showSnackBar(SnackBar(
        content: Text(
          forbidden
              ? (es
                  ? 'No tienes permiso para compartir esta invitación.'
                  : 'You do not have permission to share this invitation.')
              : cooldown
                  ? (es
                      ? 'Espera un momento antes de crear otro enlace.'
                      : 'Please wait before creating another link.')
                  : (es
                      ? 'No se pudo crear el enlace de invitación.'
                      : 'The invitation link could not be created.'),
        ),
      ));
    } finally {
      _updateUi(() => _invitationActionId = null);
    }
    if (result == null || !mounted) return;

    final url = result['url']?.toString() ?? '';
    final expiresAt = DateTime.tryParse(result['expiresAt']?.toString() ?? '');
    if (url.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(es
            ? 'El servidor no devolvió un enlace válido.'
            : 'The server did not return a valid link.'),
      ));
      return;
    }
    final copied = await showHexoraDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final material = MaterialLocalizations.of(dialogContext);
            final localExpiry = expiresAt?.toLocal();
            final expiryLabel = localExpiry == null
                ? null
                : '${material.formatFullDate(localExpiry)} · '
                    '${material.formatTimeOfDay(TimeOfDay.fromDateTime(localExpiry))}';
            return AlertDialog(
              title: Text(es
                  ? 'Enlace seguro de invitación'
                  : 'Secure invitation link'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(es
                        ? 'Este enlace es independiente del enviado por email. Crear otro enlace manual reemplazará este, pero el enlace del email seguirá funcionando.'
                        : 'This link is separate from the emailed link. Creating another manual link will replace this one, while the emailed link will continue working.'),
                    if (expiryLabel != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${es ? 'Caduca' : 'Expires'}: $expiryLabel',
                        style: Theme.of(dialogContext).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(dialogContext)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SelectableText(url),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(es ? 'Cerrar' : 'Close'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await Clipboard.setData(ClipboardData(text: url));
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(true);
                      }
                    } catch (_) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(es
                                ? 'No se pudo copiar. Puedes seleccionar el enlace manualmente.'
                                : 'Could not copy. You can select the link manually.'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  label: Text(es ? 'Copiar enlace' : 'Copy link'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (copied && mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text(es ? 'Enlace copiado.' : 'Link copied.'),
      ));
    }
  }

  Future<void> _changeInvitationRole(Invitation invitation) async {
    if (_invitationActionId != null ||
        invitation.status != InvitationStatus.pending) {
      return;
    }
    final es = Localizations.localeOf(context).languageCode == 'es';
    final currentUserId = context.read<UserDomain?>()?.user?.id ?? '';
    final actorRole = GroupRole.fromWire(
      currentUserId == widget.group.ownerId
          ? GroupRole.owner.wire
          : widget.group.userRoles[currentUserId],
    );
    final roles = const [
      GroupRole.member,
      GroupRole.coAdmin,
      GroupRole.admin,
    ].where((role) => actorRole.wire == GroupRole.owner.wire ||
        role.rank < actorRole.rank).toList();
    if (roles.isEmpty ||
        (actorRole.wire != GroupRole.owner.wire &&
            invitation.role.rank >= actorRole.rank)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(es
            ? 'No tienes permiso para cambiar este rol.'
            : 'You do not have permission to change this role.'),
      ));
      return;
    }

    var selectedRole = invitation.role;
    final chosen = await showHexoraDialog<GroupRole>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(es
              ? 'Cambiar rol de la invitación'
              : 'Change invitation role'),
          content: SizedBox(
            width: 400,
            child: DropdownButtonFormField<GroupRole>(
              initialValue: selectedRole,
              decoration: InputDecoration(
                labelText: es ? 'Rol al aceptar' : 'Role after accepting',
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              items: roles
                  .map((role) => DropdownMenuItem<GroupRole>(
                        value: role,
                        child: Text(roleLabelOf(dialogContext, role)),
                      ))
                  .toList(),
              onChanged: (role) {
                if (role != null) {
                  setDialogState(() => selectedRole = role);
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(es ? 'Cancelar' : 'Cancel'),
            ),
            FilledButton(
              onPressed: selectedRole.wire == invitation.role.wire
                  ? null
                  : () => Navigator.of(dialogContext).pop(selectedRole),
              child: Text(es ? 'Guardar rol' : 'Save role'),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;

    _updateUi(() => _invitationActionId = invitation.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await context
          .read<InvitationDomain>()
          .updateRoleOrThrow(invitation.id, chosen.wire);
      await widget.membersVM.refreshAll();
      _updateUi(() {
        _selectedInvitation = updated.copyWith(
          invitedByName: invitation.invitedByName,
        );
        _invitationAuditFuture = context
            .read<InvitationDomain>()
            .listAudit(widget.group.id, updated.id);
      });
      messenger.showSnackBar(SnackBar(
        content: Text(es
            ? 'Rol de la invitación actualizado.'
            : 'Invitation role updated.'),
      ));
    } catch (error) {
      final forbidden = error is BackendApiException &&
          error.code == 'INVITATION_ROLE_FORBIDDEN';
      messenger.showSnackBar(SnackBar(
        content: Text(forbidden
            ? (es
                ? 'No tienes permiso para asignar ese rol.'
                : 'You do not have permission to assign that role.')
            : (es
                ? 'No se pudo actualizar el rol de la invitación.'
                : 'The invitation role could not be updated.')),
      ));
    } finally {
      _updateUi(() => _invitationActionId = null);
    }
  }

  Future<void> _resendInvitation(Invitation invitation) async {
    if (_invitationActionId != null) return;
    _updateUi(() => _invitationActionId = invitation.id);
    final messenger = ScaffoldMessenger.of(context);
    final es = Localizations.localeOf(context).languageCode == 'es';
    try {
      final updated =
          await context.read<InvitationDomain>().resendOrThrow(invitation.id);
      await widget.membersVM.refreshAll();
      _updateUi(() {
        if (_selectedInvitation?.id == invitation.id) {
          _selectedInvitation = updated.copyWith(
            invitedByName: invitation.invitedByName,
          );
          _invitationAuditFuture = context
              .read<InvitationDomain>()
              .listAudit(widget.group.id, updated.id);
        }
      });
      messenger.showSnackBar(SnackBar(
        content: Text(es ? 'Invitación reenviada.' : 'Invitation resent.'),
      ));
    } catch (error) {
      final isCooldown = error is BackendApiException &&
          error.code == 'INVITATION_RESEND_COOLDOWN';
      messenger.showSnackBar(SnackBar(
        content: Text(isCooldown
            ? (es
                ? 'Espera unos minutos antes de volver a enviar la invitación.'
                : 'Please wait a few minutes before resending the invitation.')
            : (es
                ? 'No se pudo reenviar la invitación.'
                : 'The invitation could not be resent.')),
      ));
    } finally {
      _updateUi(() => _invitationActionId = null);
    }
  }

  Future<void> _revokeInvitation(Invitation invitation) async {
    if (_invitationActionId != null) return;
    final es = Localizations.localeOf(context).languageCode == 'es';
    final confirmed = await showHexoraDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(es ? 'Revocar invitación' : 'Revoke invitation'),
            content: Text(es
                ? 'Esta persona ya no podrá aceptar esta invitación.'
                : 'This person will no longer be able to accept this invitation.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(es ? 'Cancelar' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(es ? 'Revocar' : 'Revoke'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    _updateUi(() => _invitationActionId = invitation.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await context.read<InvitationDomain>().revoke(invitation.id);
      if (updated == null) throw StateError('Invitation revoke failed');
      await widget.membersVM.refreshAll();
      _updateUi(() {
        if (_selectedInvitation?.id == invitation.id) {
          _selectedInvitation = updated.copyWith(
            invitedByName: invitation.invitedByName,
          );
          _invitationAuditFuture = context
              .read<InvitationDomain>()
              .listAudit(widget.group.id, updated.id);
        }
      });
      messenger.showSnackBar(SnackBar(
        content: Text(es ? 'Invitación revocada.' : 'Invitation revoked.'),
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(es
            ? 'No se pudo revocar la invitación.'
            : 'The invitation could not be revoked.'),
      ));
    } finally {
      _updateUi(() => _invitationActionId = null);
    }
  }

  Future<void> _changeRole(User user, GroupRole newRole) async {
    final gd = context.read<GroupDomain>();
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    // Keep role changes staged until the backend confirms them.
    final oldRoles = <String, String>{
      ...widget.group.userRoles,
      ...gd.userRoles.value,
    };
    final updatedRoles = Map<String, String>.from(oldRoles)
      ..[user.id] = newRole.wire;

    try {
      final repo = gd.groupRepository;
      await repo.setUserRoleInGroup(
        groupId: widget.group.id,
        userId: user.id,
        roleWire: newRole.wire,
      );

      gd.userRoles.value = updatedRoles;
      gd.publishCurrentGroupUpdate(
        widget.group.copyWith(userRoles: updatedRoles),
      );
      _updateUi(() {
        _confirmedRoleOverrides[user.id] = newRole.wire;
        _pendingRole = null;
      });

      messenger.showSnackBar(
        SnackBar(content: Text(l.saveChanges)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el cambio de rol.')),
      );
    }
  }

  Future<bool> _confirmDiscardPendingRole(BuildContext context) async {
    if (_pendingRole == null) return true;

    return await showHexoraDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Descartar cambios'),
            content: const Text(
              'Tienes un cambio de rol sin guardar. ¿Quieres descartarlo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Seguir editando'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _confirmRemoveMember(BuildContext context, User user) async {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final gd = context.read<GroupDomain>();
    final messenger = ScaffoldMessenger.of(context);
    final displayName = user.name.isNotEmpty ? user.name : user.userName;

    final confirm = await showHexoraDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(l.remove),
            content: Text(
              '${l.remove} $displayName?',
              style: t.bodySmall,
            ),
            actions: [
              TextButton(
                style: ThemedButtons.button(
                  context,
                  variant: ButtonVariant.ghost,
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.cancel),
              ),
              FilledButton(
                style: ThemedButtons.button(
                  context,
                  variant: ButtonVariant.danger,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.remove),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final repo = gd.groupRepository;
      await repo.leaveGroup(user.id, widget.group.id);

      final updatedUserIds = List<String>.from(widget.group.userIds)
        ..remove(user.id);
      final updatedRoles = Map<String, String>.from(gd.userRoles.value)
        ..remove(user.id);
      gd.userRoles.value = updatedRoles;
      gd.publishCurrentGroupUpdate(
        widget.group.copyWith(
          userIds: updatedUserIds,
          userRoles: updatedRoles,
        ),
      );

      widget.membersVM.refreshAll();

      _updateUi(() {
        _selectedMember = null;
        _selectedUser = null;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(l.remove)),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.pendingEventsError)),
        );
      }
    }
  }
}
