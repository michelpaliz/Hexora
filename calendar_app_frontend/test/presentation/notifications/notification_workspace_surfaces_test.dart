import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/notifications/widgets/notification_density.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/notifications/widgets/notification_details_panel.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/notifications/widgets/notifications_list.dart';
import 'package:hexora/presentation/shared/widgets/hexora_menu_content_transition.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/themes/app_theme.dart';

NotificationUser _notification(String id,
        {bool read = false, Map<String, dynamic> args = const {}}) =>
    NotificationUser.fromJson({
      'id': id,
      'fallbackTitle': 'Borrador de factura recurrente creado',
      'fallbackMessage': 'Se ha creado un borrador para $id.',
      'timestamp':
          DateTime.now().subtract(const Duration(hours: 14)).toIso8601String(),
      'isRead': read,
      'args': {'invoiceId': 'inv-$id', ...args},
    });

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(backgroundColor: AppColors.workspaceCanvas, body: child),
    );

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

ColorScheme _cs(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold))).colorScheme;

Color? _rowColor(WidgetTester tester, String id) => (tester
        .widget<AnimatedContainer>(find.byKey(ValueKey('notification-row-$id')))
        .decoration as BoxDecoration?)
    ?.color;

FontWeight? _titleWeight(WidgetTester tester, String id) => tester
    .widget<Text>(find
        .descendant(
          of: find.byKey(ValueKey('notification-row-$id')),
          matching: find.text('Borrador de factura recurrente creado'),
        )
        .first)
    .style
    ?.fontWeight;

void main() {
  group('list rows', () {
    for (final brightness in Brightness.values) {
      testWidgets('only the selected row has a background ($brightness)',
          (tester) async {
        await _size(tester, const Size(700, 600));
        String? selected = 'sel';
        late StateSetter setOuter;
        await tester.pumpWidget(_app(
          StatefulBuilder(builder: (context, setState) {
            setOuter = setState;
            return NotificationsList(
              notifications: [
                _notification('read', read: true),
                _notification('unread'),
                _notification('sel'),
              ],
              selectedId: selected,
              onSelect: (n) => setOuter(() => selected = n.id),
              onDelete: (_) async {},
            );
          }),
          brightness: brightness,
        ));
        final cs = _cs(tester);

        expect(_rowColor(tester, 'sel'), NotifDensity.selectedRowFill(cs));
        expect(_rowColor(tester, 'unread'), isNull,
            reason: 'unread uses a dot, not a background');
        expect(_rowColor(tester, 'read'), isNull);

        // Unread: blue dot + semibold title. Read: no dot, regular weight.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('notification-row-unread')),
            matching: find.byKey(const ValueKey('notification-unread-dot')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('notification-row-read')),
            matching: find.byKey(const ValueKey('notification-unread-dot')),
          ),
          findsNothing,
        );
        final dot = tester.widget<Container>(
            find.byKey(const ValueKey('notification-unread-dot')).first);
        expect((dot.decoration! as BoxDecoration).color, cs.primary);
        expect(_titleWeight(tester, 'unread'), FontWeight.w600);
        expect(_titleWeight(tester, 'read'), FontWeight.w400);

        // Timestamps are plain muted text with no container behind them.
        final time = find.byKey(const ValueKey('notification-row-time')).first;
        expect(tester.widget<Text>(time).style?.color,
            NotifDensity.timestampColor(cs));
        final rowRect =
            tester.getRect(find.byKey(const ValueKey('notification-row-read')));
        expect(
            find.ancestor(
                of: time,
                matching: find.byWidgetPredicate((w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration as BoxDecoration).color != null &&
                    tester.getRect(find.byWidget(w)).width < rowRect.width)),
            findsNothing);

        // Selection animates without changing row size.
        final before =
            tester.getSize(find.byKey(const ValueKey('notification-row-read')));
        await tester.tap(find.byKey(const ValueKey('notification-row-read')));
        await tester.pump();
        expect(
            tester
                .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('notification-row-read')))
                .duration,
            const Duration(milliseconds: 150));
        await tester.pumpAndSettle();
        expect(_rowColor(tester, 'read'), NotifDensity.selectedRowFill(cs));
        expect(_rowColor(tester, 'sel'), isNull);
        expect(
            tester.getSize(find.byKey(const ValueKey('notification-row-read'))),
            before);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('selected fill is clearly stronger than hover', (tester) async {
      await _size(tester, const Size(700, 400));
      await tester.pumpWidget(_app(const SizedBox()));
      final cs = _cs(tester);
      expect(NotifDensity.selectedRowFill(cs).a,
          greaterThan(NotifDensity.hoverRowFill(cs).a * 2));
    });
  });

  group('details panel', () {
    Future<Map<String, int>> pumpDetails(
      WidgetTester tester, {
      Map<String, dynamic> args = const {},
      bool withRecurrenceLink = true,
      Brightness brightness = Brightness.light,
      double width = 520,
    }) async {
      await _size(tester, Size(width, 900));
      final calls = <String, int>{'open': 0, 'read': 0, 'recurrence': 0};
      await tester.pumpWidget(_app(
        NotificationDetailsPanel(
          notification: _notification('n1', args: args),
          groupName: 'Grupo',
          onConfirm: null,
          onNegate: null,
          onOpen: () => calls['open'] = calls['open']! + 1,
          openLabel: 'Ver borrador',
          onMarkRead: () => calls['read'] = calls['read']! + 1,
          onDelete: () {},
          onClose: () {},
          onOpenRecurrence: withRecurrenceLink
              ? () => calls['recurrence'] = calls['recurrence']! + 1
              : null,
        ),
        brightness: brightness,
      ));
      await tester.pumpAndSettle();
      return calls;
    }

    const docArgs = {
      'clientName': 'Rotamar',
      'amount': 771.98,
      'currency': 'EUR',
      'status': 'draft',
      'recurrenceName': 'Limpieza mensual Rotamar',
    };

    for (final brightness in Brightness.values) {
      testWidgets(
          'hierarchy, translated status and no repeated title '
          '($brightness)', (tester) async {
        await pumpDetails(tester, args: docArgs, brightness: brightness);

        final title = tester.widget<Text>(
            find.byKey(const ValueKey('notification-details-title')));
        expect(title.style?.fontWeight, FontWeight.w700);
        expect(title.style!.fontSize, greaterThan(14));
        // The title appears once (header) — no duplicated "Evento" field.
        expect(
            find.text('Borrador de factura recurrente creado'), findsOneWidget);
        expect(find.text('Evento'), findsNothing);

        // Close button shares the header row, aligned with the title.
        final header = tester
            .getRect(find.byKey(const ValueKey('notification-details-header')));
        final close = tester
            .getRect(find.byKey(const ValueKey('notification-details-close')));
        expect(close.top, header.top);
        expect(close.right, lessThanOrEqualTo(header.right));

        // Technical status → friendly label.
        expect(find.text('Borrador'), findsOneWidget);
        expect(find.text('draft'), findsNothing);

        // Empty optional fields are hidden instead of showing "—".
        expect(find.text('—'), findsNothing);
        expect(find.text('Método de pago'), findsNothing);
        expect(find.text('Notas'), findsNothing);

        // Client and amount get extra emphasis.
        expect(tester.widget<Text>(find.text('Rotamar')).style?.fontWeight,
            FontWeight.w600);
        expect(
            tester
                .widget<Text>(find.byWidgetPredicate(
                    (w) => w is Text && (w.data ?? '').startsWith('771,98')))
                .style
                ?.fontWeight,
            FontWeight.w600);

        // Sections are separated by subtle dividers.
        expect(find.text('DOCUMENTO'), findsOneWidget);
        expect(find.text('DETALLES'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('recurrence banner: tinted, name distinct, link opens it',
        (tester) async {
      final calls = await pumpDetails(tester, args: docArgs);
      final cs = _cs(tester);
      final banner =
          find.byKey(const ValueKey('notification-recurrence-banner'));
      final deco =
          tester.widget<Container>(banner).decoration! as BoxDecoration;
      expect(deco.color, cs.primary.withValues(alpha: 0.07));
      expect(find.text('Documento de la recurrencia'), findsOneWidget);
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('notification-recurrence-name')))
              .style
              ?.fontWeight,
          FontWeight.w600);
      // Compact padding (the test font inflates text widths, so size is not
      // a reliable measure here).
      expect(tester.widget<Container>(banner).padding,
          const EdgeInsets.fromLTRB(10, 8, 6, 8));
      await tester
          .tap(find.byKey(const ValueKey('notification-open-recurrence')));
      expect(calls['recurrence'], 1);
    });

    testWidgets('no recurrence link without navigation permission',
        (tester) async {
      await pumpDetails(tester, args: docArgs, withRecurrenceLink: false);
      expect(find.byKey(const ValueKey('notification-recurrence-banner')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('notification-open-recurrence')),
          findsNothing);
    });

    for (final width in [520.0, 360.0]) {
      testWidgets(
          'footer: canvas background, compact right-aligned actions '
          '(width $width)', (tester) async {
        final calls = await pumpDetails(tester, args: docArgs, width: width);
        final footer =
            find.byKey(const ValueKey('notification-details-footer'));
        final deco =
            tester.widget<Container>(footer).decoration! as BoxDecoration;
        expect(deco.color, isNull, reason: 'canvas shows through');
        expect((deco.border! as Border).top.style, BorderStyle.solid);

        final open = find.byKey(const ValueKey('notification-open'));
        final read = find.byKey(const ValueKey('notification-mark-read'));
        expect(tester.getSize(open).height, 34);
        expect(tester.getSize(read).height, 34);
        expect(tester.getSize(open).width, lessThan(width * 0.6),
            reason: 'primary button no longer stretches');
        // Primary is the rightmost button, next to the more-actions menu.
        final menu = find.byTooltip('Más acciones');
        expect(tester.getRect(open).right,
            lessThan(tester.getRect(menu).left + 1));
        expect(tester.getRect(menu).left - tester.getRect(open).right,
            lessThan(20));
        expect(
            tester.widget<FilledButton>(find.ancestor(
                of: find.text('Ver borrador'),
                matching: find.byWidgetPredicate((w) => w is FilledButton))),
            isNotNull);

        await tester.tap(open);
        await tester.tap(read);
        expect(calls['open'], 1);
        expect(calls['read'], 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('changing notification fades only the details', (tester) async {
      await pumpDetails(tester, args: docArgs);
      final fade = tester.widget<HexoraMenuContentTransition>(
          find.byKey(const ValueKey('notification-details-fade')));
      expect(fade.transitionKey, 'n1');
      expect(fade.duration, const Duration(milliseconds: 150));
      expect(fade.slideOffset, Offset.zero);
      expect(fade.translateX, 0);
    });
  });
}
