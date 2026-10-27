import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/show-groups/group_profile/dialog_choosement/action/edit_group_arg.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/group-settings/widgets/delete_group_dialog.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/create_edit/widgets/images/group_image.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/create_edit/widgets/fields/group_name_field.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/create_edit/widgets/fields/group_description_field.dart';
import 'package:hexora/presentation/shared/widgets/avatars/avatar_utils.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/upload_group_photo_usecase.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/update_group_usecase.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SettingsInfoSection extends StatefulWidget {
  final Group group;

  const SettingsInfoSection({
    super.key,
    required this.group,
  });

  @override
  State<SettingsInfoSection> createState() => _SettingsInfoSectionState();
}

class _SettingsInfoSectionState extends State<SettingsInfoSection> {
  bool _removing = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openEditDialog(Group group) async {
    final isWide = MediaQuery.of(context).size.width >= 600;
    if (isWide) {
      await showDialog<bool>(
        context: context,
        builder: (_) => _EditBusinessDialog(group: group),
      );
      if (!mounted) return;
      await context.read<GroupDomain>().refreshCurrentGroup();
    } else {
      final userDomain = context.read<UserDomain>();
      try {
        final users = await userDomain.getUsersForGroup(group);
        if (!mounted) return;
        await Navigator.of(context).pushNamed(
          AppRoutes.editGroupData,
          arguments: EditGroupArguments(group: group, users: users),
        );
        if (!mounted) return;
        await context.read<GroupDomain>().refreshCurrentGroup();
      } catch (_) {
        if (mounted) {
          _showError(AppLocalizations.of(context)!.failedToEditGroup);
        }
      }
    }
  }

  Future<void> _removeBusiness(Group group) async {
    if (_removing) return;
    setState(() => _removing = true);
    try {
      final groupDomain = context.read<GroupDomain>();
      final userDomain = context.read<UserDomain>();
      final fresh = await groupDomain.groupRepository.getGroupById(group.id);
      final user = userDomain.user ?? await userDomain.getUser();
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      if (user?.id != fresh.ownerId) {
        _showError(l.permissionDeniedInf);
        return;
      }
      final members = await userDomain.getUsersForGroup(fresh);
      if (!mounted) return;
      if (members.any((member) => member.id != fresh.ownerId)) {
        _showError(l.removeMembersFirst);
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => DeleteGroupDialog(groupName: fresh.name),
      );
      if (confirmed != true || !mounted) return;
      final removed = await groupDomain.removeGroup(fresh, userDomain);
      if (!mounted) return;
      if (!removed) {
        _showError(l.failedToEditGroup);
        return;
      }
      groupDomain.currentGroup = null;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.homePage,
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.failedToEditGroup);
      }
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  Map<String, int> _roleCounts(Group g) {
    final counts = <String, int>{};
    for (final role in g.userRoles.values) {
      final normalized = role.toLowerCase().trim();
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }
    return counts;
  }

  String _rolesSummary(Group g, AppLocalizations l) {
    final counts = _roleCounts(g);
    final parts = <String>[];
    final adminCount = (counts['owner'] ?? 0) +
        (counts['admin'] ?? 0) +
        (counts['co-admin'] ?? 0);
    final memberCount = counts['member'] ?? 0;
    if (adminCount > 0) parts.add('$adminCount admin');
    if (memberCount > 0) {
      parts.add('$memberCount ${l.membersTitle.toLowerCase()}');
    }
    return parts.isEmpty ? '-' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final groupDomain = context.watch<GroupDomain>();
    final currentUserId = context.watch<UserDomain>().user?.id;
    final liveGroup = groupDomain.currentGroup?.id == widget.group.id
        ? groupDomain.currentGroup!
        : widget.group;
    final isOwner = currentUserId == liveGroup.ownerId;
    final role = liveGroup.userRoles[currentUserId]?.toLowerCase();
    final canEdit = isOwner || role == 'admin' || role == 'co-admin';

    final createdStr =
        '${liveGroup.createdTime.day}/${liveGroup.createdTime.month}/${liveGroup.createdTime.year}';

    final hasTimeTracking = liveGroup.features?.timeTracking.enabled == true;
    final currency = liveGroup.features?.timeTracking.currency ?? 'EUR';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Compact business header ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarUtils.groupAvatar(
                context,
                liveGroup.photoUrl,
                radius: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      liveGroup.name,
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (liveGroup.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        liveGroup.description,
                        style: t.bodySmall
                            .copyWith(color: cs.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      createdStr,
                      style: t.caption
                          .copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                IconButton(
                  tooltip: l.edit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(
                        color:
                            cs.outlineVariant.withValues(alpha: .55)),
                  ),
                  onPressed: () => _openEditDialog(liveGroup),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Business information rows ──
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.people_outline_rounded,
                label: l.membersTitle,
                value: '${liveGroup.userIds.length}',
                detail: _rolesSummary(liveGroup, l),
              ),
              Divider(
                  height: 1,
                  indent: 44,
                  color: cs.outlineVariant.withValues(alpha: 0.25)),
              _InfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Invitaciones',
                value: '${liveGroup.inviteCount}',
                detail: liveGroup.lastInviteAt != null
                    ? '${liveGroup.lastInviteAt!.day}/${liveGroup.lastInviteAt!.month}/${liveGroup.lastInviteAt!.year}'
                    : null,
              ),
              Divider(
                  height: 1,
                  indent: 44,
                  color: cs.outlineVariant.withValues(alpha: 0.25)),
              _InfoRow(
                icon: Icons.tune_rounded,
                label: 'Features',
                value: hasTimeTracking ? 'Time tracking' : 'N/A',
                detail: hasTimeTracking ? currency : null,
              ),
              Divider(
                  height: 1,
                  indent: 44,
                  color: cs.outlineVariant.withValues(alpha: 0.25)),
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: l.statementsHeaderDate,
                value: createdStr,
              ),
            ],
          ),
        ),

        // ── Danger zone (owner only) ──
        if (isOwner) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: cs.error.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: cs.error),
                    const SizedBox(width: 8),
                    Text(
                      'Zona de peligro',
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Eliminar este negocio es permanente y no se puede deshacer.',
                  style:
                      t.caption.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                HexoraButton(
                  onPressed:
                      _removing ? null : () => _removeBusiness(liveGroup),
                  label: l.groupSettingsDeleteGroup,
                  icon: Icons.delete_outline,
                  variant: HexoraButtonVariant.danger,
                  size: HexoraButtonSize.compact,
                  loading: _removing,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: t.bodySmall
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              if (detail != null && detail!.isNotEmpty)
                Text(
                  detail!,
                  style: t.caption
                      .copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Compact edit dialog for desktop ──

class _EditBusinessDialog extends StatefulWidget {
  final Group group;
  const _EditBusinessDialog({required this.group});

  @override
  State<_EditBusinessDialog> createState() => _EditBusinessDialogState();
}

class _EditBusinessDialogState extends State<_EditBusinessDialog> {
  late TextEditingController _nameC;
  late TextEditingController _descC;
  XFile? _pickedImage;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.group.name);
    _descC = TextEditingController(text: widget.group.description);
    _nameC.addListener(_markDirty);
    _descC.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_dirty && _pickedImage == null) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar cambios'),
        content: const Text(
            'Tienes cambios sin guardar. ¿Deseas descartarlos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _save() async {
    final name = _nameC.text.trim();
    final desc = _descC.text.trim();
    if (name.isEmpty || desc.isEmpty) return;

    setState(() => _saving = true);
    try {
      final updateGroup = context.read<UpdateGroupUseCase>();
      await updateGroup(
        original: widget.group,
        name: name,
        description: desc,
      );

      if (_pickedImage != null && mounted) {
        final uploadPhoto = context.read<UploadGroupPhotoUseCase>();
        await uploadPhoto(groupId: widget.group.id, file: _pickedImage!);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.groupPhotoUpdated)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.failedToEditGroup)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final canSave =
        _nameC.text.trim().isNotEmpty && _descC.text.trim().isNotEmpty;

    return PopScope(
      canPop: !_dirty && _pickedImage == null,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.editGroup,
                        style: t.bodyLarge
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () async {
                        if (await _onWillPop()) {
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Compact image selector
                      Center(
                        child: GroupImage(
                          imageUrl: widget.group.photoUrl,
                          size: 80,
                          borderRadius: 14,
                          onPicked: (file) {
                            setState(() {
                              _pickedImage = file;
                              _dirty = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Name field
                      Text(
                        l.title(50),
                        style: t.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GroupNameField(
                        controller: _nameC,
                        onChanged: (_) => _markDirty(),
                      ),
                      const SizedBox(height: 14),

                      // Description field
                      Text(
                        l.description(200),
                        style: t.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GroupDescriptionField(
                        controller: _descC,
                        onChanged: (_) => _markDirty(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Footer actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HexoraButton(
                      onPressed: () async {
                        if (await _onWillPop()) {
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      label: 'Cancelar',
                      variant: HexoraButtonVariant.ghost,
                    ),
                    const SizedBox(width: 8),
                    HexoraButton(
                      onPressed:
                          canSave && !_saving ? _save : null,
                      label: 'Guardar cambios',
                      icon: Icons.save_outlined,
                      loading: _saving,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
