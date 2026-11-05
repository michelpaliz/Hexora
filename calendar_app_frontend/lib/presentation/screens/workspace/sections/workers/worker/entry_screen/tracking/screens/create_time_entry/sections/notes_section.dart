import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/input_border.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class NotesSection extends StatelessWidget {
  const NotesSection({
    super.key,
    required this.controller,
    required this.l,
    required this.t,
  });

  final TextEditingController controller;
  final AppLocalizations l;
  final AppTypography t;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: t.bodyMedium.copyWith(
        color: ThemeColors.textPrimary(context),
      ),
      decoration: buildInputDecoration(
        context,
        label: l.notesLabel,
        hintText: l.notesOptionalHint,
      ),
      minLines: 2,
      maxLines: 5,
    );
  }
}
