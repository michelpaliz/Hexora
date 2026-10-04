// presentation/d-event-section/screens/actions/add_screen/widgets/work_visit/work_visit_style.dart
import 'package:flutter/material.dart';

class WorkVisitStyle {
  static const EdgeInsets outerPadding = EdgeInsets.fromLTRB(0, 4, 0, 16);
  static const sectionGap = SizedBox(height: 16);
  static const afterSubmitGap = SizedBox(height: 16);

  static ThemeData compactThemeOf(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      listTileTheme: base.listTileTheme.copyWith(
        dense: false,
        titleTextStyle: base.textTheme.bodyLarge?.copyWith(
            color: base.colorScheme.onSurface, fontWeight: FontWeight.w600),
        subtitleTextStyle: base.textTheme.bodyMedium
            ?.copyWith(color: base.colorScheme.onSurfaceVariant),
        minVerticalPadding: 0,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
