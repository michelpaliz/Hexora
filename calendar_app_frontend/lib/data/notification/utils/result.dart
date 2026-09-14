import 'package:hexora/models/notification/notification_user.dart';

sealed class GetNotifResult {
  const GetNotifResult();
}

class NotifOk extends GetNotifResult {
  final NotificationUser value;
  const NotifOk(this.value);
}

class NotifNotFound extends GetNotifResult {
  const NotifNotFound();
}

class NotifError extends GetNotifResult {
  final String message;
  const NotifError(this.message);
}

