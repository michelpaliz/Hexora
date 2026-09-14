// lib/data/user/presence_role_bridge.dart
import 'package:hexora/data/user/presence_domain.dart';
import 'package:hexora/presentation/utils/roles/group_role/group_role.dart';

GroupRole toGroupRole(UserRole r) => switch (r) {
      UserRole.admin => GroupRole.admin,
      UserRole.coAdmin => GroupRole.coAdmin,
      UserRole.member => GroupRole.member,
    };
