import 'package:flutter/material.dart';

class NumberSelector extends StatefulWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final int minValue;
  final int maxValue;
  final double inputFontSize;
  final Key? key; // Add the Key parameter here

  NumberSelector({
    this.value,
    required this.onChanged,
    required this.minValue,
    required this.maxValue,
    this.inputFontSize = 14.0,
    this.key, // Initialize the Key parameter
  });

  @override
  _NumberSelectorState createState() => _NumberSelectorState();
}

class _NumberSelectorState extends State<NumberSelector> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
    _controller.addListener(_checkInputValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkInputValue() {
    final text = _controller.text;
    if (text.isEmpty) {
      widget.onChanged(null);
    } else {
      final parsedValue = int.tryParse(text);
      if (parsedValue != null) {
        if (parsedValue >= widget.minValue) {
          if (parsedValue > widget.maxValue) {
            _controller.text = widget.maxValue.toString();
            widget.onChanged(widget.maxValue);
          } else {
            widget.onChanged(parsedValue);
          }
        } else {
          _controller.text = widget.minValue.toString();
          widget.onChanged(widget.minValue);
        }
      } else {
        _controller.text = widget.maxValue.toString();
        widget.onChanged(widget.maxValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.remove),
          iconSize: 14,
          onPressed: (widget.value ?? 0) > widget.minValue
              ? () {
                  final newValue = (widget.value ?? 0) - 1;
                  _controller.text = newValue.toString();
                  widget.onChanged(newValue);
                }
              : null,
        ),
        SizedBox(
          width: 30, // Adjust the width as needed
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: widget.inputFontSize,
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(0),
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add),
          iconSize: 14,
          onPressed: () {
            final newValue = (widget.value ?? 0) + 1;
            if (newValue <= widget.maxValue) {
              _controller.text = newValue.toString();
              widget.onChanged(newValue);
            }
          },
        ),
      ],
    );
  }
}
