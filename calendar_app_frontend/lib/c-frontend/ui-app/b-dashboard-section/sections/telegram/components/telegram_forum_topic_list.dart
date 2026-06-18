import 'package:flutter/material.dart';
import 'package:hexora/a-models/telegram/telegram.dart';
import 'package:hexora/l10n/app_localizations.dart';

const _kTelegramBlue = Color(0xFF2AABEE);

class TelegramForumTopicListWidget extends StatefulWidget {
  const TelegramForumTopicListWidget({
    super.key,
    required this.chat,
    required this.topics,
    required this.onTopicTap,
    required this.onRefresh,
    this.selectedTopicId,
    this.isLoading = false,
    this.error,
  });

  final TelegramChat chat;
  final List<TelegramForumTopic> topics;
  final ValueChanged<TelegramForumTopic> onTopicTap;
  final VoidCallback onRefresh;
  final String? selectedTopicId;
  final bool isLoading;
  final String? error;

  @override
  State<TelegramForumTopicListWidget> createState() =>
      _TelegramForumTopicListWidgetState();
}

class _TelegramForumTopicListWidgetState
    extends State<TelegramForumTopicListWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TelegramForumTopic> get _filteredTopics {
    if (_query.trim().isEmpty) {
      return widget.topics;
    }
    final query = _query.trim().toLowerCase();
    return widget.topics.where((topic) {
      return topic.displayName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final topics = _filteredTopics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _kTelegramBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.forum_rounded,
                size: 17,
                color: _kTelegramBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.telegramTopics,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Text(
                    l.telegramBrowseTopicsIn(widget.chat.title),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton.outlined(
                onPressed: widget.isLoading ? null : widget.onRefresh,
                icon: widget.isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: l.telegramSearchTopics,
              hintStyle: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close_rounded, size: 16),
                    )
                  : null,
              filled: true,
              fillColor: cs.onSurface.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _kTelegramBlue.withValues(alpha: 0.45),
                  width: 1.4,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.error != null) ...[
          _TopicErrorBanner(
            message: widget.error!,
            onRetry: widget.onRefresh,
          ),
          const SizedBox(height: 10),
        ],
        if (widget.isLoading && topics.isEmpty)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: _kTelegramBlue,
              ),
            ),
          )
        else if (!widget.isLoading && topics.isEmpty)
          Expanded(
            child: _TopicEmptyState(
              hasQuery: _query.trim().isNotEmpty,
              onClearSearch: _query.trim().isNotEmpty
                  ? () {
                      _searchController.clear();
                      setState(() => _query = '');
                    }
                  : null,
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: topics.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.32),
              ),
              itemBuilder: (context, index) {
                final topic = topics[index];
                return _TelegramForumTopicRow(
                  topic: topic,
                  selected: topic.forumTopicId == widget.selectedTopicId,
                  onTap: () => widget.onTopicTap(topic),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TelegramForumTopicRow extends StatelessWidget {
  const _TelegramForumTopicRow({
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  final TelegramForumTopic topic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final unread = topic.unreadCount;
    final timeLabel = _formatLastActivity(topic.lastMessageAt);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: selected
                ? _kTelegramBlue.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border(
                    left: BorderSide(
                      color: _kTelegramBlue.withValues(alpha: 0.7),
                      width: 2.5,
                    ),
                  )
                : null,
          ),
          padding: EdgeInsets.fromLTRB(selected ? 8 : 10, 10, 10, 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _topicColor(topic.displayName),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  topic.isGeneral ? Icons.forum_outlined : Icons.topic_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (timeLabel != null)
                          Text(
                            timeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.42),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _subtitleLabel(l),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                        if (topic.isPinned) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.push_pin_rounded,
                            size: 12,
                            color: cs.onSurface.withValues(alpha: 0.35),
                          ),
                        ],
                        if (topic.isClosed) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 12,
                            color: cs.onSurface.withValues(alpha: 0.35),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (unread > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _kTelegramBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.28),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitleLabel(AppLocalizations l) {
    if (topic.isGeneral) return l.telegramGeneralTopic;
    if (topic.isHidden) return l.telegramHiddenTopic;
    return l.telegramForumTopicLabel;
  }

  String? _formatLastActivity(DateTime? value) {
    if (value == null) return null;
    final local = value.toLocal();
    final now = DateTime.now();
    final sameDay = now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;
    if (sameDay) {
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    if (now.year == local.year) {
      return '${local.day}/${local.month}';
    }
    return '${local.day}/${local.month}/${local.year}';
  }

  static Color _topicColor(String label) {
    const palette = [
      Color(0xFF5B8DEF),
      Color(0xFF3DBF7A),
      Color(0xFFEF8C3D),
      Color(0xFF9B59B6),
      Color(0xFFE74C3C),
      Color(0xFF1ABC9C),
      Color(0xFF2AABEE),
      Color(0xFFE91E8C),
    ];
    return palette[label.hashCode.abs() % palette.length];
  }
}

class _TopicErrorBanner extends StatelessWidget {
  const _TopicErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onErrorContainer,
                  ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(l.telegramRetry),
          ),
        ],
      ),
    );
  }
}

class _TopicEmptyState extends StatelessWidget {
  const _TopicEmptyState({
    required this.hasQuery,
    this.onClearSearch,
  });

  final bool hasQuery;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off_rounded : Icons.forum_outlined,
              size: 38,
              color: cs.onSurface.withValues(alpha: 0.24),
            ),
            const SizedBox(height: 10),
            Text(
              hasQuery ? l.telegramNoTopicsMatch : l.telegramNoTopicsFound,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? l.telegramNoTopicsMatchBody
                  : l.telegramNoTopicsFoundBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
            if (hasQuery && onClearSearch != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onClearSearch,
                child: Text(l.telegramClearSearch),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
