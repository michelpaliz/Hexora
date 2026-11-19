import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

void main() {
  Future<void> pumpSeparator(
    WidgetTester tester, {
    required DocumentViewMode mode,
  }) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: DocumentWorkspaceScope(
              mode: mode,
              openPreviewDrawer: () {},
              child: const HexoraMonthGroupSeparator(
                label: 'Septiembre de 2026',
              ),
            ),
          ),
        ),
      ),
    ));
  }

  testWidgets('month separator centers its compact label in split view',
      (tester) async {
    await pumpSeparator(tester, mode: DocumentViewMode.split);

    final separator = find.byKey(
      const ValueKey('document-month-group-separator-Septiembre de 2026'),
    );
    expect(tester.getSize(separator).height,
        HexoraDocumentTokens.monthHeadingHeight);
    expect(
        tester.getCenter(find.text('SEPTIEMBRE DE 2026')).dx, closeTo(200, 1));
  });

  testWidgets('month separator centers its compact label in expanded view',
      (tester) async {
    await pumpSeparator(tester, mode: DocumentViewMode.list);

    expect(
        tester.getCenter(find.text('SEPTIEMBRE DE 2026')).dx, closeTo(200, 1));
  });
}
