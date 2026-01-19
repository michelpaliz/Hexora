import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/client_classification_store.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_active_switch.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/client_classification_manager_dialog.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'add_client_controller.dart';
import 'widgets/billing_section/billing_section.dart';
import 'widgets/client_contact_form.dart';
import 'widgets/client_header.dart';
import 'widgets/save_button.dart';

class AddClientSheet extends StatefulWidget {
  final String groupId;
  final ClientsApi api;
  final GroupClient? client;
  final ValueChanged<GroupClient>? onSaved;
  final bool closeOnSave;

  const AddClientSheet({
    super.key,
    required this.groupId,
    required this.api,
    this.client,
    this.onSaved,
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
      builder: (_) => ClientClassificationManagerDialog(groupId: widget.groupId),
    );
    await _loadClassificationOptions();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);

    setState(() => _showValidation = true);
    if (!c.formKey.currentState!.validate()) return;

    setState(() => c.saving = true);
    try {
      final result = await c.save();
      if (!mounted) return;
      // Ensure options stay in sync with values actually used.
      await ClientClassificationStore.merge(
        groupId: widget.groupId,
        entityType: result.entityType,
        propertyKind: result.propertyKind,
      );
      widget.onSaved?.call(result);
      if (widget.closeOnSave) {
        Navigator.of(context).pop<GroupClient>(result);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(l.failedWithReason(e.toString()), style: typo.bodySmall)),
      );
    } finally {
      if (mounted) setState(() => c.saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom + 16;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, pad),
      child: Form(
        key: c.formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClientHeader(isEdit: c.isEdit),
              const SizedBox(height: 14),
              BillingDivider(),
              const SizedBox(height: 14),
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
              const SizedBox(height: 12),
              BillingSection(
                c: c,
                showValidation: _showValidation,
                onFieldChanged: () => setState(() {}),
                onFieldBlur: (key) => setState(() => c.markTouched(key)),
              ),
              const SizedBox(height: 6),
              ActiveSwitch(
                value: c.active,
                onChanged: (v) => setState(() => c.active = v),
              ),
              const SizedBox(height: 12),
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
