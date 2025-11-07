import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/repository/user_repository.dart';

Future<void> fetchUserData({
  required Group group,
  required UserRepository userRepository,
  required List<String> recipientIds,
  required List<User> users,
  required void Function(User) onUserFound,
}) async {
  if (group.userIds.isEmpty) return;

  // Deduplicate against what's already in `users`
  final seen = <String>{for (final u in users) u.id};

  for (final rawId in group.userIds) {
    final id = rawId.toString();
    try {
      final u = await userRepository.getUserById(id);
      if (seen.add(u.id)) {
        users.add(u);
      }
      if (recipientIds.contains(u.id)) {
        onUserFound(u);
      }
    } catch (_) {
      // ignore individual fetch errors; continue
    }
  }
}
