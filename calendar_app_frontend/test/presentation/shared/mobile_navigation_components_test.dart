import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/mobile_navigation_components.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/theme/themes/mobile_theme.dart';

void main() {
  group('mobile navigation design system', () {
    for (final brightness in Brightness.values) {
      for (final size in const [
        Size(320, 568),
        Size(390, 844),
        Size(430, 932),
      ]) {
        testWidgets('fits $size in $brightness', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          var selected = <String>{'month'};
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.forMobileViewport(
                brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
              ),
              home: DefaultTabController(
                length: 4,
                child: StatefulBuilder(
                  builder: (context, setState) => Scaffold(
                    appBar: HexoraMobileAppBar(
                      title: 'Facturas y recibos pendientes',
                      actions: [
                        HexoraHeaderAction(
                          icon: Icons.search,
                          tooltip: 'Buscar',
                          onPressed: () {},
                        ),
                      ],
                      bottom: const PreferredSize(
                        preferredSize: Size.fromHeight(48),
                        child: HexoraMobileTabs(
                          tabs: [
                            Tab(text: 'Todos'),
                            Tab(text: 'Pendientes'),
                            Tab(text: 'Emitidos'),
                            Tab(text: 'Archivados'),
                          ],
                        ),
                      ),
                    ),
                    body: Column(
                      children: [
                        const HexoraSectionHeader(
                          title: 'Resumen',
                          subtitle: 'Actividad del periodo seleccionado',
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: HexoraSegmentedControl<String>(
                            segments: const {
                              'month': Text('Mes'),
                              'quarter': Text('Trimestre'),
                            },
                            selected: selected,
                            onChanged: (value) =>
                                setState(() => selected = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(
            Theme.of(tester.element(find.byType(Scaffold)))
                .extension<MobileStatusColors>(),
            isNotNull,
          );
          expect(
            tester.getSize(find.byType(AppBar)).height,
            104,
          );

          await tester.tap(find.text('Trimestre'));
          await tester.pump();
          expect(selected, {'quarter'});
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
