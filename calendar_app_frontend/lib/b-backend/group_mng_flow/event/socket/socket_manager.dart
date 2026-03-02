// socket_manager.dart
import 'dart:async';

import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  factory SocketManager() => _instance;
  SocketManager._internal();

  IO.Socket? _socket; // ✅ no 'late'
  bool get isConnected => _socket?.connected == true;

  // ✅ NEW: keep latest token for reconnect attempts
  String? _authToken; // ✅ NEW

  // ✅ NEW: pending emits while disconnected (best-effort)
  final List<_PendingEmit> _pendingEmits = []; // ✅ NEW

  // ✅ NEW: waiters that resolve on connect()
  final List<Function()> _onReady = []; // ✅ NEW

  // Deduped listener registry
  final Map<String, void Function(dynamic)> _registeredHandlers = {};

  /// Connect only once; safe to call multiple times.
  void connect(String userToken) {
    _authToken = userToken; // ✅ UPDATED: remember for reconnects

    if (_socket != null) {
      // Already created; ensure headers are current
      try {
        _socket!.io.options?['extraHeaders'] = {
          'Authorization': 'Bearer $_authToken',
        }; // ✅ NEW
      } catch (_) {}
      return;
    }

    final socketUrl = ApiConstants.socketBaseUrl;

    // ✅ UPDATED: enable reconnection with sane defaults
    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true, // ✅ NEW
      'reconnectionAttempts': 0, // ✅ NEW (0 = infinite)
      'reconnectionDelay': 500, // ✅ NEW (ms)
      'reconnectionDelayMax': 8000, // ✅ NEW (ms)
      'randomizationFactor': 0.5, // ✅ NEW (jitter)
      'extraHeaders': {
        'Authorization': 'Bearer $_authToken',
      },
    });

    // ✅ NEW: keep auth header fresh on reconnect attempts
    _socket!.on('reconnect_attempt', (attempt) {
      // If you have a token refresher, call it here and update _authToken.
      // For now we reuse the latest known token.
      try {
        _socket!.io.options?['extraHeaders'] = {
          'Authorization': 'Bearer $_authToken',
        };
      } catch (_) {}
    });

    _socket!.onConnect((_) {
      print("✅ Socket connected");

      _rebindAllHandlers(); // attach any handlers registered "early"

      // ✅ NEW: flush any queued emits
      if (_pendingEmits.isNotEmpty) {
        for (final p in List<_PendingEmit>.from(_pendingEmits)) {
          _socket!.emit(p.event, p.data);
        }
        _pendingEmits.clear();
      }

      // ✅ NEW: resolve waiters
      if (_onReady.isNotEmpty) {
        for (final fn in List<Function()>.from(_onReady)) {
          try {
            fn();
          } catch (_) {}
        }
        _onReady.clear();
      }
    });

    _socket!.onDisconnect((_) => print("ðŸ”Œ Socket disconnected"));
    _socket!.onError((err) => print("❌ Socket error: $err"));
    _socket!.onConnectError((err) => print("❌ Socket connect error: $err"));
    _socket!.onReconnect((_) => print("🔁 Socket reconnected")); // ✅ NEW
    _socket!
        .onReconnectError((err) => print("⚠️ Reconnect error: $err")); // ✅ NEW
    _socket!.onReconnectFailed((_) => print("🛑 Reconnect failed")); // ✅ NEW
  }

  /// Register an event listener with deduplication.
  /// Safe to call before connect(); it will bind on first connect.
  void on(String event, void Function(dynamic) handler) {
    // Store/replace handler in registry
    if (_registeredHandlers.containsKey(event) && _socket != null) {
      _socket!.off(event, _registeredHandlers[event]);
    }
    _registeredHandlers[event] = handler;

    // If socket exists now, bind immediately
    if (_socket != null) {
      _socket!.on(event, handler);
    } else {
      // print('ℹ️ Queued handler for "$event" until socket connects.');
    }
  }

  /// Unregister a specific event listener
  void off(String event) {
    if (_registeredHandlers.containsKey(event)) {
      if (_socket != null) {
        _socket!.off(event, _registeredHandlers[event]);
      }
      _registeredHandlers.remove(event);
    }
  }

  /// Emit helpers
  void emit(String event, dynamic data) {
    if (_socket == null || !isConnected) {
      // ✅ UPDATED: queue until connected (best-effort)
      _pendingEmits.add(_PendingEmit(event, data));
      print('⚠️ emit("$event") queued (socket not ready)');
      return;
    }
    _socket!.emit(event, data);
  }

  void emitUserJoin({
    required String userId,
    required String userName,
    required String groupId,
    required String? photoUrl,
  }) {
    emit("user:join", {
      "userId": userId,
      "userName": userName,
      "groupId": groupId,
      "photoUrl": photoUrl,
    });
    print("ðŸ“¡ Emitted user:join for $userName ($userId)");
  }

  // ✅ NEW: simple hook for callers that need to wait for connectivity
  Future<void> waitUntilConnected() {
    if (isConnected) return Future.value();
    final c = Completer<void>();
    _onReady.add(() {
      if (!c.isCompleted) c.complete();
    });
    return c.future;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _pendingEmits.clear(); // ✅ NEW
    _onReady.clear(); // ✅ NEW
  }

  // --- internal ---
  void _rebindAllHandlers() {
    if (_socket == null) return;
    _registeredHandlers.forEach((event, handler) {
      // Make sure we don't double-attach
      _socket!.off(event, handler);
      _socket!.on(event, handler);
    });
  }
}

// ✅ NEW: tiny holder for queued emits
class _PendingEmit {
  final String event;
  final dynamic data;
  _PendingEmit(this.event, this.data);
}
