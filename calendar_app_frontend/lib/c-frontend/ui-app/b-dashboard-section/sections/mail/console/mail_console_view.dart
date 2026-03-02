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
      const railWidth = 214.0;
      const collapsed = false;
      return SizedBox(
        width: railWidth,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.mailConsoleTitle,
                style:
                    t.bodySmall.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: state._openCompose,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l.mailComposeTitle),
              ),
              const SizedBox(height: 12),
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
                  compact: collapsed,
                  onTap: () {
                    if (state._folder == folder) return;
                    state.update(() {
                      state._folder = folder;
                      state._selectedThreadKey = null;
                      state._showCompose = false;
                      state._showFooterManager = false;
                      state._showTemplateManager = false;
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
                compact: collapsed,
                onTap: state._openFooterManager,
              ),
              const SizedBox(height: 8),
              _SideActionTile(
                icon: Icons.view_list_outlined,
                label: 'Templates',
                compact: collapsed,
                onTap: state._openTemplateManager,
              ),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: itemCount,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
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

    Widget rightPaneContent() {
      return state._showCompose
          ? MailComposeScreen(
              embedded: true,
              onClose: () => state.update(() => state._showCompose = false),
              onSent: () => state.update(() => state._showCompose = false),
            )
          : state._showFooterManager
              ? _FooterManagerPanel(state: state)
              : state._showTemplateManager
                  ? _TemplatesManagerPanel(state: state)
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
                            );
    }

    Widget rightColumn() {
      return Expanded(
        flex: 3,
        child: rightPaneContent(),
      );
    }

    final content = Row(
      children: [
        leftColumn(),
        Expanded(
          child: state._showFooterManager ||
                  state._showTemplateManager ||
                  state._showCompose
              ? FolderSectionCard(
                  label: state._showCompose
                      ? l.mailComposeTitle
                      : state._showFooterManager
                          ? l.mailFooterCreateCta
                          : 'Templates',
                  leftTabOffset: 0,
                  child: rightPaneContent(),
                )
              : FolderSectionCard(
                  label:
                      '${l.mailConsoleTitle} · ${_folderLabel(state._folder, l)}',
                  leftTabOffset: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        middleColumn(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        rightColumn(),
                      ],
                    ),
                  ),
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
