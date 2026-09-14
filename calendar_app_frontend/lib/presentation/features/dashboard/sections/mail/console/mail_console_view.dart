part of '../mail_console_screen.dart';

class _MailConsoleView extends StatelessWidget {
  const _MailConsoleView({required this.state});

  final _MailConsoleScreenState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return _buildMobile(context);
        }
        return _buildDesktop(context);
      },
    );
  }

  // ── Mobile layout ──────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
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
      return '${l.mailConsoleTitle} · ${_folderLabel(state._folder, l)}';
    }

    void openFolderSheet() {
      showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  l.mailConsoleFoldersTitle,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
              ...MailFolder.values.map((folder) => ListTile(
                    leading: Icon(_folderIcon(folder),
                        color: state._folder == folder
                            ? cs.primary
                            : cs.onSurfaceVariant),
                    title: Text(
                      _folderLabel(folder, l),
                      style: t.bodySmall.copyWith(
                        fontWeight: state._folder == folder
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: state._folder == folder
                            ? cs.primary
                            : cs.onSurface,
                      ),
                    ),
                    selected: state._folder == folder,
                    onTap: () {
                      Navigator.pop(ctx);
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
                  )),
              Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ListTile(
                leading: Icon(Icons.description_outlined,
                    color: cs.onSurfaceVariant),
                title: Text(l.mailFooterCreateCta,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  state._openFooterManager();
                },
              ),
              ListTile(
                leading: Icon(Icons.view_list_outlined,
                    color: cs.onSurfaceVariant),
                title: Text('Templates',
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  state._openTemplateManager();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    Widget mobileBody() {
      if (state._showCompose) {
        return MailComposeScreen(
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
          onReply: state._sendReply,
          replyController: state._replyCtrl,
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
                onRefresh: isDetailView ? null : _asyncCallback(state._refreshAll),
                onCompose: isDetailView ? null : state._openCompose,
                hasUnread:
                    selectedThread?.messages.any((m) => m.unread),
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
        appBar: AppBar(
          centerTitle: false,
          leading: isDetailView
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: mobileBack,
                )
              : null,
          title: Text(
            appBarTitle(),
            style: t.bodySmall
                .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (!isDetailView) ...[
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
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          l.mailConsoleTitle,
                          style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              state._openCompose();
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l.mailComposeTitle),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: MailFolder.values.map((folder) {
                            return _FolderNavTile(
                              label: _folderLabel(folder, l),
                              icon: _folderIcon(folder),
                              selected: state._folder == folder,
                              compact: false,
                              onTap: () {
                                Navigator.pop(context);
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
                            );
                          }).toList(),
                        ),
                      ),
                    ],
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
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final domain = context.watch<MailDomain>();
    final threadsState = domain.threadsState;
    final threadState = state._selectedThreadKey == null
        ? null
        : domain.threadState(state._selectedThreadKey!);
    final selectedThread = threadState?.thread;

    Widget leftColumn() {
      const railWidth = 180.0;
      const collapsed = false;
      return SizedBox(
        width: railWidth,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 8, 8),
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
                onTap: _asyncCallback(state._openTemplateManager),
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
      final activeQuery = (threadsState.query ?? '').trim();
      final isThreadSearch = activeQuery.length >= 2;

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
          title: isThreadSearch
              ? l.mailThreadSearchNoResults
              : l.mailThreadsEmpty,
          subtitle: isThreadSearch
              ? '"$activeQuery" · ${l.mailThreadSearchNoResultsHint}'
              : l.mailConsoleSelectThread,
          icon: isThreadSearch
              ? Icons.search_off_rounded
              : Icons.inbox_outlined,
          actionLabel:
              isThreadSearch ? l.mailSearchClear : l.mailComposeTitle,
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

    Widget middleColumn() {
      final activeQuery = (threadsState.query ?? '').trim();
      final isSearchActive = activeQuery.length >= 2;
      return Expanded(
        flex: 2,
        child: Focus(
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
                hasUnread:
                    selectedThread?.messages.any((m) => m.unread) ?? false,
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
              Expanded(child: threadList()),
            ],
          ),
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
                              onReply: state._sendReply,
                              replyController: state._replyCtrl,
                              sendingReply: state._sendingReply,
                              onDownloadAttachment: _asyncValueChanged(
                                (attachment) => state._downloadAttachment(
                                  attachment,
                                  domain,
                                ),
                              ),
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
    final t = AppTypography.of(context);
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
          title: isThreadSearch
              ? l.mailThreadSearchNoResults
              : l.mailThreadsEmpty,
          subtitle: isThreadSearch
              ? '"$activeQuery" · ${l.mailThreadSearchNoResultsHint}'
              : l.mailConsoleSelectThread,
          icon: isThreadSearch
              ? Icons.search_off_rounded
              : Icons.inbox_outlined,
          actionLabel:
              isThreadSearch ? l.mailSearchClear : l.mailComposeTitle,
          onAction:
              isThreadSearch ? state._clearThreadSearch : state._openCompose,
        );
      }

      final itemCount =
          threads.length + (threadsState.loadingMore ? 1 : 0);

      return ListView.separated(
        controller: state._threadScroll,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          return _ThreadRow(
            thread: thread,
            selected: false,
            onTap: _asyncCallback(
              () => state._selectThread(thread.threadKey),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        // ── Compact search bar ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                TextField(
                  controller: state._threadSearchController,
                  textAlign: state._threadSearchController.text.isEmpty
                      ? TextAlign.center
                      : TextAlign.start,
                  decoration: InputDecoration(
                    hintText: l.mailConsoleSearchPlaceholder,
                    hintStyle: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    suffixIcon: threadsState.loading && isSearchActive
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            ),
                          )
                        : (state._threadSearchController.text.trim().isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(Icons.close_rounded,
                                    size: 16, color: cs.onSurfaceVariant),
                                onPressed: state._clearThreadSearch,
                                padding: EdgeInsets.zero,
                              )),
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 9),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: t.bodySmall.copyWith(fontSize: 13),
                  textInputAction: TextInputAction.search,
                  onChanged: state._onThreadSearchChanged,
                  onSubmitted: state._onThreadSearchChanged,
                ),
                if (state._threadSearchController.text.isEmpty)
                  Positioned(
                    left: 14,
                    child: Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isSearchActive)
          _ActiveSearchChip(
            query: activeQuery,
            onClear: state._clearThreadSearch,
          ),
        Expanded(child: threadListContent()),
      ],
    );
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
