import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/view_model/group_view_model.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/shared/add_user_button/widgets/empty_state.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/shared/add_user_button/widgets/search_field.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/utils/shared/add_user_button/widgets/user_chips.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class AddPeopleSheet extends StatefulWidget {
  final User? currentUser;
  final Group? group;
  final void Function(List<User>) onConfirm;

  const AddPeopleSheet({
    super.key,
    required this.currentUser,
    required this.group,
    required this.onConfirm,
  });

  @override
  State<AddPeopleSheet> createState() => _AddPeopleSheetState();
}

class _AddPeopleSheetState extends State<AddPeopleSheet> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;

  List<User> _results = [];
  final Set<User> _selected = {};
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _search.text.trim();
    if (q == _query) return;
    _query = q;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _searchUsers);
  }

  Future<void> _searchUsers() async {
    setState(() => _loading = true);
    try {
      final ctrl = context.read<GroupEditorViewModel>();
      final users = await ctrl.searchUsers(_query);
      setState(() => _results = users);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final onSheet = ThemeColors.textPrimary(context);

    return DraggableScrollableSheet(
      expand: false,
      minChildSize: 0.45,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l.addPplGroup,
                style: t.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onSheet,
                ),
              ),
              const SizedBox(height: 12),

              SearchField(
                controller: _search,
                focusNode: _focus,
                onSubmitted: (_) => _searchUsers(),
              ),
              const SizedBox(height: 8),

              if (_selected.isNotEmpty)
                SelectedUserChips(
                  users: _selected.toList(),
                  onRemove: (u) => setState(() => _selected.remove(u)),
                ),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? EmptyState(
                            query: _query,
                            onInvite: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l.noMatchesInvite,
                                      style: t.bodySmall),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: _results.length,
                            itemBuilder: (_, i) {
                              final u = _results[i];
                              final selected = _selected.contains(u);
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      cs.secondary.withOpacity(0.12),
                                  backgroundImage:
                                      (u.photoUrl?.isNotEmpty ?? false)
                                          ? NetworkImage(u.photoUrl!)
                                          : null,
                                  child: (u.photoUrl?.isEmpty ?? true)
                                      ? Text(u.name.isNotEmpty
                                          ? u.name[0].toUpperCase()
                                          : '?')
                                      : null,
                                ),
                                title: Text(
                                  u.name,
                                  style: t.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: onSheet,
                                  ),
                                ),
                                subtitle: Text(
                                  u.userName,
                                  style: t.bodySmall.copyWith(
                                    color: onSheet.withOpacity(0.75),
                                  ),
                                ),
                                trailing: selected
                                    ? Icon(Icons.check_circle,
                                        color: cs.primary)
                                    : IconButton(
                                        icon: const Icon(Icons.add),
                                        color: cs.secondary,
                                        onPressed: () =>
                                            setState(() => _selected.add(u)),
                                      ),
                                onTap: () {
                                  setState(() {
                                    selected
                                        ? _selected.remove(u)
                                        : _selected.add(u);
                                  });
                                },
                              );
                            },
                          ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => widget.onConfirm(_selected.toList()),
                  child: Text(
                    _selected.isEmpty
                        ? l.addPeople
                        : '${l.add} (${_selected.length})',
                    style: t.buttonText.copyWith(
                      color: ThemeColors.contrastOn(cs.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
