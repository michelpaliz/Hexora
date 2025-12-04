import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/themed_buttons.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

Future<String?> showChangeUsernameDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _ChangeUsernameDialog(),
  );
}

class _ChangeUsernameDialog extends StatefulWidget {
  const _ChangeUsernameDialog();

  @override
  State<_ChangeUsernameDialog> createState() => _ChangeUsernameDialogState();
}

class _ChangeUsernameDialogState extends State<_ChangeUsernameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleChanged);
  }

  void _handleChanged() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
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
    final username = _controller.text.trim();
    final hasInput = username.isNotEmpty;
    final allowed = RegExp(r'^[a-zA-Z0-9_]+$');
    final invalidChars = hasInput && !allowed.hasMatch(username);
    final canSave = hasInput && !invalidChars;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

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
              color: theme.colorScheme.secondary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.changeUsername,
              style: typography.displayMedium,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: typography.bodyLarge,
          decoration: InputDecoration(
            labelText: l.userName,
            labelStyle: typography.bodyMedium.copyWith(color: secondaryText),
            helperText: l.userNameHint,
            helperStyle: typography.caption.copyWith(color: secondaryText),
            errorText: invalidChars ? l.errorUnwantedCharactersUsername : null,
            prefixIcon: Icon(
              Icons.alternate_email_rounded,
              color: theme.colorScheme.primary,
            ),
            filled: true,
            fillColor: inputFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: border(outlineColor),
            enabledBorder: border(outlineColor),
            focusedBorder: border(theme.colorScheme.primary, 1.6),
            errorBorder: border(theme.colorScheme.error.withOpacity(0.8)),
            focusedErrorBorder:
                border(theme.colorScheme.error.withOpacity(0.8), 1.6),
          ),
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
          onPressed: canSave ? () => Navigator.pop(context, username) : null,
          child: Text(
            l.save,
            style: typography.buttonText,
          ),
        ),
      ],
    );
  }
}
