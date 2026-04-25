import 'package:flutter/material.dart';

class ShellViewModel extends ChangeNotifier {
  int tabIndex = 0;
  bool isOnline = true;

  void setTab(int i) {
    tabIndex = i;
    notifyListeners();
  }

  void toggleOnline() {
    isOnline = !isOnline;
    notifyListeners();
  }
}
