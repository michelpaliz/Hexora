import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../widgets/common_views.dart';
import 'service_list_item.dart';

class ServicesTab extends StatelessWidget {
  final List<Service> items;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final bool showInlineCTA;
  final VoidCallback? onAddTap;
  final void Function(Service service)? onEdit; // optional

  const ServicesTab({
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
        icon: Icons.design_services_outlined,
        title: l.noServicesYet,
        subtitle: l.createServicesSubtitle,
        cta: showInlineCTA ? l.addService : null,
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
          final s = items[i];
          return ServiceListItem(
            service: s,
            onTap: onEdit == null ? null : () => onEdit!(s),
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
