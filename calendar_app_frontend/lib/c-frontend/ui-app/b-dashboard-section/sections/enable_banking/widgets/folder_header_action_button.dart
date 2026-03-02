import 'package:flutter/material.dart';

class FolderHeaderActionButton extends StatelessWidget {
  const FolderHeaderActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.selected = false,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: WidgetStatePropertyAll(EdgeInsets.zero),
      minimumSize: WidgetStatePropertyAll(Size(40, 36)),
    );

    if (selected) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: icon,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: icon,
    );
  }
}
