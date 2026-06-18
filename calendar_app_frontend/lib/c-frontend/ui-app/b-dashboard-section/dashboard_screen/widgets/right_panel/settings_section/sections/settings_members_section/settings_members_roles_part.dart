part of '../settings_members_section.dart';

extension _SettingsMembersRolesPart on _SettingsMembersSectionState {
  // ── Entry point ────────────────────────────────────────────────────────────
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
                isCurrent:
                    def.wire.toLowerCase() == data.currentUserRole.toLowerCase(),
              ),
            ),
      ],
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
                    def.label.isNotEmpty ? def.label : roleLabelOf(context, role),
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? color : cs.onSurface,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
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
      case 'canInvite':
        return l.permLabelInvite;
      case 'canKick':
        return l.permLabelKick;
      case 'canEdit':
      case 'canEditGroup':
        return l.permLabelEditGroup;
      case 'canDelete':
      case 'canDeleteGroup':
        return l.permLabelDeleteGroup;
      case 'canManageRoles':
        return l.permLabelManageRoles;
      case 'canViewBilling':
        return l.permLabelViewBilling;
      case 'canManageInvoices':
        return l.permLabelManageInvoices;
      case 'canManageBudgets':
        return l.permLabelManageBudgets;
      case 'canViewMembers':
        return l.permLabelViewMembers;
      case 'canManageMembers':
        return l.permLabelManageMembers;
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
        final def = snap.data!.roleDefinitions
            .cast<RoleDefinition?>()
            .firstWhere(
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
            description,
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
