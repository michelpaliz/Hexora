import 'package:hexora/presentation/shared/widgets/feedback/snack_helper.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/utils/errors/group_membership_error_mapper.dart';
import 'package:hexora/presentation/utils/errors/premium_upgrade_dialog.dart';
import 'package:hexora/l10n/app_localizations.dart';

abstract class UiMessenger {
  void showSnack(String message);
  Future<void> showError(String message);
  Future<void> showPremiumRequired(GroupMembershipErrorContext errorContext);
  void pop(); // for simple back/close
}

// Flutter adapter the widget will provide to the VM
class MaterialUiMessenger implements UiMessenger {
  final BuildContext context;
  MaterialUiMessenger(this.context);

  @override
  void showSnack(String message) {
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    switch (message) {
      case 'Group updated!':
        showSuccessSnack(context, l.groupEdited);
      case 'Group created!':
        showSuccessSnack(context, l.groupSaved);
      default:
        showInfoSnack(context, message);
    }
  }

  @override
  Future<void> showError(String message) async {
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    final localized = switch (message) {
      'Name and description are required' => l.requiredTextFields,
      'Failed to update group' => l.failedToEditGroup,
      'Failed to create group' => l.failedToCreateGroup,
      _ => message,
    };
    showErrorSnack(context, localized);
  }

  @override
  Future<void> showPremiumRequired(
      GroupMembershipErrorContext errorContext) async {
    final l = AppLocalizations.of(context)!;
    await showPremiumUpgradeDialog(
      context,
      message: GroupMembershipErrorMapper.messageFor(l, errorContext),
    );
  }

  @override
  void pop() => Navigator.of(context).pop();
}
