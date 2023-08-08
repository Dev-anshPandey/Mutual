import 'package:flutter/material.dart';

class FeedProvider extends ChangeNotifier {
  var feedList = [];
  var myPostList = [];
  var feedState = 0;
  void addList(Widget item) {
    feedList.insert(0, item);
    notifyListeners();
  }

  void addNormal(Widget item) {
    feedList.add(item);
    notifyListeners();
  }
  void addPost(Widget item) {
    myPostList.add(item);
    notifyListeners();
  }
  void deletePost() {
    myPostList.clear();
    notifyListeners();
  }

  void changeState(int state) {
    feedState = state;
    notifyListeners();
  }

  int getState() {
    return feedState;
  }

  void deleteAll() {
    feedList.clear();
    notifyListeners();
  }
}
