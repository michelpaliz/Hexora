import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/shared/widgets/client_property_image.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/documents/hexora_status_badge.dart';
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

class ClientListItem extends StatelessWidget {
  const ClientListItem(
      {super.key,
      required this.client,
      this.selected = false,
      this.onTap,
      this.onDelete,
      required this.nameStyle,
      required this.metaStyle});
  final GroupClient client;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final TextStyle nameStyle;
  final TextStyle metaStyle;

  String get _initials {
    final parts = client.name.trim().split(RegExp(r'\s+'));
    if (parts.first.isEmpty) return '?';
    return parts
        .take(2)
        .map((part) => part.characters.first)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final contact = [client.email, client.phone]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' · ');
    final classification = [client.entityType, client.propertyKind]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' · ');
    final warnings = <Widget>[
      if (client.billing?.isComplete != true)
        HexoraStatusBadge(label: l.billingMissing, color: cs.onSurfaceVariant),
      if (client.missingCurrentMonthInvoice == true)
        HexoraStatusBadge(
            label: l.clientMissingInvoiceThisMonth, color: cs.error),
      if (!client.isActive)
        HexoraStatusBadge(label: l.inactive, color: cs.onSurfaceVariant),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 760 ||
          MediaQuery.textScalerOf(context).scale(13) > 18;
      final badges = Wrap(spacing: 4, runSpacing: 4, children: warnings);
      return HexoraListRow(
        selected: selected,
        onTap: onTap,
        minHeight: HexoraTableTokens.compactRowMinHeight,
        verticalPadding: HexoraDimensions.space,
        child: Row(children: [
          if (client.imageVersion != null)
            ClientPropertyImage(client: client, width: 30, height: 30)
          else
            CircleAvatar(
                radius: 15,
                backgroundColor: cs.surfaceContainerHighest,
                foregroundColor: cs.onSurfaceVariant,
                child: Text(_initials,
                    style: const TextStyle(
                        fontFamily: HexoraTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(client.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: nameStyle.copyWith(
                        fontFamily: HexoraTypography.fontFamily,
                        fontSize: HexoraTypography.body,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0)),
                if (contact.isNotEmpty || classification.isNotEmpty)
                  Tooltip(
                      message: [contact, classification]
                          .where((value) => value.isNotEmpty)
                          .join('\n'),
                      child: Text(
                          classification.isNotEmpty ? classification : contact,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: metaStyle.copyWith(
                              fontSize: HexoraTypography.label,
                              color: cs.onSurfaceVariant))),
                if (compact && warnings.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  badges
                ],
              ])),
          if (!compact && warnings.isNotEmpty) ...[
            const SizedBox(width: 12),
            ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220), child: badges)
          ],
          if (onTap != null || onDelete != null)
            PopupMenuButton<String>(
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (value) =>
                  value == 'edit' ? onTap?.call() : onDelete?.call(),
              itemBuilder: (_) => [
                if (onTap != null)
                  NavigationPopupMenuItem(
                      value: 'edit', child: Text(l.editClient)),
                if (onDelete != null)
                  NavigationPopupMenuItem(
                      value: 'delete', child: Text(l.remove)),
              ],
            ),
          if (onTap != null)
            Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
        ]),
      );
    });
  }
}
