import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/utils/form/description_input_widget.dart';

import 'section_card_builder.dart';

class DescriptionSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final TextEditingController controller;

  const DescriptionSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      title: title,
      child: DescriptionInputWidget(
        descriptionController: controller,
      ),
    );
  }
}
