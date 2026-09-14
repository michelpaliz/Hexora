import 'package:flutter/material.dart';
import 'package:hexora/presentation/features/events/screens/actions/shared/form/type/event_types/work/widgets/section_card_work_type.dart';

typedef SectionCardBuilder = SectionCard Function({
  Key? key,
  required String title,
  required Widget child,
});
