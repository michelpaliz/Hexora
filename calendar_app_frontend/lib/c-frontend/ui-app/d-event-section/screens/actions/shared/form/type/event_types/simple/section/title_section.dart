// c-frontend/d-event-section/screens/actions/shared/form/sections/title_section.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/shared/form/type/event_types/work/widgets/work_visit/sections/section_card_builder.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

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
    final cs = Theme.of(context).colorScheme;

    return cardBuilder(
      title: title,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        style: typo.bodyMedium.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hintText ?? '',
          hintStyle: typo.bodyMedium.copyWith(
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
          counterText: '',
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outlineVariant, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outlineVariant, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
