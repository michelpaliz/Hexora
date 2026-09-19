import 'package:flutter/material.dart';

class NoUsersAvailableWidget extends StatelessWidget {
  const NoUsersAvailableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: Text(
        'No users available to select.',
        style: TextStyle(fontSize: 16, color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  }
}
