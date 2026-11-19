import 'package:flutter/material.dart';

/// Compact search field for the mobile chat inbox.
///
/// A single ~42px filled field placed directly below the header, with a clear
/// button when a query is present. Styling only — search behaviour stays with
/// the caller via [controller]/[onChanged].
class ChatInboxSearch extends StatelessWidget {
  const ChatInboxSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hintText,
    this.clearTooltip,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;
  final String? clearTooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasQuery = controller.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          prefixIcon: const Icon(Icons.search, size: 20),
          hintText: hintText,
          hintMaxLines: 1,
          suffixIcon: hasQuery
              ? IconButton(
                  tooltip: clearTooltip,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}
