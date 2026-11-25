import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/shared/widgets/notification_preview_popover.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  NotificationUser notification({bool read = false}) => NotificationUser(
        id: 'notice-1',
        senderId: 'sender',
        recipientId: 'recipient',
        titleKey: 'notification.invoice.issued.title',
        messageKey: 'notification.invoice.issued.message',
        fallbackTitle: 'Factura emitida',
        fallbackMessage: 'La factura se ha creado correctamente.',
        args: const {'documentNumber': 'F-2026-0042'},
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        groupId: 'group-1',
        isRead: read,
        category: Category.billing,
      );

  Future<void> pumpPreview(
    WidgetTester tester, {
    required VoidCallback onOpenAll,
    required Future<void> Function() onMarkAllRead,
    ValueChanged<NotificationUser>? onNotificationTap,
    Alignment alignment = Alignment.topRight,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: alignment,
            child: NotificationPreviewPopover(
              notifications: [notification()],
              unreadCount: 1,
              selected: false,
              onOpenAll: onOpenAll,
              onMarkAllRead: onMarkAllRead,
              onNotificationTap: onNotificationTap,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('hover uses delayed open and delayed close', (tester) async {
    await pumpPreview(
      tester,
      onOpenAll: () {},
      onMarkAllRead: () async {},
    );
    final trigger = find.byKey(const ValueKey('notification-preview-trigger'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(trigger));

    await tester.pump(const Duration(milliseconds: 249));
    expect(find.byKey(const ValueKey('notification-preview-popover')),
        findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey('notification-preview-popover')),
        findsOneWidget);

    await mouse.moveTo(const Offset(10, 400));
    await tester.pump(const Duration(milliseconds: 179));
    expect(find.byKey(const ValueKey('notification-preview-popover')),
        findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey('notification-preview-popover')),
        findsNothing);
  });

  testWidgets('click pins preview and actions reuse supplied callbacks',
      (tester) async {
    var opened = 0;
    var marked = 0;
    var selected = 0;
    await pumpPreview(
      tester,
      onOpenAll: () => opened++,
      onMarkAllRead: () async => marked++,
      onNotificationTap: (_) => selected++,
    );
    await tester.tap(
      find.byKey(const ValueKey('notification-preview-trigger')),
    );
    await tester.pump();
    expect(find.text('Notificaciones'), findsOneWidget);
    expect(marked, 0, reason: 'Opening must not mark notifications as read.');

    await tester.tap(
      find.byKey(const ValueKey('notification-preview-mark-all')),
    );
    await tester.pump();
    expect(marked, 1);

    await tester.tap(
      find.byKey(const ValueKey('notification-preview-item-notice-1')),
    );
    await tester.pump();
    expect(selected, 1);
    expect(find.byKey(const ValueKey('notification-preview-popover')),
        findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('notification-preview-trigger')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('notification-preview-view-all')),
    );
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('popover stays within viewport when trigger is at the bottom',
      (tester) async {
    tester.view.physicalSize = const Size(500, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPreview(
      tester,
      alignment: Alignment.bottomRight,
      onOpenAll: () {},
      onMarkAllRead: () async {},
    );
    final trigger = find.byKey(const ValueKey('notification-preview-trigger'));
    await tester.tap(trigger);
    await tester.pump();
    final popover = find.byKey(const ValueKey('notification-preview-popover'));
    expect(popover, findsOneWidget);
    expect(tester.getBottomRight(popover).dx, lessThanOrEqualTo(488));
    expect(tester.getTopLeft(popover).dy, greaterThanOrEqualTo(12));
    expect(tester.getBottomLeft(popover).dy,
        lessThan(tester.getTopLeft(trigger).dy));
  });
}
