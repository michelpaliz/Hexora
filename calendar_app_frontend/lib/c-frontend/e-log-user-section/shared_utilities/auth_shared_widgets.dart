import 'package:hexora/f-themes/shapes/solid/auth_header.dart';
import 'package:hexora/c-frontend/utils/logo/logo_widget.dart';
import 'package:flutter/material.dart';

/// Shared constants
const double kAuthHeaderHeight = 280;

/// Shared card builder
Widget buildAuthCard({
  required BuildContext context,
  required Widget child,
}) {
  return Card(
    margin: const EdgeInsets.only(top: 24),
    elevation: 6,
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color.fromARGB(255, 11, 76, 120)
        : Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: child,
    ),
  );
}

/// Shared header with background + logo
Widget buildAuthHeader(BuildContext context) {
  final topInset = MediaQuery.of(context).padding.top;

  return Stack(
    children: [
      const BlueAuthHeader(height: kAuthHeaderHeight),
      Positioned(
        top: topInset + kAuthHeaderHeight * 0.10,
        left: 0,
        right: 0,
        child: Align(
          alignment: Alignment.center,
          child: LogoWidget.buildLogoAvatar(size: LogoSize.medium),
        ),
      ),
    ],
  );
}
