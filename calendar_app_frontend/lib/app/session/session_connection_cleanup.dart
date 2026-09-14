import 'package:hexora/b-backend/group_mng_flow/event/socket/socket_manager.dart';
import 'package:hexora/b-backend/notification/domain/socket_notification_listener.dart';

/// Releases all user-scoped realtime connections during logout or expiry.
void resetSessionConnections() {
  resetNotificationSocket();
  SocketManager().disconnect();
}
