import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/snack_helper.dart';

class PresupuestoImageLibraryView extends StatefulWidget {
  const PresupuestoImageLibraryView({
    super.key,
    required this.groupId,
    this.api,
  });

  final String groupId;
  final PresupuestosApi? api;

  @override
  State<PresupuestoImageLibraryView> createState() =>
      _PresupuestoImageLibraryViewState();
}

class _PresupuestoImageLibraryViewState
    extends State<PresupuestoImageLibraryView> {
  late final PresupuestosApi _api;
  List<PresupuestoLibraryImage> _images = const [];
  bool _loading = true;
  bool _uploading = false;
  String? _deletingId;
  String? _error;

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? PresupuestosApi();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final rows = await _api.listImageLibrary(widget.groupId);
      if (!mounted) return;
      setState(() {
        _images = rows
            .map(PresupuestoLibraryImage.fromMap)
            .where((image) => image.id.isNotEmpty)
            .toList(growable: false);
      });
    } on PresupuestosApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    if (_uploading) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null) return;
    if (file.bytes == null) {
      if (mounted) {
        showErrorSnack(context, 'No se pudo leer la imagen seleccionada.');
      }
      return;
    }

    final name = await _askImageName(file.name);
    if (name == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await _api.uploadImageLibraryAsset(
        groupId: widget.groupId,
        bytes: file.bytes!,
        fileName: file.name,
        name: name,
      );
      if (!mounted) return;
      showSuccessSnack(
        context,
        _isEs ? 'Imagen guardada en la biblioteca.' : 'Image saved to library.',
      );
      await _load();
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String?> _askImageName(String fileName) async {
    final dot = fileName.lastIndexOf('.');
    final initialName = dot > 0 ? fileName.substring(0, dot) : fileName;
    final controller = TextEditingController(text: initialName);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isEs ? 'Guardar imagen' : 'Save image'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: _isEs ? 'Nombre (opcional)' : 'Name (optional)',
            hintText: fileName,
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(_isEs ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(_isEs ? 'Subir' : 'Upload'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _delete(PresupuestoLibraryImage image) async {
    if (_deletingId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isEs ? 'Eliminar imagen' : 'Delete image'),
        content: Text(
          _isEs
              ? '¿Quieres eliminar “${image.name}” de la biblioteca?'
              : 'Delete “${image.name}” from the library?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_isEs ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_isEs ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = image.id);
    try {
      await _api.deleteImageLibraryAsset(image.id);
      if (!mounted) return;
      setState(() {
        _images = _images
            .where((candidate) => candidate.id != image.id)
            .toList(growable: false);
      });
      showSuccessSnack(
        context,
        _isEs ? 'Imagen eliminada.' : 'Image deleted.',
      );
    } on PresupuestosApiException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  void _preview(PresupuestoLibraryImage image) {
    if (image.readUrl.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        image.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: _isEs ? 'Cerrar' : 'Close',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    image.readUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const _ImageUnavailable(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEs ? 'Biblioteca de imágenes' : 'Image library',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEs
                          ? 'Guarda imágenes reutilizables para tus plantillas y presupuestos.'
                          : 'Save reusable images for your templates and budgets.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.outlined(
                    tooltip: _isEs ? 'Actualizar' : 'Refresh',
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _uploading ? null : _upload,
                    icon: _uploading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(_isEs ? 'Subir imagen' : 'Upload image'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_isEs ? 'Reintentar' : 'Retry'),
            ),
          ],
        ),
      );
    }
    if (_images.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              _isEs
                  ? 'Todavía no hay imágenes guardadas.'
                  : 'No saved images yet.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _upload,
              icon: const Icon(Icons.upload_rounded),
              label: Text(
                  _isEs ? 'Subir la primera imagen' : 'Upload first image'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 260).floor().clamp(1, 5);
        return RefreshIndicator(
          onRefresh: _load,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _images.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.16,
            ),
            itemBuilder: (context, index) {
              final image = _images[index];
              return _ImageLibraryCard(
                image: image,
                deleting: _deletingId == image.id,
                onPreview: () => _preview(image),
                onDelete: () => _delete(image),
              );
            },
          ),
        );
      },
    );
  }
}

class _ImageLibraryCard extends StatelessWidget {
  const _ImageLibraryCard({
    required this.image,
    required this.deleting,
    required this.onPreview,
    required this.onDelete,
  });

  final PresupuestoLibraryImage image;
  final bool deleting;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        onTap: image.readUrl.isEmpty ? null : onPreview,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: image.readUrl.isEmpty
                  ? const _ImageUnavailable()
                  : Image.network(
                      image.readUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ImageUnavailable(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      image.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (deleting)
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Eliminar',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageUnavailable extends StatelessWidget {
  const _ImageUnavailable();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class PresupuestoLibraryImage {
  const PresupuestoLibraryImage({
    required this.id,
    required this.name,
    required this.readUrl,
  });

  factory PresupuestoLibraryImage.fromMap(Map<String, dynamic> map) {
    final id = _text(map['_id'] ?? map['id'] ?? map['imageId']);
    final name = _text(map['name'] ?? map['fileName'] ?? map['filename']);
    return PresupuestoLibraryImage(
      id: id,
      name: name.isEmpty ? 'Imagen' : name,
      readUrl: _text(map['readUrl'] ?? map['url']),
    );
  }

  final String id;
  final String name;
  final String readUrl;
}

Future<PresupuestoLibraryImage?> showPresupuestoImageLibraryPicker(
  BuildContext context, {
  required PresupuestosApi api,
  required String groupId,
}) {
  return showDialog<PresupuestoLibraryImage>(
    context: context,
    builder: (_) => _PresupuestoImageLibraryPickerDialog(
      api: api,
      groupId: groupId,
    ),
  );
}

class _PresupuestoImageLibraryPickerDialog extends StatefulWidget {
  const _PresupuestoImageLibraryPickerDialog({
    required this.api,
    required this.groupId,
  });

  final PresupuestosApi api;
  final String groupId;

  @override
  State<_PresupuestoImageLibraryPickerDialog> createState() =>
      _PresupuestoImageLibraryPickerDialogState();
}

class _PresupuestoImageLibraryPickerDialogState
    extends State<_PresupuestoImageLibraryPickerDialog> {
  List<PresupuestoLibraryImage> _images = const [];
  bool _loading = true;
  String? _error;

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.api.listImageLibrary(widget.groupId);
      if (!mounted) return;
      setState(() {
        _images = rows
            .map(PresupuestoLibraryImage.fromMap)
            .where((image) => image.id.isNotEmpty && image.readUrl.isNotEmpty)
            .toList(growable: false);
      });
    } on PresupuestosApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEs ? 'Elegir de la biblioteca' : 'Choose from image library',
      ),
      content: SizedBox(
        width: 820,
        height: 540,
        child: _content(),
      ),
      actions: [
        IconButton(
          tooltip: _isEs ? 'Actualizar' : 'Refresh',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_isEs ? 'Cancelar' : 'Cancel'),
        ),
      ],
    );
  }

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_isEs ? 'Reintentar' : 'Retry'),
            ),
          ],
        ),
      );
    }
    if (_images.isEmpty) {
      return Center(
        child: Text(
          _isEs
              ? 'No hay imágenes disponibles. Súbelas primero desde Biblioteca de imágenes.'
              : 'No images available. Upload them from the image library first.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 190).floor().clamp(1, 4);
        return GridView.builder(
          itemCount: _images.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final image = _images[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(image),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.network(
                        image.readUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _ImageUnavailable(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        image.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _text(dynamic value) => value?.toString().trim() ?? '';
