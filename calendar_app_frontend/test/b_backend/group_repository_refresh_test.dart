import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/group_mng_flow/group/api/group_api_client.dart';
import 'package:hexora/b-backend/group_mng_flow/group/repository/group_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _groupJson(String id, String name) => <String, dynamic>{
      '_id': id,
      'name': name,
      'ownerId': 'user-1',
      'userRoles': const <String, String>{'user-1': 'owner'},
      'userIds': const <String>['user-1'],
      'createdTime': '2026-09-07T08:00:00Z',
      'description': '',
    };

void main() {
  test('refresh uses the single groups-by-user request', () async {
    final requests = <http.Request>[];
    final repository = GroupRepository(
      apiClient: HttpGroupApiClient(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode(<Map<String, dynamic>>[
              _groupJson('group-1', 'Hexora'),
            ]),
            200,
          );
        }),
      ),
      tokenSupplier: () async => 'token',
    );
    addTearDown(repository.dispose);
    final emitted = repository.userGroups$('user-1').first;

    await repository.refreshUserGroupsByIds(
      'user-1',
      const <String>['group-1'],
      userName: 'michel',
    );

    expect((await emitted).single.name, 'Hexora');
    expect(requests, hasLength(1));
    expect(requests.single.url.path, endsWith('/groups/user/michel'));
  });

  test('falls back to group IDs when the fast lookup is unexpectedly empty',
      () async {
    final requests = <http.Request>[];
    final repository = GroupRepository(
      apiClient: HttpGroupApiClient(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/groups/user/michel')) {
            return http.Response('[]', 200);
          }
          return http.Response(
            jsonEncode(_groupJson('group-1', 'Recovered')),
            200,
          );
        }),
      ),
      tokenSupplier: () async => 'token',
    );
    addTearDown(repository.dispose);
    final emitted = repository.userGroups$('user-1').first;

    await repository.refreshUserGroupsByIds(
      'user-1',
      const <String>['group-1'],
      userName: 'michel',
    );

    expect((await emitted).single.name, 'Recovered');
    expect(requests, hasLength(2));
    expect(requests.last.url.path, endsWith('/groups/group-1'));
  });

  test('an older refresh cannot overwrite a newer result', () async {
    final slowResponse = Completer<http.Response>();
    final slowStarted = Completer<void>();
    final repository = GroupRepository(
      apiClient: HttpGroupApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/user/slow')) {
            slowStarted.complete();
            return slowResponse.future;
          }
          return http.Response(
            jsonEncode(<Map<String, dynamic>>[
              _groupJson('group-new', 'Newest'),
            ]),
            200,
          );
        }),
      ),
      tokenSupplier: () async => 'token',
    );
    addTearDown(repository.dispose);
    final emissions = <String>[];
    final subscription = repository.userGroups$('user-1').listen(
          (groups) => emissions.addAll(groups.map((group) => group.name)),
        );
    addTearDown(subscription.cancel);

    final older = repository.refreshUserGroupsByIds(
      'user-1',
      const <String>['group-old'],
      userName: 'slow',
    );
    await slowStarted.future;
    await repository.refreshUserGroupsByIds(
      'user-1',
      const <String>['group-new'],
      userName: 'fast',
    );
    slowResponse.complete(
      http.Response(
        jsonEncode(<Map<String, dynamic>>[
          _groupJson('group-old', 'Stale'),
        ]),
        200,
      ),
    );
    await older;
    await Future<void>.delayed(Duration.zero);

    expect(emissions, <String>['Newest']);
  });
}
