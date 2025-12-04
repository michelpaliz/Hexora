import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/themed_buttons.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ChangePasswordResult {
  final String current;
  final String newPass;
  final String confirm;
  ChangePasswordResult(this.current, this.newPass, this.confirm);
}

Future<ChangePasswordResult?> showChangePasswordDialog(BuildContext context) {
  return showDialog<ChangePasswordResult>(
    context: context,
    builder: (_) => const _ChangePasswordDialog(),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  late final TextEditingController _currentController;
  late final TextEditingController _newPassController;
  late final TextEditingController _confirmController;
  bool _currentObscured = true;
  bool _newObscured = true;
  bool _confirmObscured = true;

  @override
  void initState() {
    super.initState();
    _currentController = TextEditingController()..addListener(_handleChanged);
    _newPassController = TextEditingController()..addListener(_handleChanged);
    _confirmController = TextEditingController()..addListener(_handleChanged);
  }

  void _handleChanged() => setState(() {});

  @override
  void dispose() {
    _currentController.dispose();
    _newPassController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final typography = AppTypography.of(context);
    final secondaryText = ThemeColors.textSecondary(context);
    final inputFill = ThemeColors.inputFillLighter(context);
    final outlineColor = theme.colorScheme.outline.withOpacity(0.5);
    final confirmMismatch = _confirmController.text.isNotEmpty &&
        _newPassController.text.isNotEmpty &&
        _confirmController.text != _newPassController.text;
    final canSave = _currentController.text.isNotEmpty &&
        _newPassController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        !confirmMismatch;

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    Widget passwordField({
      required TextEditingController controller,
      required String label,
      required IconData icon,
      required bool obscure,
      required VoidCallback onToggleVisibility,
      String? helper,
      String? error,
      TextInputAction inputAction = TextInputAction.next,
    }) {
      return TextField(
        controller: controller,
        textInputAction: inputAction,
        obscureText: obscure,
        style: typography.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: typography.bodyMedium.copyWith(color: secondaryText),
          helperText: helper,
          helperStyle: typography.caption.copyWith(color: secondaryText),
          errorText: error,
          filled: true,
          fillColor: inputFill,
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          suffixIcon: IconButton(
            tooltip: obscure ? l.showPassword : l.hidePassword,
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: secondaryText,
            ),
            onPressed: onToggleVisibility,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: inputBorder(outlineColor),
          enabledBorder: inputBorder(outlineColor),
          focusedBorder: inputBorder(theme.colorScheme.primary, 1.6),
          errorBorder: inputBorder(theme.colorScheme.error.withOpacity(0.8)),
          focusedErrorBorder:
              inputBorder(theme.colorScheme.error.withOpacity(0.8), 1.6),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: ThemeColors.cardBg(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.changePassword,
              style: typography.displayMedium,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            passwordField(
              controller: _currentController,
              label: l.currentPassword,
              icon: Icons.lock_outline_rounded,
              obscure: _currentObscured,
              onToggleVisibility: () => setState(
                () => _currentObscured = !_currentObscured,
              ),
            ),
            const SizedBox(height: 16),
            passwordField(
              controller: _newPassController,
              label: l.newPassword,
              icon: Icons.shield_moon_outlined,
              obscure: _newObscured,
              onToggleVisibility: () =>
                  setState(() => _newObscured = !_newObscured),
              helper: l.passwordHint,
            ),
            const SizedBox(height: 16),
            passwordField(
              controller: _confirmController,
              label: l.confirmPassword,
              icon: Icons.verified_user_outlined,
              obscure: _confirmObscured,
              onToggleVisibility: () =>
                  setState(() => _confirmObscured = !_confirmObscured),
              helper: l.confirmPasswordHint,
              error: confirmMismatch ? l.passwordNotMatch : null,
              inputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: secondaryText,
            textStyle: typography.bodyLarge,
          ),
          child: Text(l.cancel),
        ),
        ElevatedButton(
          style: ThemedButtons.button(context),
          onPressed: canSave
              ? () => Navigator.pop(
                    context,
                    ChangePasswordResult(
                      _currentController.text,
                      _newPassController.text,
                      _confirmController.text,
                    ),
                  )
              : null,
          child: Text(
            l.save,
            style: typography.buttonText,
          ),
        ),
      ],
    );
  }
}
