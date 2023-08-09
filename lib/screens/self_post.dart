import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:mutual/provider/chat_provider.dart';
import 'package:mutual/provider/chat_response_provider.dart';
import 'package:mutual/screens/chat.dart';
import 'package:mutual/widgets/selfpost_comment.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/ip_address.dart';
import '../provider/graphID_provider.dart';
import '../interceptor/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../widgets/selfpost_card.dart';

DioClient d = DioClient();
List feed = [];
late IO.Socket socket;

class SelfPost extends StatefulWidget {
  const SelfPost({super.key});

  @override
  State<SelfPost> createState() => _SelfPostState();
}

class _SelfPostState extends State<SelfPost> {
  Future<String> getAccessTokens() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return await pref.getString("accessToken").toString();
  }

  initSocket() async {
    print(await getAccessTokens());

    socket = IO.io('ws://${IP.ipAddress}/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'accessToken': await getAccessTokens()}
    });
    socket.connect();
    socket.onConnect((_) {
      print('Connection established');
    });
    socket.onDisconnect((_) => print('Connection Disconnection'));
    socket.onConnectError((err) => print(err));
    socket.onError((err) => print(err));
  }

  Future apiFeedd() async {
    final cp = Provider.of<ChatProvider>(context, listen: false);
    var pId = cp.postId;
    var aID = cp.authorGraphId;
    print('feed is execited');
    print(pId);
    var request = await d.dio.get(
      'http://${IP.ipAddress}/v1/api/feed/post/view?postId=$pId&selfPost=true&authorGraphId=$aID',
    );
    print("length isssssss");
    print(request.data['data'].length);
    try {
      for (int i = 0; i < request.data['data'].length; i++) {
        print("I am a counter");
        setState(() {
          print("post content is");
          print(request.data['data'][i]['chat']);
          String mutual = "";
          String time = DateFormat.jm().format(DateTime.now());
          try {
            time = Moment.parse(DateTime.parse(
                        (request.data['data'][i]['createdAt']).toString())
                    .add(Duration(hours: 5, minutes: 30))
                    .toString())
                .LT;
            mutual = request.data['data'][i]['mutual'][0]['name'] +
                    (request.data['data'][i]['mutual'].length - 1 == 0
                            ? " 's"
                            : ("+" +
                                (request.data['data'][i]['mutual'].length - 1)
                                    .toString()))
                        .toString() ??
                "";

            print(time);
          } catch (e) {
            print(e);
          }
          feed.add(
            Comment(
              firstName: request.data['data'][i]['firstName'] ?? "Tushar",
              post: request.data['data'][i]['chat'] ?? "",
              profilePic: request.data['data'][i]['profilePic'] ?? "",
              profession: request.data['data'][i]['profession'] ?? "",
              cursor: request.data['data'][i]['cursor'] ?? 4,
              time: time.toString(),
              postId: cp.postId!,
              authorGraphId: cp.authorGraphId!,
              mutual: mutual,
              chatId: request.data['data'][i]['chatId'] ?? "",
              selfCreated:
                  request.data['data'][i]['authorGraphId'] == 0 ? true : false,
            ),
          );
          print(feed.length);
        });
      }
    } catch (e) {}
    for (var element in cp.chatIDList!) {
      try {
        if (element != null) {
          print(element);
          socket.emit('joinRoom', {'chatId': element});
        }
      } catch (e) {}
    }
    if (request.statusCode == 200) {
      print("Response body :");
      print(await request.data.toString());
    } else {
      print(request.statusMessage);
    }
  }

  @override
  void initState() {
    initSocket();
    feed.clear();
    apiFeedd();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.white,
          body: Consumer<ChatRProvider>(
            builder: (context, value, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.02,
                        bottom: MediaQuery.of(context).size.height * 0.02,
                        left: MediaQuery.of(context).size.width * 0.04),
                    child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back)),
                  ),
                  Divider(color: Colors.grey, height: 1, thickness: 0.2),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01,
                  ),
                  SelfPostCard(
                    firstName: value.name ?? "",
                    post: value.post ?? "",
                    profilePic: value.profilePic ?? "",
                    profession: value.profession ?? "",
                    time: value.time ?? "",
                    postId: value.postId ?? "",
                    authorGraphId: value.authorGraphId ?? 0,
                    postUrl: value.postURL ?? "",
                  ),
                  Divider(color: Colors.grey, height: 20, thickness: 0.2),
                  Expanded(
                    child: ListView.separated(
                      separatorBuilder: (context, index) {
                        return const Divider(
                          height: 15,
                          endIndent: 0,
                          indent: 0,
                        );
                      },

                      //physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return feed[index];
                      },

                      itemCount: feed.length,
                    ),
                  ),
                ],
              );
            },
          )),
    );
  }
}
