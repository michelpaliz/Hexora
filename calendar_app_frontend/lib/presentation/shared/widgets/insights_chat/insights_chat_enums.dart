enum InsightsResponseMode { auto, stream }

enum InsightsChatEndpointType {
  chat,
  chatAuto,
  chatStream,
  chatAutoStream,
}

class InsightsSendOutcome {
  final bool timedOut;
  final String originalText;

  const InsightsSendOutcome({
    required this.timedOut,
    required this.originalText,
  });
}

enum InsightsSendSource {
  typedInput,
  followUpButton,
  backButton,
  newConversationAction,
  retryAction,
}
