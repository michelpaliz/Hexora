import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('desktop uses the shared icon scale ($brightness)', () {
      final theme = AppTheme.forPlatform(
        brightness,
        platform: TargetPlatform.windows,
        isWeb: false,
      );

      expect(theme.iconTheme.size, HexoraIconTokens.standard);
      expect(theme.primaryIconTheme.size, HexoraIconTokens.standard);
      expect(theme.appBarTheme.iconTheme?.size, HexoraIconTokens.appBar);
      expect(
        theme.appBarTheme.actionsIconTheme?.size,
        HexoraIconTokens.appBar,
      );
      expect(
        theme.iconButtonTheme.style?.iconSize?.resolve({}),
        HexoraIconTokens.compact,
      );
      expect(NavigationTokens.iconSize, HexoraIconTokens.standard);
      expect(HexoraTableTokens.icon, HexoraIconTokens.standard);
      expect(HexoraDocumentTokens.icon, HexoraIconTokens.standard);
    });

    test('mobile uses the shared icon scale ($brightness)', () {
      final theme = AppTheme.forPlatform(
        brightness,
        platform: TargetPlatform.android,
        isWeb: false,
      );

      expect(theme.iconTheme.size, HexoraIconTokens.standard);
      expect(theme.primaryIconTheme.size, HexoraIconTokens.standard);
      expect(theme.appBarTheme.iconTheme?.size, HexoraIconTokens.appBar);
      expect(
        theme.appBarTheme.actionsIconTheme?.size,
        HexoraIconTokens.appBar,
      );
      expect(
        theme.iconButtonTheme.style?.iconSize?.resolve({}),
        HexoraIconTokens.prominent,
      );
    });
  }
}
