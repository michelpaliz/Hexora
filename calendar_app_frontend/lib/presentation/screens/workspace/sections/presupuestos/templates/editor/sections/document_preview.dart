part of '../../presupuesto_template_editor_screen.dart';

extension _TemplateDocumentPreview on _PresupuestoTemplateEditorScreenState {
  Widget _buildLivePreviewCard() {
    final theme = Theme.of(context);
    final client = _variableValue('CLIENTE');
    final price = _primaryPriceValue();
    final titleTemplate = _title.text.trim().isEmpty
        ? 'Presupuesto para ${client.isEmpty ? '[CLIENTE]' : client}'
        : _title.text.trim();
    final title = _resolvePreviewTags(titleTemplate);
    final subtitle = _resolvePreviewTags(_subtitle.text.trim());
    final intro = _resolvePreviewTags(_intro.text.trim());
    final enabledSections =
        _sections.where((section) => section.enabled).toList(growable: false);
    final visibleImages = _images
        .where((image) => image.enabled && image.url.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);

    return _card(
      title: 'Vista previa',
      subtitle: 'Asi se vera el documento mientras editas.',
      icon: Icons.preview_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final previewWidth =
              constraints.maxWidth < 640 ? 640.0 : constraints.maxWidth;
          return Scrollbar(
            controller: _previewHorizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _previewHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: previewWidth,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isDark(theme)
                          ? const Color(0xFFBFE7FF).withValues(alpha: 0.22)
                          : theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: const Color(0xFF20242A),
                      height: 1.35,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    client.isEmpty
                                        ? 'Nombre del cliente'
                                        : client,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: const Color(0xFF20242A),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (price.isNotEmpty)
                                    Text(
                                      price,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _RestrictedMarkdownText(
                          data: title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _RestrictedMarkdownText(
                            data: subtitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: const Color(0xFF667085),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (intro.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _RestrictedMarkdownText(data: intro),
                        ],
                        if (visibleImages.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                visibleImages.first.url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (enabledSections.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          for (final section in enabledSections)
                            _previewSection(theme, section),
                        ],
                        if (enabledSections.isEmpty && intro.isEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            'Anade texto o secciones para completar la vista previa.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _previewSection(ThemeData theme, _TemplateSectionState section) {
    final title = _resolvePreviewTags(section.title.text.trim());
    final body = _resolvePreviewTags(section.body.text.trim());
    final items = section.itemControllers
        .map((controller) => controller.text.trim())
        .where((line) => line.isNotEmpty)
        .map(_resolvePreviewTags)
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RestrictedMarkdownText(
            data: title.isEmpty ? 'Seccion' : title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            _RestrictedMarkdownText(data: body),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('\u2022  '),
                    Expanded(child: _RestrictedMarkdownText(data: item)),
                  ],
                ),
              ),
          ],
          if (section.table != null) ...[
            const SizedBox(height: 8),
            _previewTable(theme, section.table!),
          ],
        ],
      ),
    );
  }

  Widget _previewTable(ThemeData theme, _TemplateTableState table) {
    if (table.columns.isEmpty) return const SizedBox.shrink();
    final rows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        children: [
          for (final column in table.columns)
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                _resolvePreviewTags(column.text),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      for (final row in table.rows)
        TableRow(
          children: [
            for (var i = 0; i < table.columns.length; i++)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  _resolvePreviewTags(i < row.length ? row[i].text : ''),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF344054),
                  ),
                ),
              ),
          ],
        ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: table.columns.length * 135,
        child: Table(
          border: TableBorder.all(color: const Color(0xFFD0D5DD)),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows,
        ),
      ),
    );
  }

  Widget _buildDocumentActionsCard() {
    return _card(
      title: 'Salida del documento',
      subtitle:
          'Guarda, revisa y descarga el resultado final antes de compartirlo con el cliente.',
      icon: Icons.picture_as_pdf_outlined,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton.icon(
            onPressed:
                _previewing || _mustSelectDefaultTemplate ? null : _previewPdf,
            icon: _previewing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility_outlined),
            label: const Text('Previsualizar'),
          ),
          FilledButton.icon(
            onPressed: _downloading || _mustSelectDefaultTemplate
                ? null
                : _downloadPdf,
            icon: _downloading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('Descargar PDF'),
          ),
        ],
      ),
    );
  }
}
