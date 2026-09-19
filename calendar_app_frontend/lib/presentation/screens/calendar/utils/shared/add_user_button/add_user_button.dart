import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/viewmodels/groups/group_view_model.dart';
import 'package:hexora/presentation/screens/calendar/utils/shared/add_user_button/widgets/add_ppl_sheet.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/components/themed_buttons.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class AddUserButton extends StatelessWidget {
  final User? currentUser;
  final Group? group;
  final GroupEditorViewModel controller;
  final void Function(User)? onUserAdded;

  const AddUserButton({
    super.key,
    required this.currentUser,
    required this.group,
    required this.controller,
    this.onUserAdded,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final onPrimary = ThemeColors.contrastOn(cs.primary);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () => _openSheet(context),
          icon: Icon(Icons.person_add_alt_1, color: onPrimary, size: 20),
          label: Text(
            AppLocalizations.of(context)!.addUser,
            style: t.buttonText.copyWith(color: onPrimary),
          ),
          style: ThemedButtons.button(context, variant: ButtonVariant.primary),
        ),
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ThemeColors.cardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: AddPeopleSheet(
          currentUser: currentUser,
          group: group,
          onConfirm: (users) {
            for (final u in users) {
              controller.addMember(u);
              onUserAdded?.call(u);
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
