// presentation/d-event-section/screens/actions/shared/form/sections/title_section.dart
import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/events/screens/actions/shared/form/type/event_types/work/widgets/work_visit/sections/section_card_builder.dart';

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
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return cardBuilder(
      title: title,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        style: text.bodyLarge!.copyWith(
          color: cs.onSurface,
        ),
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hintText ?? '',
          hintStyle: text.bodyLarge!.copyWith(
            color: cs.onSurfaceVariant,
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
