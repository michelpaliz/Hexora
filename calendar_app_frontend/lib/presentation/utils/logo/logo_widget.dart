import 'package:flutter/material.dart';
import 'hexora_brand.dart';

enum LogoSize { small, medium, large }

class LogoWidget {
  static Widget buildLogoAvatar({LogoSize size = LogoSize.medium}) {
    double dimension;
    switch (size) {
      case LogoSize.small:
        dimension = 80.0;
        break;
      case LogoSize.medium:
        dimension = 150.0;
        break;
      case LogoSize.large:
        dimension = 200.0;
        break;
    }

    return HexoraBrandIcon(size: dimension);
  }
}
