import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'client_list_item.dart';

class ClientsTab extends StatelessWidget {
  final List<GroupClient> items;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final bool showInlineCTA;
  final VoidCallback? onAddTap; // optional
  final void Function(GroupClient client)? onEdit; // tap-to-edit
  final bool showInactive;
  final ValueChanged<bool>? onToggleInactive;

  const ClientsTab({
    super.key,
    required this.items,
    required this.loading,
    required this.error,
    required this.onRefresh,
    this.showInlineCTA = false,
    this.onAddTap,
    this.onEdit,
    this.showInactive = false,
    this.onToggleInactive,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final activeItems =
        items.where((c) => c.isActive != false).toList(growable: false);
    final inactiveItems =
        items.where((c) => c.isActive == false).toList(growable: false);
    final visible =
        showInactive ? [...activeItems, ...inactiveItems] : activeItems;
    final activeCount = activeItems.length;
    final inactiveCount = inactiveItems.length;

    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return ErrorView(message: error!, onRetry: onRefresh);

    if (visible.isEmpty) {
      return EmptyView(
        icon: Icons.person_outline,
        title: l.noClientsYet,
        subtitle: showInactive
            ? '${l.activeClientsSection} · 0 · ${l.statusInactive}: 0'
            : '${l.activeClientsSection} · 0',
        cta: showInlineCTA ? l.addClient : null,
        onPressed: showInlineCTA ? onAddTap : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          child: Text(
            showInactive
                ? '${l.activeClientsSection} · $activeCount • ${l.statusInactive}: $inactiveCount'
                : '${l.activeClientsSection} · $activeCount',
            style: typo.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        if (onToggleInactive != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  l.statusInactive,
                  style: typo.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: showInactive,
                  onChanged: onToggleInactive,
                  activeColor: cs.primary,
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: cs.primary,
            backgroundColor: cs.surface,
            onRefresh: onRefresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = visible[i];
                return ClientListItem(
                  client: c,
                  onTap: onEdit == null ? null : () => onEdit!(c),
                  nameStyle: typo.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: .2,
                    color: cs.onSurface,
                  ),
                  metaStyle: typo.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: .1,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
