import 'package:hexora/a-models/mail/mail_attachment.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/a-models/mail/mail_address.dart';
import 'package:hexora/a-models/mail/mail_message.dart';
import 'package:hexora/a-models/mail/mail_thread.dart';
import 'package:hexora/b-backend/mail/domain/mail_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/mail/mail_console_screen.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';

class _Mail extends ChangeNotifier implements MailDomain {
  _Mail({this.detail, this.threads = const []});
  final List<MailThread> threads;
  final MailThreadDetail? detail;
  @override
  MailThreadsState get threadsState => MailThreadsState(threads: threads);
  @override
  MailThreadDetailState threadState(String key) => detail != null
      ? MailThreadDetailState(thread: detail)
      : const MailThreadDetailState(
          thread: MailThreadDetail(threadKey: 'thread-1', messages: [
          MailMessage(
              id: 'message-1', from: MailAddress(address: 'client@example.com'))
        ]));
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #loadThreadDetail ||
        invocation.memberName == #loadThreads) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _Auth extends ChangeNotifier implements AuthService {
  @override
  User? get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Groups extends ChangeNotifier implements GroupDomain {
  @override
  Group get currentGroup => Group(
      id: 'group-1',
      name: 'Group',
      ownerId: 'owner',
      userIds: [],
      userRoles: {},
      createdTime: DateTime(2026),
      description: '');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
        'inbox follows global typography and fits large text in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final mail = _Mail(threads: [
        MailThread(
            threadKey: 'one',
            subject: 'Recibos de comunidad y mantenimiento',
            participants: const ['Fercamar Central'],
            latestDate: DateTime(2026, 9, 11),
            messageCount: 3,
            unreadCount: 1,
            hasAttachments: true)
      ]);
      final theme =
          AppTheme.forPlatform(brightness, platform: TargetPlatform.android);
      await tester.pumpWidget(ChangeNotifierProvider<MailDomain>.value(
          value: mail,
          child: MaterialApp(
            theme: theme,
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!),
            home: const MailConsoleScreen(),
          )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Sin leer'), findsOneWidget);
      expect(find.text('3 mensajes'), findsOneWidget);
      final subject = tester
          .widget<Text>(find.text('Recibos de comunidad y mantenimiento'));
      expect(subject.style?.fontFamily, theme.textTheme.bodyMedium?.fontFamily);
      expect(subject.style?.color, theme.colorScheme.onSurface);
      final search = tester.widget<TextField>(find.byType(TextField));
      expect(search.style?.fontFamily, theme.textTheme.bodyLarge?.fontFamily);
      expect(tester.getSize(find.byType(TextField)).height,
          greaterThanOrEqualTo(48));
      await tester.enterText(find.byType(TextField), 'Fercamar');
      await tester.pumpAndSettle();
      final loc =
          AppLocalizations.of(tester.element(find.byType(MailConsoleScreen)))!;
      await tester.tap(find.byTooltip(loc.mailSearchClear));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      mail.dispose();
    });
  }

  testWidgets('mobile reading and replying fit large text and keyboard',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final mail = _Mail(
        detail: MailThreadDetail(
            threadKey: 'thread-1',
            subject: 'Envío de factura',
            messages: [
          MailMessage(
              id: 'message-1',
              date: DateTime(2026, 9, 11),
              from: const MailAddress(
                  address: 'long-client-address@example.com',
                  name: 'María del Carmen Aguilera Martínez'),
              htmlBody:
                  '<div><p>Adjunto justificante.</p><p><em>ADVERTENCIA LEGAL</em></p><p>Texto confidencial.</p></div>',
              attachments: const [
                MailAttachment(
                    id: 'attachment-1',
                    filename:
                        'Justificante_PAGO_MANTENIMIENTO_MICHEL_AGOSTO_2026.pdf')
              ]),
        ]));
    final auth = _Auth();
    final groups = _Groups();
    final client = MockClient((_) async => http.Response('[]', 200));
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<MailDomain>.value(value: mail),
          ChangeNotifierProvider<AuthService>.value(value: auth),
          ChangeNotifierProvider<GroupDomain>.value(value: groups),
          Provider<http.Client>.value(value: client),
        ],
        child: MaterialApp(
          theme: AppTheme.forPlatform(Brightness.light,
              platform: TargetPlatform.android),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!),
          home: const MailConsoleScreen(initialThreadKey: 'thread-1'),
        )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Texto confidencial'), findsNothing);
    final loc =
        AppLocalizations.of(tester.element(find.byType(MailConsoleScreen)))!;
    await tester.tap(find.text(loc.mailConversationReply));
    await tester.pumpAndSettle();
    final reply = find.byWidgetPredicate(
        (w) => w is TextField && w.keyboardType == TextInputType.multiline);
    await tester.enterText(reply, 'Gracias, pago recibido.');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text(loc.mailConsoleReplySend));
    await tester.pumpAndSettle();
    expect(find.text(loc.mailConsoleReplySend).hitTestable(), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(loc.mailConversationReply));
    await tester.pumpAndSettle();
    expect(find.text('Gracias, pago recibido.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    mail.dispose();
    auth.dispose();
    groups.dispose();
    client.close();
  });

  for (final fail in [false, true]) {
    testWidgets(
        'thread client response after disposal is ignored (failure=$fail)',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = const Size(430, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final response = Completer<http.Response>();
      var requested = false;
      final client = MockClient((_) {
        requested = true;
        return response.future;
      });
      final mail = _Mail();
      final auth = _Auth();
      final groups = _Groups();
      await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<MailDomain>.value(value: mail),
            ChangeNotifierProvider<AuthService>.value(value: auth),
            ChangeNotifierProvider<GroupDomain>.value(value: groups),
            Provider<http.Client>.value(value: client),
          ],
          child: MaterialApp(
            theme: AppTheme.forPlatform(Brightness.light,
                platform: TargetPlatform.android),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MailConsoleScreen(initialThreadKey: 'thread-1'),
          )));
      for (var i = 0; i < 20 && !requested; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(requested, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      if (fail) {
        response.completeError(Exception('network failed'));
      } else {
        response.complete(http.Response('[]', 200));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      client.close();
      mail.dispose();
      auth.dispose();
      groups.dispose();
    });
  }
}
