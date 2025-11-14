import 'package:flutter/material.dart';

class NoUsersAvailableWidget extends StatelessWidget {
  const NoUsersAvailableWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Text(
        'No users available to select.',
        style: const TextStyle(fontSize: 16, color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  }
}
