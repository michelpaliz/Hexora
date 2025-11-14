import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/actions/add_screen/utils/dialog/user_expandable_card.dart';

import 'section_card_builder.dart';

class AssignedUsersSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final List<User> usersAvailable;
  final List<User> initiallySelected;
  final String excludeUserId;
  final ValueChanged<List<User>> onSelectedUsersChanged;

  const AssignedUsersSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.usersAvailable,
    required this.initiallySelected,
    required this.excludeUserId,
    required this.onSelectedUsersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return cardBuilder(
      title: title,
      child: UserExpandableCard(
        usersAvailable: usersAvailable,
        initiallySelected: initiallySelected,
        excludeUserId: excludeUserId,
        onSelectedUsersChanged: onSelectedUsersChanged,
      ),
    );
  }
}
