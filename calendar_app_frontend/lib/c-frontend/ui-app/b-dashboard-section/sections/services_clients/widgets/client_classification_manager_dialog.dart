import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/client_classification_store.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientClassificationManagerDialog extends StatefulWidget {
  final String groupId;
  const ClientClassificationManagerDialog({super.key, required this.groupId});

  @override
  State<ClientClassificationManagerDialog> createState() =>
      _ClientClassificationManagerDialogState();
}

class _ClientClassificationManagerDialogState
    extends State<ClientClassificationManagerDialog> {
  final _entityCtrl = TextEditingController();
  final _propertyCtrl = TextEditingController();

  List<String> _entityTypes = const [];
  List<String> _propertyKinds = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final loaded = await ClientClassificationStore.getOptions(widget.groupId);
      if (!mounted) return;
      setState(() {
        _entityTypes = loaded.entityTypes;
        _propertyKinds = loaded.propertyKinds;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entityTypes = const [];
        _propertyKinds = const [];
      });
    }
  }

  @override
  void dispose() {
    _entityCtrl.dispose();
    _propertyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBoth() async {
    final entity = ClientClassificationStore.normalize(_entityCtrl.text);
    final prop = ClientClassificationStore.normalize(_propertyCtrl.text);
    if (entity == null && prop == null) return;

    setState(() => _saving = true);
    try {
      await ClientClassificationStore.merge(
        groupId: widget.groupId,
        entityType: entity,
        propertyKind: prop,
      );
      _entityCtrl.clear();
      _propertyCtrl.clear();
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.clientClassificationSavedSnack)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedWithReason(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final canSave = !_saving &&
        (ClientClassificationStore.normalize(_entityCtrl.text) != null ||
            ClientClassificationStore.normalize(_propertyCtrl.text) != null);

    return AlertDialog(
      title: Text(l.clientClassificationManageTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.clientEntityTypeLabel,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _entityCtrl,
                      decoration: InputDecoration(hintText: l.clientAddOptionHint),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in _entityTypes)
                    InputChip(
                      label: Text(v),
                      onDeleted: () async {
                        await ClientClassificationStore.remove(
                          groupId: widget.groupId,
                          entityType: v,
                        );
                        await _reload();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l.clientPropertyKindLabel,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _propertyCtrl,
                      decoration: InputDecoration(hintText: l.clientAddOptionHint),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in _propertyKinds)
                    InputChip(
                      label: Text(v),
                      onDeleted: () async {
                        await ClientClassificationStore.remove(
                          groupId: widget.groupId,
                          propertyKind: v,
                        );
                        await _reload();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l.clientClassificationManageHint,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            try {
              await ClientClassificationStore.rebuild(widget.groupId);
              if (!mounted) return;
              await _reload();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.clientClassificationRebuiltSnack)),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.failedWithReason(e.toString()))),
              );
            }
          },
          icon: const Icon(Icons.refresh_outlined),
          label: Text(l.clientClassificationRebuildCta),
        ),
        FilledButton(
          onPressed: canSave ? _saveBoth : null,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.clientClassificationSaveCta),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
