import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:hexora/presentation/shared/widgets/documents/hexora_status_badge.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('shared tables grow for enlarged text: $brightness',
        (tester) async {
      final theme =
          AppTheme.forPlatform(brightness, platform: TargetPlatform.windows);
      expect(theme.dataTableTheme.dataRowMinHeight,
          HexoraTableTokens.rowMinHeight);
      expect(theme.dataTableTheme.dataTextStyle?.fontFamily,
          HexoraTypography.fontFamily);
      await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SingleChildScrollView(
                  child: DataTable(columns: const [
                DataColumn(label: Text('Propuesta'))
              ], rows: const [
                DataRow(cells: [
                  DataCell(SizedBox(
                      width: 180,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                'Propuesta de mantenimiento de jardines y piscina para toda la comunidad'),
                            HexoraStatusBadge(
                                label: 'Pendiente de revisión',
                                color: Colors.blue),
                          ])))
                ]),
              ])),
            ),
          )));
      expect(tester.takeException(), isNull);
      expect(
          tester.getSize(find.byType(DataTable)).height,
          greaterThan(HexoraTableTokens.rowMinHeight +
              HexoraTableTokens.headingHeight));
    });
  }
}
