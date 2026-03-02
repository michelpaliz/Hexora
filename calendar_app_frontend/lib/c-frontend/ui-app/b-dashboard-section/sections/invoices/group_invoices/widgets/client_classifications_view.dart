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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final assigned = _assignedClients();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category_outlined, color: cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.clientClassificationSectionTitle,
                            style: t.bodyMedium
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                      Text(
                        _error!,
                        style: t.bodySmall.copyWith(color: cs.error),
                      )
                    else
                      Expanded(
                        child: ListView(
                          children: [
                            Text(
                              l.clientEntityTypeLabel,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._entityTypes.map(
                              (e) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.badge_outlined,
                                  color: cs.onSurfaceVariant,
                                ),
                                title: Text(e, style: t.bodySmall),
                                selected:
                                    _selectedIsEntity && _selectedValue == e,
                                selectedTileColor:
                                    cs.primary.withValues(alpha: 0.08),
                                onTap: () => setState(() {
                                  _selectedIsEntity = true;
                                  _selectedValue = e;
                                }),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.clientPropertyKindLabel,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._propertyKinds.map(
                              (p) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.home_work_outlined,
                                  color: cs.onSurfaceVariant,
                                ),
                                title: Text(p, style: t.bodySmall),
                                selected:
                                    !_selectedIsEntity && _selectedValue == p,
                                selectedTileColor:
                                    cs.primary.withValues(alpha: 0.08),
                                onTap: () => setState(() {
                                  _selectedIsEntity = false;
                                  _selectedValue = p;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _selectedValue == null
                          ? l.clientClassificationSelectHint
                          : l.clientClassificationAssignedCount(
                              assigned.length,
                            ),
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    if (_selectedValue != null)
                      Expanded(
                        child: assigned.isEmpty
                            ? Text(
                                l.clientClassificationNoClients,
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              )
                            : ListView.separated(
                                itemCount: assigned.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final c = assigned[i];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      c.name,
                                      style: t.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      c.billing?.legalName ??
                                          c.email ??
                                          c.phone ??
                                          '',
                                      style: t.bodySmall.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
