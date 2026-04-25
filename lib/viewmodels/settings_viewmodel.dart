import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  bool vibration = true;
  bool notifications = true;

  void setVibration(bool v) {
    vibration = v;
    notifyListeners();
  }

  void setNotifications(bool v) {
    notifications = v;
    notifyListeners();
  }
}
