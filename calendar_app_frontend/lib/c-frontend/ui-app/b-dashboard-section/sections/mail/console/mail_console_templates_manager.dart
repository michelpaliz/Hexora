part of '../mail_console_screen.dart';

class _TemplatesManagerPanel extends StatelessWidget {
  const _TemplatesManagerPanel({required this.state});

  final _MailConsoleScreenState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget listPane() {
      if (state._templatesLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state._templateError != null && state._templates.isEmpty) {
        return Center(
          child: Text(
            state._templateError!,
            style: t.bodySmall.copyWith(color: cs.error),
          ),
        );
      }
      if (state._templates.isEmpty) {
        return Center(
          child: Text(
            l.mailThreadsEmpty,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: state._templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final row = state._templates[index];
          final id = (row['id'] ?? row['_id'])?.toString().trim() ?? '';
          final selected = id == state._selectedTemplateId;
          final isDefault = row['isDefault'] == true;
          final name = (row['name'] ?? '').toString().trim();
          final subject = (row['subject'] ?? '').toString().trim();
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => state._selectTemplate(id),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? cs.primaryContainer.withValues(alpha: 0.45)
                    : cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? cs.primary.withValues(alpha: 0.6)
                      : cs.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name.isEmpty ? 'Template' : name,
                          style:
                              t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l.mailFooterDefaultBadge,
                            style: t.bodySmall.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (subject.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: cs.surface,
      labelStyle: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.4),
      ),
    );

    Widget formPane() {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Templates',
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: state._templateNameCtrl,
              decoration: inputDecoration.copyWith(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: state._templateSubjectCtrl,
              decoration: inputDecoration.copyWith(labelText: 'Subject'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: state._templateTextCtrl,
              minLines: 4,
              maxLines: 8,
              decoration: inputDecoration.copyWith(labelText: 'Text body'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: state._templateHtmlCtrl,
              minLines: 4,
              maxLines: 8,
              decoration: inputDecoration.copyWith(labelText: 'HTML body'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Switch(
                  value: state._templateDefault,
                  onChanged: state._setTemplateDefaultLocal,
                ),
                Text(
                  l.mailFooterDefaultBadge,
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (state._templateError != null) ...[
              const SizedBox(height: 6),
              Text(
                state._templateError!,
                style: t.bodySmall.copyWith(color: cs.error),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: state._templateSaving ? null : state._newTemplate,
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                ),
                OutlinedButton.icon(
                  onPressed: state._templateSaving
                      ? null
                      : state._applyHexoraTemplatePreset,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Use Hexora template'),
                ),
                FilledButton.icon(
                  onPressed: state._templateSaving
                      ? null
                      : _asyncCallback(state._saveTemplate),
                  icon: state._templateSaving
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l.saveDraft),
                ),
                FilledButton.tonalIcon(
                  onPressed: state._templateSaving
                      ? null
                      : _asyncCallback(state._setDefaultTemplate),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Set default'),
                ),
                OutlinedButton.icon(
                  onPressed: state._templateDeleting
                      ? null
                      : _asyncCallback(state._deleteTemplate),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.remove),
                ),
                TextButton.icon(
                  onPressed: state._templatesLoading
                      ? null
                      : _asyncCallback(state._loadTemplates),
                  icon: const Icon(Icons.refresh),
                  label: Text(l.refreshAction),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Card(
              elevation: 0,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: listPane(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Card(
              elevation: 0,
              color: cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: formPane(),
            ),
          ),
        ],
      ),
    );
  }
}
