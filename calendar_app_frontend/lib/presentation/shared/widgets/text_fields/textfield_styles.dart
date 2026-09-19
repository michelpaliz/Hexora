import 'package:flutter/material.dart';

class TextFieldStyles {
  static InputDecoration saucyInputDecoration({
    required String hintText,
    required String labelText,
    required IconData? suffixIcon
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontStyle: FontStyle.italic,
        color: Color.fromARGB(255, 18, 113, 151),
      ),
      labelText: labelText,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color.fromARGB(255, 41, 161, 197)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color.fromARGB(255, 18, 165, 233)),
      ),
      suffixIcon: Icon(suffixIcon, color: Colors.blue),
    );
  }
}
