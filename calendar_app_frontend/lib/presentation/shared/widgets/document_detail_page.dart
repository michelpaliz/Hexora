import 'package:flutter/material.dart';
import 'section_app_bar.dart';

/// Shared full-screen shell for mobile document details.
class DocumentDetailPage extends StatelessWidget {
  const DocumentDetailPage(
      {super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: SectionAppBar(title: title),
        body: SafeArea(top: false, child: child),
      );
}
