import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatRProvider extends ChangeNotifier {
  String? name;
  String? postId;
  String? post;
  String? profilePic;
  String? profession;
  String? mutuals;
  String? time;
  int? cursor;
  String? chatID;
  int? authorGraphId;
  String? postURL;
  late IO.Socket socket;
  void setData(
      {required String nameData,
      required String postIDData,
      required String profileData,
      required String professionData,
      required String timeData,
      required int graphData,
      required String mutual,
      required String chatId,
      required String postUrl,
      required int postCursor,
      required IO.Socket socketData,
      required String postData}) {
    name = nameData;
    postId = postIDData;
    profilePic = profileData;
    post = postData;
    time = timeData;
    cursor = postCursor;
    mutuals = mutual;
    postURL = postUrl;
    chatID = chatId;
    authorGraphId = graphData;
    profession = professionData;
    socket = socketData;
    notifyListeners();
  }
}
