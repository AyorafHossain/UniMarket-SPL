import 'package:flutter/material.dart';

/// Provider to manage the bottom navigation state
class NavProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  /// Update the selected index and notify listeners
  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
