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
  final ValueChanged<Service>? onSaved;
  final bool closeOnSave;

  const AddServiceSheet({
    super.key,
    required this.groupId,
    required this.api,
    this.service,
    this.onSaved,
    this.closeOnSave = true,
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
  bool _showValidation = false;
  bool _nameTouched = false;

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
    setState(() => _showValidation = true);
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
        widget.onSaved?.call(updated);
        if (widget.closeOnSave) {
          Navigator.of(context).pop<Service>(updated);
        }
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
        widget.onSaved?.call(created);
        if (widget.closeOnSave) {
          Navigator.of(context).pop<Service>(created);
        }
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final typo = AppTypography.of(context);
    final pad = MediaQuery.of(context).viewInsets.bottom + 16;

    InputDecoration buildServiceInputDecoration({
      required String label,
      String? hintText,
      Widget? prefixIcon,
      bool isRequired = false,
      bool isFilled = false,
      bool showCheck = false,
    }) {
      return InputDecoration(
        labelText: isRequired ? '$label *' : label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: typo.bodySmall.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: typo.bodySmall.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
        ),
        hintText: hintText,
        hintStyle: typo.bodySmall.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: showCheck
            ? Icon(Icons.check_circle_rounded, color: cs.secondary)
            : null,
        filled: true,
        fillColor: isLight
            ? Colors.white
            : (isFilled ? cs.primary.withValues(alpha: 0.06) : cs.surface),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 1.6),
        ),
      );
    }

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
                    color: cs.primary.withValues(alpha: 0.12),
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
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 14),

            // Name
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) setState(() => _nameTouched = true);
              },
              child: TextFormField(
                controller: _name,
                style: typo.bodyMedium,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: buildServiceInputDecoration(
                  label: l.nameLabel,
                  hintText: l.serviceNameExample,
                  prefixIcon: const Icon(Icons.design_services_outlined),
                  isRequired: true,
                  isFilled: _name.text.trim().isNotEmpty,
                  showCheck: _name.text.trim().isNotEmpty,
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (!_showValidation && !_nameTouched) return null;
                  return (v == null || v.trim().isEmpty)
                      ? l.nameIsRequired
                      : null;
                },
              ),
            ),
            const SizedBox(height: 12),

            // Default minutes
            TextFormField(
              controller: _minutes,
              style: typo.bodyMedium,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: buildServiceInputDecoration(
                label: l.defaultMinutesLabel,
                hintText: l.defaultMinutesHint,
                prefixIcon: const Icon(Icons.timer_outlined),
                isFilled: _minutes.text.trim().isNotEmpty,
              ),
              onChanged: (_) => setState(() {}),
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
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]
                          : [],
                      border: Border.all(
                        width: selected ? 3 : 1,
                        color: selected
                            ? cs.onSurface.withValues(alpha: 0.65)
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
