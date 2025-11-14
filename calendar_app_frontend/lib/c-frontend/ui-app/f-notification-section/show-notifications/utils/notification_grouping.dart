import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/l10n/app_localizations.dart';

Map<String, List<NotificationUser>> groupNotificationsByTime(
  List<NotificationUser> list,
  AppLocalizations loc,
) {
  final now = DateTime.now();
  final grouped = {
    loc.groupRecent: <NotificationUser>[],
    loc.groupLast7Days: <NotificationUser>[],
    loc.groupLast30Days: <NotificationUser>[],
    loc.groupOlder: <NotificationUser>[],
  };

  for (var ntf in list) {
    final d = now.difference(ntf.timestamp);
    if (d.inDays < 1)
      grouped[loc.groupRecent]!.add(ntf);
    else if (d.inDays < 7)
      grouped[loc.groupLast7Days]!.add(ntf);
    else if (d.inDays < 30)
      grouped[loc.groupLast30Days]!.add(ntf);
    else
      grouped[loc.groupOlder]!.add(ntf);
  }

  return grouped;
}
