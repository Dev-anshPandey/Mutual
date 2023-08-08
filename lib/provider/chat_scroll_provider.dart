import 'package:flutter/material.dart';

class ChatScroll extends ChangeNotifier {
  bool floatstate = false;
  void setFloatState(bool value) {
    floatstate = value;
    notifyListeners();
  }
}
