import 'package:flutter/material.dart';
import 'package:hexora/a-models/telegram/telegram.dart';
import 'package:hexora/l10n/app_localizations.dart';

const _kTelegramBlue = Color(0xFF2AABEE);

/// Displays list of accessible Telegram chats
class TelegramChatListWidget extends StatefulWidget {
  const TelegramChatListWidget({
    super.key,
    required this.chats,
    required this.onChatTap,
    required this.onRefresh,
    this.selectedChatId,
    this.isLoading = false,
    this.error,
  });

  final List<TelegramChat> chats;
  final Function(TelegramChat) onChatTap;
  final VoidCallback onRefresh;
  final String? selectedChatId;
  final bool isLoading;
  final String? error;

  @override
  State<TelegramChatListWidget> createState() => _TelegramChatListWidgetState();
}

class _TelegramChatListWidgetState extends State<TelegramChatListWidget> {
  final _searchController = TextEditingController();
  String _query = '';
  _ChatFilter _filter = _ChatFilter.all;
  bool _archivedExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TelegramChat> _applyFilters(Iterable<TelegramChat> chats) {
    var filtered = List<TelegramChat>.from(chats);
    if (_filter == _ChatFilter.groups) {
      filtered = filtered.where((c) => c.isGroup).toList();
    } else if (_filter == _ChatFilter.channels) {
      filtered = filtered.where((c) => c.isChannel).toList();
    } else if (_filter == _ChatFilter.private) {
      filtered = filtered.where((c) => c.isPrivate).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered
          .where((c) =>
              c.title.toLowerCase().contains(q) ||
              (c.description?.toLowerCase().contains(q) ?? false) ||
              (c.username?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return filtered;
  }

  List<TelegramChat> get _mainChats =>
      _applyFilters(widget.chats.where((c) => !c.isArchivedChat));

  List<TelegramChat> get _archivedChats =>
      _applyFilters(widget.chats.where((c) => c.isArchivedChat));

  int _countForMain(_ChatFilter filter) {
    final chats = widget.chats.where((c) => !c.isArchivedChat);
    switch (filter) {
      case _ChatFilter.groups:
        return chats.where((c) => c.isGroup).length;
      case _ChatFilter.channels:
        return chats.where((c) => c.isChannel).length;
      case _ChatFilter.private:
        return chats.where((c) => c.isPrivate).length;
      case _ChatFilter.all:
        return chats.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final mainChats = _mainChats;
    final archivedChats = _archivedChats;
    final hasAnyChats = mainChats.isNotEmpty || archivedChats.isNotEmpty;
    final showArchivedSection = archivedChats.isNotEmpty;
    final archivedExpanded = _archivedExpanded ||
        _query.isNotEmpty ||
        archivedChats.any((chat) => chat.id == widget.selectedChatId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search + refresh row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: l.telegramSearchChats,
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
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            padding: EdgeInsets.zero,
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
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton.outlined(
                onPressed: widget.isLoading ? null : widget.onRefresh,
                icon: widget.isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Filter chips
        if (widget.chats.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: l.telegramFilterAll,
                  count: _countForMain(_ChatFilter.all),
                  selected: _filter == _ChatFilter.all,
                  onTap: () => setState(() => _filter = _ChatFilter.all),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: l.telegramFilterGroups,
                  count: _countForMain(_ChatFilter.groups),
                  selected: _filter == _ChatFilter.groups,
                  onTap: () => setState(() => _filter = _ChatFilter.groups),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: l.telegramFilterChannels,
                  count: _countForMain(_ChatFilter.channels),
                  selected: _filter == _ChatFilter.channels,
                  onTap: () => setState(() => _filter = _ChatFilter.channels),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: l.telegramFilterPrivate,
                  count: _countForMain(_ChatFilter.private),
                  selected: _filter == _ChatFilter.private,
                  onTap: () => setState(() => _filter = _ChatFilter.private),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Error state
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.error ?? l.telegramChatsLoadError,
                      style:
                          TextStyle(color: cs.onErrorContainer, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Empty / no-results state
        if (!hasAnyChats && !widget.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _query.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 40,
                    color: cs.onSurface.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _query.isNotEmpty
                        ? l.telegramNoChatsMatch(_query)
                        : l.telegramNoChatsAvailable,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (_query.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      child: Text(l.telegramClearSearch),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (showArchivedSection)
                  _ChatSectionHeader(
                    title: l.telegramMainChatsSection,
                    count: mainChats.length,
                  ),
                if (mainChats.isEmpty && archivedChats.isNotEmpty)
                  _SectionInfoBanner(
                    message: l.telegramNoMainChatsInfo,
                  ),
                ..._buildChatRows(mainChats),
                if (showArchivedSection) ...[
                  const SizedBox(height: 12),
                  _ArchiveSectionHeader(
                    label: l.telegramArchivedChats,
                    count: archivedChats.length,
                    expanded: archivedExpanded,
                    onTap: () => setState(
                      () => _archivedExpanded = !_archivedExpanded,
                    ),
                  ),
                  if (archivedExpanded) ...[
                    const SizedBox(height: 6),
                    ..._buildChatRows(archivedChats),
                  ],
                ],
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildChatRows(List<TelegramChat> chats) {
    final widgets = <Widget>[];
    for (var index = 0; index < chats.length; index++) {
      final chat = chats[index];
      widgets.add(
        _ChatListItem(
          chat: chat,
          selected: chat.id == widget.selectedChatId,
          onTap: () => widget.onChatTap(chat),
        ),
      );
      if (index != chats.length - 1) {
        widgets.add(
          Builder(
            builder: (context) {
              final cs = Theme.of(context).colorScheme;
              return Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.35),
              );
            },
          ),
        );
      }
    }
    return widgets;
  }
}

enum _ChatFilter { all, groups, channels, private }

class _ChatSectionHeader extends StatelessWidget {
  const _ChatSectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: _kTelegramBlue.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.72),
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _kTelegramBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _kTelegramBlue,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveSectionHeader extends StatelessWidget {
  const _ArchiveSectionHeader({
    required this.label,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.onSurface.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.archive_outlined,
                size: 17,
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Spacer(),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionInfoBanner extends StatelessWidget {
  const _SectionInfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.62),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? _kTelegramBlue.withValues(alpha: 0.12)
              : cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _kTelegramBlue.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? _kTelegramBlue
                    : cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? _kTelegramBlue.withValues(alpha: 0.75)
                      : cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single chat row
class _ChatListItem extends StatelessWidget {
  const _ChatListItem({
    required this.chat,
    required this.selected,
    required this.onTap,
  });

  final TelegramChat chat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lastMessageLabel = _formatLastMessageDate(chat.lastMessageDate);
    final unreadCount = chat.unreadCount;
    final showUnread = unreadCount > 0;
    final showPinned = chat.isPinned;
    final showArchiveBadge = chat.isArchivedChat;

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
          padding: EdgeInsets.fromLTRB(selected ? 6 : 8, 10, 8, 10),
          child: Row(
            children: [
              // Avatar with type badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _avatarColor(chat.title),
                    ),
                    child: Center(
                      child: Text(
                        chat.title.isNotEmpty
                            ? chat.title[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _typeIcon,
                          size: 10,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showPinned) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.push_pin_rounded,
                            size: 13,
                            color: cs.onSurface.withValues(alpha: 0.38),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lastMessageLabel != null)
                    Text(
                      lastMessageLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.42),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showArchiveBadge) ...[
                        Icon(
                          Icons.archive_outlined,
                          size: 13,
                          color: cs.onSurface.withValues(alpha: 0.34),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (showUnread)
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
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: cs.onSurface.withValues(alpha: 0.3),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    final desc = chat.description?.trim();
    if (desc != null && desc.isNotEmpty) return desc;
    final username = chat.username?.trim();
    if (username != null && username.isNotEmpty) return '@$username';
    if (chat.membersCount != null) {
      final count = chat.membersCount!;
      final label = chat.isChannel ? 'subscribers' : 'members';
      return '$count $label';
    }
    return chat.typeLabel;
  }

  IconData get _typeIcon {
    if (chat.isForumChat) return Icons.forum_outlined;
    if (chat.isChannel) return Icons.campaign_rounded;
    if (chat.isGroup) return Icons.group_rounded;
    return Icons.person_rounded;
  }

  String? _formatLastMessageDate(DateTime? value) {
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

  static Color _avatarColor(String title) {
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
    return palette[title.hashCode.abs() % palette.length];
  }
}

/// Chat detail bottom sheet / dialog content
class TelegramChatDetailSheet extends StatelessWidget {
  const TelegramChatDetailSheet({
    super.key,
    required this.chat,
    this.detail,
    this.isLoadingDetail = false,
    this.onExport,
  });

  final TelegramChat chat;
  final TelegramChatDetail? detail;
  final bool isLoadingDetail;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chat header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ChatListItem._avatarColor(chat.title),
                ),
                child: Center(
                  child: Text(
                    chat.title.isNotEmpty ? chat.title[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          _typeIcon,
                          size: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chat.typeLabel,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (chat.description != null && chat.description!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                chat.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 20),

          // Stats grid
          if (isLoadingDetail)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            _StatsGrid(chat: chat, detail: detail),

          // Export button
          if (onExport != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: Text(l.telegramExport),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTelegramBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData get _typeIcon {
    if (chat.isChannel) return Icons.campaign_rounded;
    if (chat.isGroup) return Icons.group_rounded;
    return Icons.person_rounded;
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.chat, this.detail});

  final TelegramChat chat;
  final TelegramChatDetail? detail;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = <_StatItem>[
      if (chat.membersCount != null)
        _StatItem(
          icon: Icons.people_outline_rounded,
          label: chat.isChannel
              ? l.telegramFilterChannels
              : l.telegramFilterGroups,
          value: _fmt(chat.membersCount!),
        ),
      if (detail != null) ...[
        _StatItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Messages',
          value: _fmt(detail!.messageCount),
        ),
        _StatItem(
          icon: Icons.image_outlined,
          label: 'Photos',
          value: _fmt(detail!.photoCount),
        ),
        _StatItem(
          icon: Icons.videocam_outlined,
          label: 'Videos',
          value: _fmt(detail!.videoCount),
        ),
        _StatItem(
          icon: Icons.insert_drive_file_outlined,
          label: 'Documents',
          value: _fmt(detail!.documentCount),
        ),
        if (detail!.mediaCount > 0)
          _StatItem(
            icon: Icons.perm_media_outlined,
            label: 'Total media',
            value: _fmt(detail!.mediaCount),
          ),
      ],
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) => _StatTile(item: item)).toList(),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            item.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}
