import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/widgets/receipt_line_draft.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/widgets/receipt_lines_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ReceiptFormCard extends StatelessWidget {
  final String? clientId;
  final List<GroupClient> clients;
  final String issueDateLabel;
  final TextEditingController notesController;
  final bool canEdit;
  final VoidCallback onPickDate;
  final ValueChanged<String?> onClientChanged;

  final List<ReceiptLineDraft> lines;
  final VoidCallback onAddLine;
  final ValueChanged<int> onRemoveLine;
  final VoidCallback onLinesChanged;

  const ReceiptFormCard({
    super.key,
    required this.clientId,
    required this.clients,
    required this.issueDateLabel,
    required this.notesController,
    required this.canEdit,
    required this.onPickDate,
    required this.onClientChanged,
    required this.lines,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onLinesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    InputDecoration _dec({
      required String label,
      IconData? icon,
      Widget? suffix,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixIcon: suffix,
        border: const OutlineInputBorder(),
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.receiptEditorFormTitle,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: clientId,
                    items: clients
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: canEdit ? onClientChanged : null,
                    decoration: _dec(
                      label: l.invoiceBillToLabel,
                      icon: Icons.person_outline,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: canEdit ? onPickDate : null,
                    child: InputDecorator(
                      decoration: _dec(
                        label: l.receiptIssueDateLabel,
                        icon: Icons.event_outlined,
                        suffix: canEdit
                            ? Tooltip(
                                message: l.change,
                                child: IconButton(
                                  onPressed: onPickDate,
                                  icon:
                                      const Icon(Icons.edit_calendar_outlined),
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              issueDateLabel,
                              style: t.bodyMedium.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 10),
              collapsedIconColor: cs.onSurfaceVariant,
              iconColor: cs.onSurfaceVariant,
              title: Text(
                l.invoiceNotesLabel,
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                l.optionalLabel,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              children: [
                TextField(
                  controller: notesController,
                  enabled: canEdit,
                  minLines: 2,
                  maxLines: 6,
                  decoration: _dec(
                    label: l.invoiceNotesLabel,
                    icon: Icons.notes_outlined,
                  ).copyWith(hintText: l.receiptNotesHint),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.receiptLinesTitle,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: canEdit ? onAddLine : null,
                  icon: const Icon(Icons.add),
                  label: Text(l.addLine),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ReceiptLinesEditor(
              lines: lines,
              canEdit: canEdit,
              onRemove: onRemoveLine,
              onChanged: onLinesChanged,
            ),
          ],
        ),
      ),
    );
  }
}
