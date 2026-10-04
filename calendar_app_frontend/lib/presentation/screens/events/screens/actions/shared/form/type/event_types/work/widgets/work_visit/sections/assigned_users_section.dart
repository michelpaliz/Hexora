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
    final selectedIds = initiallySelected.map((user) => user.id).toSet();
    final l = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<List<User>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  l.delegateVisit,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final user = available[index];
                    return CheckboxListTile(
                      value: selectedIds.contains(user.id),
                      title: Text(_nameOf(user)),
                      subtitle: user.userName == _nameOf(user)
                          ? null
                          : Text('@${user.userName}'),
                      onChanged: (selected) => setSheetState(() {
                        if (selected == true) {
                          selectedIds.add(user.id);
                        } else {
                          selectedIds.remove(user.id);
                        }
                      }),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                    sheetContext,
                    available
                        .where((user) => selectedIds.contains(user.id))
                        .toList(),
                  ),
                  child: Text(l.confirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
