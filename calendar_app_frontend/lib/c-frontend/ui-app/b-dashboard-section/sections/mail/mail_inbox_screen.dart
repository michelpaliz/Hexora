import 'package:flutter/material.dart';
import 'package:hexora/a-models/mail/mail_folder.dart';
import 'package:hexora/a-models/mail/mail_message.dart';
import 'package:hexora/b-backend/mail/domain/mail_domain.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MailInboxScreen extends StatefulWidget {
  const MailInboxScreen({super.key, this.initialFolder = MailFolder.inbox});

  final MailFolder initialFolder;

  @override
  State<MailInboxScreen> createState() => _MailInboxScreenState();
}

class _MailInboxScreenState extends State<MailInboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<MailFolder> _folders;
  final _searchController = TextEditingController();
  String? _searchError;

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
      final domain = context.read<MailDomain>();
      domain.currentFolder = widget.initialFolder;
      domain.updateSearchFilters(
        domain.searchState.filters.copyWith(folder: widget.initialFolder),
      );
      final state = domain.folderState(widget.initialFolder);
      if (!state.hasRequested) {
        domain.loadFolder(widget.initialFolder);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final folder = _folders[_tabController.index];
    final domain = context.read<MailDomain>();
    domain.currentFolder = folder;
    domain.updateSearchFilters(
      domain.searchState.filters.copyWith(folder: folder),
    );
    final state = domain.folderState(folder);
    if (!state.hasRequested) {
      domain.loadFolder(folder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mailInboxTitle),
        actions: [
          IconButton(
            tooltip: l.mailComposeTitle,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/mail/compose'),
          ),
          IconButton(
            tooltip: l.mailThreadsTitle,
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/mail/threads'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.mailSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: l.mailSearchClear,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<MailDomain>()
                              .updateSearchQuery('');
                          setState(() {
                            _searchError = null;
                          });
                        },
                      ),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                context.read<MailDomain>().updateSearchQuery(value);
                if (_searchError != null) {
                  setState(() => _searchError = null);
                } else {
                  setState(() {});
                }
              },
              onSubmitted: (_) => _triggerSearch(),
            ),
          ),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _searchError!,
                  style: t.bodySmall.copyWith(color: cs.error),
                ),
              ),
            ),
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
            child: Consumer<MailDomain>(
              builder: (context, domain, _) {
                final hasQuery =
                    _searchController.text.trim().isNotEmpty;
                if (hasQuery) {
                  return Column(
                    children: [
                      _SearchFilters(
                        unreadOnly: domain.searchState.filters.unreadOnly,
                        dateRange: _buildDateRange(
                          domain.searchState.filters.after,
                          domain.searchState.filters.before,
                        ),
                        onToggleUnread: (value) {
                          final filters = domain.searchState.filters
                              .copyWith(unreadOnly: value);
                          domain.updateSearchFilters(filters);
                          _triggerSearch();
                        },
                        onPickDateRange: () =>
                            _pickDateRange(domain.searchState.filters),
                        onClearDates: () {
                          final filters = domain.searchState.filters
                              .copyWith(after: null, before: null);
                          domain.updateSearchFilters(filters);
                          _triggerSearch();
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: MailSearchResultsList(
                          onOpenMessage: _openMessage,
                        ),
                      ),
                    ],
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: _folders
                      .map(
                        (folder) => MailFolderList(
                          folder: folder,
                          onOpenMessage: _openMessage,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openMessage(String id) {
    Navigator.of(context).pushNamed('/mail/$id');
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    if (query.length < 2) {
      setState(() {
        _searchError = AppLocalizations.of(context)!.mailSearchMinChars;
      });
      return;
    }
    setState(() => _searchError = null);
    context.read<MailDomain>().runSearch(refresh: true);
  }

  String? _buildDateRange(DateTime? after, DateTime? before) {
    if (after == null || before == null) return null;
    final l = AppLocalizations.of(context)!;
    final start = DateFormat.yMMMd(l.localeName).format(after);
    final end = DateFormat.yMMMd(l.localeName).format(before);
    return '$start – $end';
  }

  Future<void> _pickDateRange(MailSearchFilters filters) async {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: (filters.after != null && filters.before != null)
          ? DateTimeRange(start: filters.after!, end: filters.before!)
          : null,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      helpText: l.mailSearchDateRange,
    );
    if (picked == null) return;
    final nextFilters = filters.copyWith(
      after: picked.start,
      before: picked.end,
    );
    context.read<MailDomain>().updateSearchFilters(nextFilters);
    _triggerSearch();
  }
}

class MailFolderList extends StatefulWidget {
  const MailFolderList({
    super.key,
    required this.folder,
    required this.onOpenMessage,
  });

  final MailFolder folder;
  final ValueChanged<String> onOpenMessage;

  @override
  State<MailFolderList> createState() => _MailFolderListState();
}

class _MailFolderListState extends State<MailFolderList>
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
    final state = domain.folderState(widget.folder);
    if (state.loadingMore || state.loading) return;
    if (!state.hasMore) return;
    domain.loadMoreFolder(widget.folder);
  }

  Future<void> _refresh() async {
    await context.read<MailDomain>().refreshFolder(widget.folder);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Consumer<MailDomain>(
      builder: (context, domain, _) {
        final state = domain.folderState(widget.folder);
        final messages = state.messages;

        if (state.loading && messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && messages.isEmpty) {
          return Center(
            child: Text(
              state.error!,
              style: t.bodySmall.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!state.loading && messages.isEmpty) {
          return Center(
            child: Text(
              'No messages found.',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          );
        }

        final itemCount = messages.length + (state.loadingMore ? 1 : 0);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index >= messages.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final message = messages[index];
              return _MailMessageRow(
                message: message,
                onTap: () => widget.onOpenMessage(message.id),
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

class _MailMessageRow extends StatelessWidget {
  const _MailMessageRow({
    required this.message,
    required this.onTap,
  });

  final MailMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final subject = message.subject.trim().isEmpty
        ? '(no subject)'
        : message.subject.trim();
    final snippet = message.snippet?.trim() ?? '';
    final dateLabel = _formatRelativeDate(message.date);

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
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6, right: 10),
                decoration: BoxDecoration(
                  color: message.unread ? cs.primary : cs.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.fromAddress.isEmpty
                          ? 'Unknown sender'
                          : message.fromAddress,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject,
                      style: t.bodyMedium.copyWith(
                        fontWeight:
                            message.unread ? FontWeight.w700 : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (snippet.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        snippet,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateLabel,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (message.hasAttachments)
                    Icon(
                      Icons.attach_file,
                      size: 18,
                      color: cs.onSurfaceVariant,
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

class MailSearchResultsList extends StatefulWidget {
  const MailSearchResultsList({
    super.key,
    required this.onOpenMessage,
  });

  final ValueChanged<String> onOpenMessage;

  @override
  State<MailSearchResultsList> createState() => _MailSearchResultsListState();
}

class _MailSearchResultsListState extends State<MailSearchResultsList> {
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
    final state = domain.searchState;
    if (state.loading || state.loadingMore) return;
    if (!state.hasMore) return;
    domain.runSearch(refresh: false);
  }

  Future<void> _refresh() async {
    final domain = context.read<MailDomain>();
    final query = domain.searchState.query.trim();
    if (query.length < 2) return;
    await domain.runSearch(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Consumer<MailDomain>(
      builder: (context, domain, _) {
        final state = domain.searchState;
        final results = state.results;
        final query = state.query.trim();
        if (query.isNotEmpty && query.length < 2) {
          return Center(
            child: Text(
              l.mailSearchMinChars,
              style: t.bodySmall.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (state.loading && results.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && results.isEmpty) {
          final error = state.error!;
          final displayError = error.contains('at least 2')
              ? l.mailSearchMinChars
              : error;
          return Center(
            child: Text(
              displayError,
              style: t.bodySmall.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!state.loading && results.isEmpty) {
          return Center(
            child: Text(
              l.mailSearchNoResults,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          );
        }

        final itemCount = results.length + (state.loadingMore ? 1 : 0);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index >= results.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final message = results[index];
              return _MailMessageRow(
                message: message,
                onTap: () => widget.onOpenMessage(message.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _SearchFilters extends StatelessWidget {
  const _SearchFilters({
    required this.unreadOnly,
    required this.dateRange,
    required this.onToggleUnread,
    required this.onPickDateRange,
    required this.onClearDates,
  });

  final bool unreadOnly;
  final String? dateRange;
  final ValueChanged<bool> onToggleUnread;
  final VoidCallback onPickDateRange;
  final VoidCallback onClearDates;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: Text(l.mailSearchUnreadOnly),
            selected: unreadOnly,
            onSelected: onToggleUnread,
          ),
          ActionChip(
            label: Text(dateRange ?? l.mailSearchDateRange),
            avatar: const Icon(Icons.date_range, size: 18),
            onPressed: onPickDateRange,
          ),
          if (dateRange != null)
            ActionChip(
              label: Text(l.mailSearchClearDates),
              avatar: const Icon(Icons.close_rounded, size: 18),
              onPressed: onClearDates,
            ),
        ],
      ),
    );
  }
}
