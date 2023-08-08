import 'package:flutter/material.dart';

class ChatDataProvider extends ChangeNotifier {
  var chatList = [];
  var chatState = 0;
  void addList(Widget item) {
    chatList.insert(0, item);
    notifyListeners();
  }

  void addNormal(Widget item) {
    chatList.add(item);
    notifyListeners();
  }

  void changeState(int state) {
    chatState = state;
    notifyListeners();
  }

  int getState() {
    return chatState;
  }

  void deleteAll() {
    chatList.clear();
    notifyListeners();
  }
}
