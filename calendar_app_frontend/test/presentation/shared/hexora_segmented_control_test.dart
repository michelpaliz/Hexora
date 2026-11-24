import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/hexora_segmented_control.dart';
import 'package:hexora/theme/themes/app_theme.dart';

const _views = ['day', 'week', 'month', 'agenda'];
const _labels = {
  'day': 'Día',
  'week': 'Semana',
  'month': 'Mes',
  'agenda': 'Agenda',
};

class _Host extends StatefulWidget {
  const _Host({required this.changes});
  final List<String> changes;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String selected = 'week';

  @override
  Widget build(BuildContext context) => Center(
        child: HexoraSegmentedControl<String>(
          key: const ValueKey('control'),
          selected: selected,
          onChanged: (v) {
            widget.changes.add(v);
            setState(() => selected = v);
          },
          segments: [
            for (final v in _views)
              HexoraSegment(
                key: ValueKey('seg-$v'),
                value: v,
                label: _labels[v]!,
                icon: Icons.calendar_today_outlined,
              ),
          ],
        ),
      );
}

Future<List<String>> _pump(WidgetTester tester,
    {Brightness brightness = Brightness.light}) async {
  final changes = <String>[];
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
    home: Scaffold(body: _Host(changes: changes)),
  ));
  return changes;
}

Color? _segColor(WidgetTester tester, String v) =>
    (tester.widget<AnimatedContainer>(find.byKey(ValueKey('seg-$v'))).decoration
            as BoxDecoration?)
        ?.color;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('neutral track, rounded light-blue selected pill ($brightness)',
        (tester) async {
      await _pump(tester, brightness: brightness);
      final cs = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
      final control = find.byKey(const ValueKey('control'));
      final track = tester.widget<Container>(
          find.descendant(of: control, matching: find.byType(Container)).first);
      final trackDeco = track.decoration! as BoxDecoration;
      expect(trackDeco.color, HexoraSegmentedControl.trackColor(cs));
      expect(trackDeco.border, isNull, reason: 'no prominent outer border');
      expect(track.padding, const EdgeInsets.all(3));
      expect(tester.getSize(control).height, 34);

      expect(
          _segColor(tester, 'week'), HexoraSegmentedControl.selectedColor(cs));
      expect(_segColor(tester, 'day'), isNull);
      final selectedRect =
          tester.getRect(find.byKey(const ValueKey('seg-week')));
      final controlRect = tester.getRect(control);
      // The pill sits inside the track instead of touching its edges.
      expect(selectedRect.top - controlRect.top, 3);
      expect(controlRect.bottom - selectedRect.bottom, 3);

      final icon = tester.widget<Icon>(find.descendant(
          of: find.byKey(const ValueKey('seg-week')),
          matching: find.byType(Icon)));
      expect(icon.size, 16);
      expect(icon.color, cs.primary);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('selection animates in 150 ms without moving the tabs',
      (tester) async {
    final changes = await _pump(tester);
    final before = {
      for (final v in _views) v: tester.getRect(find.byKey(ValueKey('seg-$v'))),
    };
    await tester.tap(find.byKey(const ValueKey('seg-month')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    // Mid-transition: the colour is between the two states.
    final cs = Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
    final mid = tester
        .widget<AnimatedContainer>(find.byKey(const ValueKey('seg-month')));
    expect(mid.duration, const Duration(milliseconds: 150));
    expect(mid.curve, Curves.easeOutCubic);
    await tester.pumpAndSettle();
    expect(changes, ['month']);
    expect(
        _segColor(tester, 'month'), HexoraSegmentedControl.selectedColor(cs));
    expect(_segColor(tester, 'week'), isNull);
    for (final v in _views) {
      expect(tester.getRect(find.byKey(ValueKey('seg-$v'))), before[v],
          reason: '$v must not shift when the weight changes');
    }

    await tester.tap(find.byKey(const ValueKey('seg-month')));
    await tester.pumpAndSettle();
    expect(changes, ['month'], reason: 'reselecting does nothing');
  });

  testWidgets('selected and inactive typography', (tester) async {
    await _pump(tester);
    TextStyle styleOf(String label) => tester
        .widget<AnimatedDefaultTextStyle>(find.ancestor(
            of: find.text(label).last,
            matching: find.byType(AnimatedDefaultTextStyle)).first)
        .style;
    expect(styleOf('Semana').fontWeight, FontWeight.w600);
    expect(styleOf('Día').fontWeight, FontWeight.w400);
    expect(styleOf('Día').fontSize, 13);
  });
}
