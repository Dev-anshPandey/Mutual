import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mutual/provider/chat_provider.dart';
import 'package:provider/provider.dart';

class FeedCard3 extends StatelessWidget {
  String firstName;
  String profilePic;
  String post;
  String profession;
  String? mutual;
  String time;
  int? cursor;
  int authorGraphId;
  String postId;
  FeedCard3(
      {required this.firstName,
      required this.post,
      required this.profilePic,
      required this.profession,
      required this.time,
      required this.authorGraphId,
      required this.postId,
      this.cursor,
      this.mutual});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, value, child) {
        final cp = Provider.of<ChatProvider>(context, listen: false);
        return InkWell(
          onTap: () {
            // cp.setData(
            //     nameData: firstName,
            //     postData: post,
            //     postIDData: postId,
            //     professionData: profession,
            //     timeData: time,
            //     graphData: authorGraphId,
            //     socketData: socket,
            //     profileData: profilePic);
            // selfCreated==true?Navigator.pushNamed(context, '/self'):Navigator.pushNamed(context, '/chat');
          },
          child: Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.00,
                left: MediaQuery.of(context).size.width * 0.0,
                right: MediaQuery.of(context).size.width * 0.0),
            child: Container(
              color: Colors.grey.withOpacity(0.036),
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.00,
                    left: MediaQuery.of(context).size.width * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Consumer<GraphID>(
                        //   builder: (context, value, child) {
                        //     final gp =
                        //         Provider.of<GraphID>(context, listen: false);
                        //     return Padding(
                        //       padding: EdgeInsets.only(
                        //         left: MediaQuery.of(context).size.width * 0.00,
                        //         top: MediaQuery.of(context).size.height * 0.00,
                        //       ),
                        //       child: InkWell(
                        //         onTap: () {
                        //           Navigator.pushNamed(context, '/seeProfile',
                        //               arguments: {'graphID': authorGraphId});
                        //           gp.setGID(authorGraphId);
                        //         },
                        //         child: CircleAvatar(
                        //           backgroundImage: NetworkImage(
                        //             profilePic,
                        //           ),
                        //           radius: 28,
                        //         ),
                        //       ),
                        //     );
                        //   },
                        // ),
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
                                        // Text(
                                        //   firstName,
                                        //   style: GoogleFonts.roboto(
                                        //     textStyle: TextStyle(
                                        //         color: Colors.black,
                                        //         fontWeight: FontWeight.w600,
                                        //         fontSize: MediaQuery.of(context)
                                        //                 .size
                                        //                 .height *
                                        //             0.019),
                                        //   ),
                                        // ),
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
                                                                0.008,
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
                                                              0.011,
                                                        )))
                                                  ],
                                                ),
                                              ),
                                      ],
                                    ),
                                    // Padding(
                                    //   padding: EdgeInsets.only(
                                    //       top: MediaQuery.of(context)
                                    //               .size
                                    //               .height *
                                    //           0.0),
                                    //   child: Text(
                                    //     time,
                                    //     style: GoogleFonts.roboto(
                                    //       textStyle: TextStyle(
                                    //           fontWeight: FontWeight.w400,
                                    //           color: Color(0xffA8A8A8),
                                    //           // fontWeight: FontWeight.bold,
                                    //           fontSize: MediaQuery.of(context)
                                    //                   .size
                                    //                   .height *
                                    //               0.013),
                                    //     ),
                                    //   ),
                                    // )
                                  ],
                                ),
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
                              //                   0.011),
                              //     ),
                              //   ),
                              // ),
                              // SizedBox(
                              //   height: 18,
                              // ),
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
                    // SizedBox(
                    //   height: 10,
                    // ),
                    // Divider(color: Colors.grey,height: 10,)
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