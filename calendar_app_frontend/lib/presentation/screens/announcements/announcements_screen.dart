import 'package:flutter/material.dart';
import 'package:hexora/models/announcements/announcement.dart';
import 'package:hexora/services/announcements/announcements_api.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showAnnouncementsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final compact = size.width < 700 || size.height < 620;
      if (compact) {
        return const Dialog.fullscreen(
          child: AnnouncementsScreen(embedded: true),
        );
      }
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 1120,
            maxHeight: size.height * .88,
          ),
          child: const AnnouncementsScreen(embedded: true),
        ),
      );
    },
  );
}

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _api = AnnouncementsApi();
  String? _category;
  int _page = 1;
  Future<AnnouncementPage>? _request;

  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';

  void _load() {
    setState(() {
      _request = _api.list(
        language: _isSpanish ? 'es' : 'en',
        category: _category,
        page: _page,
        limit: 12,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request ??= _api.list(
      language: _isSpanish ? 'es' : 'en',
      page: 1,
      limit: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final content = Column(children: [
      if (widget.embedded)
        _DialogHeader(
          isSpanish: _isSpanish,
          showAdmin: user?.platformRole == 'admin',
          onAdmin: _openAdmin,
        ),
      SizedBox(
        height: 58,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          children: [
            _filter(null, _isSpanish ? 'Todo' : 'All'),
            _filter('feature', _isSpanish ? 'Funciones' : 'Features'),
            _filter('improvement', _isSpanish ? 'Mejoras' : 'Improvements'),
            _filter('bug_fix', _isSpanish ? 'Correcciones' : 'Fixes'),
            _filter(
                'maintenance', _isSpanish ? 'Mantenimiento' : 'Maintenance'),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<AnnouncementPage>(
          future: _request,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.cloud_off_outlined,
                message: _isSpanish
                    ? 'No se pudieron cargar las novedades.'
                    : 'Updates could not be loaded.',
                action: _load,
                actionLabel: _isSpanish ? 'Reintentar' : 'Try again',
              );
            }
            final data = snapshot.data!;
            if (data.items.isEmpty) {
              return _MessageState(
                icon: Icons.newspaper_outlined,
                message: _isSpanish
                    ? 'No hay novedades en esta categoría.'
                    : 'There are no updates in this category.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: data.items.length + (data.pages > 1 ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == data.items.length) return _pager(data);
                return _NewsCard(
                  item: data.items[index],
                  isSpanish: _isSpanish,
                  onTap: () => _showDetails(data.items[index]),
                );
              },
            );
          },
        ),
      ),
    ]);
    if (widget.embedded) {
      return Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: content,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isSpanish ? 'Novedades de Hexora' : 'Hexora News & Updates'),
        actions: [
          if (user?.platformRole == 'admin')
            IconButton(
              tooltip: _isSpanish ? 'Administrar novedades' : 'Manage updates',
              onPressed: _openAdmin,
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
        ],
      ),
      body: content,
    );
  }

  Future<void> _openAdmin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AnnouncementAdminScreen()),
    );
    if (mounted) _load();
  }

  Widget _filter(String? value, String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          selected: _category == value,
          label: Text(label),
          onSelected: (_) {
            _category = value;
            _page = 1;
            _load();
          },
        ),
      );

  Widget _pager(AnnouncementPage data) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
            onPressed: data.page > 1
                ? () {
                    _page--;
                    _load();
                  }
                : null,
            icon: const Icon(Icons.chevron_left)),
        Text('${data.page} / ${data.pages}'),
        IconButton(
            onPressed: data.page < data.pages
                ? () {
                    _page++;
                    _load();
                  }
                : null,
            icon: const Icon(Icons.chevron_right)),
      ]);

  Future<void> _showDetails(Announcement item) async {
    if (!item.isRead) _api.markRead(item.id).catchError((_) {});
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (item.imageUrl?.isNotEmpty == true) ...[
            ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(item.imageUrl!,
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink())),
            const SizedBox(height: 18),
          ],
          Text(item.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(item.description, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 18),
          SelectableText(item.content,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
          if (item.videoUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse(item.videoUrl!),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(_isSpanish ? 'Ver vídeo' : 'Watch video'),
            ),
          ],
        ]),
      )),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.isSpanish,
    required this.showAdmin,
    required this.onAdmin,
  });

  final bool isSpanish;
  final bool showAdmin;
  final VoidCallback onAdmin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('announcements-dialog-header'),
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.campaign_outlined, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish ? 'Novedades de Hexora' : 'Hexora News & Updates',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  isSpanish
                      ? 'Funciones, mejoras y avisos del servicio'
                      : 'Features, improvements and service notices',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (showAdmin)
            IconButton(
              tooltip: isSpanish ? 'Administrar novedades' : 'Manage updates',
              onPressed: onAdmin,
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          IconButton(
            tooltip: isSpanish ? 'Cerrar' : 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard(
      {required this.item, required this.isSpanish, required this.onTap});
  final Announcement item;
  final bool isSpanish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            if (item.imageUrl?.isNotEmpty == true) ...[
              ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(item.imageUrl!,
                      width: 92,
                      height: 82,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 0))),
              const SizedBox(width: 14),
            ],
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    if (item.isPinned)
                      Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.push_pin_outlined,
                              size: 16, color: cs.primary)),
                    Expanded(
                        child: Text(item.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 5),
                  Text(item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  if (item.publishedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                        DateFormat.yMMMd(isSpanish ? 'es' : 'en')
                            .format(item.publishedAt!),
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ])),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }
}

class AnnouncementAdminScreen extends StatefulWidget {
  const AnnouncementAdminScreen({super.key});
  @override
  State<AnnouncementAdminScreen> createState() =>
      _AnnouncementAdminScreenState();
}

class _AnnouncementAdminScreenState extends State<AnnouncementAdminScreen> {
  final _api = AnnouncementsApi();
  Future<AnnouncementPage>? _request;
  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reload();
  }

  void _reload() {
    _request =
        _api.list(language: _isSpanish ? 'es' : 'en', admin: true, limit: 50);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title:
                Text(_isSpanish ? 'Administrar novedades' : 'Manage updates')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add),
          label: Text(_isSpanish ? 'Nueva' : 'New'),
        ),
        body: FutureBuilder<AnnouncementPage>(
            future: _request,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                itemCount: snapshot.data!.items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = snapshot.data!.items[index];
                  return ListTile(
                    title: Text(item.title),
                    subtitle: Text(
                        '${item.status} · ${item.visibility} · ${item.category}'),
                    onTap: () => _edit(item),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) => _action(item, action),
                      itemBuilder: (_) => [
                        if (item.status == 'draft')
                          const PopupMenuItem(
                              value: 'publish', child: Text('Publish')),
                        if (item.status != 'archived')
                          const PopupMenuItem(
                              value: 'archive', child: Text('Archive')),
                      ],
                    ),
                  );
                },
              );
            }),
      );

  Future<void> _action(Announcement item, String action) async {
    try {
      if (action == 'publish') {
        await _api.publish(item.id);
      } else {
        await _api.archive(item.id);
      }
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _edit([Announcement? item]) async {
    final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _AnnouncementEditor(api: _api, item: item));
    if (saved == true) _reload();
  }
}

class _AnnouncementEditor extends StatefulWidget {
  const _AnnouncementEditor({required this.api, this.item});
  final AnnouncementsApi api;
  final Announcement? item;
  @override
  State<_AnnouncementEditor> createState() => _AnnouncementEditorState();
}

class _AnnouncementEditorState extends State<_AnnouncementEditor> {
  final _key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  String _category = 'general';
  String _visibility = 'authenticated';
  final Set<String> _placements = {'news', 'home'};
  bool _pinned = false;
  bool _importantNotification = false;
  bool _saving = false;

  String _translation(String field, String language) {
    final value = widget.item?.translations?[field];
    return value is Map ? (value[language] ?? '').toString() : '';
  }

  @override
  void initState() {
    super.initState();
    _fields = {
      for (final field in [
        'titleEn',
        'titleEs',
        'descriptionEn',
        'descriptionEs',
        'contentEn',
        'contentEs',
        'imageUrl',
        'videoUrl',
        'expiresAt'
      ])
        field: TextEditingController(),
    };
    final item = widget.item;
    if (item != null) {
      _fields['titleEn']!.text = _translation('title', 'en');
      _fields['titleEs']!.text = _translation('title', 'es');
      _fields['descriptionEn']!.text = _translation('description', 'en');
      _fields['descriptionEs']!.text = _translation('description', 'es');
      _fields['contentEn']!.text = _translation('content', 'en');
      _fields['contentEs']!.text = _translation('content', 'es');
      _fields['imageUrl']!.text = item.imageUrl ?? '';
      _fields['videoUrl']!.text = item.videoUrl ?? '';
      _fields['expiresAt']!.text =
          item.expiresAt?.toUtc().toIso8601String() ?? '';
      _category = item.category;
      _visibility = item.visibility;
      _placements
        ..clear()
        ..addAll(item.placements);
      _pinned = item.isPinned;
      _importantNotification = item.notificationPriority == 'important';
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
            widget.item == null ? 'New announcement' : 'Edit announcement'),
        content: SizedBox(
            width: 680,
            child: Form(
                key: _key,
                child: SingleChildScrollView(
                    child: Column(children: [
                  _input('titleEn', 'Title (English)'),
                  _input('titleEs', 'Título (Español)'),
                  _input('descriptionEn', 'Description (English)', lines: 2),
                  _input('descriptionEs', 'Descripción (Español)', lines: 2),
                  _input('contentEn', 'Content (English)', lines: 5),
                  _input('contentEs', 'Contenido (Español)', lines: 5),
                  Row(children: [
                    Expanded(
                        child: DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration:
                                const InputDecoration(labelText: 'Category'),
                            items: [
                              'feature',
                              'improvement',
                              'bug_fix',
                              'maintenance',
                              'general'
                            ]
                                .map((v) =>
                                    DropdownMenuItem(value: v, child: Text(v)))
                                .toList(),
                            onChanged: (v) => _category = v!)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: DropdownButtonFormField<String>(
                            initialValue: _visibility,
                            decoration:
                                const InputDecoration(labelText: 'Visibility'),
                            items: ['public', 'authenticated']
                                .map((v) =>
                                    DropdownMenuItem(value: v, child: Text(v)))
                                .toList(),
                            onChanged: (v) => _visibility = v!)),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 6,
                      children: [
                        'authentication',
                        'home',
                        'news',
                        'notifications',
                        'mobile'
                      ]
                          .map((value) => FilterChip(
                                label: Text(value),
                                selected: _placements.contains(value),
                                onSelected: (selected) => setState(() {
                                  if (selected) {
                                    _placements.add(value);
                                  } else if (_placements.length > 1) {
                                    _placements.remove(value);
                                  }
                                }),
                              ))
                          .toList()),
                  _input('imageUrl', 'Image URL (HTTPS)', required: false),
                  _input('videoUrl', 'YouTube URL', required: false),
                  _input('expiresAt', 'Expires at (optional ISO date)',
                      required: false),
                  SwitchListTile(
                      value: _pinned,
                      onChanged: (v) => setState(() => _pinned = v),
                      title: const Text('Pin announcement')),
                  SwitchListTile(
                    value: _importantNotification,
                    onChanged: (value) => setState(() {
                      _importantNotification = value;
                      if (value) _placements.add('notifications');
                    }),
                    title: const Text('Notify users'),
                    subtitle:
                        const Text('Use only for important announcements'),
                  ),
                ])))),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          OutlinedButton(
              onPressed: _saving ? null : _preview,
              child: const Text('Preview')),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save draft')),
        ],
      );

  Widget _input(String key, String label,
          {int lines = 1, bool required = true}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
            controller: _fields[key],
            maxLines: lines,
            decoration: InputDecoration(
                labelText: label, border: const OutlineInputBorder()),
            validator: required
                ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
                : null),
      );

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.saveDraft(id: widget.item?.id, data: {
        'title': {
          'en': _fields['titleEn']!.text,
          'es': _fields['titleEs']!.text
        },
        'description': {
          'en': _fields['descriptionEn']!.text,
          'es': _fields['descriptionEs']!.text
        },
        'content': {
          'en': _fields['contentEn']!.text,
          'es': _fields['contentEs']!.text
        },
        'category': _category,
        'visibility': _visibility,
        'placements': _placements.toList(),
        'isPinned': _pinned,
        'notificationPriority': _importantNotification ? 'important' : 'none',
        'imageUrl': _fields['imageUrl']!.text,
        'videoUrl': _fields['videoUrl']!.text,
        'expiresAt': _fields['expiresAt']!.text,
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _preview() async {
    final useSpanish = Localizations.localeOf(context).languageCode == 'es';
    final title = _fields[useSpanish ? 'titleEs' : 'titleEn']!.text.trim();
    final description =
        _fields[useSpanish ? 'descriptionEs' : 'descriptionEn']!.text.trim();
    final content =
        _fields[useSpanish ? 'contentEs' : 'contentEn']!.text.trim();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title.isEmpty ? 'Preview' : title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (description.isNotEmpty)
                    Text(description,
                        style: Theme.of(context).textTheme.titleSmall),
                  if (description.isNotEmpty) const SizedBox(height: 16),
                  Text(content),
                ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState(
      {required this.icon,
      required this.message,
      this.action,
      this.actionLabel});
  final IconData icon;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: action, child: Text(actionLabel!))
            ],
          ])));
}
