import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_section_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RecurringWizardClientStep extends StatefulWidget {
  final List<GroupClient> clients;
  final String? clientId;
  final ValueChanged<String?> onClientChanged;
  final TextEditingController nameCtrl;
  final TextEditingController currencyCtrl;
  final TextEditingController notesCtrl;

  const RecurringWizardClientStep({
    super.key,
    required this.clients,
    required this.clientId,
    required this.onClientChanged,
    required this.nameCtrl,
    required this.currencyCtrl,
    required this.notesCtrl,
  });

  @override
  State<RecurringWizardClientStep> createState() =>
      _RecurringWizardClientStepState();
}

class _RecurringWizardClientStepState extends State<RecurringWizardClientStep> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showInactive = false;
  String? _entityFilter;
  String? _propertyFilter;
  static const String _defaultPropertyKind = 'comunidad de propietarios';

  @override
  void initState() {
    super.initState();
    _applyDefaultPropertyFilter();
  }

  @override
  void didUpdateWidget(covariant RecurringWizardClientStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clients != oldWidget.clients) {
      _applyDefaultPropertyFilter(useSetState: true);
    }
  }

  String? _resolveDefaultPropertyKind() {
    final match =
        widget.clients.map((c) => (c.propertyKind ?? '').trim()).firstWhere(
              (v) => v.toLowerCase() == _defaultPropertyKind,
              orElse: () => '',
            );
    return match.isEmpty ? null : match;
  }

  void _applyDefaultPropertyFilter({bool useSetState = false}) {
    if ((_propertyFilter ?? '').trim().isNotEmpty) return;
    final match = _resolveDefaultPropertyKind();
    if (match == null || match.isEmpty) return;
    if (useSetState) {
      setState(() => _propertyFilter = match);
    } else {
      _propertyFilter = match;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesSearch(GroupClient c) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = <String>[
      c.name,
      c.email ?? '',
      c.phone ?? '',
      c.billing?.legalName ?? '',
      c.entityType ?? '',
      c.propertyKind ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final entityOptions = widget.clients
        .map((c) => (c.entityType ?? '').trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final propertyOptions = widget.clients
        .map((c) => (c.propertyKind ?? '').trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final filtered = widget.clients.where((c) {
      if (!_showInactive && c.isActive == false) return false;
      if ((_entityFilter ?? '').trim().isNotEmpty &&
          (c.entityType ?? '').trim() != (_entityFilter ?? '').trim()) {
        return false;
      }
      if ((_propertyFilter ?? '').trim().isNotEmpty &&
          (c.propertyKind ?? '').trim() != (_propertyFilter ?? '').trim()) {
        return false;
      }
      return _matchesSearch(c);
    }).toList();

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    );

    InputDecoration fieldDecoration({required String label, IconData? icon}) {
      return InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        labelStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
        isDense: true,
        filled: true,
        fillColor: cs.surface,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      );
    }

    return RecurringWizardSectionCard(
      title: l.recurringInvoicesStepClient,
      icon: Icons.person_outline,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: widget.nameCtrl,
                        style: t.bodyMedium,
                        decoration: fieldDecoration(
                          label: l.recurringInvoicesNameLabel,
                          icon: Icons.edit_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: widget.currencyCtrl,
                        style: t.bodyMedium,
                        decoration: fieldDecoration(
                          label: l.currencyLabel,
                          icon: Icons.currency_exchange_outlined,
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                TextFormField(
                  controller: widget.nameCtrl,
                  style: t.bodyMedium,
                  decoration: fieldDecoration(
                    label: l.recurringInvoicesNameLabel,
                    icon: Icons.edit_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: widget.currencyCtrl,
                  style: t.bodyMedium,
                  decoration: fieldDecoration(
                    label: l.currencyLabel,
                    icon: Icons.currency_exchange_outlined,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.notesCtrl,
                maxLines: 2,
                style: t.bodyMedium,
                decoration: fieldDecoration(
                  label: l.notesLabel,
                  icon: Icons.sticky_note_2_outlined,
                ),
              ),
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(
                  chipTheme: ChipTheme.of(context).copyWith(
                    selectedColor: cs.primaryContainer.withValues(alpha: 0.45),
                    checkmarkColor: cs.primary,
                    labelStyle: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    secondaryLabelStyle: t.bodySmall.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                child: ClientsSearchFilters(
                  searchController: _searchCtrl,
                  onSearchChanged: () => setState(() {}),
                  searchHint: l.clientSearchHint,
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  clientsForCounts: widget.clients,
                  activeCountLabel: l.activeClientsSection,
                  inactiveCountLabel: l.statusInactive,
                  inactiveValue: _showInactive,
                  onInactiveChanged: (v) => setState(() => _showInactive = v),
                  inactiveLabelOn: l.hideInactiveClients,
                  inactiveLabelOff: l.showInactiveClients,
                  entityLabel: l.clientEntityTypeLabel,
                  entityOptions: entityOptions,
                  entityFilter: _entityFilter,
                  onToggleEntity: (v) => setState(() => _entityFilter = v),
                  onClearEntity: () => setState(() => _entityFilter = null),
                  propertyLabel: l.clientPropertyKindLabel,
                  propertyOptions: propertyOptions,
                  propertyFilter: _propertyFilter,
                  onToggleProperty: (v) => setState(() => _propertyFilter = v),
                  onClearProperty: () => setState(() => _propertyFilter = null),
                  onClearFilters: () {
                    final defaultKind = _resolveDefaultPropertyKind();
                    setState(() {
                      _showInactive = false;
                      _entityFilter = null;
                      _propertyFilter = defaultKind;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          l.noClientsYet,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final client = filtered[i];
                          final selected = client.id == widget.clientId;
                          final meta = <String>[
                            if ((client.email ?? '').isNotEmpty) client.email!,
                            if ((client.phone ?? '').isNotEmpty) client.phone!,
                            if ((client.propertyKind ?? '').isNotEmpty)
                              client.propertyKind!,
                          ].join(' · ');
                          return ListItemCard(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  cs.primary.withValues(alpha: 0.1),
                              child: Text(
                                client.name.trim().isEmpty
                                    ? '?'
                                    : client.name.trim()[0].toUpperCase(),
                                style: t.bodySmall.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: client.name,
                            subtitle: meta.isEmpty ? null : meta,
                            selected: selected,
                            showLeadingStripe: true,
                            trailing: selected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: cs.primary,
                                  )
                                : null,
                            onTap: () => widget.onClientChanged(client.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
