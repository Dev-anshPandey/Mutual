import 'package:flutter/material.dart';

class PostProvider extends ChangeNotifier {
  String postBody = "";
  void postContent(String pc) {
    postBody = pc;
    notifyListeners();
  }

  
}
