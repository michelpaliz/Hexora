import 'package:flutter/material.dart';
import 'package:hexora/b-backend/user/presence_domain.dart';
import 'package:hexora/c-frontend/utils/image/widgets/user_item.dart';

class UserStatusRow extends StatelessWidget {
  final List<UserPresence> userList;

  const UserStatusRow({super.key, required this.userList});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: userList.length,
        itemBuilder: (context, index) {
          return UserItem(user: userList[index]);
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
      ),
    );
  }
}
