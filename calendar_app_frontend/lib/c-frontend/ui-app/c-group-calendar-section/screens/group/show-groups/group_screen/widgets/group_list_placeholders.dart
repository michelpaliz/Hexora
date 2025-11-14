import 'package:flutter/material.dart';

class NoGroupsText extends StatelessWidget {
  const NoGroupsText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final smallBody = Theme.of(context).textTheme.bodySmall!;
    final color = Theme.of(context).colorScheme.outline;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: smallBody.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final smallBody = Theme.of(context).textTheme.bodySmall!;
    final color = Theme.of(context).colorScheme.error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: smallBody.copyWith(color: color, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
