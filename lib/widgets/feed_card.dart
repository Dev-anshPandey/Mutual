import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mutual/constant/ip_address.dart';
import 'package:mutual/provider/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:readmore/readmore.dart';

import '../provider/chat_response_provider.dart';
import '../provider/graphID_provider.dart';
import '../interceptor/dio.dart';
import '../screens/feed.dart';

class FeedCard extends StatelessWidget {
  String firstName;
  String profilePic;
  String post;
  String profession;
  String? mutual;
  String time;
  int? cursor;
  int authorGraphId;
  String postId;
  bool selfCreated;
  String? chatID;
  String? postUrl;
  int? view;
  FeedCard(
      {required this.firstName,
      required this.selfCreated,
      required this.post,
      required this.profilePic,
      required this.profession,
      required this.time,
      required this.authorGraphId,
      required this.postId,
      required this.chatID,
      required this.postUrl,
      this.cursor,
      this.view,
      this.mutual});
  Future apiFullPostView(
      String postID, bool selfTrue, int authorGId, String? chatID) async {
    print("chatt id is $chatID");
    var request = await d.dio.get(
        'http://${IP.ipAddress}/v1/api/feed/post/view?postId=$postId&selfPost=$selfTrue&authorGraphId=$authorGId&chatID=$chatID');

    //print(request.data);
    if (request.statusCode == 200) {
    } else {
      print(request.statusMessage);
    }
    List chatIDs = [];
    String chatId;
    print(selfTrue);
    if (selfTrue == false) {
      print(request.data['data']['chatId']);
      chatId = request.data['data']['chatId'];
      return chatId;
    } else {
      if (request.data['data'].length > 0) {
        for (var cid in request.data['data']) {
          print(cid['chatId']);
          chatIDs.add(cid['chatId']);
        }
      }
    }
    return chatIDs;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, value, child) {
        final cp = Provider.of<ChatProvider>(context, listen: false);
        final cpr = Provider.of<ChatRProvider>(context, listen: false);
        return InkWell(
          onTap: () async {
            if (selfCreated == true) {
              List cId = await apiFullPostView(
                  postId, selfCreated, authorGraphId, chatID ?? null);
              print('object is $authorGraphId');
              cp.setData(
                  nameData: firstName,
                  postData: post,
                  postIDData: postId,
                  professionData: profession,
                  timeData: time,
                  graphData: authorGraphId,
                  socketData: socket,
                  chatsId: cId,
                  chatId: "",
                  mutual: mutual ?? "",
                  profileData: profilePic);
              cpr.setData(
                  postCursor: 0,
                  nameData: firstName,
                  postData: post,
                  postIDData: postId,
                  professionData: profession,
                  timeData: time,
                  graphData: authorGraphId,
                  socketData: socket,
                  postUrl: postUrl ?? "",
                  chatId: "",
                  mutual: mutual ?? "",
                  profileData: profilePic);

              Navigator.pushNamed(context, '/self');
            } else {
              String cId = await apiFullPostView(
                  postId, selfCreated, authorGraphId, chatID ?? null);
              print("graph id is $authorGraphId");
              cp.setData(
                  nameData: firstName,
                  postData: post,
                  postIDData: postId,
                  professionData: profession,
                  timeData: time,
                  graphData: authorGraphId,
                  socketData: socket,
                  chatsId: [],
                  chatId: cId,
                  mutual: mutual ?? "",
                  profileData: profilePic);
              Navigator.pushNamed(context, '/chat');
            }
          },
          child: Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.014,
                left: MediaQuery.of(context).size.width * 0.0,
                right: MediaQuery.of(context).size.width * 0.0),
            child: Container(
              color: Colors.white,
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.004,
                    left: MediaQuery.of(context).size.width * 0.0),
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
                                  top:
                                      MediaQuery.of(context).size.height * 0.00,
                                  left:
                                      MediaQuery.of(context).size.width * 0.02),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(context, '/seeProfile',
                                      arguments: {'graphID': authorGraphId});
                                  gp.setGID(authorGraphId);
                                },
                                child: profilePic.isNotEmpty
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          profilePic,
                                        ),
                                        radius:
                                            MediaQuery.of(context).size.height *
                                                0.024,
                                      )
                                    : CircleAvatar(
                                        radius:
                                            MediaQuery.of(context).size.height *
                                                0.024,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.account_circle_outlined,
                                          color: Colors.grey,
                                          size: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.05,
                                        ),
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
                                width: MediaQuery.of(context).size.width * 0.82,
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Icon(
                                                Icons.remove_red_eye,
                                                color: Colors.grey,
                                                size: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.014,
                                              ),
                                              SizedBox(
                                                width: 2,
                                              ),
                                              Text(
                                                view.toString(),
                                                style: GoogleFonts.roboto(
                                                  textStyle: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Color(0xffA8A8A8),
                                                      // fontWeight: FontWeight.bold,
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.013),
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
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 0.0, right: 4),
                                    child: Text(
                                      profession,
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
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 2.0, right: 6),
                                    child: CircleAvatar(
                                      radius: 2,
                                      backgroundColor: Colors.grey,
                                    ),
                                  ),
                                  Text(
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
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height * 0.01,
                          left: MediaQuery.of(context).size.width * 0.03),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 1,
                        child: ReadMoreText(
                          post,
                          trimLines: 3,
                          colorClickableText: Color(0xff336FD7),
                          trimMode: TrimMode.Line,

                          // overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          //softWrap: true,
                          trimCollapsedText: 'show more',
                          trimExpandedText: '  show less',
                          style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                                color: Color(0xff373737),
                                fontWeight: FontWeight.w400,
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.022),
                          ),
                        ),
                      ),
                    ),
                    postUrl!.isNotEmpty
                        ? Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).size.height * 0.014,
                                left: MediaQuery.of(context).size.width * 0.0),
                            child: AspectRatio(
                              aspectRatio: 16 / 13,
                              child: Image.network(
                                postUrl ?? "",
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                width: MediaQuery.of(context).size.width * 1,
                                fit: BoxFit.fill,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.5,
                                    width:
                                        MediaQuery.of(context).size.width * 1,
                                    child: Center(
                                        child: Text(
                                      "Failed to load image",
                                      style: GoogleFonts.roboto(
                                        textStyle: TextStyle(
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xffA8A8A8),
                                            // fontWeight: FontWeight.bold,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.018),
                                      ),
                                    )),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.5,
                                    width:
                                        MediaQuery.of(context).size.width * 1,
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
