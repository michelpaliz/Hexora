import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/providers/providers_api.dart';

/// Mixin for provider management operations
mixin ProviderOperationsMixin<T extends StatefulWidget> on State<T> {
  ProvidersApi get providersApi;
  List<Map<String, dynamic>> get providers;
  set providers(List<Map<String, dynamic>> value);
  bool get loadingProviders;
  set loadingProviders(bool value);
  String? get providersError;
  set providersError(String? value);
  bool get savingProvider;
  set savingProvider(bool value);
  String? get editingProviderId;
  set editingProviderId(String? value);
  String? get selectedProviderId;
  set selectedProviderId(String? value);
  String? get selectedProviderSummaryId;
  set selectedProviderSummaryId(String? value);

  // Provider form controllers
  TextEditingController get providerNameController;
  TextEditingController get providerTaxIdController;
  TextEditingController get providerEmailController;
  TextEditingController get providerPhoneController;
  TextEditingController get providerNotesController;
  TextEditingController get providerStreetController;
  TextEditingController get providerExtraController;
  TextEditingController get providerCityController;
  TextEditingController get providerProvinceController;
  TextEditingController get providerPostalCodeController;
  TextEditingController get providerCountryController;

  // Vendor form controllers
  TextEditingController get vendorController;
  TextEditingController get vendorTaxIdController;

  String resolveGroupId();

  /// Load providers from API
  Future<void> loadProviders() async {
    final groupId = resolveGroupId();
    if (groupId.isEmpty) {
      setState(() {
        loadingProviders = false;
        providersError = 'Missing group id.';
      });
      if (kDebugMode) {
        debugPrint('[ProviderOperations] providers: missing group id');
      }
      return;
    }
    setState(() {
      loadingProviders = true;
      providersError = null;
    });
    try {
      if (kDebugMode) {
        debugPrint('[ProviderOperations] providers: groupId=$groupId');
      }
      final list = List<Map<String, dynamic>>.from(
        await providersApi.list(groupId: groupId),
      );
      list.sort((a, b) {
        final an = (a['name'] ?? '').toString();
        final bn = (b['name'] ?? '').toString();
        return an.compareTo(bn);
      });
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[ProviderOperations] providers: loaded ${list.length} items',
        );
      }
      setState(() {
        providers = list;
        selectedProviderSummaryId ??=
            providers.isEmpty ? null : providerId(providers.first);
      });
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('[ProviderOperations] providers: error $e');
      }
      setState(() => providersError = e.toString());
    } finally {
      if (mounted) setState(() => loadingProviders = false);
    }
  }

  /// Select a provider and populate form fields
  void selectProvider(String? id) {
    setState(() => selectedProviderId = id);
    if (id == null) return;
    final match = providers.firstWhere(
      (p) => (p['id'] ?? p['_id'] ?? p['providerId'])?.toString() == id,
      orElse: () => const <String, dynamic>{},
    );
    if (match.isEmpty) return;
    final name = match['name']?.toString() ?? '';
    final taxId = match['taxId']?.toString() ?? '';
    if (name.isNotEmpty) vendorController.text = name;
    if (taxId.isNotEmpty) vendorTaxIdController.text = taxId;
  }

  /// Extract provider ID from provider map
  String? providerId(Map<String, dynamic> provider) {
    return (provider['id'] ?? provider['_id'] ?? provider['providerId'])
        ?.toString();
  }

  /// Extract provider name from provider map
  String providerName(Map<String, dynamic> provider) {
    return provider['name']?.toString().trim() ?? '';
  }

  /// Reset provider form fields
  void resetProviderForm() {
    editingProviderId = null;
    providerNameController.clear();
    providerTaxIdController.clear();
    providerEmailController.clear();
    providerPhoneController.clear();
    providerNotesController.clear();
    providerStreetController.clear();
    providerExtraController.clear();
    providerCityController.clear();
    providerProvinceController.clear();
    providerPostalCodeController.clear();
    providerCountryController.clear();
  }

  /// Load provider data into form for editing
  void editProvider(Map<String, dynamic> provider) {
    setState(() {
      editingProviderId =
          (provider['id'] ?? provider['_id'] ?? provider['providerId'])
              ?.toString();
      providerNameController.text = provider['name']?.toString() ?? '';
      providerTaxIdController.text = provider['taxId']?.toString() ?? '';
      providerEmailController.text = provider['email']?.toString() ?? '';
      providerPhoneController.text = provider['phone']?.toString() ?? '';
      providerNotesController.text = provider['notes']?.toString() ?? '';
      final address = provider['address'];
      if (address is Map) {
        providerStreetController.text = address['street']?.toString() ?? '';
        providerExtraController.text = address['extra']?.toString() ?? '';
        providerCityController.text = address['city']?.toString() ?? '';
        providerProvinceController.text =
            address['province']?.toString() ?? '';
        providerPostalCodeController.text =
            address['postalCode']?.toString() ?? '';
        providerCountryController.text = address['country']?.toString() ?? '';
      }
    });
  }

  /// Save or update provider
  Future<void> saveProvider() async {
    if (savingProvider) return;
    final groupId = resolveGroupId();
    if (groupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing group id.')),
      );
      if (kDebugMode) {
        debugPrint('[ProviderOperations] save provider: missing group id');
      }
      return;
    }
    final name = providerNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => savingProvider = true);
    try {
      if (kDebugMode) {
        debugPrint('[ProviderOperations] save provider: groupId=$groupId');
      }
      final address = <String, dynamic>{
        if (providerStreetController.text.trim().isNotEmpty)
          'street': providerStreetController.text.trim(),
        if (providerExtraController.text.trim().isNotEmpty)
          'extra': providerExtraController.text.trim(),
        if (providerCityController.text.trim().isNotEmpty)
          'city': providerCityController.text.trim(),
        if (providerProvinceController.text.trim().isNotEmpty)
          'province': providerProvinceController.text.trim(),
        if (providerPostalCodeController.text.trim().isNotEmpty)
          'postalCode': providerPostalCodeController.text.trim(),
        if (providerCountryController.text.trim().isNotEmpty)
          'country': providerCountryController.text.trim(),
      };
      if (editingProviderId == null) {
        await providersApi.create(
          name: name,
          taxId: providerTaxIdController.text.trim().isEmpty
              ? null
              : providerTaxIdController.text.trim(),
          email: providerEmailController.text.trim().isEmpty
              ? null
              : providerEmailController.text.trim(),
          phone: providerPhoneController.text.trim().isEmpty
              ? null
              : providerPhoneController.text.trim(),
          address: address.isEmpty ? null : address,
          notes: providerNotesController.text.trim().isEmpty
              ? null
              : providerNotesController.text.trim(),
          groupId: groupId,
        );
      } else {
        await providersApi.update(
          id: editingProviderId!,
          name: name,
          taxId: providerTaxIdController.text.trim().isEmpty
              ? null
              : providerTaxIdController.text.trim(),
          email: providerEmailController.text.trim().isEmpty
              ? null
              : providerEmailController.text.trim(),
          phone: providerPhoneController.text.trim().isEmpty
              ? null
              : providerPhoneController.text.trim(),
          address: address.isEmpty ? null : address,
          notes: providerNotesController.text.trim().isEmpty
              ? null
              : providerNotesController.text.trim(),
        );
      }
      await loadProviders();
      resetProviderForm();
    } finally {
      if (mounted) setState(() => savingProvider = false);
    }
  }

  /// Delete a provider
  Future<void> deleteProvider(String id) async {
    await providersApi.delete(id);
    await loadProviders();
  }
}
