import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/client_classification_store.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_active_switch.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/client_classification_manager_dialog.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

import 'add_client_controller.dart';
import 'widgets/billing_section/billing_section.dart';
import 'widgets/client_contact_form.dart';
import 'widgets/client_header.dart';
import 'widgets/save_button.dart';
import 'widgets/service_location_section.dart';

GroupClient? findClientByTrimmedName(
  Iterable<GroupClient> clients,
  String name, {
  String? excludeClientId,
}) {
  final normalizedName = name.trim().toLowerCase();
  if (normalizedName.isEmpty) return null;
  for (final client in clients) {
    if (excludeClientId != null && client.id == excludeClientId) continue;
    if (client.name.trim().toLowerCase() == normalizedName) return client;
  }
  return null;
}

class AddClientSheet extends StatefulWidget {
  final String groupId;
  final ClientsApi api;
  final GroupClient? client;
  final ValueChanged<GroupClient>? onSaved;
  final ValueChanged<GroupClient>? onOpenExisting;
  final List<GroupClient> existingClients;
  final bool closeOnSave;

  const AddClientSheet({
    super.key,
    required this.groupId,
    required this.api,
    this.client,
    this.onSaved,
    this.onOpenExisting,
    this.existingClients = const [],
    this.closeOnSave = true,
  });

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  late final AddClientController c;
  List<String> _entityTypeOptions = const [];
  List<String> _propertyKindOptions = const [];
  bool _showValidation = false;
  bool _locatingServiceAddress = false;

  @override
  void initState() {
    super.initState();
    c = AddClientController(
      api: widget.api,
      groupId: widget.groupId,
      client: widget.client,
    );
    _loadClassificationOptions();
  }

  Future<void> _loadClassificationOptions() async {
    try {
      final loaded = await ClientClassificationStore.getOptions(widget.groupId);
      if (!mounted) return;
      setState(() {
        _entityTypeOptions = loaded.entityTypes;
        _propertyKindOptions = loaded.propertyKinds;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entityTypeOptions = const [];
        _propertyKindOptions = const [];
      });
    }
  }

  Future<void> _manageClassificationOptions() async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          ClientClassificationManagerDialog(groupId: widget.groupId),
    );
    await _loadClassificationOptions();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (c.saving) return;
    final typo = AppTypography.of(context);

    setState(() => _showValidation = true);
    final trimmedName = c.name.text.trim();
    if (trimmedName.isEmpty) {
      c.markTouched('name');
      c.formKey.currentState?.validate();
      return;
    }
    if (c.name.text != trimmedName) {
      c.name.value = TextEditingValue(
        text: trimmedName,
        selection: TextSelection.collapsed(offset: trimmedName.length),
      );
    }

    if (!c.isEdit) {
      final existing = findClientByTrimmedName(
        widget.existingClients,
        trimmedName,
      );
      if (existing != null) {
        _showDuplicateClientMessage(
          message: 'Este cliente ya existe.',
          existingClient: existing,
        );
        return;
      }
    }
    if (!c.formKey.currentState!.validate()) return;
    final locationError = c.serviceLocationValidationError();
    if (locationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locationError)),
      );
      return;
    }

    setState(() => c.saving = true);
    try {
      var result = await c.save();
      result = await c.saveServiceLocation(result);
      if (!mounted) return;
      // Ensure options stay in sync with values actually used.
      await ClientClassificationStore.merge(
        groupId: widget.groupId,
        entityType: result.entityType,
        propertyKind: result.propertyKind,
      );
      if (!mounted) return;
      widget.onSaved?.call(result);
      if (widget.closeOnSave) {
        Navigator.of(context).pop<GroupClient>(result);
      }
    } on ClientsApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        final existing = await _findExistingClient(trimmedName);
        if (!mounted) return;
        _showDuplicateClientMessage(
          message: 'Ya existe un cliente con este nombre en el grupo.',
          existingClient: existing,
        );
        return;
      }
      final message = e.message.trim().isNotEmpty
          ? e.message.trim()
          : 'No se pudo crear el cliente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, style: typo.bodySmall)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear el cliente.', style: typo.bodySmall),
        ),
      );
    } finally {
      if (mounted) setState(() => c.saving = false);
    }
  }

  Future<void> _useCurrentServiceLocation() async {
    if (_locatingServiceAddress) return;
    setState(() => _locatingServiceAddress = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Activa la ubicación del dispositivo para continuar.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('No se ha concedido permiso de ubicación.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() {
        c.serviceLatitude.text = position.latitude.toStringAsFixed(6);
        c.serviceLongitude.text = position.longitude.toStringAsFixed(6);
        c.serviceLocationExpanded = true;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _locatingServiceAddress = false);
    }
  }

  Future<GroupClient?> _findExistingClient(String name) async {
    final loaded = findClientByTrimmedName(widget.existingClients, name);
    if (loaded != null) return loaded;
    try {
      final matches = await widget.api.list(
        groupId: widget.groupId,
        search: name,
        active: null,
      );
      return findClientByTrimmedName(matches, name);
    } catch (_) {
      return null;
    }
  }

  void _showDuplicateClientMessage({
    required String message,
    required GroupClient? existingClient,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: existingClient == null
            ? null
            : SnackBarAction(
                label: 'Abrir cliente existente',
                onPressed: () => _openExistingClient(existingClient),
              ),
      ),
    );
  }

  Future<void> _openExistingClient(GroupClient existingClient) async {
    final callback = widget.onOpenExisting;
    if (callback != null) {
      callback(existingClient);
      return;
    }
    final updated = await showModalBottomSheet<GroupClient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddClientSheet(
        groupId: widget.groupId,
        api: widget.api,
        client: existingClient,
        existingClients: widget.existingClients,
      ),
    );
    if (updated != null) widget.onSaved?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom + 16;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, pad),
      child: Form(
        key: c.formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClientHeader(isEdit: c.isEdit),
              const SizedBox(height: 8),
              const BillingDivider(),
              const SizedBox(height: 8),
              ClientContactForm(
                c: c,
                entityTypeOptions: _entityTypeOptions,
                propertyKindOptions: _propertyKindOptions,
                onManageClassification: _manageClassificationOptions,
                onClassificationChanged: () => setState(() {}),
                showValidation: _showValidation,
                onFieldChanged: () => setState(() {}),
                onFieldBlur: (key) => setState(() => c.markTouched(key)),
              ),
              const SizedBox(height: 8),
              BillingSection(
                c: c,
                showValidation: _showValidation,
                onFieldChanged: () => setState(() {}),
                onFieldBlur: (key) => setState(() => c.markTouched(key)),
              ),
              if (c.isEdit) ...[
                const SizedBox(height: 8),
                ServiceLocationSection(
                  controller: c,
                  locating: _locatingServiceAddress,
                  onUseCurrentLocation: _useCurrentServiceLocation,
                  onChanged: () => setState(() {}),
                ),
              ],
              const SizedBox(height: 4),
              ActiveSwitch(
                value: c.active,
                onChanged: (v) => setState(() => c.active = v),
              ),
              const SizedBox(height: 8),
              SaveButton(
                saving: c.saving,
                isEdit: c.isEdit,
                onPressed: c.saving ? null : _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BillingDivider extends StatelessWidget {
  const BillingDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4));
  }
}
