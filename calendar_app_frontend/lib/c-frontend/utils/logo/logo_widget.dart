import 'package:flutter/material.dart';

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

    return SizedBox(
      width: dimension,
      height: dimension,
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
