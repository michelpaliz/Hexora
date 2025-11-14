// c-frontend/d-event-section/screens/actions/add_screen/widgets/work_visit/work_visit_style.dart
import 'package:flutter/material.dart';

class WorkVisitStyle {
  static const EdgeInsets outerPadding = EdgeInsets.fromLTRB(12, 6, 12, 12);
  static const sectionGap = SizedBox(height: 12);
  static const afterSubmitGap = SizedBox(height: 16);

  static ThemeData compactThemeOf(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      listTileTheme: const ListTileThemeData(
        dense: true,
        minVerticalPadding: 0,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
