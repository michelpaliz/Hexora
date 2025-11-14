import 'package:flutter/material.dart';

class StatusDot extends StatelessWidget {
  final String token; // 'Accepted' | 'Pending' | 'NotAccepted'
  const StatusDot({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (token) {
      case 'Accepted':
        c = Colors.green;
        break;
      case 'Pending':
        c = Colors.amber;
        break;
      default:
        c = Colors.redAccent;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}
