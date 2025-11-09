import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final TextInputType keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final String? hintText;

  // 👇 new (optional)
  final ValueChanged<String>? onChanged;

  const TextFieldWidget({
    required this.controller,
    required this.decoration,
    required this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
    this.validator,
    this.hintText,
    this.onChanged, // 👈 new
    Key? key,
  }) : super(key: key);

  @override
  _TextFieldWidgetState createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  bool showError = false;

  @override
  Widget build(BuildContext context) {
    final baseDecoration = widget.decoration.copyWith(
      // Keep provided labelText (for floating labels)
      hintText: widget.hintText ?? widget.decoration.hintText,
      // Make labels float like Material fields (placeholder clarity)
      floatingLabelBehavior: widget.decoration.floatingLabelBehavior ??
          FloatingLabelBehavior.auto,
      errorText: showError
          ? (widget.validator != null
              ? widget.validator!(widget.controller.text)
              : null)
          : null,
      isDense: true,
      contentPadding:
          widget.decoration.contentPadding ?? const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );

    return TextField(
      controller: widget.controller,
      decoration: baseDecoration,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      inputFormatters: widget.inputFormatters,
      onChanged: (value) {
        widget.onChanged?.call(value); // 👈 let parents react (e.g., strength)
        setState(() {
          showError =
              widget.validator != null && widget.validator!(value) != null;
        });
      },
    );
  }
}
