import 'package:flutter/material.dart';

class GraphID extends ChangeNotifier {
  int graphID = 0;
  void setGID(int value) {
    graphID = value;
    notifyListeners();
  }
}
