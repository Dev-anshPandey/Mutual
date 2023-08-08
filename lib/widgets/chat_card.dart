import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../provider/graphID_provider.dart';

class ChatCard extends StatelessWidget {
  //const ChatCard({super.key});
  String text;
  bool right = true;
  String profilePic;
  String name;
  String postId2;
  String time;
  String profession;
  String mutual;
  String chatId;
  int cursor;
  int graphId;
  ChatCard(
      {required this.text,
      required this.graphId,
      required this.cursor,
      required this.profession,
      required this.time,
      required this.right,
      required this.chatId,
      required this.profilePic,
      required this.postId2,
      required this.mutual,
      required this.name});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: right == true
              ? MediaQuery.of(context).size.width * 0.0
              : MediaQuery.of(context).size.width * 0.03,
          top: MediaQuery.of(context).size.height * 0.004,
          bottom: MediaQuery.of(context).size.height * 0.0,
          right: right == true
              ? MediaQuery.of(context).size.width * 0.03
              : MediaQuery.of(context).size.width * 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            right == true ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, value, child) {
              final gp = Provider.of<GraphID>(context, listen: false);
              return Visibility(
                visible: !right,
                child: Padding(
                  padding: EdgeInsets.only(left: 2, right: 2),
                  child: InkWell(
                    onTap: () {
                      gp.setGID(graphId);
                      Navigator.pushNamed(context, '/seeProfile');
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.grey,
                      radius: MediaQuery.of(context).size.height * 0.014,
                      backgroundImage: NetworkImage(
                        profilePic,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(children: [
                Container(
                  constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width * 0.2,
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                      gradient: right == true
                          ? const LinearGradient(
                              colors: [Color(0xffE5EEFF), Color(0xffE5EEFF)])
                          : const LinearGradient(
                              colors: [Color(0xffEFEFEF), Color(0xffEFEFEF)]),
                      borderRadius: right == true
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              topRight: Radius.circular(12),
                              // bottomRight: Radius.circular(8)
                            )
                          : const BorderRadius.only(
                              topRight: Radius.circular(16),
                              topLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              //bottomLeft: Radius.circular(24)
                            )),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        //crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          right == false
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12.0, right: 10, top: 8, bottom: 0),
                                  child: Text(name,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.roboto(
                                          textStyle: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.0175,
                                      ))),
                                )
                              : Container(
                                  height: 0,
                                ),
                          right == false
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, right: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Color(0xff336FD7),
                                        radius: 5,
                                        child: CircleAvatar(
                                          radius: 4,
                                          backgroundColor: Colors.white,
                                          child: Text(
                                            'm',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.roboto(
                                                textStyle: TextStyle(
                                              color: Color(0xff336FD7),
                                              fontWeight: FontWeight.w400,
                                              fontSize: MediaQuery.of(context)
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
                                      Text("$mutual",
                                          style: GoogleFonts.roboto(
                                              textStyle: TextStyle(
                                            color: Color(0xff336FD7),
                                            fontWeight: FontWeight.w400,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.011,
                                          )))
                                    ],
                                  ),
                                )
                              : Container(
                                  height: 0,
                                  width: 0,
                                )
                        ],
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.only(
                      //       left: 12.0, right: 0, top: 1, bottom: 0),
                      //   child: Text(profession,
                      //       textAlign: TextAlign.start,
                      //       style: GoogleFonts.roboto(
                      //           textStyle: TextStyle(
                      //         color: Color(0xff336FD7),
                      //         // fontWeight: FontWeight.w700,
                      //         fontSize:
                      //             MediaQuery.of(context).size.height * 0.011,
                      //       ))),
                      // ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 12.0, right: 20, top: 6, bottom: 14),
                        child: Text(text,
                            textAlign: TextAlign.start,
                            style: GoogleFonts.roboto(
                                textStyle: TextStyle(
                              color: Color(0xff373737),
                              fontWeight: FontWeight.w400,
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.0165,
                            ))),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 6,
                  child: Padding(
                    padding: EdgeInsets.only(
                        //  left: MediaQuery.of(context).size.width * 0.3,
                        right: 1,
                        top: 0,
                        bottom: 4),
                    child: Text(time,
                        textAlign: TextAlign.start,
                        style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                          color: right == true ? Colors.grey : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: MediaQuery.of(context).size.height * 0.01,
                        ))),
                  ),
                )
              ]),
            ],
          ),
          // Visibility(
          //   visible: right,
          //   child: Padding(
          //     padding: EdgeInsets.only(left: 6),
          //     child: CircleAvatar(
          //       backgroundColor: Colors.grey,
          //       backgroundImage: NetworkImage(profilePic),
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }
}