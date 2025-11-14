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

  const ClientsTab({
    super.key,
    required this.items,
    required this.loading,
    required this.error,
    required this.onRefresh,
    this.showInlineCTA = false,
    this.onAddTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return ErrorView(message: error!, onRetry: onRefresh);

    if (items.isEmpty) {
      return EmptyView(
        icon: Icons.person_outline,
        title: l.noClientsYet,
        subtitle: l.addYourFirstClient,
        cta: showInlineCTA ? l.addClient : null,
        onPressed: showInlineCTA ? onAddTap : null,
      );
    }

    return RefreshIndicator(
      color: cs.primary,
      backgroundColor: cs.surface,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final c = items[i];
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
    );
  }
}
