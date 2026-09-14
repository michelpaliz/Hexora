import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/utils/image/user_image/avatar_utils.dart';

void main() {
  test('photo-less users use the declared default profile asset', () {
    for (final imageUrl in <String?>[null, '']) {
      final provider = AvatarUtils.profileImageProvider(imageUrl);

      expect(provider, isA<AssetImage>());
      expect(
        (provider as AssetImage).assetName,
        'assets/images/default_profile.png',
      );
    }
  });
}
