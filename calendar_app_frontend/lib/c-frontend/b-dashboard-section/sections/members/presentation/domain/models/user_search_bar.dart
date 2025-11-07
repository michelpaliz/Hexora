import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';

class UserSearchBar extends StatefulWidget {
  const UserSearchBar({
    super.key,
    required this.onChanged,
    this.onClear,
    this.hintText,
    this.autofocus = true,
  });

  final void Function(String query) onChanged;
  final VoidCallback? onClear;
  final String? hintText;
  final bool autofocus;

  @override
  State<UserSearchBar> createState() => _UserSearchBarState();
}

class _UserSearchBarState extends State<UserSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      widget.onChanged(value);
    });
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
    setState(() {});
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
