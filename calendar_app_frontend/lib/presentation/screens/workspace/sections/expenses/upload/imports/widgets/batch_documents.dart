part of '../../expense_upload_screen.dart';

class _BatchDocumentList extends StatelessWidget {
  final List<String> names;
  final List<Uint8List> bytes;
  final Set<String> uploadedFileNames;
  final bool disabled;
  final void Function(int index) onRemoveAt;
  final VoidCallback onClearAll;

  const _BatchDocumentList({
    required this.names,
    required this.bytes,
    required this.uploadedFileNames,
    required this.disabled,
    required this.onRemoveAt,
    required this.onClearAll,
  });

  bool _isDuplicate(String name) =>
      uploadedFileNames.contains(name.toLowerCase().trim());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final duplicateCount = names.where(_isDuplicate).length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Header ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
            child: Row(
              children: [
                Icon(Icons.folder_open_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${names.length} archivos',
                    style: ts.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (duplicateCount > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.amber.withValues(alpha: 0.15),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 10, color: Colors.amber.shade600),
                        const SizedBox(width: 3),
                        Text(
                          '$duplicateCount ya subido${duplicateCount == 1 ? '' : 's'}',
                          style: ts.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                TextButton.icon(
                  onPressed: disabled ? null : onClearAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: cs.error,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  icon: const Icon(Icons.clear_all, size: 14),
                  label: const Text('Limpiar todo'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
          // ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ Scrollable file list ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: names.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 10,
                endIndent: 10,
                color: cs.outlineVariant.withValues(alpha: 0.2),
              ),
              itemBuilder: (_, i) => _BatchDocFileRow(
                name: names[i],
                sizeBytes: i < bytes.length ? bytes[i].length : 0,
                isDuplicate: _isDuplicate(names[i]),
                disabled: disabled,
                onRemove: () => onRemoveAt(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchDocFileRow extends StatelessWidget {
  final String name;
  final int sizeBytes;
  final bool isDuplicate;
  final bool disabled;
  final VoidCallback onRemove;

  const _BatchDocFileRow({
    required this.name,
    required this.sizeBytes,
    required this.isDuplicate,
    required this.disabled,
    required this.onRemove,
  });

  String get _sizeLabel {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 15,
            color: isDuplicate
                ? Colors.amber.shade500
                : cs.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: ts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sizeBytes > 0)
                  Text(
                    _sizeLabel,
                    style: ts.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          if (isDuplicate) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.amber.withValues(alpha: 0.12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Ya subido',
                style: ts.bodySmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade500,
                ),
              ),
            ),
          ],
          const SizedBox(width: 2),
          IconButton(
            tooltip: 'Quitar',
            icon: Icon(
              Icons.close,
              size: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.55),
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: disabled ? null : onRemove,
          ),
        ],
      ),
    );
  }
}
