import 'package:flutter/material.dart';

class GroupDashboardContent extends StatelessWidget {
  final Color panelBg;
  final Widget child;

  const GroupDashboardContent({
    super.key,
    required this.panelBg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: panelBg),
      child: child,
    );
  }
}
