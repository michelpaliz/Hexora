part of '../../presupuesto_template_editor_screen.dart';

extension _TemplateImageEditor on _PresupuestoTemplateEditorScreenState {
  Widget _buildImagesCard() {
    return _card(
      title: 'Imagenes',
      subtitle: 'Sube fotos que apareceran en el PDF del presupuesto.',
      icon: Icons.collections_outlined,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final image in _images) _imageSlot(image),
        ],
      ),
    );
  }

  Widget _imageSlot(_TemplateImageState image) {
    final theme = Theme.of(context);
    final url = image.url.trim();
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 0,
        color: _editorPanelBg(theme),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _editorBorder(theme)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      image.slot.replaceAll('_', ' ').toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    image.enabled
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: image.enabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 118,
                decoration: BoxDecoration(
                  color: _editorSoftAccentBg(theme),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _editorBorder(theme)),
                ),
                clipBehavior: Clip.antiAlias,
                child: url.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sin imagen',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              _field(
                image.label,
                'Etiqueta',
                dense: true,
                hint: 'Describe brevemente esta imagen',
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _libraryImageBusySlots.contains(image.slot)
                      ? null
                      : () => _chooseLibraryImage(image),
                  icon: _libraryImageBusySlots.contains(image.slot)
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library_outlined),
                  label: const Text('Usar de la biblioteca'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _uploadImage(image),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(url.isEmpty ? 'Subir' : 'Reemplazar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: image.enabled ? 'Ocultar' : 'Mostrar',
                    onPressed: () => _updateEditorState(
                        () => image.enabled = !image.enabled),
                    icon: Icon(
                      image.enabled
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
