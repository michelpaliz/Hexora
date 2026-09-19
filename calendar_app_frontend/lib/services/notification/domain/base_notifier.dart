import 'package:flutter/material.dart';

class BaseNotifier extends ChangeNotifier {
  // Call this method when you want to notify listeners of state changes.
  void notify() {
    notifyListeners();
  }

  @override
  void dispose() {
    // Perform any additional cleanup here
    super.dispose();
  }
}
