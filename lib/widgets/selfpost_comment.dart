import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../provider/chat_provider.dart';
import '../provider/graphID_provider.dart';
import '../screens/self_post.dart';

class Comment extends StatelessWidget {
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
  Comment(
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
