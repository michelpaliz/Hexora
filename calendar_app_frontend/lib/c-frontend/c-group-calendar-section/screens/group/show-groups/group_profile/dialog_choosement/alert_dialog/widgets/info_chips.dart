// lib/.../dialog_content/widgets/info_chips.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';

class InfoChips extends StatelessWidget {
  const InfoChips({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyS = Theme.of(context).textTheme.bodySmall!;

    Widget chip(IconData icon, String label, {double? maxWidth}) {
      final content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: scheme.surfaceContainerHighest,
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bodyS.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (maxWidth != null) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: content,
        );
      }
      return content;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(Icons.group_outlined, '${group.userIds.length}'),
        if (group.description.isNotEmpty == true)
          chip(Icons.description_outlined, group.description, maxWidth: 240),
      ],
    );
  }
}
