import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/client_classification_store.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientClassificationsView extends StatefulWidget {
  final String groupId;
  final List<GroupClient> clients;

  const ClientClassificationsView({
    super.key,
    required this.groupId,
    required this.clients,
  });

  @override
  State<ClientClassificationsView> createState() =>
      _ClientClassificationsViewState();
}

class _ClientClassificationsViewState extends State<ClientClassificationsView> {
  List<String> _entityTypes = const [];
  List<String> _propertyKinds = const [];
  bool _loading = true;
  String? _error;
  String? _selectedValue;
  bool _selectedIsEntity = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void didUpdateWidget(covariant ClientClassificationsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _loadOptions();
    }
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loaded = await ClientClassificationStore.getOptions(widget.groupId);
      if (!mounted) return;
      setState(() {
        _entityTypes = loaded.entityTypes;
        _propertyKinds = loaded.propertyKinds;
        if (_entityTypes.isNotEmpty) {
          _selectedIsEntity = true;
          _selectedValue ??= _entityTypes.first;
        } else if (_propertyKinds.isNotEmpty) {
          _selectedIsEntity = false;
          _selectedValue ??= _propertyKinds.first;
        } else {
          _selectedValue = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<GroupClient> _assignedClients() {
    if (_selectedValue == null || _selectedValue!.isEmpty) return const [];
    return widget.clients.where((c) {
      final value = _selectedIsEntity ? c.entityType : c.propertyKind;
      return (value ?? '').trim() == _selectedValue;
    }).toList();
  }

  int _countForValue(String value, bool isEntity) {
    return widget.clients.where((c) {
      final v = isEntity ? c.entityType : c.propertyKind;
      return (v ?? '').trim() == value;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final assigned = _assignedClients();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Left panel: Classification filters ───
          SizedBox(
            width: 220,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.clientClassificationSectionTitle,
                        style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_error != null)
                    Text(
                      _error!,
                      style: t.bodySmall.copyWith(color: cs.error),
                    )
                  else ...[
                    _SectionLabel(label: l.clientEntityTypeLabel),
                    const SizedBox(height: 6),
                    ..._entityTypes.map((e) {
                      final isSelected = _selectedIsEntity && _selectedValue == e;
                      final count = _countForValue(e, true);
                      return _ClassificationItem(
                        label: e,
                        icon: Icons.badge_outlined,
                        count: count,
                        selected: isSelected,
                        onTap: () => setState(() {
                          _selectedIsEntity = true;
                          _selectedValue = e;
                        }),
                      );
                    }),
                    const SizedBox(height: 14),
                    _SectionLabel(label: l.clientPropertyKindLabel),
                    const SizedBox(height: 6),
                    ..._propertyKinds.map((p) {
                      final isSelected = !_selectedIsEntity && _selectedValue == p;
                      final count = _countForValue(p, false);
                      return _ClassificationItem(
                        label: p,
                        icon: Icons.home_work_outlined,
                        count: count,
                        selected: isSelected,
                        onTap: () => setState(() {
                          _selectedIsEntity = false;
                          _selectedValue = p;
                        }),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          // ─── Right panel: Assigned clients ───
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedValue == null
                                ? l.clientClassificationSelectHint
                                : l.clientClassificationAssignedCount(
                                    assigned.length,
                                  ),
                            style: t.bodyMedium
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (_selectedValue != null && assigned.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${assigned.length}',
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_selectedValue != null) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    Expanded(
                      child: assigned.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.group_off_outlined,
                                    size: 36,
                                    color:
                                        cs.onSurfaceVariant.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l.clientClassificationNoClients,
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: assigned.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, indent: 56),
                              itemBuilder: (_, i) {
                                final c = assigned[i];
                                final initials = c.name.trim().isNotEmpty
                                    ? c.name.trim()[0].toUpperCase()
                                    : '?';
                                final subtitle = c.billing?.legalName?.trim().isNotEmpty == true
                                    ? c.billing!.legalName!.trim()
                                    : (c.email?.trim().isNotEmpty == true
                                        ? c.email!.trim()
                                        : (c.phone?.trim() ?? ''));
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: cs.primaryContainer
                                            .withValues(alpha: 0.55),
                                        child: Text(
                                          initials,
                                          style: t.bodySmall.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: cs.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.name,
                                              style: t.bodySmall.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (subtitle.isNotEmpty)
                                              Text(
                                                subtitle,
                                                style: t.bodySmall.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                  fontSize: 11,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ] else
                    const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: t.bodySmall.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ClassificationItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ClassificationItem({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.55)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: t.bodySmall.copyWith(
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? cs.primary.withValues(alpha: 0.15)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
