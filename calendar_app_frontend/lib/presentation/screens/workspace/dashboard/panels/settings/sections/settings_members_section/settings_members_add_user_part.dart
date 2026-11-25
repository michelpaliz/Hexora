part of '../settings_members_section.dart';

extension _SettingsMembersAddUserPart on _SettingsMembersSectionState {
  Future<void> _inviteExternalEmail(BuildContext context) async {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final emailController = TextEditingController();
    final currentUserId = context.read<UserDomain?>()?.user?.id ?? '';
    final currentRoleWire = currentUserId == widget.group.ownerId
        ? GroupRole.owner.wire
        : widget.group.userRoles[currentUserId] ?? GroupRole.member.wire;
    final currentRole = GroupRole.fromWire(currentRoleWire);
    final availableRoles = const [
      GroupRole.member,
      GroupRole.coAdmin,
      GroupRole.admin,
    ].where((role) => currentRole.wire == GroupRole.owner.wire ||
        role.rank < currentRole.rank).toList();
    if (availableRoles.isEmpty) {
      emailController.dispose();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(es
            ? 'No tienes permiso para enviar invitaciones.'
            : 'You do not have permission to send invitations.'),
      ));
      return;
    }
    var selectedRole = GroupRole.member;
    var submitting = false;
    var reviewing = false;
    var removedDuplicates = 0;
    String? formError;
    List<String> reviewEmails = const [];
    final rolesByEmail = <String, GroupRole>{};

    String roleDescription(GroupRole role) {
      if (role.wire == GroupRole.admin.wire) {
        return es
            ? 'Gestiona miembros, roles y la configuración del negocio.'
            : 'Manages members, roles, and business settings.';
      }
      if (role.wire == GroupRole.coAdmin.wire) {
        return es
            ? 'Ayuda a gestionar el trabajo diario y las invitaciones.'
            : 'Helps manage daily work and invitations.';
      }
      return es
          ? 'Usa las herramientas del negocio que tenga disponibles.'
          : 'Uses the business tools made available to them.';
    }

    final result = await showHexoraDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(es ? 'Invitar por email' : 'Invite by email'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!reviewing) ...[
                  Text(es
                      ? 'Añade hasta 50 emails separados por comas, espacios o líneas. Podrás revisar los roles antes de enviar.'
                      : 'Add up to 50 emails separated by commas, spaces, or lines. You can review roles before sending.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    enabled: !submitting,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 7,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: es ? 'Emails' : 'Email addresses',
                      hintText: 'ana@example.com\nmarco@example.com',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      errorText: formError,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<GroupRole>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText:
                          es ? 'Rol inicial para todos' : 'Initial role for all',
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    items: availableRoles
                        .map((role) => DropdownMenuItem<GroupRole>(
                              value: role,
                              child: Text(roleLabelOf(dialogContext, role)),
                            ))
                        .toList(),
                    onChanged: submitting
                        ? null
                        : (role) {
                            if (role == null) return;
                            setDialogState(() => selectedRole = role);
                          },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roleDescription(selectedRole),
                    style:
                        Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                              color: Theme.of(dialogContext)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                  ),
                ] else ...[
                  Text(es
                      ? '${reviewEmails.length} invitación(es) listas para enviar.'
                      : '${reviewEmails.length} invitation(s) ready to send.'),
                  if (removedDuplicates > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        es
                            ? 'Se eliminaron $removedDuplicates email(s) duplicados.'
                            : '$removedDuplicates duplicate email(s) removed.',
                        style: Theme.of(dialogContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(dialogContext)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: reviewEmails.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final email = reviewEmails[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 155,
                                child: DropdownButtonFormField<GroupRole>(
                                  initialValue: rolesByEmail[email],
                                  isDense: true,
                                  decoration: InputDecoration(
                                    labelText: es ? 'Rol' : 'Role',
                                  ),
                                  items: availableRoles
                                      .map((role) =>
                                          DropdownMenuItem<GroupRole>(
                                            value: role,
                                            child: Text(roleLabelOf(
                                                dialogContext, role)),
                                          ))
                                      .toList(),
                                  onChanged: submitting
                                      ? null
                                      : (role) {
                                          if (role != null) {
                                            setDialogState(() =>
                                                rolesByEmail[email] = role);
                                          }
                                        },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (reviewing)
              TextButton(
                onPressed: submitting
                    ? null
                    : () => setDialogState(() {
                          reviewing = false;
                          formError = null;
                        }),
                child: Text(es ? 'Atrás' : 'Back'),
              ),
            TextButton(
              onPressed: submitting
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: Text(es ? 'Cancelar' : 'Cancel'),
            ),
            FilledButton.icon(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!reviewing) {
                        final rawEmails = emailController.text
                            .split(RegExp(r'[\s,;]+'))
                            .map((email) => email.trim().toLowerCase())
                            .where((email) => email.isNotEmpty)
                            .toList(growable: false);
                        final uniqueEmails = <String>[];
                        final seen = <String>{};
                        for (final email in rawEmails) {
                          if (seen.add(email)) uniqueEmails.add(email);
                        }
                        final emailPattern =
                            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                        final invalid = uniqueEmails
                            .where((email) =>
                                email.length > 254 ||
                                !emailPattern.hasMatch(email))
                            .toList(growable: false);
                        if (uniqueEmails.isEmpty) {
                          setDialogState(() {
                            formError = es
                                ? 'Añade al menos un email válido.'
                                : 'Add at least one valid email address.';
                          });
                          return;
                        }
                        if (uniqueEmails.length > 50) {
                          setDialogState(() {
                            formError = es
                                ? 'Puedes enviar un máximo de 50 invitaciones cada vez.'
                                : 'You can send a maximum of 50 invitations at a time.';
                          });
                          return;
                        }
                        if (invalid.isNotEmpty) {
                          final sample = invalid.take(3).join(', ');
                          setDialogState(() {
                            formError = es
                                ? 'Revisa estos emails: $sample'
                                : 'Check these email addresses: $sample';
                          });
                          return;
                        }
                        setDialogState(() {
                          removedDuplicates =
                              rawEmails.length - uniqueEmails.length;
                          reviewEmails = uniqueEmails;
                          rolesByEmail
                            ..clear()
                            ..addEntries(uniqueEmails.map(
                              (email) => MapEntry(email, selectedRole),
                            ));
                          reviewing = true;
                          formError = null;
                        });
                        return;
                      }

                      setDialogState(() {
                        submitting = true;
                        formError = null;
                      });
                      var sent = 0;
                      var alreadyPending = 0;
                      var savedWithoutEmail = 0;
                      final failed = <String>[];
                      for (final email in reviewEmails) {
                        try {
                          await context
                              .read<InvitationDomain>()
                              .sendInvitationOrThrow(
                                groupId: widget.group.id,
                                email: email,
                                role:
                                    (rolesByEmail[email] ?? selectedRole).wire,
                              );
                          sent += 1;
                        } catch (error) {
                          if (error is BackendApiException &&
                              error.code ==
                                  'INVITATION_EMAIL_DELIVERY_FAILED') {
                            savedWithoutEmail += 1;
                          } else if (error is BackendApiException &&
                              error.code == 'INVITATION_ALREADY_PENDING') {
                            alreadyPending += 1;
                          } else {
                            final reason = error is BackendApiException
                                ? error.message
                                : (es
                                    ? 'Error desconocido'
                                    : 'Unknown error');
                            failed.add('$email — $reason');
                          }
                        }
                      }
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop({
                          'total': reviewEmails.length,
                          'sent': sent,
                          'alreadyPending': alreadyPending,
                          'savedWithoutEmail': savedWithoutEmail,
                          'failed': failed,
                        });
                      }
                    },
              icon: submitting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(reviewing
                  ? (es ? 'Enviar invitaciones' : 'Send invitations')
                  : (es ? 'Revisar' : 'Review')),
            ),
          ],
        ),
      ),
    );
    emailController.dispose();
    if (result == null || !mounted) return;

    final sent = result['sent'] as int? ?? 0;
    final savedWithoutEmail = result['savedWithoutEmail'] as int? ?? 0;
    if (sent + savedWithoutEmail > 0) {
      await widget.membersVM.refreshAll();
      if (!mounted) return;
      _updateUi(() {
        _selectedTab = 1;
        _selectedMember = null;
        _selectedUser = null;
        _selectedInvitation = null;
      });
    }
    if (!mounted) return;
    final alreadyPending = result['alreadyPending'] as int? ?? 0;
    final failed = (result['failed'] as List?)?.cast<String>() ?? const [];
    await showHexoraDialog<void>(
      context: context,
      builder: (summaryContext) => AlertDialog(
        title: Text(es ? 'Resultado de invitaciones' : 'Invitation results'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bulkInviteResultRow(
                summaryContext,
                icon: Icons.mark_email_read_outlined,
                label: es ? 'Enviadas' : 'Sent',
                count: sent,
                color: Colors.green,
              ),
              _bulkInviteResultRow(
                summaryContext,
                icon: Icons.schedule_send_outlined,
                label: es ? 'Ya estaban pendientes' : 'Already pending',
                count: alreadyPending,
                color: Theme.of(summaryContext).colorScheme.primary,
              ),
              _bulkInviteResultRow(
                summaryContext,
                icon: Icons.mail_lock_outlined,
                label: es
                    ? 'Guardadas sin entregar email'
                    : 'Saved without email delivery',
                count: savedWithoutEmail,
                color: Colors.orange,
              ),
              _bulkInviteResultRow(
                summaryContext,
                icon: Icons.error_outline_rounded,
                label: es ? 'Fallidas' : 'Failed',
                count: failed.length,
                color: Theme.of(summaryContext).colorScheme.error,
              ),
              if (failed.isNotEmpty) ...[
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: failed.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 5),
                    itemBuilder: (_, index) => Text(
                      failed[index],
                      style: Theme.of(summaryContext).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(summaryContext).pop(),
            child: Text(es ? 'Cerrar' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _bulkInviteResultRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSelectedInvitations(
    BuildContext context,
    AddUserController ctrl,
  ) async {
    if (_sendingInvitations || ctrl.selectedUsers.isEmpty) return;

    final selected = List<User>.from(ctrl.selectedUsers);
    final messenger = ScaffoldMessenger.of(context);
    final groupRepo = context.read<GroupDomain>().groupRepository;
    _updateUi(() => _sendingInvitations = true);

    try {
      var sent = 0;
      var alreadyPending = 0;
      for (final user in selected) {
        final role = ctrl.stagedRoleOf(user.id) ?? GroupRole.member;
        try {
          await groupRepo.sendGroupInvitation(
            groupId: widget.group.id,
            userId: user.id,
            roleWire: role.wire,
          );
          sent += 1;
        } on HttpFailure catch (error) {
          // A retry after a partial success can legitimately find the invite.
          if (error.statusCode != 409) rethrow;
          alreadyPending += 1;
        }
      }

      if (!mounted) return;
      ctrl.clearSelection();
      await widget.membersVM.refreshAll();
      if (!mounted) return;
      _updateUi(() {
        _selectedTab = 1;
        _selectedMember = null;
        _selectedUser = null;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(alreadyPending == 0
              ? '$sent invitación(es) enviada(s)'
              : '$sent enviada(s); $alreadyPending ya estaba(n) pendiente(s).'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo enviar la invitación: $error')),
      );
    } finally {
      _updateUi(() => _sendingInvitations = false);
    }
  }

  Widget _buildAddMembersTab(BuildContext context) {
    final currentUser = context.read<UserDomain?>()?.user;
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GroupEditorViewModel>(
          create: (c) => GroupEditorViewModel(
            currentUser: currentUser,
            ui: MaterialUiMessenger(c),
            createGroup: c.read<CreateGroupUseCase>(),
            inviteMembers: c.read<InviteMembersUseCase>(),
            uploadPhoto: c.read<UploadGroupPhotoUseCase>(),
            searchUsersUseCase: c.read<SearchUsersUseCase>(),
            updateGroup: c.read<UpdateGroupUseCase>(),
          )..enterEditFrom(widget.group),
        ),
        ProxyProvider<GroupEditorViewModel, IGroupEditorPort>(
          update: (_, vm, __) => VmGroupEditorPort(vm),
        ),
        ChangeNotifierProvider<AddUserController>(
          create: (ctx) =>
              AddUserController(port: ctx.read<IGroupEditorPort>()),
        ),
      ],
      child: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _seedVmFromGroupOnce(context);
          });

          final ctrl = context.watch<AddUserController>();
          final l = AppLocalizations.of(context)!;
          return Stack(
            children: [
              AddUsersTab(
                inviteByEmail: () => _inviteExternalEmail(context),
                openPicker: () async {
                  final useDialog = MediaQuery.sizeOf(context).width >= 720;
                  if (useDialog) {
                    await showHexoraDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<AddUserController>(),
                        child: const AddUsersPickerDialog(),
                      ),
                    );
                    return;
                  }

                  await showModalBottomSheet<void>(
                    sheetAnimationStyle: HexoraMotion.sheetStyle(context),
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => ChangeNotifierProvider.value(
                      value: context.read<AddUserController>(),
                      child: const AddUsersBottomSheet(),
                    ),
                  );
                },
              ),
              if (ctrl.selectedUsers.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: FilledButton.icon(
                    style: ThemedButtons.button(context),
                    onPressed: _sendingInvitations
                        ? null
                        : () => _sendSelectedInvitations(context, ctrl),
                    icon: _sendingInvitations
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: Text(l.done),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
