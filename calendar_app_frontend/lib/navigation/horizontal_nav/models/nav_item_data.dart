import 'package:flutter/material.dart';

class NavItemData {
  final IconData icon;
  final String route;
  final String? semanticLabel;
  final bool isProfile;

  const NavItemData({
    required this.icon,
    required this.route,
    this.semanticLabel,
    this.isProfile = false,
  });
}
