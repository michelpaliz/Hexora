import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/create_edit/widgets/navigation/bottom_nav_bar.dart';

class EditGroupBottomNav extends StatelessWidget {
  final VoidCallback onUpdate;

  const EditGroupBottomNav({
    Key? key,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationSection(onGroupUpdate: onUpdate);
  }
}
