import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:mutual/provider/chat_provider.dart';
import 'package:mutual/provider/chat_response_provider.dart';
import 'package:mutual/screens/chat.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/graphID_provider.dart';
import 'dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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

    socket = IO.io('ws://3.110.164.26/', <String, dynamic>{
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
      'http://3.110.164.26/v1/api/feed/post/view?postId=$pId&selfPost=true&authorGraphId=$aID',
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
            FeedCard2(
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
                  FeedCard4(
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

class FeedCard2 extends StatelessWidget {
  String firstName;
  String profilePic;
  String post;
  String chatId;
  String profession;
  String? mutual;
  String time;
  int? cursor;
  int authorGraphId;
  String postId;
  bool selfCreated;
  FeedCard2(
      {required this.firstName,
      required this.selfCreated,
      required this.post,
      required this.profilePic,
      required this.chatId,
      required this.profession,
      required this.time,
      required this.authorGraphId,
      required this.postId,
      required this.cursor,
      required this.mutual});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, value, child) {
        final cpr = Provider.of<ChatProvider>(context, listen: false);
        return InkWell(
          onTap: () {
            print("testing chat id $chatId");
            cpr.setData(
                // postCursor: cursor ?? 0,
                nameData: firstName,
                postData: post,
                postIDData: postId,
                professionData: profession,
                timeData: time,
                graphData: authorGraphId,
                socketData: socket,
                chatId: chatId,
                chatsId: [],
                mutual: mutual ?? "",
                profileData: profilePic);
            Navigator.pushNamed(context, '/chat');
          },
          child: Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.005,
                left: MediaQuery.of(context).size.width * 0.04,
                right: MediaQuery.of(context).size.width * 0.0),
            child: Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.004,
                    left: MediaQuery.of(context).size.width * 0.02),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Consumer<GraphID>(
                          builder: (context, value, child) {
                            final gp =
                                Provider.of<GraphID>(context, listen: false);
                            return Padding(
                              padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height * 0.00,
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, '/seeProfile',
                                      arguments: {'graphID': authorGraphId});
                                  gp.setGID(authorGraphId);
                                },
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    profilePic,
                                  ),
                                  radius: 22,
                                ),
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.0,
                              bottom: MediaQuery.of(context).size.height * 0.01,
                              left: MediaQuery.of(context).size.width * 0.03),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.72,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          firstName,
                                          style: GoogleFonts.roboto(
                                            textStyle: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.016),
                                          ),
                                        ),
                                        mutual == null || mutual == ""
                                            ? Container(
                                                height: 0,
                                                width: 0,
                                              )
                                            : Padding(
                                                padding: EdgeInsets.only(
                                                    top: MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        0.0025,
                                                    left: MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.03),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundColor:
                                                          Color(0xff336FD7),
                                                      radius: 5.5,
                                                      child: CircleAvatar(
                                                        radius: 4.5,
                                                        backgroundColor:
                                                            Colors.white,
                                                        child: Text(
                                                          'm',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .roboto(
                                                                  textStyle:
                                                                      TextStyle(
                                                            color: Color(
                                                                0xff336FD7),
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.009,
                                                          )),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 4,
                                                    ),
                                                    Text("$mutual Mutual",
                                                        style:
                                                            GoogleFonts.roboto(
                                                                textStyle:
                                                                    TextStyle(
                                                          color:
                                                              Color(0xff336FD7),
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.012,
                                                        )))
                                                  ],
                                                ),
                                              ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.0),
                                      child: Text(
                                        time,
                                        style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xffA8A8A8),
                                              // fontWeight: FontWeight.bold,
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.012),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.005,
                              ),
                              // Padding(
                              //   padding: const EdgeInsets.only(top: 1.0),
                              //   child: Text(
                              //     profession,
                              //     style: GoogleFonts.roboto(
                              //       textStyle: TextStyle(
                              //           fontWeight: FontWeight.w400,
                              //           color: Color(0xff336FD7),
                              //           fontSize:
                              //               MediaQuery.of(context).size.height *
                              //                   0.012),
                              //     ),
                              //   ),
                              // ),
                              // SizedBox(
                              //   height: 5,
                              // ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.73,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.start,
                                      softWrap: true,
                                      style: GoogleFonts.roboto(
                                        textStyle: TextStyle(
                                            color: Color(0xff373737),
                                            fontWeight: FontWeight.w400,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.014),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.reply,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(
                                          width: 0,
                                        ),
                                        Text(
                                          " Reply",
                                          style: GoogleFonts.roboto(
                                            textStyle: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                color: Colors.grey,
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.014),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FeedCard4 extends StatelessWidget {
  String firstName;
  String profilePic;
  String post;
  String profession;
  String? mutual;
  String time;
  int? cursor;
  int authorGraphId;
  String postId;
  String postUrl;
  FeedCard4(
      {required this.firstName,
      required this.post,
      required this.profilePic,
      required this.profession,
      required this.time,
      required this.authorGraphId,
      required this.postId,
      required this.postUrl,
      this.cursor,
      this.mutual});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, value, child) {
        final cp = Provider.of<ChatProvider>(context, listen: false);
        return Padding(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.00,
              left: MediaQuery.of(context).size.width * 0.0,
              right: MediaQuery.of(context).size.width * 0.0),
          child: Container(
            color: Colors.grey.withOpacity(0.036),
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.004,
                  left: MediaQuery.of(context).size.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Consumer<GraphID>(
                        builder: (context, value, child) {
                          final gp =
                              Provider.of<GraphID>(context, listen: false);
                          return Padding(
                            padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.00,
                              top: MediaQuery.of(context).size.height * 0.00,
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/seeProfile',
                                    arguments: {'graphID': authorGraphId});
                                gp.setGID(authorGraphId);
                              },
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  profilePic,
                                ),
                                radius: 28,
                              ),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.0,
                            bottom: MediaQuery.of(context).size.height * 0.02,
                            left: MediaQuery.of(context).size.width * 0.03),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.72,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        firstName,
                                        style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.019),
                                        ),
                                      ),
                                      mutual == null || mutual == ""
                                          ? Container(
                                              height: 0,
                                              width: 0,
                                            )
                                          : Padding(
                                              padding: EdgeInsets.only(
                                                  top: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.0025,
                                                  left: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.03),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        Color(0xff336FD7),
                                                    radius: 5,
                                                    child: CircleAvatar(
                                                      radius: 4,
                                                      backgroundColor:
                                                          Colors.white,
                                                      child: Text(
                                                        'm',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            GoogleFonts.roboto(
                                                                textStyle:
                                                                    TextStyle(
                                                          color:
                                                              Color(0xff336FD7),
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.008,
                                                        )),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 4,
                                                  ),
                                                  Text("$mutual Mutual",
                                                      style: GoogleFonts.roboto(
                                                          textStyle: TextStyle(
                                                        color:
                                                            Color(0xff336FD7),
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.011,
                                                      )))
                                                ],
                                              ),
                                            ),
                                    ],
                                  ),
                                  PopupMenuButton(
                                    child: Container(
                                      height: 36,
                                      width: 48,
                                      alignment: Alignment.centerRight,
                                      child: Icon(
                                        Icons.more_vert,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        height: 30,
                                        value: 1,
                                        child: Text("Close Chat"),
                                      ),
                                      // PopupMenuItem 2
                                    ],
                                    //offset: Offset(0, 100),
                                    color: Colors.white,
                                    elevation: 2,
                                    onSelected: (value) {
                                      if (value == 1) {
                                        // _showDialog(context);
                                        // if value 2 show dialog
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.72,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1.0),
                                    child: Text(
                                      profession,
                                      style: GoogleFonts.roboto(
                                        textStyle: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xff336FD7),
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.011),
                                      ),
                                    ),
                                  ),
                                  //Expanded(child: Container()),
                                  Padding(
                                    padding: EdgeInsets.only(top: 1),
                                    child: Text(
                                      time,
                                      style: GoogleFonts.roboto(
                                        textStyle: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xffA8A8A8),
                                            // fontWeight: FontWeight.bold,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.013),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Text(
                      post,
                      maxLines: 200,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      softWrap: true,
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                            color: Color(0xff373737),
                            fontWeight: FontWeight.w400,
                            fontSize:
                                MediaQuery.of(context).size.height * 0.018),
                      ),
                    ),
                  ),
                  postUrl!.isNotEmpty
                      ? Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.01,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              postUrl ?? "",
                              height: MediaQuery.of(context).size.height * 0.4,
                              width: MediaQuery.of(context).size.width * 0.9,
                              fit: BoxFit.fill,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.4,
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xff4666ED),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 0,
                        )

                  // SizedBox(
                  //   height: 10,
                  // ),
                  // Divider(color: Colors.grey,height: 10,)
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


//khud ki profile pe block nhi karna h
//tumhai profile me view block contact , 3 dots
// design
// closed chat popup design
// akshat chat left
// chat profile pic