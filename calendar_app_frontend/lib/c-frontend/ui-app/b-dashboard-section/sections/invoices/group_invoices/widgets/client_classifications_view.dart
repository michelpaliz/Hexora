import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/client_classification_store.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/client_classification_manager_dialog.dart';
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
  bool _addBusy = false;
  String? _addError;
  final TextEditingController _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
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

  Future<void> _openManager() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ClientClassificationManagerDialog(
        groupId: widget.groupId,
      ),
    );
    await _loadOptions();
  }

  Future<void> _addClassification() async {
    final raw = _addController.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _addBusy = true;
      _addError = null;
    });
    try {
      await ClientClassificationStore.merge(
        groupId: widget.groupId,
        entityType: _selectedIsEntity ? raw : null,
        propertyKind: _selectedIsEntity ? null : raw,
      );
      _addController.clear();
      await _loadOptions();
    } catch (e) {
      if (!mounted) return;
      setState(() => _addError = e.toString());
    } finally {
      if (mounted) setState(() => _addBusy = false);
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
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    );

    InputDecoration fieldDecoration({required String label, IconData? icon}) {
      return InputDecoration(
        labelText: label,
        labelStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
        prefixIcon: icon == null ? null : Icon(icon),
        isDense: true,
        filled: true,
        fillColor: cs.surface,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Card(
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
                        TextButton(
                          onPressed: _openManager,
                          child: Text(l.clientClassificationManageCta),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.clientClassificationAddTitle,
                      style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 720;
                        final dropdown = DropdownButtonFormField<bool>(
                          value: _selectedIsEntity,
                          items: [
                            DropdownMenuItem(
                              value: true,
                              child: Text(
                                l.clientEntityTypeLabel,
                                style: t.bodyMedium,
                              ),
                            ),
                            DropdownMenuItem(
                              value: false,
                              child: Text(
                                l.clientPropertyKindLabel,
                                style: t.bodyMedium,
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _selectedIsEntity = v);
                          },
                          decoration: fieldDecoration(
                            label: l.clientClassificationTypeLabel,
                            icon: Icons.tune_outlined,
                          ),
                        );
                        final nameField = TextField(
                          controller: _addController,
                          style: t.bodyMedium,
                          decoration: fieldDecoration(
                            label: l.clientClassificationNameLabel,
                            icon: Icons.text_fields_outlined,
                          ).copyWith(
                            hintText: l.clientAddOptionHint,
                            hintStyle: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        );
                        final addButton = FilledButton.icon(
                          onPressed: _addBusy ? null : _addClassification,
                          icon: _addBusy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(l.add, style: t.bodyMedium),
                        );
                        if (narrow) {
                          return Column(
                            children: [
                              dropdown,
                              const SizedBox(height: 10),
                              nameField,
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 48,
                                width: double.infinity,
                                child: addButton,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            SizedBox(width: 200, child: dropdown),
                            const SizedBox(width: 10),
                            Expanded(child: nameField),
                            const SizedBox(width: 10),
                            SizedBox(height: 48, child: addButton),
                          ],
                        );
                      },
                    ),
                    if (_addError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _addError!,
                        style: t.bodySmall.copyWith(color: cs.error),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      _selectedValue == null
                          ? l.clientClassificationSelectHint
                          : l.clientClassificationAssignedCount(
                              assigned.length,
                            ),
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedValue != null)
                      Expanded(
                        child: assigned.isEmpty
                            ? Text(
                                l.clientClassificationNoClients,
                                style: t.bodySmall
                                    .copyWith(color: cs.onSurfaceVariant),
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
