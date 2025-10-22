// lib/c-frontend/d-event-section/screens/event_detail/widgets/read_only_field.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_utilities/view-item-styles/text_field/static/custom_text_field.dart';

class ReadOnlyField extends StatelessWidget {
  final IconData icon;
  final String text;
  final String hint;

  const ReadOnlyField(
      {super.key, required this.icon, required this.text, required this.hint});

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    return CustomTextFieldWithIcons(
      text: text,
      hintText: hint,
      prefixIcon: icon,
      suffixIcon: null,
      fontFamily:
          typo.bodyLarge.fontFamily ?? 'Manrope', // if your widget requires it
    );
  }
}
