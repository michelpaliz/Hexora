import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/business_chat_screen.dart';

void main() {
  test('embedded conversation menu follows icons-only preference', () {
    expect(
      resolveBusinessChatConversationPaneCollapsed(
        narrow: false,
        manuallyCollapsed: false,
        embedded: true,
        displayMode: NavigationDisplayMode.iconsOnly,
      ),
      isTrue,
    );
    expect(
      resolveBusinessChatConversationPaneCollapsed(
        narrow: false,
        manuallyCollapsed: false,
        embedded: true,
        displayMode: NavigationDisplayMode.iconsAndText,
      ),
      isFalse,
    );
    expect(
      resolveBusinessChatConversationPaneCollapsed(
        narrow: false,
        manuallyCollapsed: false,
        embedded: true,
        displayMode: NavigationDisplayMode.automatic,
      ),
      isFalse,
    );
  });

  test('manual, mobile and standalone behavior remains intact', () {
    expect(
      resolveBusinessChatConversationPaneCollapsed(
        narrow: false,
        manuallyCollapsed: true,
        embedded: true,
        displayMode: NavigationDisplayMode.iconsAndText,
      ),
      isTrue,
    );
    expect(
      resolveBusinessChatConversationPaneCollapsed(
        narrow: true,
        manuallyCollapsed: true,
        embedded: true,
        displayMode: NavigationDisplayMode.iconsOnly,
      ),
      isFalse,
    );
    expect(
      resolveBusinessChatConversationPaneCollapsed(
        narrow: false,
        manuallyCollapsed: false,
        embedded: false,
        displayMode: NavigationDisplayMode.iconsOnly,
      ),
      isFalse,
    );
  });
}
