import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';

class UserSearchBar extends StatefulWidget {
  const UserSearchBar({
    super.key,
    required this.onChanged,
    this.onClear,
    this.hintText,
    this.autofocus = true,
    this.minChars = 1, // NEW: configurable gate
    this.debounceMs = 250, // NEW: configurable debounce
  });

  /// Called with the (trimmed) query after debounce.
  final void Function(String query) onChanged;

  /// Called after pressing the clear (X) button.
  final VoidCallback? onClear;

  final String? hintText;
  final bool autofocus;

  /// Minimum characters before emitting queries. Default = 1
  final int minChars;

  /// Debounce interval in milliseconds. Default = 250
  final int debounceMs;

  @override
  State<UserSearchBar> createState() => _UserSearchBarState();
}

class _UserSearchBarState extends State<UserSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _lastEmitted = '';

  @override
  void initState() {
    super.initState();
    // Keep suffix icon state in sync even on programmatic changes.
    _controller.addListener(_rebuildForSuffixIcon);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_rebuildForSuffixIcon);
    _controller.dispose();
    super.dispose();
  }

  void _rebuildForSuffixIcon() {
    if (mounted) setState(() {});
  }

  void _emit(String raw) {
    final q = raw.trim();

    // Enforce min length gate; send empty when below threshold.
    if (q.length < widget.minChars) {
      if (_lastEmitted.isNotEmpty) {
        _lastEmitted = '';
        widget.onChanged('');
      }
      return;
    }

    // Distinct until changed
    if (q == _lastEmitted) return;

    _lastEmitted = q;
    widget.onChanged(q);
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: widget.debounceMs), () {
      _emit(value);
    });
  }

  void _onSubmitted(String value) {
    // Immediate search on submit
    _debounce?.cancel();
    _emit(value);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    _lastEmitted = '';
    widget.onChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bg = ThemeColors.containerBg(context);
    final onBg = ThemeColors.textPrimary(context);
    final hint = ThemeColors.textSecondary(context);

    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onChanged: _onTextChanged,
      onSubmitted: _onSubmitted, // NEW: immediate submit handling
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Search users…',
        filled: true,
        fillColor: bg,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clear,
                icon: const Icon(Icons.clear),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: hint),
      ),
      style: TextStyle(color: onBg),
    );
  }
}
