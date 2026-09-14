import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/create_worker/form/create_worker_screen.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class _FakeTimeTrackingRepository implements ITimeTrackingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserRepository implements IUserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Group _group() => Group(
      id: 'group-1',
      name: 'Group',
      ownerId: 'user-1',
      userRoles: const {'user-1': 'owner'},
      userIds: const ['user-1'],
      createdTime: DateTime.utc(2026, 1, 1),
      description: 'Test group',
    );

void main() {
  testWidgets('disposes all form controllers when removed from the tree',
      (tester) async {
    final userDomain = UserDomain(
      userRepository: _FakeUserRepository(),
      notificationDomain: NotificationDomain(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ITimeTrackingRepository>.value(
            value: _FakeTimeTrackingRepository(),
          ),
          Provider<UserDomain>.value(value: userDomain),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CreateWorkerScreen(group: _group()),
        ),
      ),
    );

    final controllers = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .map((field) => field.controller!)
        .toSet();

    await tester.tap(find.byType(Switch));
    await tester.pump();
    controllers.add(
      tester.widget<TextFormField>(find.byType(TextFormField).first).controller!,
    );

    expect(controllers, hasLength(5));

    await tester.pumpWidget(const SizedBox());

    for (final controller in controllers) {
      expect(() => controller.addListener(() {}), throwsFlutterError);
    }
  });
}
