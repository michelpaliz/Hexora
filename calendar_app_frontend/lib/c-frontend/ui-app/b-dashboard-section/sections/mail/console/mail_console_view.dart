part of '../mail_console_screen.dart';

class _MailConsoleView extends StatelessWidget {
  const _MailConsoleView({required this.state});

  final _MailConsoleScreenState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final domain = context.watch<MailDomain>();
    final threadsState = domain.threadsState;
    final threadState = state._selectedThreadKey == null
        ? null
        : domain.threadState(state._selectedThreadKey!);
    final selectedThread = threadState?.thread;

    Widget leftColumn() {
      final railWidth = state._leftCollapsed ? 68.0 : 240.0;
      return Container(
        width: railWidth,
        padding: const EdgeInsets.fromLTRB(14, 16, 12, 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border(
            right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: state._leftCollapsed
                      ? const SizedBox.shrink()
                      : Text(
                          l.mailConsoleTitle,
                          style:
                              t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                        ),
                ),
                IconButton(
                  tooltip: state._leftCollapsed ? 'Expand' : 'Collapse',
                  icon: Icon(
                    state._leftCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                  ),
                  onPressed: () => state.setState(
                    () => state._leftCollapsed = !state._leftCollapsed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (state._leftCollapsed)
              IconButton(
                tooltip: l.mailComposeTitle,
                icon: const Icon(Icons.edit_outlined),
                onPressed: state._openCompose,
              )
            else
              FilledButton.icon(
                onPressed: state._openCompose,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l.mailComposeTitle),
              ),
            const SizedBox(height: 18),
            if (!state._leftCollapsed)
              Text(
                l.mailConsoleFoldersTitle,
                style: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 8),
            ...MailFolder.values.map(
              (folder) => _FolderNavTile(
                label: _folderLabel(folder, l),
                icon: _folderIcon(folder),
                selected: state._folder == folder,
                compact: state._leftCollapsed,
                onTap: () {
                  if (state._folder == folder) return;
                  state.setState(() {
                    state._folder = folder;
                    state._selectedThreadKey = null;
                    state._showCompose = false;
                    state._showFooterManager = false;
                  });
                  state._syncRoute();
                  state._loadThreads(refresh: true);
                },
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            _SideActionTile(
              icon: Icons.description_outlined,
              label: l.mailFooterCreateCta,
              compact: state._leftCollapsed,
              onTap: state._openFooterManager,
            ),
          ],
        ),
      );
    }

    Widget threadList() {
      final threads = threadsState.folder == state._folder
          ? threadsState.threads
          : const <MailThread>[];
      if (threadsState.loading && threads.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (threadsState.error != null && threads.isEmpty) {
        return _EmptyCard(
          title: l.mailConsoleLoadError,
          subtitle: l.tryAgain,
          icon: Icons.cloud_off_outlined,
          actionLabel: l.refreshAction,
          onAction: () => state._loadThreads(refresh: true),
        );
      }
      if (!threadsState.loading && threads.isEmpty) {
        return _EmptyCard(
          title: l.mailThreadsEmpty,
          subtitle: l.mailConsoleSelectThread,
          icon: Icons.inbox_outlined,
          actionLabel: l.mailComposeTitle,
          onAction: state._openCompose,
        );
      }

      final itemCount = threads.length + (threadsState.loadingMore ? 1 : 0);

      return ListView.separated(
        controller: state._threadScroll,
        padding: const EdgeInsets.all(12),
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
            selected: thread.threadKey == state._selectedThreadKey,
            onTap: () => state._selectThread(thread.threadKey),
          );
        },
      );
    }

    Widget middleColumn() {
      return Expanded(
        flex: 2,
        child: Column(
          children: [
            _ThreadToolbar(
              folder: state._folder,
              hasSelection: selectedThread != null,
              hasUnread: selectedThread?.messages.any((m) => m.unread) ?? false,
              onRefresh: state._refreshAll,
              onToggleRead: () => state._markSelectedRead(
                unread:
                    !(selectedThread?.messages.any((m) => m.unread) ?? false),
              ),
              onArchive: () => state._moveSelectedThread(
                context.read<MailDomain>().archive,
                toastMessage: l.mailDetailArchived,
              ),
              onSpam: () => state._moveSelectedThread(
                context.read<MailDomain>().spam,
                toastMessage: l.mailDetailSpammed,
              ),
              onTrash: () => state._moveSelectedThread(
                context.read<MailDomain>().trash,
                toastMessage: l.mailDetailTrashed,
              ),
            ),
            Expanded(child: threadList()),
          ],
        ),
      );
    }

    Widget rightColumn() {
      return Expanded(
        flex: 3,
        child: state._showCompose
            ? MailComposeScreen(
                embedded: true,
                onClose: () =>
                    state.setState(() => state._showCompose = false),
                onSent: () =>
                    state.setState(() => state._showCompose = false),
              )
            : state._showFooterManager
                ? _FooterManagerPanel(state: state)
                : state._selectedThreadKey == null
                ? Center(child: Text(l.mailConsoleSelectThread))
                : (selectedThread == null)
                    ? (threadState?.error != null)
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l.mailConsoleLoadError),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => context
                                      .read<MailDomain>()
                                      .loadThreadDetail(
                                          state._selectedThreadKey!),
                                  child: Text(l.tryAgain),
                                ),
                              ],
                            ),
                          )
                        : const Center(child: CircularProgressIndicator())
                    : _ConversationPane(
                        thread: selectedThread,
                        onReply: state._sendReply,
                        replyController: state._replyCtrl,
                        sendingReply: state._sendingReply,
                        onDownloadAttachment: (attachment) =>
                            state._downloadAttachment(attachment, domain),
                      ),
      );
    }

    final content = Row(
      children: [
        leftColumn(),
        Expanded(
          child: state._showFooterManager
              ? _FooterManagerPanel(state: state)
              : Row(
                  children: [
                    middleColumn(),
                    Container(
                      width: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                    rightColumn(),
                  ],
                ),
        ),
      ],
    );

    if (state.widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: Text(l.mailConsoleTitle)),
      body: content,
    );
  }
}
