import 'package:flutter/material.dart';

/// Gives each field a full line when the available space is limited.
class ClientFormFields extends StatelessWidget {
  const ClientFormFields({
    super.key,
    required this.first,
    required this.second,
    this.firstFlex = 1,
    this.secondFlex = 1,
    this.gap = 10,
  });

  final Widget first;
  final Widget second;
  final int firstFlex;
  final int secondFlex;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      if (constraints.maxWidth < 380 * textScale) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, SizedBox(height: gap), second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: firstFlex, child: first),
          SizedBox(width: gap),
          Expanded(flex: secondFlex, child: second),
        ],
      );
    });
  }
}
