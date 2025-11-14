import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AddServiceSheet extends StatefulWidget {
  final String groupId; // used on create
  final ServiceApi api;
  final Service? service; // null = create, non-null = edit

  const AddServiceSheet({
    super.key,
    required this.groupId,
    required this.api,
    this.service,
  });

  @override
  State<AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<AddServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _minutes = TextEditingController();
  bool _active = true;
  bool _saving = false;

  static const _palette = <String>[
    '#3b82f6',
    '#10b981',
    '#f59e0b',
    '#ef4444',
    '#8b5cf6',
    '#06b6d4',
  ];
  late List<String> _swatches;
  late String _color;

  bool get _isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    _swatches = List<String>.from(_palette);
    if (_isEdit) {
      final s = widget.service!;
      _name.text = s.name;
      if (s.defaultMinutes != null) _minutes.text = s.defaultMinutes.toString();
      _active = s.isActive;
      _color = s.color ?? _swatches.first;
      if (!_swatches.contains(_color)) _swatches.insert(0, _color);
    } else {
      _color = _swatches.first;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = int.parse('FF$cleaned', radix: 16);
    return Color(value);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (_isEdit) {
        final minutes = _minutes.text.trim().isEmpty
            ? null
            : int.tryParse(_minutes.text.trim());

        final patch = <String, dynamic>{
          'name': _name.text.trim(),
          'defaultMinutes': minutes,
          'color': _color,
          'isActive': _active,
        };

        final updated =
            await widget.api.updateFields(widget.service!.id, patch);
        if (!mounted) return;
        Navigator.of(context).pop<Service>(updated);
      } else {
        final created = await widget.api.create(
          Service(
            id: '',
            name: _name.text.trim(),
            groupId: widget.groupId,
            defaultMinutes: _minutes.text.trim().isEmpty
                ? null
                : int.tryParse(_minutes.text.trim()),
            color: _color,
            isActive: _active,
            createdAt: DateTime.now(),
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop<Service>(created);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(l.failedWithReason(e.toString()), style: typo.bodySmall)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final pad = MediaQuery.of(context).viewInsets.bottom + 16;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, pad),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isEdit
                        ? Icons.edit_note_rounded
                        : Icons.design_services_outlined,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEdit ? l.editService : l.createService,
                    style: typo.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: cs.outlineVariant.withOpacity(0.4)),
            const SizedBox(height: 14),

            // Name
            TextFormField(
              controller: _name,
              style: typo.bodyMedium,
              decoration: InputDecoration(
                labelText: '${l.nameLabel} *',
                labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                hintText: l.e_gJohnDoe, // reuse generic hint
                hintStyle: typo.bodySmall
                    .copyWith(color: cs.onSurfaceVariant.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.design_services_outlined),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                errorBorder: inputBorder.copyWith(
                  borderSide: BorderSide(color: cs.error),
                ),
                focusedErrorBorder: inputBorder.copyWith(
                  borderSide: BorderSide(color: cs.error, width: 1.5),
                ),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.nameIsRequired : null,
            ),
            const SizedBox(height: 12),

            // Default minutes
            TextFormField(
              controller: _minutes,
              style: typo.bodyMedium,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l.defaultMinutesLabel,
                labelStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                hintText: l.defaultMinutesHint,
                hintStyle: typo.bodySmall
                    .copyWith(color: cs.onSurfaceVariant.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.timer_outlined),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Color label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l.colorLabel,
                style: typo.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Color picker
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _swatches.map((hex) {
                final selected = _color == hex;
                final color = _hexToColor(hex);
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]
                          : [],
                      border: Border.all(
                        width: selected ? 3 : 1,
                        color: selected
                            ? cs.onSurface.withOpacity(0.65)
                            : Colors.black12,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            // Active switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: Text(l.active,
                  style: typo.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _active ? l.serviceWillBeActive : l.serviceWillBeInactive,
                style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ),

            const SizedBox(height: 12),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? l.saving
                      : (_isEdit ? l.saveChanges : l.saveService),
                  style: typo.bodySmall.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .2,
                  ),
                ),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
