// c-frontend/d-event-section/screens/actions/shared/form/sections/title_section.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/work_visit/sections/section_card_builder.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';

class TitleSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final TextEditingController controller;
  final String? hintText;
  final int maxLength;

  const TitleSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.controller,
    this.hintText,
    this.maxLength = 120,
  });

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);

    return cardBuilder(
      title: title,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        style: typo.bodyMedium, // your main text style
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hintText ?? '',
          hintStyle: typo.bodySmall, // subtle hint
          counterText: '', // hide default counter row
          border: InputBorder.none, // card provides the chrome
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
