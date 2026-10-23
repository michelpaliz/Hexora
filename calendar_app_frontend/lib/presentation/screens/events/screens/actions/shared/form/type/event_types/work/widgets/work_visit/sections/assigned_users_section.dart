import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/user/user.dart';

import 'section_card_builder.dart';

class AssignedUsersSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final List<User> usersAvailable;
  final List<User> initiallySelected;
  final String excludeUserId;
  final ValueChanged<List<User>> onSelectedUsersChanged;

  const AssignedUsersSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.usersAvailable,
    required this.initiallySelected,
    required this.excludeUserId,
    required this.onSelectedUsersChanged,
  });

  String _nameOf(User user) {
    final preferred = user.displayName?.trim();
    if (preferred != null && preferred.isNotEmpty) return preferred;
    if (user.name.trim().isNotEmpty) return user.name.trim();
    return user.userName;
  }

  Future<void> _chooseUsers(BuildContext context, List<User> available) async {
    final initialIds = initiallySelected.map((u) => u.id).toSet();
    final isDesktop = MediaQuery.sizeOf(context).width >= 600;
    List<User>? result;

    if (isDesktop) {
      result = await showDialog<List<User>>(
        context: context,
        builder: (_) => _WorkerPickerDialog(
          available: available,
          initialIds: initialIds,
          nameOf: _nameOf,
        ),
      );
    } else {
      result = await showModalBottomSheet<List<User>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        constraints: const BoxConstraints(maxWidth: 560),
        builder: (_) => _WorkerPickerSheet(
          available: available,
          initialIds: initialIds,
          nameOf: _nameOf,
        ),
      );
    }
    if (result != null) onSelectedUsersChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final available =
        usersAvailable.where((user) => user.id != excludeUserId).toList();
    final selected =
        initiallySelected.where((user) => user.id != excludeUserId).toList();
    final subtitle = available.isEmpty
        ? l.delegateNoWorkers
        : selected.isEmpty
            ? l.delegateVisitHint
            : selected.map(_nameOf).join(', ');

    return cardBuilder(
      title: title,
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              available.isEmpty ? null : () => _chooseUsers(context, available),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.group_add_outlined, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.delegateVisit,
                        style: t.bodyLarge!.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            t.bodyMedium!.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (selected.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      '${selected.length}',
                      style:
                          t.bodyMedium!.copyWith(color: cs.onPrimaryContainer),
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared picker body ────────────────────────────────────────────────────────

class _WorkerPickerBody extends StatefulWidget {
  const _WorkerPickerBody({
    required this.available,
    required this.initialIds,
    required this.nameOf,
  });

  final List<User> available;
  final Set<String> initialIds;
  final String Function(User) nameOf;

  @override
  State<_WorkerPickerBody> createState() => _WorkerPickerBodyState();
}

class _WorkerPickerBodyState extends State<_WorkerPickerBody> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.initialIds);
  }

  void _toggle(String id) => setState(() {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      });

  List<User> get _result =>
      widget.available.where((u) => _selectedIds.contains(u.id)).toList();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final count = _selectedIds.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.delegateVisit,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$count',
                    style: tt.labelMedium
                        ?.copyWith(color: cs.onPrimaryContainer),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Worker list
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.available.length,
            itemBuilder: (_, i) {
              final user = widget.available[i];
              final name = widget.nameOf(user);
              final selected = _selectedIds.contains(user.id);
              final initial =
                  name.isNotEmpty ? name[0].toUpperCase() : '?';

              return Material(
                color: selected
                    ? cs.primaryContainer.withValues(alpha: 0.35)
                    : Colors.transparent,
                child: InkWell(
                  onTap: () => _toggle(user.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: selected
                              ? cs.primary.withValues(alpha: 0.15)
                              : cs.surfaceContainerHighest,
                          backgroundImage:
                              user.photoUrl?.trim().isNotEmpty == true
                                  ? NetworkImage(user.photoUrl!.trim())
                                  : null,
                          child: user.photoUrl?.trim().isNotEmpty != true
                              ? Text(
                                  initial,
                                  style: tt.bodyMedium?.copyWith(
                                    color: selected
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        // Name + username
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              if (user.userName != name)
                                Text(
                                  '@${user.userName}',
                                  style: tt.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                        // Checkbox
                        Checkbox(
                          value: selected,
                          onChanged: (_) => _toggle(user.id),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        // Confirm button
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FilledButton(
            onPressed: count == 0
                ? null
                : () => Navigator.pop(context, _result),
            child: Text(
              count == 0
                  ? l.confirm
                  : '${l.confirm} ($count)',
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mobile bottom sheet wrapper ───────────────────────────────────────────────

class _WorkerPickerSheet extends StatelessWidget {
  const _WorkerPickerSheet({
    required this.available,
    required this.initialIds,
    required this.nameOf,
  });

  final List<User> available;
  final Set<String> initialIds;
  final String Function(User) nameOf;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.80;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: _WorkerPickerBody(
        available: available,
        initialIds: initialIds,
        nameOf: nameOf,
      ),
    );
  }
}

// ── Desktop dialog wrapper ────────────────────────────────────────────────────

class _WorkerPickerDialog extends StatelessWidget {
  const _WorkerPickerDialog({
    required this.available,
    required this.initialIds,
    required this.nameOf,
  });

  final List<User> available;
  final Set<String> initialIds;
  final String Function(User) nameOf;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.80;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: maxH),
        child: _WorkerPickerBody(
          available: available,
          initialIds: initialIds,
          nameOf: nameOf,
        ),
      ),
    );
  }
}
