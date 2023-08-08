import 'package:flutter/material.dart';

class LoginCheck extends ChangeNotifier {
  bool isLogin = false;
  void Loggedin() {
    isLogin == true;
    notifyListeners();
  }
}
