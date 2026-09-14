part of '../mail_console_screen.dart';

/// Mobile reading and replying use separate layouts within the current route.
class _MobileConversation extends StatelessWidget {
  const _MobileConversation({required this.pane, required this.messages});
  final _ConversationPane pane;
  final List<MailMessage> messages;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final target = pane.replyTarget;
    if (target != null) {
      final sent = target.folderEnum == MailFolder.sent ||
          (target.folderEnum == null && pane.folder == MailFolder.sent);
      final recipient = sent
          ? target.to.map((a) => a.display).join(', ')
          : target.fromAddress;
      return SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 16),
            child: _ReplyComposer(
              subjectController: pane.replySubjectController,
              replyController: pane.replyController,
              replyFocus: pane.replyFocus,
              onReply: _asyncCallback(() => pane.onReply(target)),
              onClose: pane.onCloseReply,
              sendingReply: pane.sendingReply,
              replyToLabel: l.mailConversationReplyTo(recipient),
            ),
          ));
    }
    final newestFirst = [...messages]..sort((a, b) =>
        (b.date ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.date ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return SafeArea(
        top: false,
        child: Column(children: [
          Expanded(
              child: ListView.builder(
            key: PageStorageKey('mail-conversation-${pane.thread.threadKey}'),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            itemCount: newestFirst.length,
            itemBuilder: (context, index) {
              final message = newestFirst[index];
              final card = _MessageCard(
                  key: ValueKey(message.id),
                  message: message,
                  onReply: () => pane.onStartReply(message),
                  onDownloadAttachment: pane.onDownloadAttachment);
              if (index == 0) return card;
              return Card(
                  child: ExpansionTile(
                key: PageStorageKey('mail-message-${message.id}'),
                title: Text(message.fromAddress,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(message.snippet ?? message.subject,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                children: [
                  card,
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: OutlinedButton.icon(
                          onPressed: () => pane.onStartReply(message),
                          icon: const Icon(Icons.reply_rounded),
                          label: Text(l.mailConversationReply)))
                ],
              ));
            },
          )),
          if (newestFirst.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                      top: BorderSide(
                          color:
                              Theme.of(context).colorScheme.outlineVariant))),
              child: FilledButton.icon(
                  onPressed: () => pane.onStartReply(newestFirst.first),
                  icon: const Icon(Icons.reply_rounded),
                  label: Text(l.mailConversationReply)),
            ),
        ]));
  }
}

class _MessageHeaderLayout extends StatelessWidget {
  const _MessageHeaderLayout({required this.sender, required this.date});
  final Widget sender;
  final Widget date;
  @override
  Widget build(BuildContext context) => MediaQuery.sizeOf(context).width < 650
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [sender, const SizedBox(height: 6), date])
      : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: sender), const SizedBox(width: 8), date]);
}
