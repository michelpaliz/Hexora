import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/models/documents/private_document.dart';
import 'package:hexora/presentation/screens/workspace/sections/private_documents/widgets/private_document_detail_dialog.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/presentation/shared/widgets/feedback/snack_helper.dart';
import 'package:hexora/services/documents/private_documents_api.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Contextual right-side (or full-screen on mobile) preview for a selected
/// private document. Shows an inline PDF/image preview, the document metadata,
/// and edit / download / delete actions. Closing it never mutates the list
/// selection, search or scroll — the parent owns that state.
class PrivateDocumentPreviewPanel extends StatefulWidget {
  const PrivateDocumentPreviewPanel({
    super.key,
    required this.document,
    required this.api,
    required this.groupId,
    required this.onClose,
    required this.onChanged,
    this.showCloseButton = true,
  });

  final PrivateDocument document;
  final PrivateDocumentsApi api;
  final String groupId;

  /// Dismisses the panel without touching the list.
  final VoidCallback onClose;

  /// The document (or the list behind it) changed: the parent reloads.
  final VoidCallback onChanged;

  final bool showCloseButton;

  @override
  State<PrivateDocumentPreviewPanel> createState() =>
      _PrivateDocumentPreviewPanelState();
}

class _PrivateDocumentPreviewPanelState
    extends State<PrivateDocumentPreviewPanel> {
  Uint8List? _bytes;
  bool _loadingPreview = false;
  String? _previewError;
  int _loadToken = 0;

  bool _opening = false;
  bool _deleting = false;

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  bool get _isPdf {
    final mime = widget.document.mimeType?.toLowerCase() ?? '';
    if (mime.contains('pdf')) return true;
    return widget.document.fileName.toLowerCase().endsWith('.pdf');
  }

  bool get _isImage {
    final mime = widget.document.mimeType?.toLowerCase() ?? '';
    if (mime.startsWith('image/')) return true;
    final name = widget.document.fileName.toLowerCase();
    return const ['.jpg', '.jpeg', '.jpe', '.png', '.webp']
        .any(name.endsWith);
  }

  bool get _previewable => _isPdf || _isImage;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void didUpdateWidget(covariant PrivateDocumentPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only the file identity matters for the preview bytes; metadata edits on
    // the same file keep the cached bytes.
    if (oldWidget.document.id != widget.document.id ||
        oldWidget.document.fileReplacedAt != widget.document.fileReplacedAt) {
      _bytes = null;
      _loadPreview();
    }
  }

  Future<void> _loadPreview() async {
    if (!_previewable) return;
    final token = ++_loadToken;
    setState(() {
      _loadingPreview = true;
      _previewError = null;
    });
    try {
      final bytes = await widget.api.downloadFileBytes(
        groupId: widget.groupId,
        documentId: widget.document.id,
      );
      if (!mounted || token != _loadToken) return;
      setState(() => _bytes = bytes);
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() =>
          _previewError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && token == _loadToken) {
        setState(() => _loadingPreview = false);
      }
    }
  }

  Future<void> _download() async {
    setState(() => _opening = true);
    try {
      final url = await widget.api.getFileDownloadUrl(
        groupId: widget.groupId,
        documentId: widget.document.id,
      );
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        showErrorSnack(
          context,
          _isEs ? 'No se pudo abrir el archivo' : 'Could not open the file',
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _edit() async {
    final result = await PrivateDocumentDetailDialog.show(
      context,
      api: widget.api,
      groupId: widget.groupId,
      document: widget.document,
    );
    if (result == PrivateDocumentDetailResult.changed) widget.onChanged();
  }

  Future<void> _delete() async {
    final isEs = _isEs;
    final confirmed = await showHexoraDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Eliminar documento' : 'Delete document'),
        content: Text(
          isEs
              ? '¿Seguro que quieres eliminar "${widget.document.displayTitle}"? Esta acción no se puede deshacer.'
              : 'Are you sure you want to delete "${widget.document.displayTitle}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(isEs ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isEs ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await widget.api.remove(
        groupId: widget.groupId,
        documentId: widget.document.id,
      );
      if (!mounted) return;
      showSuccessSnack(
          context, isEs ? 'Documento eliminado' : 'Document deleted');
      widget.onClose();
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = _isEs;
    final d = widget.document;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── header ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            border: Border(
              bottom:
                  BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(_categoryIcon(d.category),
                    color: cs.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      d.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      isEs
                          ? PrivateDocumentCategory.labelEs(d.category)
                          : PrivateDocumentCategory.labelEn(d.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (widget.showCloseButton)
                IconButton(
                  tooltip: isEs ? 'Cerrar' : 'Close',
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
        // ── body ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _previewSurface(cs, isEs),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _PreviewChip(
                      label: isEs
                          ? PrivateDocumentReviewStatus.labelEs(d.status)
                          : PrivateDocumentReviewStatus.labelEn(d.status),
                      color: _statusColor(d.status, cs),
                    ),
                    if (d.expiryDate != null)
                      _PreviewChip(
                        label:
                            '${isEs ? "Vence" : "Expires"} ${DateFormat('dd/MM/yyyy').format(d.expiryDate!)}',
                        color: d.isExpired
                            ? cs.error
                            : d.isExpiringSoon
                                ? Colors.orange
                                : cs.onSurfaceVariant,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                _MetaRow(
                  label: isEs ? 'Archivo' : 'File',
                  value: d.fileName,
                ),
                if (d.fileSizeBytes != null)
                  _MetaRow(
                    label: isEs ? 'Tamaño' : 'Size',
                    value: '${(d.fileSizeBytes! / 1024).toStringAsFixed(0)} KB',
                  ),
                if (d.uploadedByName != null)
                  _MetaRow(
                    label: isEs ? 'Subido por' : 'Uploaded by',
                    value: d.uploadedByName!,
                  ),
                if (d.createdAt != null)
                  _MetaRow(
                    label: isEs ? 'Fecha de subida' : 'Uploaded on',
                    value: DateFormat('dd/MM/yyyy HH:mm')
                        .format(d.createdAt!.toLocal()),
                  ),
                if (d.tags.isNotEmpty)
                  _MetaChips(
                    label: isEs ? 'Etiquetas' : 'Tags',
                    values: d.tags,
                    color: cs.primary,
                  ),
                if (d.counterparties.isNotEmpty)
                  _MetaChips(
                    label: isEs ? 'Contrapartes' : 'Counterparties',
                    values: d.counterparties,
                    color: cs.tertiary,
                  ),
                if ((d.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    isEs ? 'Notas' : 'Notes',
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(d.notes!.trim(), style: t.bodySmall),
                ],
              ],
            ),
          ),
        ),
        // ── actions ──
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          child: Row(
            children: [
              HexoraButton(
                icon: Icons.edit_outlined,
                label: isEs ? 'Editar' : 'Edit',
                variant: HexoraButtonVariant.secondary,
                size: HexoraButtonSize.compact,
                onPressed: _edit,
              ),
              const SizedBox(width: 8),
              HexoraButton(
                icon: Icons.download_rounded,
                label: isEs ? 'Descargar' : 'Download',
                size: HexoraButtonSize.compact,
                loading: _opening,
                onPressed: _opening ? null : _download,
              ),
              const Spacer(),
              HexoraButton.iconOnly(
                icon: Icons.delete_outline_rounded,
                tooltip: isEs ? 'Eliminar' : 'Delete',
                variant: HexoraButtonVariant.ghost,
                size: HexoraButtonSize.compact,
                accentColor: cs.error,
                loading: _deleting,
                onPressed: _deleting ? null : _delete,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewSurface(ColorScheme cs, bool isEs) {
    const height = 340.0;
    Widget inner;
    if (!_previewable) {
      inner = _PreviewPlaceholder(
        icon: Icons.insert_drive_file_outlined,
        label: isEs
            ? 'Vista previa no disponible'
            : 'Preview not available',
      );
    } else if (_loadingPreview && _bytes == null) {
      inner = const Center(child: CircularProgressIndicator());
    } else if (_previewError != null && _bytes == null) {
      inner = _PreviewPlaceholder(
        icon: Icons.error_outline_rounded,
        label: _previewError!,
      );
    } else if (_bytes != null && _isImage) {
      inner = Center(
        child: InteractiveViewer(
          child: Image.memory(_bytes!, fit: BoxFit.contain),
        ),
      );
    } else if (_bytes != null && _isPdf) {
      return PdfInlinePreview(bytes: _bytes!, height: height);
    } else {
      inner = const Center(child: CircularProgressIndicator());
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: inner,
    );
  }
}

// ── small pieces ─────────────────────────────────────────────────────────────

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: cs.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: t.bodySmall.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  const _MetaChips({
    required this.label,
    required this.values,
    required this.color,
  });

  final String label;
  final List<String> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final v in values)
                _PreviewChip(label: v, color: color),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

IconData _categoryIcon(String category) => switch (category) {
      PrivateDocumentCategory.contract => Icons.description_outlined,
      PrivateDocumentCategory.loan => Icons.account_balance_outlined,
      PrivateDocumentCategory.insurance => Icons.shield_outlined,
      PrivateDocumentCategory.legal => Icons.gavel_rounded,
      PrivateDocumentCategory.tax => Icons.receipt_long_outlined,
      PrivateDocumentCategory.property => Icons.home_work_outlined,
      _ => Icons.folder_outlined,
    };

Color _statusColor(String status, ColorScheme cs) => switch (status) {
      PrivateDocumentReviewStatus.reviewed => Colors.green,
      PrivateDocumentReviewStatus.archived => cs.onSurfaceVariant,
      _ => Colors.orange,
    };
