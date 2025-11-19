// lib/c-frontend/ui-app/shared/widgets/group_identity_row.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/widget/group_header_primitives.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';

/// Lightweight meta token that can be either text or icon.
class MetaEntry {
  final String? text;
  final IconData? icon;
  const MetaEntry._({this.text, this.icon});
  const MetaEntry.text(String value) : this._(text: value);
  const MetaEntry.icon(IconData value) : this._(icon: value);
}

class GroupIdentityRow extends StatelessWidget {
  const GroupIdentityRow({
    super.key,
    required this.title,
    required this.metaTexts,
    this.metaInlineWidgets, // highest precedence
    this.metaEntries, // NEW: text/icon tokens
    this.photoUrl,
    this.avatarRadius = 24,
    this.trailing,
    this.titleStyle,
    this.dense = true,
  });

  final String title;
  final List<String> metaTexts; // kept for backward compatibility
  final List<Widget>? metaInlineWidgets; // custom widgets (takes precedence)
  final List<MetaEntry>? metaEntries; // NEW
  final String? photoUrl;
  final double avatarRadius;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipOval(
          child: SizedBox(
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            child: AvatarUtils.groupAvatar(context, photoUrl,
                radius: avatarRadius),
          ),
        ),
        SizedBox(width: dense ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (titleStyle ?? textTheme.titleMedium)?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              SizedBox(height: dense ? 2 : 4),
              // Precedence: custom widgets > entries (text/icon) > plain texts
              if (metaInlineWidgets != null && metaInlineWidgets!.isNotEmpty)
                Row(
                    mainAxisSize: MainAxisSize.min,
                    children: metaInlineWidgets!)
              else if (metaEntries != null && metaEntries!.isNotEmpty)
                _MetaTokensLine(
                    entries: metaEntries!, iconColor: cs.onSurfaceVariant)
              else
                _MetaTextsLine(metaTexts: metaTexts),
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: dense ? 8 : 12),
          trailing!,
        ],
      ],
    );
  }
}

class _MetaTextsLine extends StatelessWidget {
  const _MetaTextsLine({required this.metaTexts});
  final List<String> metaTexts;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < metaTexts.length; i++) {
      items.add(MetaText(text: metaTexts[i]));
      if (i != metaTexts.length - 1) items.add(const MetaSeparatorDot());
    }
    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }
}

class _MetaTokensLine extends StatelessWidget {
  const _MetaTokensLine({required this.entries, required this.iconColor});
  final List<MetaEntry> entries;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (e.text != null) {
        items.add(MetaText(text: e.text!));
      } else if (e.icon != null) {
        items.add(Icon(e.icon!, size: 14, color: iconColor));
      }
      if (i != entries.length - 1) items.add(const MetaSeparatorDot());
    }
    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }
}
