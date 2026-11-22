import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/feedback/snack_helper.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/widgets/hexora_section_tabs.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/client_classification_store.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_active_switch.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/client_classification_manager_dialog.dart';

import 'add_client_controller.dart';
import 'widgets/billing_section/billing_section.dart';
import 'widgets/client_contact_form.dart';
import 'widgets/client_editor_theme.dart';
import 'widgets/save_button.dart';
import 'widgets/service_location_section.dart';
import 'widgets/client_identity_header.dart';

/// Opens the client form as a page with persistent navigation and save controls.
Future<GroupClient?> showClientEditor({
  required BuildContext context,
  required String groupId,
  required ClientsApi api,
  GroupClient? client,
  List<GroupClient> existingClients = const [],
  ValueChanged<GroupClient>? onOpenExisting,
}) {
  return Navigator.of(context, rootNavigator: true).push<GroupClient>(
    MaterialPageRoute(
      builder: (_) => AddClientSheet(
        groupId: groupId,
        api: api,
        client: client,
        existingClients: existingClients,
        onOpenExisting: onOpenExisting,
        fullScreen: true,
      ),
    ),
  );
}

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
  final bool fullScreen;
  final bool showInlineHeader;
  final Widget? identityTrailing;
  final VoidCallback? onCancel;

  const AddClientSheet({
    super.key,
    required this.groupId,
    required this.api,
    this.client,
    this.onSaved,
    this.onOpenExisting,
    this.existingClients = const [],
    this.closeOnSave = true,
    this.fullScreen = false,
    this.showInlineHeader = true,
    this.identityTrailing,
    this.onCancel,
  });

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet>
    with SingleTickerProviderStateMixin {
  late final AddClientController c;
  late final TabController _sectionTab;
  List<String> _entityTypeOptions = const [];
  List<String> _propertyKindOptions = const [];
  bool _showValidation = false;
  bool _locatingServiceAddress = false;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _removeImage = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    c = AddClientController(
      api: widget.api,
      groupId: widget.groupId,
      client: widget.client,
    );
    _sectionTab = TabController(length: 4, vsync: this)
      ..addListener(_handleSectionTabChanged);
    _loadClassificationOptions();
  }

  void _handleSectionTabChanged() {
    if (mounted) setState(() {});
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
    await showHexoraDialog<void>(
      context: context,
      builder: (_) =>
          ClientClassificationManagerDialog(groupId: widget.groupId),
    );
    await _loadClassificationOptions();
  }

  @override
  void dispose() {
    _sectionTab
      ..removeListener(_handleSectionTabChanged)
      ..dispose();
    c.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (c.saving) return;

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
    if (!c.formKey.currentState!.validate()) {
      final generalHasError = c.name.text.trim().isEmpty;
      final billingHasError =
          c.billingRequiredKeys.any((key) => !c.isBillingFieldFilled(key));
      _sectionTab.animateTo(generalHasError ? 0 : (billingHasError ? 3 : 0));
      return;
    }
    final locationChanged = c.serviceLocationChanged;
    final locationError = c.serviceLocationValidationError();

    final wasEdit = c.isEdit;
    final es = Localizations.localeOf(context).languageCode == 'es';
    final saveFailedTitle = wasEdit
        ? (es ? 'No se pudieron guardar los cambios' : 'Could not save changes')
        : (es ? 'No se pudo crear el cliente' : 'Could not create the client');
    setState(() => c.saving = true);
    try {
      var result = await c.save();
      // Retain the new ID so retries after a secondary upload failure update
      // the existing client rather than creating a duplicate.
      c.client = result;
      // The client itself is stored from here on; later steps report their
      // own failure instead of claiming the whole save failed.
      String? locationWarning;
      if (locationChanged && locationError != null) {
        locationWarning = es
            ? 'Cliente guardado; ubicación del servicio sin cambios. $locationError'
            : 'Client saved; service location unchanged. $locationError';
      } else if (locationChanged) {
        try {
          result = await c.saveServiceLocation(result);
        } catch (_) {
          locationWarning = es
              ? 'Cliente guardado, pero no se pudo actualizar la ubicación del servicio.'
              : 'Client saved, but its service location could not be updated.';
        }
      }
      if (_imageBytes != null || _removeImage) {
        setState(() => _uploadingImage = true);
        try {
          result = _imageBytes != null
              ? await widget.api
                  .uploadImage(result.id, _imageBytes!, _imageName!)
              : await widget.api.removeImage(result.id);
          _imageBytes = null;
          _imageName = null;
          _removeImage = false;
        } catch (e) {
          if (mounted) {
            showFailureSnack(context, e,
                title: AppLocalizations.of(context)!.clientImageSaveFailed);
          }
          return;
        } finally {
          if (mounted) setState(() => _uploadingImage = false);
        }
      }
      c.client = result;
      if (!mounted) return;
      // Keep the classification suggestions in sync. Best effort only: the
      // client is already saved, so a failure here must not be reported as
      // a failed save.
      try {
        await ClientClassificationStore.merge(
          groupId: widget.groupId,
          entityType: result.entityType,
          propertyKind: result.propertyKind,
        );
      } catch (e) {
        debugPrint('Client classification sync failed: $e');
      }
      if (!mounted) return;
      widget.onSaved?.call(result);
      if (locationWarning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locationWarning)),
        );
      }
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
      showFailureSnack(context, e, title: saveFailedTitle);
    } catch (e) {
      if (!mounted) return;
      showFailureSnack(context, e, title: saveFailedTitle);
    } finally {
      if (mounted) setState(() => c.saving = false);
    }
  }

  Future<void> _useCurrentServiceLocation() async {
    if (_locatingServiceAddress) return;
    final es = Localizations.localeOf(context).languageCode == 'es';
    setState(() => _locatingServiceAddress = true);
    try {
      // The device location is only requested here, on explicit user action.
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(es
            ? 'Activa la ubicación del dispositivo para continuar.'
            : 'Turn on device location to continue.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(es
            ? 'No se ha concedido permiso de ubicación.'
            : 'Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      final address =
          await _reverseGeocode(position.latitude, position.longitude);
      if (!mounted) return;

      final currentLat = c.serviceLatitude.text.trim();
      final currentLng = c.serviceLongitude.text.trim();
      final currentAddress = c.serviceLocationLabel.text.trim();
      final hasCoordinates = currentLat.isNotEmpty || currentLng.isNotEmpty;
      final coordsDiffer = currentLat != lat || currentLng != lng;
      final addressDiffers = address != null && address != currentAddress;

      var replaceAddress = currentAddress.isEmpty && address != null;
      if ((hasCoordinates && coordsDiffer) ||
          (currentAddress.isNotEmpty && addressDiffers)) {
        final choice = await _confirmReplaceLocation(
          es: es,
          newCoordinates: '$lat, $lng',
          currentCoordinates:
              hasCoordinates ? '$currentLat, $currentLng' : null,
          newAddress: address,
          currentAddress: currentAddress.isEmpty ? null : currentAddress,
        );
        if (choice == null || !mounted) return;
        replaceAddress = replaceAddress || choice;
      }

      setState(() {
        c.serviceLatitude.text = lat;
        c.serviceLongitude.text = lng;
        if (replaceAddress && address != null) {
          c.serviceLocationLabel.text = address;
        }
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

  /// Best-effort street address for a position. Reverse geocoding is skipped
  /// on web, where the plugin is unreliable.
  Future<String?> _reverseGeocode(double lat, double lng) async {
    if (kIsWeb) return null;
    try {
      final marks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 8));
      if (marks.isEmpty) return null;
      final m = marks.first;
      final street = [m.street, m.subThoroughfare]
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .join(' ');
      final parts = [
        street,
        [m.postalCode, m.locality]
            .whereType<String>()
            .where((e) => e.trim().isNotEmpty)
            .join(' '),
        m.subAdministrativeArea ?? m.administrativeArea,
      ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty);
      final result = parts.toSet().join(', ');
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  /// Returns null when cancelled; otherwise whether the address should also
  /// be replaced (coordinates are always replaced on confirm).
  Future<bool?> _confirmReplaceLocation({
    required bool es,
    required String newCoordinates,
    required String? currentCoordinates,
    required String? newAddress,
    required String? currentAddress,
  }) {
    final canReplaceAddress = newAddress != null &&
        currentAddress != null &&
        newAddress != currentAddress;
    var alsoAddress = false;
    return showHexoraDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final text = Theme.of(dialogContext).textTheme;
          Widget line(String label, String value) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ])),
              );
          return AlertDialog(
            title: Text(es
                ? '¿Usar tu ubicación actual?'
                : 'Use your current location?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  es
                      ? 'Este cliente ya tiene una ubicación guardada. Se reemplazarán las coordenadas.'
                      : 'This client already has a saved location. Its coordinates will be replaced.',
                  style: text.bodyMedium,
                ),
                if (currentCoordinates != null)
                  line(es ? 'Actuales' : 'Current', currentCoordinates),
                line(es ? 'Nuevas' : 'New', newCoordinates),
                if (canReplaceAddress) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: alsoAddress,
                    onChanged: (v) =>
                        setDialogState(() => alsoAddress = v ?? false),
                    title: Text(es
                        ? 'Reemplazar también la dirección'
                        : 'Also replace the address'),
                    subtitle: Text(newAddress),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(es ? 'Cancelar' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(alsoAddress),
                child: Text(es ? 'Reemplazar' : 'Replace'),
              ),
            ],
          );
        },
      ),
    );
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
    showErrorSnack(
      context,
      message,
      title: 'Cliente duplicado',
      action: existingClient == null
          ? null
          : SnackBarAction(
              label: 'Abrir cliente existente',
              onPressed: () => _openExistingClient(existingClient),
            ),
    );
  }

  Future<void> _openExistingClient(GroupClient existingClient) async {
    final callback = widget.onOpenExisting;
    if (callback != null) {
      callback(existingClient);
      return;
    }
    final updated = await showClientEditor(
      context: context,
      groupId: widget.groupId,
      api: widget.api,
      client: existingClient,
      existingClients: widget.existingClients,
    );
    if (updated != null) widget.onSaved?.call(updated);
  }

  Widget _identityHeader() {
    final liveName = c.name.text.trim();
    final displayName = liveName.isEmpty ? (c.client?.name ?? '') : liveName;
    final imageClient = (c.client ?? GroupClient(id: '', name: displayName))
        .copyWith(name: displayName);
    return ClientIdentityHeader(
      client: imageClient,
      name: displayName,
      email: c.email.text,
      bytes: _imageBytes,
      removed: _removeImage,
      disabled: c.saving,
      uploading: _uploadingImage,
      trailing: widget.identityTrailing,
      onChanged: (bytes, name) => setState(() {
        _imageBytes = bytes;
        _imageName = name;
        _removeImage = false;
      }),
      onRemove: () => setState(() {
        _imageBytes = null;
        _imageName = null;
        _removeImage = c.client?.imageVersion != null;
      }),
    );
  }

  Widget _editorTabs(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final generalHasError = _showValidation && c.name.text.trim().isEmpty;
    final billingHasError = _showValidation &&
        c.billingRequiredKeys.any((key) => !c.isBillingFieldFilled(key));
    final locationHasError =
        _showValidation && c.serviceLocationValidationError() != null;

    Tab tab({
      required IconData icon,
      required String label,
      bool hasError = false,
    }) {
      return Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
            if (hasError) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return HexoraSectionTabs(
      controller: _sectionTab,
      compact: true,
      segmented: true,
      tabs: [
        tab(
          icon: Icons.person_outline,
          label: 'General',
          hasError: generalHasError,
        ),
        tab(
          icon: Icons.location_on_outlined,
          label: isSpanish ? 'Ubicación' : 'Location',
          hasError: locationHasError,
        ),
        tab(
          icon: Icons.badge_outlined,
          label: l.clientClassificationSectionTitle,
        ),
        tab(
          icon: Icons.receipt_long_outlined,
          label: isSpanish ? 'Facturación' : 'Billing',
          hasError: billingHasError,
        ),
      ],
    );
  }

  ClientContactForm _contactSection(ClientContactSection section) =>
      ClientContactForm(
        c: c,
        section: section,
        entityTypeOptions: _entityTypeOptions,
        propertyKindOptions: _propertyKindOptions,
        onManageClassification: _manageClassificationOptions,
        onClassificationChanged: () => setState(() {}),
        showValidation: _showValidation,
        onFieldChanged: () => setState(() {}),
        onFieldBlur: (key) => setState(() => c.markTouched(key)),
      );

  @override
  Widget build(BuildContext context) => Theme(
        data: clientEditorThemeOf(context),
        child: Builder(builder: _buildEditor),
      );

  Widget _buildEditor(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom + 12;
    final inline = !widget.closeOnSave && !widget.fullScreen;

    // Reuse the Hexora motion tokens for the tab fade.
    const tabFade = Duration(milliseconds: 200);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Keep each tab's subtree in the widget tree so controllers, focus,
    // validation state and scroll positions survive tab switches without
    // rebuilding the editor.
    Widget tabChild(int index, Widget child) {
      final isActive = _sectionTab.index == index;
      return Offstage(
        offstage: !isActive,
        child: TickerMode(
          enabled: isActive,
          child: AnimatedOpacity(
            duration: reduceMotion ? Duration.zero : tabFade,
            curve: Curves.easeOut,
            opacity: isActive ? 1 : 0,
            child: child,
          ),
        ),
      );
    }

    Widget sectionCard(Widget child) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: .42),
            ),
          ),
          child: child,
        );

    final form = Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, widget.fullScreen ? 12 : pad),
      child: Form(
        key: c.formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!inline) ...[
                _identityHeader(),
                const SizedBox(height: 4),
              ],
              _editorTabs(context),
              const SizedBox(height: 10),
              tabChild(
                0,
                sectionCard(Column(
                  children: [
                    _contactSection(ClientContactSection.general),
                    Divider(
                      height: 24,
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: .45),
                    ),
                    // Whether the client is active in Hexora. Unrelated to
                    // the geofence, which is toggled in the Ubicación tab.
                    ActiveSwitch(
                      value: c.active,
                      onChanged: (v) => setState(() => c.active = v),
                    ),
                  ],
                )),
              ),
              tabChild(
                1,
                sectionCard(
                  ServiceLocationSection(
                    controller: c,
                    enabled: c.isEdit,
                    locating: _locatingServiceAddress,
                    onUseCurrentLocation: _useCurrentServiceLocation,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
              tabChild(
                2,
                sectionCard(
                    _contactSection(ClientContactSection.classification)),
              ),
              tabChild(
                3,
                sectionCard(
                  BillingSection(
                    c: c,
                    showValidation: _showValidation,
                    onFieldChanged: () => setState(() {}),
                    onFieldBlur: (key) => setState(() => c.markTouched(key)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (!widget.fullScreen && !inline)
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
    if (inline) {
      final l = AppLocalizations.of(context)!;
      final cs = Theme.of(context).colorScheme;
      return Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _identityHeader()),
        Expanded(child: form),
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                    top: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: .4)))),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 6,
              children: [
                if (widget.onCancel != null) ...[
                  HexoraButton(
                      onPressed: c.saving ? null : widget.onCancel,
                      label: l.cancel,
                      variant: HexoraButtonVariant.secondary,
                      size: HexoraButtonSize.standard),
                ],
                SaveButton(
                    saving: c.saving,
                    isEdit: c.isEdit,
                    onPressed: c.saving ? null : _onSave),
              ],
            )),
      ]);
    }
    if (!widget.fullScreen) return form;

    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(c.isEdit ? l.editClient : l.createClient)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: form,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                    top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                )),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 808),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      HexoraButton(
                        onPressed: c.saving
                            ? null
                            : (widget.onCancel ??
                                () => Navigator.of(context).maybePop()),
                        label: l.cancel,
                        variant: HexoraButtonVariant.secondary,
                      ),
                      SaveButton(
                        saving: c.saving,
                        isEdit: c.isEdit,
                        onPressed: c.saving ? null : _onSave,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
