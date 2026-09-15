import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/repository/i_group_repository.dart';
import 'package:hexora/services/groups/event/resolver/event_group_resolver.dart';
import 'package:hexora/services/user/repository/i_user_repository.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/viewmodels/groups/use_cases/update_group_usecase.dart';

class _Repo implements IGroupRepository {
  bool fail = false;
  @override
  Future<void> updateGroup(Group group) async {
    if (fail) throw StateError('save failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Users implements IUserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Resolver implements GroupEventResolver {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserDomain implements UserDomain {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Domain extends GroupDomain {
  _Domain(_Repo repo)
      : super(
            groupRepository: repo,
            userRepository: _Users(),
            groupEventResolver: _Resolver(),
            user: null);
  final refresh = Completer<void>();
  @override
  Future<void> refreshGroupsForCurrentUser(UserDomain userDomain) =>
      refresh.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = Group(
      id: 'g',
      name: 'Group',
      ownerId: 'u',
      userRoles: const {'u': 'owner'},
      userIds: const ['u'],
      createdTime: DateTime(2026),
      description: 'Before');
  test('successful edits notify immediately before list refresh finishes',
      () async {
    final domain = _Domain(_Repo());
    addTearDown(domain.dispose);
    final changed = Completer<Group>();
    domain.addListener(() {
      final group = domain.lastUpdatedGroup;
      if (group != null && !changed.isCompleted) changed.complete(group);
    });
    final save = UpdateGroupUseCase(domain, _UserDomain())(
        original: original, name: original.name, description: 'After');
    expect((await changed.future).description, 'After');
    domain.refresh.complete();
    await save;
  });
  test('failed edits throw and do not publish a successful update', () async {
    final domain = _Domain(_Repo()..fail = true);
    addTearDown(domain.dispose);
    await expectLater(
        UpdateGroupUseCase(domain, _UserDomain())(
            original: original, name: original.name, description: 'After'),
        throwsStateError);
    expect(domain.lastUpdatedGroup, isNull);
  });
}
