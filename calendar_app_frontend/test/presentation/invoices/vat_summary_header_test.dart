import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/vat_summary/vat_summary_header.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  Widget subject({
    double width = 1000,
    required VoidCallback onToday,
  }) {
    return MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: _HeaderHarness(onToday: onToday),
        ),
      ),
    );
  }

  testWidgets('keeps period actions and quarters in one compact toolbar',
      (tester) async {
    var todayTaps = 0;
    await tester.pumpWidget(subject(onToday: () => todayTaps++));

    expect(find.text('Exportar'), findsOneWidget);
    expect(find.text('T1'), findsOneWidget);
    expect(find.text('T4'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);

    await tester.ensureVisible(find.text('T2'));
    await tester.tap(find.text('T2'));
    await tester.pumpAndSettle();
    final segmented = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );
    expect(segmented.selected, {2});
    expect(
      segmented.style?.backgroundColor?.resolve({WidgetState.selected}),
      Theme.of(tester.element(find.byType(SegmentedButton<int>)))
          .colorScheme
          .primary,
    );

    await tester.tap(find.text('Hoy'));
    expect(todayTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolls instead of overflowing on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      subject(width: 340, onToday: () {}),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('T4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _HeaderHarness extends StatefulWidget {
  const _HeaderHarness({required this.onToday});

  final VoidCallback onToday;

  @override
  State<_HeaderHarness> createState() => _HeaderHarnessState();
}

class _HeaderHarnessState extends State<_HeaderHarness>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);
    _controller.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VatSummaryHeader(
        year: 2026,
        rangeLabel: 'T1 · ene–mar 2026',
        deadlineLabel: 'Presentación hasta abril',
        exportingVatAudit: false,
        onExportVatAudit: () {},
        onPrevYear: () {},
        onNextYear: () {},
        onToday: widget.onToday,
        isCurrentPeriod: false,
        tabs: _controller,
      );
}
