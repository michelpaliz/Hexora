import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/mail/mail_folder.dart';
import 'package:hexora/models/mail/mail_message.dart';
import 'package:hexora/models/mail/mail_page.dart';
import 'package:hexora/models/mail/mail_thread.dart';
import 'package:hexora/services/mail/domain/mail_domain.dart';
import 'package:hexora/services/mail/models/mail_requests.dart';
import 'package:hexora/services/mail/repository/i_mail_repository.dart';
import 'package:hexora/presentation/screens/workspace/sections/mail/mail_console_screen.dart';
import 'package:hexora/presentation/shared/widgets/collapsible_sidebar.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

const _typography = AppTypography(
  displayLarge: TextStyle(),
  displayMedium: TextStyle(),
  titleLarge: TextStyle(),
  bodyLarge: TextStyle(),
  bodyMedium: TextStyle(),
  bodySmall: TextStyle(),
  buttonText: TextStyle(),
  caption: TextStyle(),
  accentHeading: TextStyle(),
  accentText: TextStyle(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Email menu collapses and expands with selection and tooltips intact',
      (tester) async {
    await _setSurfaceSize(tester, const Size(1200, 800));
    final repository = _FakeMailRepository();

    await tester.pumpWidget(
      _mailApp(
        repository: repository,
        home: const MailConsoleScreen(
          embedded: true,
          initialFolder: MailFolder.archive,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      tester.getSize(find.byKey(const ValueKey('collapsible-sidebar'))).width,
      CollapsibleSidebar.expandedWidth,
    );
    expect(
      tester
          .widget<SidebarItem>(
            find.byKey(const ValueKey('mail-folder-archive')),
          )
          .isSelected,
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey('collapsible-sidebar-toggle')),
    );
    await tester.pump();
    await tester.pump(CollapsibleSidebar.animationDuration);

    expect(
      tester.getSize(find.byKey(const ValueKey('collapsible-sidebar'))).width,
      CollapsibleSidebar.collapsedWidth,
    );
    expect(
      tester
          .widget<SidebarItem>(
            find.byKey(const ValueKey('mail-folder-archive')),
          )
          .isSelected,
      isTrue,
    );
    for (final label in const [
      'Compose',
      'Inbox',
      'Sent',
      'Archive',
      'Trash',
      'Spam',
      'Create footer',
      'Templates',
    ]) {
      expect(find.byTooltip(label), findsOneWidget);
    }

    await tester.tap(
      find.byKey(const ValueKey('collapsible-sidebar-toggle')),
    );
    await tester.pump();
    await tester.pump(CollapsibleSidebar.animationDuration);
    expect(
      tester.getSize(find.byKey(const ValueKey('collapsible-sidebar'))).width,
      CollapsibleSidebar.expandedWidth,
    );
  });

  testWidgets('mobile Email drawer closes after selecting a folder',
      (tester) async {
    await _setSurfaceSize(tester, const Size(500, 800));
    final repository = _FakeMailRepository();

    await tester.pumpWidget(
      _mailApp(
        repository: repository,
        home: const MailConsoleScreen(),
        routeAwareMailScreen: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.openDrawer();
    await tester.pumpAndSettle();
    expect(scaffold.isDrawerOpen, isTrue);

    await tester.tap(find.byKey(const ValueKey('mail-folder-sent')));
    await tester.pumpAndSettle();

    final currentScaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(currentScaffold.isDrawerOpen, isFalse);

    currentScaffold.openDrawer();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SidebarItem>(
            find.byKey(const ValueKey('mail-folder-sent')),
          )
          .isSelected,
      isTrue,
    );
  });

  testWidgets('collapsing Email menu preserves the selected thread',
      (tester) async {
    await _setSurfaceSize(tester, const Size(1200, 800));
    final repository = _FakeMailRepository(pendingThreadDetail: true);

    await tester.pumpWidget(
      _mailApp(
        repository: repository,
        home: const MailConsoleScreen(embedded: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();

    await tester.tap(find.text('Quarterly update'));
    await tester.pump();
    expect(repository.threadRequests, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('collapsible-sidebar-toggle')),
    );
    await tester.pump();
    await tester.pump(CollapsibleSidebar.animationDuration);

    expect(repository.threadRequests, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Select a thread to read it.'), findsNothing);
  });
}

Widget _mailApp({
  required _FakeMailRepository repository,
  required Widget home,
  bool routeAwareMailScreen = false,
}) {
  return ChangeNotifierProvider(
    create: (_) => MailDomain(repository: repository),
    child: MaterialApp(
      locale: const Locale('en'),
      theme: ThemeData(extensions: const [_typography]),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(child: home),
      onGenerateRoute: routeAwareMailScreen
          ? (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => MailConsoleScreen.fromRoute(context),
              )
          : null,
    ),
  );
}

Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

class _FakeMailRepository implements IMailRepository {
  _FakeMailRepository({this.pendingThreadDetail = false});

  final bool pendingThreadDetail;
  final Completer<MailThreadDetail> _threadCompleter =
      Completer<MailThreadDetail>();
  int threadRequests = 0;

  static const _thread = MailThread(
    threadKey: 'thread-1',
    subject: 'Quarterly update',
    participants: ['Client'],
    messageCount: 1,
  );

  @override
  Future<MailPage<MailThread>> getThreads({
    required MailFolder folder,
    int limit = 25,
    String? cursor,
    String? query,
  }) async {
    return const MailPage(items: [_thread]);
  }

  @override
  Future<MailThreadDetail> getThread(String threadKey) {
    threadRequests += 1;
    if (pendingThreadDetail) return _threadCompleter.future;
    return Future.value(
      MailThreadDetail(threadKey: threadKey, subject: _thread.subject),
    );
  }

  @override
  Future<MailPage<MailMessage>> getMessages({
    required MailFolder folder,
    int limit = 25,
    String? cursor,
  }) async =>
      const MailPage(items: []);

  @override
  Future<MailMessage> getMessage(String id) async => MailMessage(id: id);

  @override
  Future<MailPage<MailMessage>> searchMessages({
    required String query,
    MailFolder? folder,
    bool? unread,
    DateTime? after,
    DateTime? before,
    int limit = 25,
    String? cursor,
  }) async =>
      const MailPage(items: []);

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markUnread(String id) async {}

  @override
  Future<void> archive(String id) async {}

  @override
  Future<void> trash(String id) async {}

  @override
  Future<void> spam(String id) async {}

  @override
  Future<http.Response> downloadAttachment(String attachmentId) async =>
      http.Response('', 200);

  @override
  Future<void> sendMessage(MailSendRequest request) async {}

  @override
  Future<void> reply(String id, MailReplyRequest request) async {}

  @override
  Future<void> forward(String id, MailForwardRequest request) async {}
}
