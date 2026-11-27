import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/create_edit/models/create_group_data.dart';
import 'package:hexora/presentation/viewmodels/groups/group_editor_state.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/create_group_usecase.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/invite_members_usecase.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/search_users_usecase.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/update_group_usecase.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/upload_group_photo_usecase.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class _UserDomain extends ChangeNotifier implements UserDomain {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  User get user => User(
      id: 'owner',
      name: 'Owner',
      email: 'owner@example.com',
      userName: 'owner',
      groupIds: [],
      emailVerified: true);
}

class _Create extends Fake implements CreateGroupUseCase {}

class _Invite extends Fake implements InviteMembersUseCase {}

class _Search extends Fake implements SearchUsersUseCase {}

class _Update extends Fake implements UpdateGroupUseCase {}

class _Upload extends Fake implements UploadGroupPhotoUseCase {}

Future<void> mount(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MultiProvider(providers: [
    ChangeNotifierProvider<UserDomain>.value(value: _UserDomain()),
    Provider<CreateGroupUseCase>.value(value: _Create()),
    Provider<InviteMembersUseCase>.value(value: _Invite()),
    Provider<SearchUsersUseCase>.value(value: _Search()),
    Provider<UpdateGroupUseCase>.value(value: _Update()),
    Provider<UploadGroupPhotoUseCase>.value(value: _Upload()),
  ], child: const MaterialApp(home: Scaffold(body: CreateGroupData()))));
  await tester.pumpAndSettle();
}

Finder field(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label);

Future<void> enter(WidgetTester tester, String label, String text) async {
  await tester.ensureVisible(field(label));
  await tester.enterText(field(label), text);
}

Future<void> next(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  test('a removed logo is cleared while unrelated edits preserve it', () {
    final image = XFile('logo.png');
    final state = GroupEditorState(image: image);
    expect(state.copyWith(name: 'Business').image, same(image));
    expect(state.copyWith(image: null).image, isNull);
  });

  for (final size in [const Size(390, 844), const Size(1100, 950)]) {
    testWidgets('all steps validate and preserve edits at $size',
        (tester) async {
      await mount(tester, size);
      expect(find.text('Step 1 of 4'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
      await next(tester);
      expect(find.text('This field is required.'), findsOneWidget);
      expect(find.text('Choose a business type.'), findsOneWidget);
      await enter(tester, 'Business name *', 'Garden Studio');
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gardening and pools').last);
      await tester.pumpAndSettle();
      await next(tester);
      await tester.tap(find.text('Use business name'));
      await enter(tester, 'Tax ID / VAT number *', 'TEST-123');
      await enter(tester, 'Street address *', 'Main Street 1');
      await enter(tester, 'City *', 'Madrid');
      await enter(tester, 'Postal code *', '28001');
      await enter(tester, 'Business email (optional)', 'invalid');
      await next(tester);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      await enter(tester, 'Business email (optional)', 'hello@example.com');
      await next(tester);
      expect(find.text('Example calculation'), findsOneWidget);
      expect(find.text('121.00 EUR'), findsOneWidget);
      await next(tester);
      expect(find.text('Invite your team'), findsOneWidget);
      expect(find.text('Skip team'), findsOneWidget);
      await enter(tester, 'Email address', 'invalid');
      await tester.tap(find.text('Create business').last);
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      await enter(tester, 'Email address', 'person@example.com');
      await tester.ensureVisible(find.text('Add another person'));
      await tester.tap(find.text('Add another person'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(field('Email address').last);
      await tester.enterText(field('Email address').last, 'PERSON@example.com');
      await tester.tap(find.text('Create business').last);
      await tester.pumpAndSettle();
      expect(find.text('This email is already in the list.'), findsNWidgets(2));
      await tester.ensureVisible(find.text('Edit identity'));
      await tester.tap(find.text('Edit identity'));
      await tester.pumpAndSettle();
      expect(find.text('Garden Studio'), findsOneWidget);
    });
  }
}
