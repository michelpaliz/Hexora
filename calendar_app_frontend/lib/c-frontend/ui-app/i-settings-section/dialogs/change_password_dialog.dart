import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ChangePasswordResult {
  final String current;
  final String newPass;
  final String confirm;
  ChangePasswordResult(this.current, this.newPass, this.confirm);
}

Future<ChangePasswordResult?> showChangePasswordDialog(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  final current = TextEditingController();
  final newPass = TextEditingController();
  final confirm = TextEditingController();

  return showDialog<ChangePasswordResult>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(l.changePassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: current,
              decoration: InputDecoration(labelText: l.currentPassword),
              obscureText: true),
          TextField(
              controller: newPass,
              decoration: InputDecoration(labelText: l.newPassword),
              obscureText: true),
          TextField(
              controller: confirm,
              decoration: InputDecoration(labelText: l.confirmPassword),
              obscureText: true),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            Navigator.pop(context,
                ChangePasswordResult(current.text, newPass.text, confirm.text));
          },
          child: Text(l.save),
        ),
      ],
    ),
  );
}
