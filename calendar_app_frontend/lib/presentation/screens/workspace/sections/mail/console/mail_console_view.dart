part of '../mail_console_screen.dart';

class _MailConsoleView extends StatelessWidget {
  const _MailConsoleView({required this.state});

  final _MailConsoleScreenState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < CollapsibleSidebar.responsiveBreakpoint) {
          return _buildMobile(context);
        }
        return _buildDesktop(context);
      },
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────────────────

  Widget _buildMailSidebar(
    BuildContext context, {
    bool drawer = false,
    VoidCallback? closeOverlay,
  }) {
    final l = AppLocalizations.of(context)!;

    void invoke(VoidCallback action) {
      closeOverlay?.call();
      action();
    }

    return CollapsibleSidebar(
      title: l.mailConsoleTitle,
      headerIcon: Icons.mail_outline_rounded,
      collapsed: state._leftCollapsed,
      drawer: drawer,
      expandTooltip: l.groupInvoicesNavExpand,
      collapseTooltip: l.groupInvoicesNavCollapse,
      onToggleCollapsed: () => state.update(
        () => state._leftCollapsed = !state._leftCollapsed,
      ),
      primaryAction: CollapsibleSidebarItem(
        key: const ValueKey('mail-compose-action'),
        icon: Icons.edit_outlined,
        label: l.mailComposeTitle,
        onTap: () => invoke(state._openCompose),
      ),
      items: [
        for (final folder in MailFolder.values)
          CollapsibleSidebarItem(
            key: ValueKey('mail-folder-${folder.name}'),
            icon: _folderIcon(folder),
            label: _folderLabel(folder, l),
            selected: state._folder == folder,
            onTap: () => invoke(() => state._selectFolder(folder)),
          ),
      ],
      secondaryItems: [
        CollapsibleSidebarItem(
          key: const ValueKey('mail-footer-action'),
          icon: Icons.description_outlined,
          label: l.mailFooterCreateCta,
          onTap: () => invoke(state._openFooterManager),
        ),
        CollapsibleSidebarItem(
          key: const ValueKey('mail-templates-action'),
          icon: Icons.view_list_outlined,
          label: 'Templates',
          onTap: () => invoke(
            () => unawaited(state._openTemplateManager()),
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final domain = context.watch<MailDomain>();
    final threadsState = domain.threadsState;
    final threadState = state._selectedThreadKey == null
        ? null
        : domain.threadState(state._selectedThreadKey!);
    final selectedThread = threadState?.thread;

    final bool isDetailView = state._selectedThreadKey != null ||
        state._showCompose ||
        state._showFooterManager ||
        state._showTemplateManager;

    void mobileBack() {
      if (state._sendingReply) return;
      if (state._replyTarget != null) {
        state._closeReplyComposer();
        return;
      }
      state.update(() {
        state._selectedThreadKey = null;
        state._showCompose = false;
        state._showFooterManager = false;
        state._showTemplateManager = false;
      });
    }

    String appBarTitle() {
      if (state._showCompose) return l.mailComposeTitle;
      if (state._showFooterManager) return l.mailFooterCreateCta;
      if (state._showTemplateManager) return 'Templates';
      if (state._selectedThreadKey != null) {
        final subject = (selectedThread?.subject ?? '').trim();
        if (subject.isNotEmpty) return subject;
        final msgSubject =
            (selectedThread?.messages.firstOrNull?.subject ?? '').trim();
        return msgSubject.isEmpty ? l.mailDetailNoSubject : msgSubject;
      }
      // At the folder/list level, show which folder you're looking at
      // (e.g. "Bandeja de entrada") instead of the generic "Correo" —
      // avoids a redundant second heading duplicating this in the body.
      return _folderLabel(state._folder, l);
    }

    void openFolderSheet() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.72,
            child: _buildMailSidebar(
              ctx,
              drawer: true,
              closeOverlay: () => Navigator.pop(ctx),
            ),
          ),
        ),
      );
    }

    Widget mobileBody() {
      if (state._showCompose) {
        return MailComposeScreen(
          groupId: state._currentGroupId(),
          embedded: true,
          onClose: mobileBack,
          onSent: mobileBack,
        );
      }
      if (state._showFooterManager) {
        return _FooterManagerPanel(state: state);
      }
      if (state._showTemplateManager) {
        return _TemplatesManagerPanel(state: state);
      }
      if (state._selectedThreadKey != null) {
        if (selectedThread == null) {
          if (threadState?.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.mailConsoleLoadError),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _asyncCallback(
                      () => context
                          .read<MailDomain>()
                          .loadThreadDetail(state._selectedThreadKey!),
                    ),
                    child: Text(l.tryAgain),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        return _ConversationPane(
          thread: selectedThread,
          folder: state._folder,
          replyTarget: state._replyTarget,
          onStartReply: state._startReply,
          onReply: state._sendReply,
          onCloseReply: state._closeReplyComposer,
          replySubjectController: state._replySubjectCtrl,
          replyController: state._replyCtrl,
          replyFocus: state._replyFocus,
          sendingReply: state._sendingReply,
          onDownloadAttachment: _asyncValueChanged(
            (a) => state._downloadAttachment(a, domain),
          ),
          hideSubjectBar: true,
        );
      }
      return _MobileThreadList(state: state, threadsState: threadsState);
    }

    // ── When embedded: inject actions into parent AppBar, no inner Scaffold ──
    if (state.widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!state.mounted) return;
        try {
          context.read<GroupDashboardState>().setMailBarActions(MailBarActions(
                title: appBarTitle(),
                isDetailView: isDetailView,
                onBack: isDetailView ? mobileBack : null,
                onOpenFolderMenu: isDetailView ? null : openFolderSheet,
                onRefresh:
                    isDetailView ? null : _asyncCallback(state._refreshAll),
                onCompose: isDetailView ? null : state._openCompose,
                hasUnread: selectedThread?.messages.any((m) => m.unread),
                onToggleRead: selectedThread != null
                    ? _asyncCallback(
                        () => state._markSelectedRead(
                          unread: !selectedThread.messages.any((m) => m.unread),
                        ),
                      )
                    : null,
                onArchive: selectedThread != null
                    ? _asyncCallback(
                        () => state._moveSelectedThread(
                          context.read<MailDomain>().archive,
                          toastMessage: l.mailDetailArchived,
                        ),
                      )
                    : null,
                onSpam: selectedThread != null
                    ? _asyncCallback(
                        () => state._moveSelectedThread(
                          context.read<MailDomain>().spam,
                          toastMessage: l.mailDetailSpammed,
                        ),
                      )
                    : null,
                onTrash: selectedThread != null
                    ? _asyncCallback(
                        () => state._moveSelectedThread(
                          context.read<MailDomain>().trash,
                          toastMessage: l.mailDetailTrashed,
                        ),
                      )
                    : null,
              ));
        } catch (_) {}
      });

      return PopScope(
        canPop: !isDetailView,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) mobileBack();
        },
        child: mobileBody(),
      );
    }

    // ── Standalone (not embedded): own Scaffold with AppBar ───────────────────
    return PopScope(
      canPop: !isDetailView,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) mobileBack();
      },
      child: Scaffold(
        appBar: SectionAppBar(
          title: appBarTitle(),
          onBack: isDetailView ? mobileBack : null,
          actions: [
            if (!isDetailView) ...[
              IconButton(
                icon: Icon(_folderIcon(state._folder)),
                tooltip: l.mailConsoleFoldersTitle,
                onPressed: openFolderSheet,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l.refreshAction,
                onPressed: _asyncCallback(state._refreshAll),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l.mailComposeTitle,
                onPressed: state._openCompose,
              ),
            ],
          ],
        ),
        drawer: isDetailView
            ? null
            : Drawer(
                child: Builder(
                  builder: (drawerContext) => SafeArea(
                    child: _buildMailSidebar(
                      drawerContext,
                      drawer: true,
                      closeOverlay: () => Navigator.pop(drawerContext),
                    ),
                  ),
                ),
              ),
        body: mobileBody(),
      ),
    );
  }

  // ── Desktop layout ─────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final domain = context.watch<MailDomain>();
    final threadsState = domain.threadsState;
    final threadState = state._selectedThreadKey == null
        ? null
        : domain.threadState(state._selectedThreadKey!);
    final selectedThread = threadState?.thread;

    Widget threadList(BuildContext navContext) {
      final navCs = Theme.of(navContext).colorScheme;
      final folderThreads = threadsState.folder == state._folder
          ? threadsState.threads
          : const <MailThread>[];
      final threads = switch (state._desktopListFilter) {
        1 => folderThreads.where((thread) => thread.unreadCount > 0).toList(),
        2 => folderThreads.where((thread) => thread.important).toList(),
        _ => folderThreads,
      };
      final activeQuery = (threadsState.query ?? '').trim();
      final isThreadSearch = activeQuery.length >= 2;

      if (threadsState.loading && threads.isEmpty) {
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          itemCount: 9,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: navCs.outlineVariant.withValues(alpha: 0.35),
          ),
          itemBuilder: (_, i) => _SkeletonThreadRow(key: ValueKey(i), seed: i),
        );
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
          title:
              isThreadSearch ? l.mailThreadSearchNoResults : l.mailThreadsEmpty,
          subtitle: isThreadSearch
              ? '"$activeQuery" · ${l.mailThreadSearchNoResultsHint}'
              : l.mailConsoleSelectThread,
          icon:
              isThreadSearch ? Icons.search_off_rounded : Icons.inbox_outlined,
          actionLabel: isThreadSearch ? l.mailSearchClear : l.mailComposeTitle,
          onAction:
              isThreadSearch ? state._clearThreadSearch : state._openCompose,
        );
      }

      final itemCount = threads.length + (threadsState.loadingMore ? 1 : 0);

      return ListView.separated(
        controller: state._threadScroll,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: itemCount,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: navCs.outlineVariant.withValues(alpha: 0.35),
        ),
        itemBuilder: (context, index) {
          if (index >= threads.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final thread = threads[index];
          return _ThreadRow(
            thread: thread,
            selected: thread.threadKey == state._selectedThreadKey,
            onTap: _asyncCallback(
              () => state._selectThread(thread.threadKey),
            ),
          );
        },
      );
    }

    void selectListFilter(int index) {
      state.update(() => state._desktopListFilter = index);
      final target = index == 3 ? MailFolder.archive : MailFolder.inbox;
      if (state._folder != target) state._selectFolder(target);
    }

    Widget listTabs(BuildContext navContext) {
      final navTheme = Theme.of(navContext);
      final navCs = navTheme.colorScheme;
      final all = threadsState.folder == state._folder
          ? threadsState.threads
          : const <MailThread>[];
      final unread = all.where((thread) => thread.unreadCount > 0).length;
      final important = all.where((thread) => thread.important).length;
      final tabs = <(String, int?)>[
        ('Todos', state._folder == MailFolder.inbox ? all.length : null),
        ('No leídos', state._folder == MailFolder.inbox ? unread : null),
        ('Importantes', state._folder == MailFolder.inbox ? important : null),
        ('Archivados', state._folder == MailFolder.archive ? all.length : null),
      ];
      return SizedBox(
        height: 46,
        child: Row(
          children: [
            for (var index = 0; index < tabs.length; index++)
              Expanded(
                child: InkWell(
                  key: ValueKey('mail-list-filter-$index'),
                  onTap: () => selectListFilter(index),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: state._desktopListFilter == index
                              ? navCs.primary
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Text(
                      tabs[index].$2 == null
                          ? tabs[index].$1
                          : '${tabs[index].$1} (${tabs[index].$2})',
                      overflow: TextOverflow.ellipsis,
                      style: navTheme.textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: state._desktopListFilter == index
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: state._desktopListFilter == index
                            ? navCs.primary
                            : navCs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget middleColumn(BuildContext navContext) {
      final activeQuery = (threadsState.query ?? '').trim();
      final isSearchActive = activeQuery.length >= 2;
      return Focus(
        focusNode: state._threadListFocus,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            state._navigateThread(1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            state._navigateThread(-1);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            _ThreadToolbar(
              folder: state._folder,
              searchController: state._threadSearchController,
              searching: threadsState.loading &&
                  (threadsState.query ?? '').trim().length >= 2,
              onSearchChanged: state._onThreadSearchChanged,
              onClearSearch: state._clearThreadSearch,
              hasSelection: selectedThread != null,
              hasUnread: selectedThread?.messages.any((m) => m.unread) ?? false,
              onRefresh: _asyncCallback(state._refreshAll),
              onToggleRead: _asyncCallback(
                () => state._markSelectedRead(
                  unread:
                      !(selectedThread?.messages.any((m) => m.unread) ?? false),
                ),
              ),
              onArchive: _asyncCallback(
                () => state._moveSelectedThread(
                  context.read<MailDomain>().archive,
                  toastMessage: l.mailDetailArchived,
                ),
              ),
              onSpam: _asyncCallback(
                () => state._moveSelectedThread(
                  context.read<MailDomain>().spam,
                  toastMessage: l.mailDetailSpammed,
                ),
              ),
              onTrash: _asyncCallback(
                () => state._moveSelectedThread(
                  context.read<MailDomain>().trash,
                  toastMessage: l.mailDetailTrashed,
                ),
              ),
            ),
            if (isSearchActive)
              _ActiveSearchChip(
                query: activeQuery,
                onClear: state._clearThreadSearch,
              ),
            listTabs(navContext),
            Expanded(child: threadList(navContext)),
          ],
        ),
      );
    }

    Widget rightPaneContent() {
      return state._showCompose
          ? MailComposeScreen(
              groupId: state._currentGroupId(),
              embedded: true,
              onClose: () => state.update(() => state._showCompose = false),
              onSent: () => state.update(() => state._showCompose = false),
            )
          : state._showFooterManager
              ? _FooterManagerPanel(state: state)
              : state._showTemplateManager
                  ? _TemplatesManagerPanel(state: state)
                  : state._selectedThreadKey == null
                      ? const _MailReadingEmptyState()
                      : (selectedThread == null)
                          ? (threadState?.error != null)
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(l.mailConsoleLoadError),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: _asyncCallback(
                                          () => context
                                              .read<MailDomain>()
                                              .loadThreadDetail(
                                                state._selectedThreadKey!,
                                              ),
                                        ),
                                        child: Text(l.tryAgain),
                                      ),
                                    ],
                                  ),
                                )
                              : const Center(child: CircularProgressIndicator())
                          : _ConversationPane(
                              thread: selectedThread,
                              folder: state._folder,
                              replyTarget: state._replyTarget,
                              onStartReply: state._startReply,
                              onReply: state._sendReply,
                              onCloseReply: state._closeReplyComposer,
                              replySubjectController: state._replySubjectCtrl,
                              replyController: state._replyCtrl,
                              replyFocus: state._replyFocus,
                              sendingReply: state._sendingReply,
                              onDownloadAttachment: _asyncValueChanged(
                                (attachment) => state._downloadAttachment(
                                  attachment,
                                  domain,
                                ),
                              ),
                            );
    }

    Widget desktopHeader(BuildContext navContext) {
      final navTheme = Theme.of(navContext);
      final navCs = navTheme.colorScheme;
      return Container(
        key: const ValueKey('mail-desktop-header-surface'),
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: navCs.surface,
          border: Border(
            bottom:
                BorderSide(color: navCs.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.mail_outline_rounded, color: navCs.primary, size: 22),
            const SizedBox(width: 10),
            PopupMenuButton<MailFolder>(
              tooltip: l.mailConsoleFoldersTitle,
              onSelected: (folder) {
                state.update(() => state._desktopListFilter =
                    folder == MailFolder.archive ? 3 : 0);
                state._selectFolder(folder);
              },
              itemBuilder: (_) => [
                for (final folder in MailFolder.values)
                  PopupMenuItem(
                    value: folder,
                    child: Row(
                      children: [
                        Icon(_folderIcon(folder), size: 17),
                        const SizedBox(width: 9),
                        Text(_folderLabel(folder, l)),
                      ],
                    ),
                  ),
              ],
              child: Row(
                children: [
                  Text(
                    l.mailConsoleTitle,
                    style: navTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: navCs.onSurfaceVariant),
                ],
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              key: const ValueKey('mail-desktop-more-action'),
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              icon: const Icon(Icons.more_horiz_rounded, size: 20),
              onSelected: (value) {
                if (value == 'footer') {
                  state._openFooterManager();
                } else if (value == 'templates') {
                  unawaited(state._openTemplateManager());
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'footer',
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l.mailFooterCreateCta),
                  ),
                ),
                const PopupMenuItem(
                  value: 'templates',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.view_list_outlined),
                    title: Text('Templates'),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              key: const ValueKey('mail-desktop-compose-action'),
              onPressed: state._openCompose,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                l.localeName.startsWith('es') ? 'Nuevo correo' : 'New email',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ],
        ),
      );
    }

    final content = Column(
      children: [
        if (!state._showCompose)
          NavigationSurface(builder: (context) => desktopHeader(context)),
        Expanded(
          child: state._showFooterManager ||
                  state._showTemplateManager ||
                  state._showCompose
              ? rightPaneContent()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final listWidth =
                        (constraints.maxWidth * 0.41).clamp(440.0, 720.0);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: listWidth,
                          child: NavigationSurface(
                            key: const ValueKey('mail-desktop-list-surface'),
                            builder: (context) => middleColumn(context),
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                        Expanded(child: rightPaneContent()),
                      ],
                    );
                  },
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

// ── Mobile thread list body ───────────────────────────────────────────────────

class _MobileThreadList extends StatelessWidget {
  const _MobileThreadList({
    required this.state,
    required this.threadsState,
  });

  final _MailConsoleScreenState state;
  final MailThreadsState threadsState;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final threads = threadsState.folder == state._folder
        ? threadsState.threads
        : const <MailThread>[];
    final activeQuery = (threadsState.query ?? '').trim();
    final isSearchActive = activeQuery.length >= 2;
    final isThreadSearch = isSearchActive;

    Widget threadListContent() {
      if (threadsState.loading && threads.isEmpty) {
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          itemCount: 9,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.15),
          ),
          itemBuilder: (_, i) => _SkeletonThreadRow(key: ValueKey(i), seed: i),
        );
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
          title:
              isThreadSearch ? l.mailThreadSearchNoResults : l.mailThreadsEmpty,
          subtitle: isThreadSearch
              ? '"$activeQuery" · ${l.mailThreadSearchNoResultsHint}'
              : l.mailConsoleSelectThread,
          icon:
              isThreadSearch ? Icons.search_off_rounded : Icons.inbox_outlined,
          actionLabel: isThreadSearch ? l.mailSearchClear : l.mailComposeTitle,
          onAction:
              isThreadSearch ? state._clearThreadSearch : state._openCompose,
        );
      }

      final itemCount = threads.length + (threadsState.loadingMore ? 1 : 0);

      return ListView.separated(
        key: PageStorageKey(state._folder),
        controller: state._threadScroll,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: itemCount,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: cs.outlineVariant.withValues(alpha: 0.15),
        ),
        itemBuilder: (context, index) {
          if (index >= threads.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final thread = threads[index];
          return _MobileThreadRow(
            thread: thread,
            onTap: _asyncCallback(
              () async {
                FocusScope.of(context).unfocus();
                await state._selectThread(thread.threadKey);
              },
            ),
          );
        },
      );
    }

    return SafeArea(
        top: false,
        child: Column(
          children: [
            // The folder name (e.g. "Bandeja de entrada") is already shown
            // as the app bar title above, so it isn't repeated here.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                controller: state._threadSearchController,
                style: t.bodyLarge?.copyWith(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: l.mailConsoleSearchPlaceholder,
                  hintStyle: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: state._threadSearchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l.mailSearchClear,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: state._clearThreadSearch),
                ),
                textInputAction: TextInputAction.search,
                onChanged: state._onThreadSearchChanged,
                onSubmitted: (value) {
                  FocusScope.of(context).unfocus();
                  state._onThreadSearchChanged(value);
                },
              ),
            ),
            if (threadsState.loading && threads.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
            if (isSearchActive)
              _ActiveSearchChip(
                query: activeQuery,
                onClear: state._clearThreadSearch,
              ),
            Expanded(
                child: RefreshIndicator(
                    onRefresh: state._refreshAll, child: threadListContent())),
          ],
        ));
  }
}

// ── Active search chip ────────────────────────────────────────────────────────

class _ActiveSearchChip extends StatelessWidget {
  const _ActiveSearchChip({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 5, 10, 5),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 13,
            color: cs.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 5),
          Text(
            'q: ',
            style: t.bodySmall.copyWith(
              fontSize: 11,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              query,
              style: t.bodySmall.copyWith(
                fontSize: 11,
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Tooltip(
              message: l.mailSearchClear,
              child: Icon(
                Icons.close_rounded,
                size: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
