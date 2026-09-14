import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/app/session/session_expiry_handler.dart';
import 'package:hexora/data/auth/api/i_auth_api_client.dart';
import 'package:hexora/data/auth/auth/auth_services/auth_provider.dart';
import 'package:hexora/data/auth/auth/token/model/token_obj.dart';
import 'package:hexora/data/auth/auth/token/token_store/Itoken_store.dart';
import 'package:hexora/data/group_management/event/socket/socket_manager.dart';
import 'package:hexora/data/notification/domain/notification_domain.dart';
import 'package:hexora/data/notification/domain/socket_notification_listener.dart';
import 'package:hexora/data/user/repository/i_user_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _FakeNotificationSocket implements NotificationSocketClient {
  final Map<String, Function> _handlers = {};
  bool _connected = false;
  bool disposed = false;

  @override
  bool get connected => _connected;

  @override
  void connect() => _connected = true;

  @override
  void dispose() {
    disposed = true;
    _connected = false;
  }

  Future<void> emit(String event, dynamic data) async {
    final result = _handlers[event]?.call(data);
    if (result is Future) await result;
  }

  @override
  void on(String event, Function handler) => _handlers[event] = handler;

  @override
  void onConnect(Function handler) => _handlers['connect'] = handler;

  @override
  void onDisconnect(Function handler) => _handlers['disconnect'] = handler;
}

class _FakeAuthApiClient implements IAuthApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserRepository implements IUserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryTokenStore implements TokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccess() async => null;

  @override
  Future<AuthTokens?> readBoth() async => null;

  @override
  Future<String?> readRefresh() async => null;

  @override
  Future<void> save(AuthTokens tokens) async {}
}

void _configureOfflineSocketManager(
  List<Map<String, dynamic>> socketOptions,
) {
  SocketManager().setSocketFactoryForTesting((_, options) {
    socketOptions.add(Map<String, dynamic>.from(options));
    return io.io('http://localhost', <String, dynamic>{
      'autoConnect': false,
      'forceNew': true,
      'transports': ['websocket'],
    });
  });
}

void _stageSocketLifecycle(SocketManager manager, String token) {
  manager.connect(token);
  manager.on('prior-user:event', (_) {});
  manager.emit('prior-user:emit', <String, dynamic>{'id': 'queued'});
  unawaited(manager.waitUntilConnected());
}

void _expectSocketManagerCleared() {
  final state = SocketManager().stateForTesting;
  expect(state.hasSocket, isFalse);
  expect(state.authToken, isNull);
  expect(state.pendingEmitCount, 0);
  expect(state.readinessWaiterCount, 0);
  expect(state.registeredHandlerCount, 0);
}

AuthProvider _buildAuthProvider() {
  return AuthProvider(
    userRepository: _FakeUserRepository(),
    authApi: _FakeAuthApiClient(),
    tokens: _MemoryTokenStore(),
  );
}

void main() {
  tearDown(() {
    setNotificationSocketFactoryForTesting(null);
    SocketManager().setSocketFactoryForTesting(null);
  });

  test(
    'logout clears realtime state and ignores prior inbound notifications',
    () async {
      final socket = _FakeNotificationSocket();
      final socketOptions = <Map<String, dynamic>>[];
      final notificationDomain = NotificationDomain();
      setNotificationSocketFactoryForTesting((_, __) => socket);
      _configureOfflineSocketManager(socketOptions);
      initializeNotificationSocket(
        'prior-user',
        notificationDomain: notificationDomain,
      );
      _stageSocketLifecycle(SocketManager(), 'prior-token');
      final auth = _buildAuthProvider();

      await auth.logOut();

      expect(socket.disposed, isTrue);
      expect(socketOptions, hasLength(1));
      _expectSocketManagerCleared();
      await socket.emit('notification:created', <String, dynamic>{
        'id': 'notification-1',
        'recipientId': 'prior-user',
        'timestamp': DateTime.now().toIso8601String(),
      });
      expect(notificationDomain.notifications, isEmpty);

      auth.dispose();
      notificationDomain.dispose();
    },
  );

  test('session expiry resets the active notification socket', () async {
    final socket = _FakeNotificationSocket();
    final socketOptions = <Map<String, dynamic>>[];
    setNotificationSocketFactoryForTesting((_, __) => socket);
    _configureOfflineSocketManager(socketOptions);
    initializeNotificationSocket('prior-user');
    _stageSocketLifecycle(SocketManager(), 'expired-token');

    await SessionExpiryHandler.handle(clearTokens: () async {});

    expect(socket.disposed, isTrue);
    expect(socketOptions, hasLength(1));
    _expectSocketManagerCleared();
  });

  test('account switch starts a fresh group-event socket lifecycle', () async {
    final socketOptions = <Map<String, dynamic>>[];
    _configureOfflineSocketManager(socketOptions);
    final manager = SocketManager();
    _stageSocketLifecycle(manager, 'first-account-token');

    final auth = _buildAuthProvider();
    await auth.logOut();

    manager.connect('second-account-token');

    expect(socketOptions, hasLength(2));
    expect(socketOptions.last['extraHeaders'], <String, String>{
      'Authorization': 'Bearer second-account-token',
    });
    final state = manager.stateForTesting;
    expect(state.authToken, 'second-account-token');
    expect(state.pendingEmitCount, 0);
    expect(state.readinessWaiterCount, 0);
    expect(state.registeredHandlerCount, 0);

    auth.dispose();
  });
}
