import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/models/announcements/announcement.dart';
import 'package:hexora/services/announcements/announcements_api.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementPanel extends StatefulWidget {
  const AnnouncementPanel({
    super.key,
    required this.placement,
    this.publicOnly = false,
    this.limit = 3,
    this.compact = false,
    this.showHeader = true,
    this.showEmptyState = false,
    this.onViewAll,
  });

  final String placement;
  final bool publicOnly;
  final int limit;
  final bool compact;
  final bool showHeader;
  final bool showEmptyState;
  final VoidCallback? onViewAll;

  @override
  State<AnnouncementPanel> createState() => _AnnouncementPanelState();
}

class _AnnouncementPanelState extends State<AnnouncementPanel> {
  final _api = AnnouncementsApi();
  Future<AnnouncementPage>? _request;
  String? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language =
        Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'es';
    if (_request == null || language != _language) {
      _language = language;
      _request = _api.list(
        language: language,
        placement: widget.placement,
        limit: widget.limit,
        publicOnly: widget.publicOnly,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AnnouncementPage>(
      future: _request,
      builder: (context, snapshot) {
        // Announcement surfaces must never block login or Home.
        final isEs = _language == 'es';
        final items = snapshot.data?.items ?? const <Announcement>[];
        if (items.isEmpty && !widget.showEmptyState) {
          return const SizedBox.shrink();
        }
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeader) ...[
              Row(children: [
                const Icon(Icons.campaign_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      isEs ? 'Novedades de Hexora' : 'What’s new in Hexora',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (widget.onViewAll != null)
                  TextButton(
                    onPressed: widget.onViewAll,
                    child: Text(isEs ? 'Ver todo' : 'View all'),
                  ),
              ]),
              const SizedBox(height: 10),
            ],
            if (items.isEmpty)
              _AnnouncementEmptyState(
                isSpanish: isEs,
                isLoading: isLoading,
              )
            else
              for (var index = 0; index < items.length; index++) ...[
                _AnnouncementCard(
                  announcement: items[index],
                  compact: widget.compact,
                  isSpanish: isEs,
                  onOpen: () => _open(items[index]),
                ),
                if (index != items.length - 1) const SizedBox(height: 8),
              ],
          ],
        );
        if (!widget.publicOnly) return content;
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        );
      },
    );
  }

  Future<void> _open(Announcement announcement) async {
    if (!widget.publicOnly && !announcement.isRead) {
      unawaited(_api.markRead(announcement.id).catchError((_) {}));
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AnnouncementDetails(
          announcement: announcement, isSpanish: _language == 'es'),
    );
  }
}

class _AnnouncementEmptyState extends StatelessWidget {
  const _AnnouncementEmptyState({
    required this.isSpanish,
    required this.isLoading,
  });

  final bool isSpanish;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      key: const ValueKey('announcement-empty-state'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          if (isLoading)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colors.primary,
              ),
            )
          else
            Icon(
              Icons.newspaper_rounded,
              size: 28,
              color: colors.onSurfaceVariant,
            ),
          const SizedBox(height: 10),
          Text(
            isLoading
                ? (isSpanish ? 'Cargando novedades…' : 'Loading updates…')
                : (isSpanish
                    ? 'Las próximas novedades aparecerán aquí.'
                    : 'New updates will appear here.'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard(
      {required this.announcement,
      required this.compact,
      required this.isSpanish,
      required this.onOpen});
  final Announcement announcement;
  final bool compact;
  final bool isSpanish;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(_categoryIcon(announcement.category),
                  size: 20, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(announcement.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700))),
                    if (announcement.isPinned)
                      Icon(Icons.push_pin_outlined,
                          size: 15, color: cs.primary),
                  ]),
                  const SizedBox(height: 3),
                  Text(announcement.description,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  if (announcement.publishedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                        DateFormat.yMMMd(isSpanish ? 'es' : 'en')
                            .format(announcement.publishedAt!),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ])),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ]),
        ),
      ),
    );
  }
}

class _AnnouncementDetails extends StatelessWidget {
  const _AnnouncementDetails(
      {required this.announcement, required this.isSpanish});
  final Announcement announcement;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 4, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (announcement.imageUrl?.isNotEmpty == true) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(announcement.imageUrl!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
                const SizedBox(height: 18),
              ],
              Text(announcement.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(announcement.description,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              SelectableText(announcement.content,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.5)),
              if (announcement.videoUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => launchUrl(Uri.parse(announcement.videoUrl!),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text(isSpanish ? 'Ver vídeo' : 'Watch video'),
                ),
              ],
            ]),
      ),
    );
  }
}

IconData _categoryIcon(String category) => switch (category) {
      'feature' => Icons.auto_awesome_outlined,
      'improvement' => Icons.trending_up_rounded,
      'bug_fix' => Icons.build_circle_outlined,
      'maintenance' => Icons.settings_suggest_outlined,
      _ => Icons.campaign_outlined,
    };
