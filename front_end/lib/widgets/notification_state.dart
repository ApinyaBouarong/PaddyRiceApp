import 'package:flutter/material.dart';

class NotificationState extends ChangeNotifier {
  bool _shouldShowNotification = false;
  bool get shouldShowNotification => _shouldShowNotification;

  void showNotificationDot() {
    _shouldShowNotification = true;
    notifyListeners();
  }

  void clearNotificationDot() {
    _shouldShowNotification = false;
    notifyListeners();
  }
}
