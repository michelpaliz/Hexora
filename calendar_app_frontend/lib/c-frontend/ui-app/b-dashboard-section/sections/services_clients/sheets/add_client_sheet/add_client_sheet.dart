import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/widgets/billing_section/billing_active_switch.dart';
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

  const AddClientSheet({
    super.key,
    required this.groupId,
    required this.api,
    this.client,
  });

  @override
  State<AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<AddClientSheet> {
  late final AddClientController c;

  @override
  void initState() {
    super.initState();
    c = AddClientController(
      api: widget.api,
      groupId: widget.groupId,
      client: widget.client,
    );
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);

    if (!c.formKey.currentState!.validate()) return;

    setState(() => c.saving = true);
    try {
      final result = await c.save();
      if (!mounted) return;
      Navigator.of(context).pop<GroupClient>(result);
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
              ClientContactForm(c: c),
              const SizedBox(height: 12),
              BillingSection(c: c),
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
    return Divider(height: 1, color: cs.outlineVariant.withOpacity(0.4));
  }
}
