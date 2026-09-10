import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
import 'package:hexora/a-models/group_model/worker/geofenced_visit.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/c-frontend/utils/address/spain_postal_code_autofill.dart';
import 'dart:developer' as devtools show log;

class AddClientController {
  AddClientController({
    required this.api,
    required this.groupId,
    this.client,
  }) {
    _initFromClient();
  }

  final ClientsApi api;
  final String groupId;
  final GroupClient? client;

  final formKey = GlobalKey<FormState>();

  // Contact
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();

  // Classification (optional)
  final entityType = TextEditingController();
  final propertyKind = TextEditingController();

  // Billing
  final billingLegalName = TextEditingController();
  final billingTaxId = TextEditingController();
  final billingStreet = TextEditingController();
  final billingExtra = TextEditingController();
  final billingCity = TextEditingController();
  final billingProvince = TextEditingController();
  final billingPostal = TextEditingController();
  final billingCountry = TextEditingController();
  final billingEmail = TextEditingController();
  final billingPhone = TextEditingController();
  final serviceLatitude = TextEditingController();
  final serviceLongitude = TextEditingController();
  final serviceRadius = TextEditingController(text: '75');
  final serviceLocationLabel = TextEditingController();
  String billingDocType = 'invoice';

  bool active = true;
  bool billingExpanded = false;
  bool serviceLocationExpanded = false;
  bool serviceLocationEnabled = true;
  bool saving = false;
  final Map<String, bool> _touched = {};

  bool get isEdit => client != null;

  void _initFromClient() {
    final c = client;
    if (c == null) return;

    name.text = c.name;
    phone.text = c.phone ?? '';
    email.text = c.email ?? '';
    entityType.text = c.entityType ?? '';
    propertyKind.text = c.propertyKind ?? '';
    active = c.isActive;

    final b = c.billing;
    if (b != null) {
      billingLegalName.text = b.legalName ?? c.name;
      billingTaxId.text = b.taxId ?? '';
      billingStreet.text = b.addressStreet ?? '';
      billingExtra.text = b.addressExtra ?? '';
      billingCity.text = b.addressCity ?? '';
      billingProvince.text = b.addressProvince ?? '';
      billingPostal.text = b.addressPostalCode ?? '';
      billingCountry.text = b.addressCountry ?? '';
      billingEmail.text = b.email ?? (c.email ?? '');
      billingPhone.text = b.phone ?? (c.phone ?? '');
      billingExpanded = b.hasData;
      billingDocType = b.documentType ?? 'invoice';
    } else {
      // Nudge users to reuse contact details
      billingLegalName.text = c.name;
      billingEmail.text = c.email ?? '';
      billingPhone.text = c.phone ?? '';
    }

    final serviceLocation = c.serviceLocation;
    if (serviceLocation != null) {
      serviceLatitude.text = serviceLocation.latitude.toStringAsFixed(6);
      serviceLongitude.text = serviceLocation.longitude.toStringAsFixed(6);
      serviceRadius.text = serviceLocation.radiusMeters.toStringAsFixed(0);
      serviceLocationLabel.text = serviceLocation.label ?? '';
      serviceLocationEnabled = serviceLocation.isEnabled;
      serviceLocationExpanded = true;
    }

    autofillBillingAddressFromPostalCode();
  }

  ClientBilling? billingFromInputs({bool includeNulls = false}) {
    final billing = ClientBilling(
      legalName: billingLegalName.text,
      taxId: billingTaxId.text,
      addressStreet: billingStreet.text,
      addressExtra: billingExtra.text,
      addressCity: billingCity.text,
      addressProvince: billingProvince.text,
      addressPostalCode: billingPostal.text,
      addressCountry: billingCountry.text,
      email: billingEmail.text,
      phone: billingPhone.text,
      documentType: billingDocType,
    );
    final payload = billing.toPayload(includeNulls: includeNulls);
    return payload == null ? null : billing;
  }

  Map<String, dynamic>? billingPayload({bool includeNulls = false}) =>
      billingFromInputs(includeNulls: includeNulls)
          ?.toPayload(includeNulls: includeNulls);

  bool get hasBillingData =>
      billingFromInputs(includeNulls: false)?.hasData ?? false;

  static const List<String> billingRequiredKeys = [
    'billingTaxId',
    'billingCountry',
  ];

  int get billingRequiredTotal => billingRequiredKeys.length;

  int get billingCompletedCount =>
      billingRequiredKeys.where(isBillingFieldFilled).length;

  bool isBillingFieldFilled(String key) =>
      _billingControllerFor(key)?.text.trim().isNotEmpty ?? false;

  bool isBillingRequired(String key) => billingRequiredKeys.contains(key);

  TextEditingController? _billingControllerFor(String key) {
    switch (key) {
      case 'billingLegalName':
        return billingLegalName;
      case 'billingTaxId':
        return billingTaxId;
      case 'billingStreet':
        return billingStreet;
      case 'billingCity':
        return billingCity;
      case 'billingPostal':
        return billingPostal;
      case 'billingCountry':
        return billingCountry;
      case 'billingEmail':
        return billingEmail;
      case 'billingPhone':
        return billingPhone;
      default:
        return null;
    }
  }

  void markTouched(String key) {
    _touched[key] = true;
  }

  void autofillBillingAddressFromPostalCode() {
    final autofill = inferSpainPostalAutofill(
      postalCode: billingPostal.text,
      currentCountry: billingCountry.text,
    );
    if (autofill == null) return;

    if (billingProvince.text.trim() != autofill.province) {
      billingProvince.text = autofill.province;
    }
    if (billingCountry.text.trim().isEmpty) {
      billingCountry.text = autofill.country;
    }
  }

  bool shouldShowError(String key, bool force) =>
      force || (_touched[key] ?? false);

  void dispose() {
    for (final c in [
      name,
      phone,
      email,
      entityType,
      propertyKind,
      billingLegalName,
      billingTaxId,
      billingStreet,
      billingExtra,
      billingCity,
      billingProvince,
      billingPostal,
      billingCountry,
      billingEmail,
      billingPhone,
      serviceLatitude,
      serviceLongitude,
      serviceRadius,
      serviceLocationLabel,
    ]) {
      c.dispose();
    }
  }

  Future<GroupClient> save() async {
    final trimmedName = name.text.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('El nombre del cliente es obligatorio.');
    }
    // Send only non-null billing fields to avoid backend wiping values.
    final billingPatch = billingPayload(includeNulls: false);

    String? norm(String s) {
      final v = s.trim().toLowerCase();
      return v.isEmpty ? null : v;
    }

    if (isEdit) {
      final patch = <String, dynamic>{
        'name': trimmedName,
        'entityType': norm(entityType.text),
        'propertyKind': norm(propertyKind.text),
        'isActive': active,
        'contact': {
          'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
          'email': email.text.trim().isEmpty ? null : email.text.trim(),
        },
      };
      if (billingPatch != null) patch['billing'] = billingPatch;

      devtools.log('PATCH /clients/${client!.id} payload=$patch',
          name: 'AddClientController');
      return api.updateFields(client!.id, patch);
    }

    devtools.log(
        'POST /clients payload name=$trimmedName groupId=$groupId billing=$billingPatch',
        name: 'AddClientController');
    return api.create(
      GroupClient(
        id: '',
        name: trimmedName,
        groupId: groupId,
        entityType: norm(entityType.text),
        propertyKind: norm(propertyKind.text),
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        email: email.text.trim().isEmpty ? null : email.text.trim(),
        isActive: active,
        billing: billingFromInputs(),
        createdAt: DateTime.now(),
      ),
    );
  }

  String? serviceLocationValidationError() {
    final latitude = double.tryParse(serviceLatitude.text.trim());
    final longitude = double.tryParse(serviceLongitude.text.trim());
    final radius = double.tryParse(serviceRadius.text.trim());
    final hasAnyCoordinate = serviceLatitude.text.trim().isNotEmpty ||
        serviceLongitude.text.trim().isNotEmpty;
    if (!hasAnyCoordinate && client?.serviceLocation == null) return null;
    if (latitude == null || latitude < -90 || latitude > 90) {
      return 'La latitud debe estar entre -90 y 90.';
    }
    if (longitude == null || longitude < -180 || longitude > 180) {
      return 'La longitud debe estar entre -180 y 180.';
    }
    if (radius == null || radius < 10 || radius > 1000) {
      return 'El radio debe estar entre 10 y 1.000 metros.';
    }
    return null;
  }

  Future<GroupClient> saveServiceLocation(GroupClient saved) async {
    if (client == null) return saved;
    final latitude = double.tryParse(serviceLatitude.text.trim());
    final longitude = double.tryParse(serviceLongitude.text.trim());
    final radius = double.tryParse(serviceRadius.text.trim());
    if (latitude == null || longitude == null || radius == null) return saved;
    final location = await api.updateServiceLocation(
      saved.id,
      ClientServiceLocation(
        clientId: saved.id,
        clientName: saved.name,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radius,
        label: serviceLocationLabel.text.trim().isEmpty
            ? null
            : serviceLocationLabel.text.trim(),
        isEnabled: serviceLocationEnabled,
      ),
    );
    return saved.copyWith(serviceLocation: location);
  }
}
