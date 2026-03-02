import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientPickerField extends FormField<String> {
  ClientPickerField({
    super.key,
    required String? value,
    required String labelText,
    required List<GroupClient> clients,
    required ValueChanged<String?> onChanged,
    FormFieldValidator<String>? validator,
  }) : super(
          initialValue: value,
          validator: validator,
          builder: (state) {
            final cs = Theme.of(state.context).colorScheme;
            final t = AppTypography.of(state.context);
            final l = AppLocalizations.of(state.context)!;

            final selected = clients.firstWhere(
              (c) => c.id == state.value,
              orElse: () => GroupClient(
                  id: '', name: l.invoiceSelectClientLabel, isActive: true),
            );

            Future<void> openPicker() async {
              final picked = await showModalBottomSheet<String>(
                context: state.context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (ctx) {
                  String query = '';
                  return StatefulBuilder(
                    builder: (ctx, setModalState) {
                      final filtered = query.trim().isEmpty
                          ? clients
                          : clients
                              .where((c) => c.name
                                  .toLowerCase()
                                  .contains(query.trim().toLowerCase()))
                              .toList();

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          MediaQuery.of(ctx).viewInsets.bottom + 16,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l.invoiceSelectClientLabel,
                                    style: t.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              autofocus: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: l.invoiceClientSearchHint,
                              ),
                              onChanged: (v) => setModalState(() => query = v),
                            ),
                            const SizedBox(height: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 420),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final c = filtered[i];
                                  final selected = c.id == state.value;
                                  return ListTile(
                                    title: Text(c.name),
                                    subtitle: Text(
                                      c.email ?? (c.billing?.legalName ?? ''),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: selected
                                        ? Icon(Icons.check_circle,
                                            color: cs.primary)
                                        : null,
                                    onTap: () => Navigator.of(ctx).pop(c.id),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );

              if (picked == null) return;
              state.didChange(picked);
              onChanged(picked);
            }

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: openPicker,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: labelText,
                  errorText: state.errorText,
                  suffixIcon: const Icon(Icons.expand_more),
                ),
                child: Text(
                  selected.id.isEmpty
                      ? l.invoiceSelectClientLabel
                      : selected.name,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            );
          },
        );
}
