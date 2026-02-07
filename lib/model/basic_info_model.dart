import 'package:flutter/material.dart';

class BasicInfoModel extends ChangeNotifier {
  bool windowIsMaxed = false;

  void setIsMaxed(bool value) {
    if (windowIsMaxed == value) return;
    windowIsMaxed = value;
    notifyListeners();
  }
}
