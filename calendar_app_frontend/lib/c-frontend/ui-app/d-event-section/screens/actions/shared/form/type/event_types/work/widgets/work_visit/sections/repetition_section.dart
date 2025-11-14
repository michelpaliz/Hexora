import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/screen/widgets/repetition_toggle_widget.dart';

import 'section_card_builder.dart';

class RepetitionSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final bool isRepetitive;
  final double? toggleWidth;
  final Future<void> Function() onTap;

  const RepetitionSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.isRepetitive,
    required this.toggleWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      title: title,
      child: RepetitionToggleWidget(
        key: ValueKey(isRepetitive),
        isRepetitive: isRepetitive,
        toggleWidth: toggleWidth ?? 0,
        onTap: onTap, // now matches the async type
      ),
    );
  }
}
