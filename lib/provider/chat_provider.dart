import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatProvider extends ChangeNotifier {
  String? name;
  String? postId;
  String? post;
  List? chatIDList;
  String? chatID;
  String? profilePic;
  String? profession;
  String? mutuals;
  String? time;
  int? cursor;
  int? authorGraphId;
  late IO.Socket socket;
  void setData(
      {required String nameData,
      required String postIDData,
      required String profileData,
      required String professionData,
      required String timeData,
      required int graphData,
      required List chatsId,
      required String chatId,
      required String mutual,
      required IO.Socket socketData,
      required String postData}) {
    name = nameData;
    postId = postIDData;
    profilePic = profileData;
    post = postData;
    time = timeData;
    mutuals = mutual;
    chatIDList = chatsId;
    chatID = chatId;
    authorGraphId = graphData;
    profession = professionData;
    socket = socketData;
    notifyListeners();
  }
}
