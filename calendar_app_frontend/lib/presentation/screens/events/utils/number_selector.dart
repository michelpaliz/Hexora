import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/l10n/app_localizations.dart';

class NumberSelector extends StatefulWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final int minValue;
  final int maxValue;
  final double inputFontSize;

  const NumberSelector({
    super.key,
    this.value,
    required this.onChanged,
    required this.minValue,
    required this.maxValue,
    this.inputFontSize = 14.0,
  });

  @override
  State<NumberSelector> createState() => _NumberSelectorState();
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.remove, size: 18),
              tooltip: AppLocalizations.of(context)!.repeatIntervalDecrease,
              padding: EdgeInsets.zero,
              onPressed: (widget.value ?? 0) > widget.minValue
                  ? () =>
                      _controller.text = ((widget.value ?? 0) - 1).toString()
                  : null,
            ),
          ),
          Container(width: 1, color: cs.outlineVariant),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(fontSize: widget.inputFontSize),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(width: 1, color: cs.outlineVariant),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.add, size: 18),
              tooltip: AppLocalizations.of(context)!.repeatIntervalIncrease,
              padding: EdgeInsets.zero,
              onPressed: (widget.value ?? 0) < widget.maxValue
                  ? () =>
                      _controller.text = ((widget.value ?? 0) + 1).toString()
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
