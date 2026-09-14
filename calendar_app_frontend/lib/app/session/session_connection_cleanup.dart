import 'package:hexora/data/group_management/event/socket/socket_manager.dart';
import 'package:hexora/data/notification/domain/socket_notification_listener.dart';

/// Releases all user-scoped realtime connections during logout or expiry.
void resetSessionConnections() {
  resetNotificationSocket();
  SocketManager().disconnect();
}
