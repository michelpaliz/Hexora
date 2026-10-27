part of '../settings_members_section.dart';

extension _SettingsMembersRolesPart on _SettingsMembersSectionState {
  void _showPermissionsGuide(BuildContext context) {
    _permissionsFuture ??= context
        .read<GroupDomain>()
        .groupRepository
        .getGroupPermissions(widget.group.id);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width >= 900 ? 860 : size.width - 32,
              maxHeight: size.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Guía de permisos',
                          style: Theme.of(dialogContext).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consulta los permisos de cada rol',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: FutureBuilder<GroupPermissionsResponse>(
                      future: _permissionsFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snap.hasError || !snap.hasData) {
                          return _buildPermissionsError(context, snap.error);
                        }
                        return _buildCompactPermissionsGuide(
                            context, snap.data!);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Entry point ────────────────────────────────────────────────────────────
  // Retained as the legacy full guide while the compact dialog is rolled out.
  // ignore: unused_element
  Widget _buildRolesTab(BuildContext context) {
    _permissionsFuture ??= context
        .read<GroupDomain>()
        .groupRepository
        .getGroupPermissions(widget.group.id);

    return FutureBuilder<GroupPermissionsResponse>(
      future: _permissionsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snap.hasError) {
          return _buildPermissionsError(context, snap.error);
        }
        final data = snap.data!;
        return _buildRolesContent(context, data);
      },
    );
  }

  Widget _buildPermissionsError(BuildContext context, Object? error) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: cs.error, size: 32),
          const SizedBox(height: 10),
          Text(
            l.rolesLoadError,
            style: t.bodySmall.copyWith(
              color: cs.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            style: ThemedButtons.button(
              context,
              variant: ButtonVariant.ghost,
            ),
            onPressed: () => _updateUi(() => _permissionsFuture = null),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: Text(l.rolesRetryButton),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesContent(
    BuildContext context,
    GroupPermissionsResponse data,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── My current role banner ─────────────────────────────────────────
        _buildMyRoleBanner(context, data.currentUserRole, data.permissions),
        const SizedBox(height: 16),

        // ── Section title ──────────────────────────────────────────────────
        Row(
          children: [
            Icon(
              Icons.format_list_bulleted_rounded,
              size: 13,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              l.rolesGuideTitle,
              style: t.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Role definition cards ──────────────────────────────────────────
        if (data.roleDefinitions.isEmpty)
          _buildFallbackRolesGuide(context)
        else
          for (final def in data.roleDefinitions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildRoleCard(
                context,
                def: def,
                isCurrent: def.wire.toLowerCase() ==
                    data.currentUserRole.toLowerCase(),
              ),
            ),
      ],
    );
  }

  Widget _buildCompactPermissionsGuide(
    BuildContext context,
    GroupPermissionsResponse data,
  ) {
    final definitions = [...data.roleDefinitions]..sort(
        (a, b) => GroupRole.fromWire(b.wire)
            .rank
            .compareTo(GroupRole.fromWire(a.wire).rank),
      );
    if (definitions.isEmpty) return _buildFallbackRolesGuide(context);

    final permissions = <String>{
      for (final definition in definitions) ...definition.permissions.keys,
    }.toList()
      ..sort();

    return Scrollbar(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 38,
            dataRowMaxHeight: 44,
            columnSpacing: 20,
            columns: [
              const DataColumn(label: Text('Permiso')),
              for (final definition in definitions)
                DataColumn(
                  label: Tooltip(
                    message: definition.label,
                    child: Text(
                      roleLabelOf(context, GroupRole.fromWire(definition.wire)),
                    ),
                  ),
                ),
            ],
            rows: [
              for (final permission in permissions)
                DataRow(
                  cells: [
                    DataCell(
                      Tooltip(
                        message: _permissionExplanation(context, permission),
                        child: Text(_permissionLabel(context, permission)),
                      ),
                    ),
                    for (final definition in definitions)
                      DataCell(
                        SizedBox(
                          width: 30,
                          child: Center(
                            child: definition.permissions[permission] == true
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 17,
                                    color: Colors.green.shade700,
                                  )
                                : Text(
                                    '—',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── My role banner ─────────────────────────────────────────────────────────
  Widget _buildMyRoleBanner(
    BuildContext context,
    String roleWire,
    Map<String, bool> permissions,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final role = GroupRole.fromWire(roleWire);
    final color = role.roleChipColor(cs);
    final label = roleLabelOf(context, role);

    final enabledCount = permissions.values.where((v) => v).length;
    final totalCount = permissions.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            cs.primaryContainer.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(role.icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.rolesCurrentRoleLabel,
                  style: t.caption.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  label,
                  style: t.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (totalCount > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$enabledCount/$totalCount',
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  l.rolesPermissionsUnit,
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

  // ── Individual role definition card ────────────────────────────────────────
  Widget _buildRoleCard(
    BuildContext context, {
    required RoleDefinition def,
    required bool isCurrent,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final role = GroupRole.fromWire(def.wire);
    final color = role.roleChipColor(cs);

    return Container(
      decoration: BoxDecoration(
        color: isCurrent
            ? color.withValues(alpha: 0.06)
            : cs.surfaceContainerHighest.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? color.withValues(alpha: 0.25)
              : cs.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Icon(role.icon, size: 15, color: color),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    def.label.isNotEmpty
                        ? def.label
                        : roleLabelOf(context, role),
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? color : cs.onSurface,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l.rolesYourRoleBadge,
                      style: t.caption.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Description
          if (def.description != null && def.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Text(
                _localizedRoleDesc(context, role, def.description!),
                style: t.caption.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Permissions
          if (def.permissions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Wrap(
                spacing: 5,
                runSpacing: 4,
                children: def.permissions.entries
                    .map((e) => _buildPermissionChip(context, e.key, e.value))
                    .toList(),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ── Permission chip ────────────────────────────────────────────────────────
  Widget _buildPermissionChip(
    BuildContext context,
    String key,
    bool granted,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final label = _permissionLabel(context, key);
    final color = granted ? Colors.green.shade600 : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: granted
            ? Colors.green.withValues(alpha: 0.08)
            : cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: granted
              ? Colors.green.withValues(alpha: 0.2)
              : cs.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? Icons.check_rounded : Icons.remove_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Fallback guide when backend returns no roleDefinitions ─────────────────
  Widget _buildFallbackRolesGuide(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          for (final role in GroupRole.defaults)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: role.roleChipColor(cs).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      role.icon,
                      size: 14,
                      color: role.roleChipColor(cs),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roleLabelOf(context, role),
                          style: t.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: role.roleChipColor(cs),
                          ),
                        ),
                        Text(
                          _fallbackRoleDescription(context, role),
                          style: t.caption.copyWith(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Convert camelCase permission keys to localized labels.
  String _permissionLabel(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    switch (key) {
      case 'canManageBilling':
        return 'Gestionar facturación';
      case 'canViewAllData':
        return 'Ver datos compartidos';
      case 'canInvite':
        return l.permLabelInvite;
      case 'canKick':
        return l.permLabelKick;
      case 'canEdit':
      case 'canEditGroup':
        return 'Configurar negocio';
      case 'canDelete':
      case 'canDeleteGroup':
        return l.permLabelDeleteGroup;
      case 'canManageRoles':
        return 'Gestionar roles';
      case 'canViewBilling':
        return 'Gestionar facturación';
      case 'canManageInvoices':
        return l.permLabelManageInvoices;
      case 'canManageBudgets':
        return l.permLabelManageBudgets;
      case 'canViewMembers':
        return l.permLabelViewMembers;
      case 'canManageMembers':
        return 'Gestionar miembros';
      case 'canSendMessages':
        return l.permLabelSendMessages;
      case 'canViewCalendar':
        return l.permLabelViewCalendar;
      case 'canEditCalendar':
        return l.permLabelEditCalendar;
      case 'canManageEvents':
        return l.permLabelManageEvents;
      case 'canViewReports':
        return l.permLabelViewReports;
      case 'canManageSettings':
        return l.permLabelManageSettings;
      case 'canTransferOwnership':
        return l.permLabelTransferOwnership;
      // Category-based keys from backend roleDefinitions
      case 'group':
        return l.permLabelGroup;
      case 'statements':
        return l.permLabelStatements;
      case 'calendar':
        return l.permLabelCalendar;
      case 'events':
        return l.permLabelEvents;
      case 'timeTracking':
      case 'time Tracking':
      case 'time tracking':
        return l.permLabelTimeTracking;
      case 'expenses':
        return l.permLabelExpenses;
      case 'invoices':
        return l.permLabelInvoices;
      case 'reports':
        return l.permLabelReports;
      case 'settings':
        return l.permLabelSettings;
      case 'members':
        return l.permLabelMembers;
      default:
        // Fallback: humanize camelCase
        final stripped = key.startsWith('can') ? key.substring(3) : key;
        return stripped
            .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
            .trim();
    }
  }

  String _permissionExplanation(BuildContext context, String key) {
    switch (key) {
      case 'canManageBilling':
      case 'canViewBilling':
        return 'Permite consultar y gestionar la facturación del negocio.';
      case 'canEdit':
      case 'canEditGroup':
        return 'Permite cambiar la configuración general del negocio.';
      case 'canManageMembers':
        return 'Permite invitar, quitar y gestionar miembros según el rol.';
      case 'canManageRoles':
        return 'Permite cambiar roles dentro de los límites del rol propio.';
      case 'canViewAllData':
        return 'Permite consultar los datos compartidos del negocio.';
      default:
        return _permissionLabel(context, key);
    }
  }

  String _fallbackRoleDescription(BuildContext context, GroupRole role) {
    final l = AppLocalizations.of(context)!;
    if (role == GroupRole.owner) return l.roleFallbackDescOwner;
    if (role == GroupRole.admin) return l.roleFallbackDescAdmin;
    if (role == GroupRole.coAdmin) return l.roleFallbackDescCoAdmin;
    return l.roleFallbackDescMember;
  }

  String _localizedRoleDesc(
    BuildContext context,
    GroupRole role,
    String backendDesc,
  ) {
    final l = AppLocalizations.of(context)!;
    if (role == GroupRole.owner) return l.roleDescOwner;
    if (role == GroupRole.admin) return l.roleDescAdmin;
    if (role == GroupRole.coAdmin) return l.roleDescCoAdmin;
    if (role == GroupRole.member) return l.roleDescMember;
    return backendDesc;
  }

  /// Shows the role description from the backend's roleDefinitions,
  /// reusing [_permissionsFuture] so it only fetches once.
  Widget _buildRoleDescriptionFromPermissions(
    BuildContext context,
    GroupRole role,
  ) {
    _permissionsFuture ??= context
        .read<GroupDomain>()
        .groupRepository
        .getGroupPermissions(widget.group.id);

    return FutureBuilder<GroupPermissionsResponse>(
      future: _permissionsFuture,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final def =
            snap.data!.roleDefinitions.cast<RoleDefinition?>().firstWhere(
                  (d) => d!.wire.toLowerCase() == role.wire.toLowerCase(),
                  orElse: () => null,
                );
        final description = def?.description;
        if (description == null || description.isEmpty) {
          return const SizedBox.shrink();
        }
        final t = AppTypography.of(context);
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _localizedRoleDesc(context, role, description),
            style: t.caption.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      },
    );
  }
}
