import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/client_billing.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
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
  String billingDocType = 'invoice';

  bool active = true;
  bool billingExpanded = false;
  bool saving = false;

  bool get isEdit => client != null;

  void _initFromClient() {
    final c = client;
    if (c == null) return;

    name.text = c.name;
    phone.text = c.phone ?? '';
    email.text = c.email ?? '';
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

  void dispose() {
    for (final c in [
      name,
      phone,
      email,
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
    ]) {
      c.dispose();
    }
  }

  Future<GroupClient> save() async {
    // Send only non-null billing fields to avoid backend wiping values.
    final billingPatch = billingPayload(includeNulls: false);

    if (isEdit) {
      final patch = <String, dynamic>{
        'name': name.text.trim(),
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
        'POST /clients payload name=${name.text.trim()} groupId=$groupId billing=$billingPatch',
        name: 'AddClientController');
    return api.create(
      GroupClient(
        id: '',
        name: name.text.trim(),
        groupId: groupId,
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        email: email.text.trim().isEmpty ? null : email.text.trim(),
        isActive: active,
        billing: billingFromInputs(),
        createdAt: DateTime.now(),
      ),
    );
  }
}
