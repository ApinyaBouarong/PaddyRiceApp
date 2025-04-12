import 'package:flutter/material.dart';

class NotificationState extends ChangeNotifier {
  bool _shouldShowNotification = false;
  bool get shouldShowNotification => _shouldShowNotification;

  void showNotificationDot() {
    _shouldShowNotification = true;
    print("Notification dot should be visible now.");
    notifyListeners();
  }

  void hideNotificationDot() {
    _shouldShowNotification = false;
    notifyListeners();
  }
}
