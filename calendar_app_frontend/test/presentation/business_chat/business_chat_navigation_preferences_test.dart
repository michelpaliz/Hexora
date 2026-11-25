import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/business_chat_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/widgets/compact_chat_bubble.dart';
import 'package:hexora/theme/theme_provider.dart';
import 'package:hexora/theme/themes/app_theme.dart';

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

  test('chat canvas follows every selected appearance', () {
    final neutral = AppTheme.forPlatform(
      Brightness.light,
      platform: TargetPlatform.windows,
      lightVariant: LightThemeVariant.neutral,
    );
    final blue = AppTheme.forPlatform(
      Brightness.light,
      platform: TargetPlatform.windows,
      lightVariant: LightThemeVariant.blue,
    );
    final dark = AppTheme.forPlatform(
      Brightness.dark,
      platform: TargetPlatform.windows,
    );

    for (final theme in [neutral, blue, dark]) {
      expect(resolveBusinessChatCanvas(theme), theme.scaffoldBackgroundColor);
    }
    expect(resolveBusinessChatCanvas(neutral),
        isNot(resolveBusinessChatCanvas(blue)));
  });

  testWidgets('message bubbles derive their surfaces from the active theme',
      (tester) async {
    for (final theme in [
      AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
        lightVariant: LightThemeVariant.blue,
      ),
      AppTheme.forPlatform(
        Brightness.dark,
        platform: TargetPlatform.windows,
      ),
    ]) {
      Future<Color?> bubbleColor(bool mine) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: CompactChatBubble(
                mine: mine,
                isFirstInGroup: true,
                isLastInGroup: true,
                child: const Text('Message'),
              ),
            ),
          ),
        );
        final container = tester.widget<Container>(
          find.byKey(const ValueKey('business-chat-bubble-surface')),
        );
        return (container.decoration as BoxDecoration).color;
      }

      final incoming = await bubbleColor(false);
      final activeTheme = Theme.of(
        tester.element(find.byType(CompactChatBubble)),
      );
      expect(incoming, activeTheme.colorScheme.surfaceContainerLow);
      expect(
        await bubbleColor(true),
        Color.alphaBlend(
          activeTheme.colorScheme.primary.withValues(alpha: .14),
          activeTheme.colorScheme.surface,
        ),
      );
    }
  });
}
