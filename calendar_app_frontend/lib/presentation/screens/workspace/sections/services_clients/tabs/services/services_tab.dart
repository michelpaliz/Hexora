import 'package:flutter/material.dart';
import 'package:hexora/models/service_catalog/service.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../../widgets/common_views.dart';
import 'service_list_item.dart';

class ServicesTab extends StatefulWidget {
  final List<Service> items;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final bool showInlineCTA;
  final VoidCallback? onAddTap;
  final void Function(Service service)? onEdit; // optional
  final void Function(Service service)? onDelete; // optional

  const ServicesTab({
    super.key,
    required this.items,
    required this.loading,
    required this.error,
    required this.onRefresh,
    this.showInlineCTA = false,
    this.onAddTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  String _query = '';
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items
        .where((service) => service.name.toLowerCase().contains(_query))
        .toList();
    final loading = widget.loading;
    final error = widget.error;
    final onRefresh = widget.onRefresh;
    final onAddTap = widget.onAddTap;
    final showInlineCTA = widget.showInlineCTA;
    final onEdit = widget.onEdit;
    final onDelete = widget.onDelete;
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return ErrorView(message: error, onRetry: onRefresh);

    if (widget.items.isEmpty) {
      return EmptyView(
        icon: Icons.design_services_outlined,
        title: l.noServicesYet,
        subtitle: l.createServicesSubtitle,
        cta: showInlineCTA ? l.addService : null,
        onPressed: showInlineCTA ? onAddTap : null,
      );
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: TextField(
          controller: _search,
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: l.localeName.startsWith('es')
                ? 'Buscar servicios…'
                : 'Search services…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l.localeName.startsWith('es')
                        ? 'Borrar búsqueda'
                        : 'Clear search',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _search.clear();
                      _query = '';
                    }),
                  ),
          ),
        ),
      ),
      if (items.isEmpty)
        Expanded(
            child: Center(
                child: Text(l.localeName.startsWith('es')
                    ? 'No hay servicios que coincidan.'
                    : 'No matching services.')))
      else
        Expanded(
            child: RefreshIndicator(
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
                onTap: onEdit == null ? null : () => onEdit(s),
                onDelete: onDelete == null ? null : () => onDelete(s),
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
        )),
    ]);
  }
}
