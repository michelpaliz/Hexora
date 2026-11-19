// add_users_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:provider/provider.dart';

import '../../../controller/add_user_controller.dart';
import '../../../domain/models/user_search_bar.dart';
import 'user_search_result_item.dart';

class AddUsersBottomSheet extends StatelessWidget {
  const AddUsersBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // handlexa
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // search
          Consumer<AddUserController>(
            builder: (_, ctrl, __) => UserSearchBar(
              hintText: 'Search by username…',
              onChanged: (q) => ctrl.searchUser(q, context),
              onClear: () => ctrl.clearResults(),
              autofocus: true,
            ),
          ),

          const SizedBox(height: 8),

          // results
          Flexible(
            child: Consumer<AddUserController>(
              builder: (context, ctrl, _) {
                final results = ctrl.searchResults;
                if (results.isEmpty) {
                  return const _Hint(
                      text: 'Type at least 3 characters to search.');
                }

                return ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: cs.outlineVariant),
                  itemBuilder: (context, i) {
                    final username = results[i];

                    // ✅ compute flags
                    final isMember = ctrl.port.membersById.values.any(
                      (u) => u.userName.toLowerCase() == username.toLowerCase(),
                    );
                    final isPending = ctrl.selectedUsers.any(
                      (u) => u.userName.toLowerCase() == username.toLowerCase(),
                    );

                    return UserSearchResultItem(
                      username: username,
                      isMember: isMember,
                      isPending: isPending,
                      onRemove:
                          isPending ? () => ctrl.unselect(username) : null,
                      onAdd: (isMember || isPending)
                          ? null
                          : () async {
                              await ctrl.addUser(username, context);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added @$username')),
                              );
                            },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Done'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class AddUsersPickerDialog extends StatelessWidget {
  const AddUsersPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = context.watch<AddUserController>();
    final selectedCount = ctrl.selectedUsers.length;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 12, 8),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Agregar usuarios',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Busca y selecciona los usuarios que quieres añadir como miembros.',
              style: TextStyle(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: UserSearchBar(
                hintText: 'Buscar por nombre de usuario...',
                onChanged: (q) => ctrl.searchUser(q, context),
                onClear: ctrl.clearResults,
                autofocus: true,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _SearchResultsList(controller: ctrl, dense: false),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$selectedCount ${selectedCount == 1 ? 'usuario seleccionado' : 'usuarios seleccionados'}',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: selectedCount == 0
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text('Añadir usuarios ($selectedCount)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({required this.controller, required this.dense});

  final AddUserController controller;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final results = controller.searchResults;
    if (results.isEmpty) {
      return const _Hint(text: 'Escribe al menos 3 caracteres para buscar.');
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final username = results[index];
        final isMember = controller.port.membersById.values.any(
          (user) => user.userName.toLowerCase() == username.toLowerCase(),
        );
        final isSelected = controller.selectedUsers.any(
          (user) => user.userName.toLowerCase() == username.toLowerCase(),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.45),
            ),
            color:
                isSelected ? cs.primaryContainer.withValues(alpha: 0.22) : null,
          ),
          child: UserSearchResultItem(
            username: username,
            isMember: isMember,
            isPending: isSelected,
            onRemove: isSelected ? () => controller.unselect(username) : null,
            onAdd: (isMember || isSelected)
                ? null
                : () async {
                    await controller.addUser(username, context);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Añadido @$username')),
                    );
                  },
          ),
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: ThemeColors.textSecondary(context)),
      ),
    );
  }
}
