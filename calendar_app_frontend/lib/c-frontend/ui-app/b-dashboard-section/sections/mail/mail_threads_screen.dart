import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/mail/mail_folder.dart';
import 'package:hexora/a-models/mail/mail_thread.dart';
import 'package:hexora/b-backend/mail/domain/mail_domain.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class MailThreadsScreen extends StatefulWidget {
  const MailThreadsScreen({super.key, this.initialFolder = MailFolder.inbox});

  final MailFolder initialFolder;

  @override
  State<MailThreadsScreen> createState() => _MailThreadsScreenState();
}

class _MailThreadsScreenState extends State<MailThreadsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<MailFolder> _folders;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _folders = MailFolder.values;
    _tabController = TabController(
      length: _folders.length,
      vsync: this,
      initialIndex: _folders.indexOf(widget.initialFolder),
    );
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleLoadThreads(widget.initialFolder, refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final folder = _folders[_tabController.index];
    _scheduleLoadThreads(folder, refresh: true);
  }

  void _scheduleLoadThreads(MailFolder folder, {required bool refresh}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      context.read<MailDomain>().loadThreads(folder: folder, refresh: refresh);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mailThreadsTitle),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelStyle: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'INBOX'),
              Tab(text: 'Sent'),
              Tab(text: 'Archive'),
              Tab(text: 'Trash'),
              Tab(text: 'Spam'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _folders
                  .map((folder) => _ThreadsList(folder: folder))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadsList extends StatefulWidget {
  const _ThreadsList({required this.folder});

  final MailFolder folder;

  @override
  State<_ThreadsList> createState() => _ThreadsListState();
}

class _ThreadsListState extends State<_ThreadsList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.maxScrollExtent - position.pixels > 220) return;
    final domain = context.read<MailDomain>();
    final state = domain.threadsState;
    if (state.folder != widget.folder) return;
    if (state.loading || state.loadingMore) return;
    if (!state.hasMore) return;
    domain.loadThreads(folder: widget.folder, refresh: false);
  }

  Future<void> _refresh() async {
    await context
        .read<MailDomain>()
        .loadThreads(folder: widget.folder, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Consumer<MailDomain>(
      builder: (context, domain, _) {
        final state = domain.threadsState;
        final isActive = state.folder == widget.folder;
        final threads = isActive ? state.threads : const <MailThread>[];

        if (isActive && state.loading && threads.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (isActive && state.error != null && threads.isEmpty) {
          return Center(
            child: Text(
              state.error!,
              style: t.bodySmall.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (isActive && !state.loading && threads.isEmpty) {
          return Center(
            child: Text(
              l.mailThreadsEmpty,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          );
        }

        final itemCount = threads.length +
            ((isActive && state.loadingMore) ? 1 : 0);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index >= threads.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final thread = threads[index];
              return _ThreadRow(
                thread: thread,
                onTap: () => Navigator.of(context)
                    .pushNamed('/mail/threads/${thread.threadKey}'),
              );
            },
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread, required this.onTap});

  final MailThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final subject = thread.subject.trim().isEmpty
        ? l.mailDetailNoSubject
        : thread.subject.trim();
    final participants = _shortParticipants(thread.participants);
    final dateLabel = _formatRelativeDate(thread.latestDate);

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      participants,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            dateLabel,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (thread.unreadCount > 0)
                _CountBadge(
                  label: '${thread.unreadCount}',
                  color: cs.primary,
                  textColor: cs.onPrimary,
                ),
              if (thread.unreadCount > 0) const SizedBox(width: 6),
              _CountBadge(
                label: '${thread.messageCount}',
                color: cs.surfaceContainerHighest,
                textColor: cs.onSurfaceVariant,
                border: BorderSide(color: cs.outlineVariant),
              ),
            ],
          ),
          IconButton(
            tooltip: l.mailThreadOpenThread,
            icon: const Icon(Icons.open_in_new, size: 18),
            color: cs.onSurfaceVariant,
            onPressed: onTap,
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

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.label,
    required this.color,
    required this.textColor,
    this.border,
  });

  final String label;
  final Color color;
  final Color textColor;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.fromBorderSide(border!),
      ),
      child: Text(
        label,
        style: AppTypography.of(context)
            .bodySmall
            .copyWith(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _shortParticipants(List<String> participants) {
  if (participants.isEmpty) return '';
  if (participants.length <= 2) return participants.join(', ');
  final rest = participants.length - 2;
  return '${participants.take(2).join(', ')} +$rest';
}

String _formatRelativeDate(DateTime? date) {
  if (date == null) return '-';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return '${weeks}w';
  final months = (diff.inDays / 30).floor();
  if (months < 12) return '${months}mo';
  final years = (diff.inDays / 365).floor();
  return '${years}y';
}
