import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientListItem extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;

  /// Typography (from Typo)
  final TextStyle nameStyle;
  final TextStyle metaStyle;

  const ClientListItem({
    super.key,
    required this.client,
    this.onTap,
    required this.nameStyle,
    required this.metaStyle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.surface,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.35), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar / Icon
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primary.withOpacity(0.10),
                child: Icon(Icons.person_outline, color: cs.primary),
              ),
              const SizedBox(width: 12),

              // Title + details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      client.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle,
                    ),
                    const SizedBox(height: 4),

                    // Meta (phone/email)
                    _MetaRow(
                      phone: client.phone,
                      email: client.email,
                      textStyle: metaStyle,
                      iconColor: cs.onSurfaceVariant.withOpacity(0.9),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Status + chevron
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusChip(active: client.isActive),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String? phone;
  final String? email;
  final TextStyle textStyle;
  final Color iconColor;

  const _MetaRow({
    required this.phone,
    required this.email,
    required this.textStyle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    if ((phone ?? '').isNotEmpty) {
      rows.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone_rounded, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              phone!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ));
    }

    if ((email ?? '').isNotEmpty) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 2));
      rows.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alternate_email_rounded, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              email!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ));
    }

    if (rows.isEmpty) {
      rows.add(Text(
        AppLocalizations.of(context)!.contact,
        style: textStyle.copyWith(fontStyle: FontStyle.italic),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);

    // Warmer, modern hues
    final Color bg = active ? const Color(0xFFE07A5F) : const Color(0xFFE63946);
    final Color fg = ThemeColors.getContrastTextColorForBackground(bg);
    final String label = active ? l.active : l.inactive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          if (active)
            BoxShadow(
              color: bg.withOpacity(0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Text(
        label,
        style: typo.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
